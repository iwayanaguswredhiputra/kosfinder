import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/auth_screen.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  final authChanges = StreamController<AuthState>.broadcast();
  Future<AuthResponse> Function(String email, String password)? signInHandler;
  Future<AuthResponse> Function(String email, String password)? signUpHandler;

  @override
  Stream<AuthState> get authStateChanges => authChanges.stream;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return signInHandler!(email, password);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return signUpHandler!(email, password);
  }
}

Session _testSession() {
  const user = User(
    id: 'owner-1',
    appMetadata: {},
    userMetadata: null,
    aud: 'authenticated',
    email: 'owner@example.com',
    createdAt: '2026-01-01T00:00:00Z',
  );
  return Session(accessToken: 'access-token', tokenType: 'bearer', user: user);
}

void main() {
  late _FakeAuthRepository repository;
  late AuthProvider authProvider;
  late KosProvider kosProvider;

  setUp(() {
    repository = _FakeAuthRepository();
    authProvider = AuthProvider(repository: repository);
    kosProvider = KosProvider(
      repository: KosRepository(customFetcher: () async => []),
    );
  });

  tearDown(() async {
    authProvider.dispose();
    kosProvider.dispose();
    await repository.authChanges.close();
  });

  Future<void> pumpAuthScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<KosProvider>.value(
        value: kosProvider,
        child: MaterialApp(home: AuthScreen(authProvider: authProvider)),
      ),
    );
  }

  Future<void> enterValidCredentials(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('authEmailField')),
      'owner@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('authPasswordField')),
      'secret1',
    );
  }

  testWidgets('validates email format and minimum password length', (
    tester,
  ) async {
    await pumpAuthScreen(tester);
    await tester.enterText(find.byKey(const Key('authEmailField')), 'invalid');
    await tester.enterText(find.byKey(const Key('authPasswordField')), '123');
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pump();

    expect(find.text('Masukkan format email yang valid'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('shows invalid credentials without leaving the screen', (
    tester,
  ) async {
    repository.signInHandler = (_, _) async {
      throw const AuthException('Invalid login credentials');
    };
    await pumpAuthScreen(tester);
    await enterValidCredentials(tester);
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi tidak valid'), findsOneWidget);
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('shows the network error for login and registration', (
    tester,
  ) async {
    var signUpAttempts = 0;
    String? submittedEmail;
    String? submittedPassword;
    Future<AuthResponse> networkFailure(String _, String _) async {
      throw AuthRetryableFetchException(message: 'Network unavailable');
    }

    repository.signInHandler = networkFailure;
    repository.signUpHandler = networkFailure;
    await pumpAuthScreen(tester);
    await enterValidCredentials(tester);
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    const message =
        'Koneksi internet terputus, silakan coba beberapa saat lagi';
    expect(find.text(message), findsOneWidget);

    await tester.tap(find.text('Registrasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(find.byKey(const Key('authRetryButton')), findsOneWidget);

    final session = _testSession();
    repository.signUpHandler = (email, password) async {
      signUpAttempts++;
      submittedEmail = email;
      submittedPassword = password;
      return AuthResponse(session: session, user: session.user);
    };
    await tester.tap(find.byKey(const Key('authRetryButton')));
    await tester.pumpAndSettle();

    expect(signUpAttempts, 1);
    expect(submittedEmail, 'owner@example.com');
    expect(submittedPassword, 'secret1');
    expect(find.byType(OwnerDashboardScreen), findsOneWidget);
  });

  testWidgets('successful login navigates to the owner dashboard', (
    tester,
  ) async {
    final session = _testSession();
    repository.signInHandler = (_, _) async =>
        AuthResponse(session: session, user: session.user);
    await tester.pumpWidget(
      ChangeNotifierProvider<KosProvider>.value(
        value: kosProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthScreen(authProvider: authProvider),
                  ),
                ),
                child: const Text('Beranda'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await enterValidCredentials(tester);
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.byType(OwnerDashboardScreen), findsOneWidget);
    expect(authProvider.isAuthenticated, isTrue);
  });

  testWidgets('successful registration navigates to the owner dashboard', (
    tester,
  ) async {
    final session = _testSession();
    repository.signUpHandler = (_, _) async =>
        AuthResponse(session: session, user: session.user);
    await tester.pumpWidget(
      ChangeNotifierProvider<KosProvider>.value(
        value: kosProvider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthScreen(authProvider: authProvider),
                  ),
                ),
                child: const Text('Beranda'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrasi'));
    await tester.pumpAndSettle();
    await enterValidCredentials(tester);
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.byType(OwnerDashboardScreen), findsOneWidget);
    expect(authProvider.isAuthenticated, isTrue);
  });
}
