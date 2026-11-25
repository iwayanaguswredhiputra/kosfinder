import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ClientException implements Exception {
  const _ClientException();
}

class _FakeAuthRepository extends AuthRepository {
  final authChanges = StreamController<AuthState>.broadcast();
  Future<AuthResponse> Function(String email, String password)? signUpHandler;
  Future<AuthResponse> Function(String email, String password)? signInHandler;
  bool signedOut = false;

  @override
  Stream<AuthState> get authStateChanges => authChanges.stream;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return signUpHandler!(email, password);
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return signInHandler!(email, password);
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

User _testUser() => const User(
  id: 'owner-1',
  appMetadata: {},
  userMetadata: null,
  aud: 'authenticated',
  email: 'owner@example.com',
  createdAt: '2026-01-01T00:00:00Z',
);

Session _testSession() => Session(
  accessToken: 'access-token',
  tokenType: 'bearer',
  user: _testUser(),
);

void main() {
  late _FakeAuthRepository repository;
  late AuthProvider provider;

  setUp(() {
    repository = _FakeAuthRepository();
    provider = AuthProvider(repository: repository);
  });

  tearDown(() async {
    provider.dispose();
    await repository.authChanges.close();
  });

  test('signUp sends credentials and updates authenticated state', () async {
    final session = _testSession();
    repository.signUpHandler = (email, password) async {
      expect(email, 'owner@example.com');
      expect(password, 'secret1');
      return AuthResponse(session: session, user: session.user);
    };

    await provider.signUp(email: 'owner@example.com', password: 'secret1');

    expect(provider.session, same(session));
    expect(provider.isAuthenticated, isTrue);
    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('signIn sends credentials and updates authenticated state', () async {
    final session = _testSession();
    repository.signInHandler = (email, password) async {
      expect(email, 'owner@example.com');
      expect(password, 'secret1');
      return AuthResponse(session: session, user: session.user);
    };

    await provider.signIn(email: 'owner@example.com', password: 'secret1');

    expect(provider.session, same(session));
    expect(provider.isAuthenticated, isTrue);
  });

  test('signIn reports invalid credentials without authenticating', () async {
    repository.signInHandler = (_, _) async {
      throw const AuthException('Invalid login credentials');
    };

    await provider.signIn(email: 'owner@example.com', password: 'wrong');

    expect(provider.isAuthenticated, isFalse);
    expect(provider.errorMessage, 'Email atau kata sandi tidak valid');
    expect(provider.isLoading, isFalse);
  });

  test('signUp reports an already registered email specifically', () async {
    repository.signUpHandler = (_, _) async {
      throw const AuthException(
        'User already registered',
        code: 'user_already_exists',
      );
    };

    await provider.signUp(email: 'owner@example.com', password: 'secret1');

    expect(provider.isAuthenticated, isFalse);
    expect(provider.errorMessage, 'Email sudah terdaftar');
    expect(provider.isLoading, isFalse);
  });

  test('signUp reports other failures as registration errors', () async {
    repository.signUpHandler = (_, _) async {
      throw const AuthException(
        'Signups are disabled',
        code: 'signup_disabled',
      );
    };

    await provider.signUp(email: 'owner@example.com', password: 'secret1');

    expect(provider.errorMessage, 'Gagal mendaftar: Signups are disabled');
  });

  test(
    'auth requests report network failures with the required message',
    () async {
      repository.signUpHandler = (_, _) async {
        throw AuthRetryableFetchException(message: 'Network unavailable');
      };

      await provider.signUp(email: 'owner@example.com', password: 'secret1');

      expect(
        provider.errorMessage,
        'Koneksi internet terputus, silakan coba beberapa saat lagi',
      );
      expect(provider.isAuthenticated, isFalse);
    },
  );

  test(
    'maps socket, client, timeout, and DNS failures to a friendly message',
    () async {
      final networkErrors = <Object>[
        const SocketException('Failed host lookup: example.invalid'),
        TimeoutException('request timed out'),
        const _ClientException(),
        Exception('Failed host lookup: example.invalid'),
      ];

      for (final error in networkErrors) {
        repository.signInHandler = (_, _) async => throw error;

        await provider.signIn(email: 'owner@example.com', password: 'secret1');

        expect(
          provider.errorMessage,
          'Koneksi internet terputus, silakan coba beberapa saat lagi',
        );
        expect(provider.errorMessage, isNot(contains('Exception:')));
        expect(provider.errorMessage, isNot(contains('example.invalid')));
      }
    },
  );

  test('auth state changes update the current session', () async {
    final session = _testSession();
    repository.authChanges.add(AuthState(AuthChangeEvent.signedIn, session));
    await Future<void>.delayed(Duration.zero);

    expect(provider.session, same(session));
    expect(provider.isAuthenticated, isTrue);
  });

  test('signOut clears session after delegating to the repository', () async {
    final session = _testSession();
    repository.authChanges.add(AuthState(AuthChangeEvent.signedIn, session));
    await Future<void>.delayed(Duration.zero);
    expect(provider.isAuthenticated, isTrue);

    await provider.signOut();

    expect(repository.signedOut, isTrue);
    expect(provider.session, isNull);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.isLoading, isFalse);
  });
}
