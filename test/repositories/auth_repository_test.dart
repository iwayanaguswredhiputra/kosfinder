import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthClient extends GoTrueClient {
  _FakeAuthClient() : super(autoRefreshToken: false);

  final authChanges = StreamController<AuthState>.broadcast();
  String? signUpEmail;
  String? signUpPassword;
  String? signInEmail;
  String? signInPassword;
  bool signedOut = false;
  AuthResponse signUpResponse = AuthResponse();
  AuthResponse signInResponse = AuthResponse();
  Object? signInError;

  @override
  Stream<AuthState> get onAuthStateChange => authChanges.stream;

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    signUpEmail = email;
    signUpPassword = password;
    return signUpResponse;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    final error = signInError;
    if (error != null) throw error;
    signInEmail = email;
    signInPassword = password;
    return signInResponse;
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signedOut = true;
  }
}

class _FakeSupabaseClient extends SupabaseClient {
  _FakeSupabaseClient(this.fakeAuth)
    : super(
        'https://example.supabase.co',
        'test-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final _FakeAuthClient fakeAuth;

  @override
  GoTrueClient get auth => fakeAuth;
}

void main() {
  late _FakeAuthClient fakeAuth;
  late _FakeSupabaseClient client;
  late AuthRepository repository;

  setUp(() {
    fakeAuth = _FakeAuthClient();
    client = _FakeSupabaseClient(fakeAuth);
    repository = AuthRepository(client: client);
  });

  tearDown(() async {
    await client.dispose();
    fakeAuth.dispose();
    await fakeAuth.authChanges.close();
  });

  test(
    'signUp forwards email and password and returns the auth response',
    () async {
      final response = AuthResponse();
      fakeAuth.signUpResponse = response;

      final result = await repository.signUp(
        email: 'owner@example.com',
        password: 'secure-password',
      );

      expect(fakeAuth.signUpEmail, 'owner@example.com');
      expect(fakeAuth.signUpPassword, 'secure-password');
      expect(result, same(response));
    },
  );

  test('signIn forwards credentials and returns the auth response', () async {
    final response = AuthResponse();
    fakeAuth.signInResponse = response;

    final result = await repository.signIn(
      email: 'owner@example.com',
      password: 'secure-password',
    );

    expect(fakeAuth.signInEmail, 'owner@example.com');
    expect(fakeAuth.signInPassword, 'secure-password');
    expect(result, same(response));
  });

  test('signIn propagates authentication errors', () async {
    final error = AuthException('Invalid credentials');
    fakeAuth.signInError = error;

    await expectLater(
      repository.signIn(email: 'owner@example.com', password: 'wrong'),
      throwsA(same(error)),
    );
  });

  test('signOut delegates to Supabase auth', () async {
    await repository.signOut();

    expect(fakeAuth.signedOut, isTrue);
  });

  test('authStateChanges exposes Supabase auth session events', () async {
    final eventFuture = repository.authStateChanges.first;
    final event = AuthState(AuthChangeEvent.signedOut, null);
    fakeAuth.authChanges.add(event);

    expect(await eventFuture, same(event));
  });
}
