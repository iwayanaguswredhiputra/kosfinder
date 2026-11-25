import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  final authChanges = StreamController<AuthState>.broadcast();
  bool signedOut = false;

  @override
  Stream<AuthState> get authStateChanges => authChanges.stream;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  late _FakeAuthRepository repository;
  late AuthProvider authProvider;

  setUp(() {
    repository = _FakeAuthRepository();
    authProvider = AuthProvider(repository: repository);
  });

  tearDown(() async {
    authProvider.dispose();
    await repository.authChanges.close();
  });

  testWidgets('shows the empty listing state and add button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OwnerDashboardScreen(authProvider: authProvider)),
    );

    expect(find.text('Anda belum memiliki listing kos'), findsOneWidget);
    expect(find.text('Tambah Kos Sekarang'), findsOneWidget);
  });

  testWidgets('logout signs out and returns to the home screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      OwnerDashboardScreen(authProvider: authProvider),
                ),
              ),
              child: const Text('Beranda'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ownerLogoutButton')));
    await tester.pumpAndSettle();

    expect(repository.signedOut, isTrue);
    expect(authProvider.isAuthenticated, isFalse);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.byType(OwnerDashboardScreen), findsNothing);
  });
}
