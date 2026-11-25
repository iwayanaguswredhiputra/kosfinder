import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  final authChanges = StreamController<AuthState>.broadcast();
  bool signedOut = false;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final session = _testSession();
    return AuthResponse(session: session, user: session.user);
  }

  @override
  Stream<AuthState> get authStateChanges => authChanges.stream;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

Session _testSession() {
  const user = User(
    id: 'owner-current',
    appMetadata: {},
    userMetadata: null,
    aud: 'authenticated',
    email: 'owner@example.com',
    createdAt: '2026-01-01T00:00:00Z',
  );
  return Session(accessToken: 'access-token', tokenType: 'bearer', user: user);
}

Widget _dashboardApp(AuthProvider authProvider, KosProvider kosProvider) {
  return ChangeNotifierProvider<KosProvider>.value(
    value: kosProvider,
    child: MaterialApp(home: OwnerDashboardScreen(authProvider: authProvider)),
  );
}

Map<String, dynamic> _kosMap(String id, String ownerId, String name) => {
  'id': id,
  'owner_id': ownerId,
  'name': name,
  'area': 'Kukusan',
  'price': 800000,
  'type': 'Putra',
  'facilities': <String>[],
  'rooms_available': 2,
  'contact_name': 'Pemilik',
  'contact_phone': '0812345678',
};

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

  testWidgets('shows the empty listing state and add button', (tester) async {
    await tester.pumpWidget(_dashboardApp(authProvider, kosProvider));
    await tester.pumpAndSettle();

    expect(find.text('Anda belum memiliki listing kos'), findsOneWidget);
    expect(find.text('Tambah Kos Sekarang'), findsOneWidget);
  });

  testWidgets('shows only listings owned by the authenticated user', (
    tester,
  ) async {
    await authProvider.signIn(email: 'owner@example.com', password: 'secret1');
    final ownerKosProvider = KosProvider(
      repository: KosRepository(
        customFetcher: () async => [
          _kosMap('mine', 'owner-current', 'Kos Saya'),
          _kosMap('other', 'owner-other', 'Kos Orang Lain'),
        ],
      ),
    );
    addTearDown(ownerKosProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, ownerKosProvider));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('ownerKosList')),
        matching: find.text('Kos Saya'),
      ),
      findsOneWidget,
    );
    expect(find.text('Kos Orang Lain'), findsNothing);
    expect(find.byKey(const Key('ownerKosList')), findsOneWidget);
    expect(find.byKey(const Key('decreaseRooms_mine')), findsNothing);
    expect(find.byKey(const Key('increaseRooms_mine')), findsNothing);
    expect(find.byKey(const Key('editKos_mine')), findsOneWidget);
    expect(find.byKey(const Key('deleteKos_mine')), findsOneWidget);
  });

  testWidgets('canceling delete keeps the listing and confirming removes it', (
    tester,
  ) async {
    await authProvider.signIn(email: 'owner@example.com', password: 'secret1');
    String? deletedId;
    var failDelete = true;
    final ownerKosProvider = KosProvider(
      repository: KosRepository(
        customFetcher: () async => [
          _kosMap('mine', 'owner-current', 'Kos Saya'),
        ],
        customDeleter: (id) async {
          if (failDelete) throw StateError('raw connection details');
          deletedId = id;
        },
      ),
    );
    addTearDown(ownerKosProvider.dispose);

    await tester.pumpWidget(_dashboardApp(authProvider, ownerKosProvider));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteKos_mine')));
    await tester.pumpAndSettle();

    expect(find.text('Hapus listing?'), findsOneWidget);
    expect(
      find.text('Listing "Kos Saya" akan dihapus permanen.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancelDeleteKosButton')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('ownerKosList')),
        matching: find.text('Kos Saya'),
      ),
      findsOneWidget,
    );
    expect(deletedId, isNull);

    await tester.tap(find.byKey(const Key('deleteKos_mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDeleteKosButton')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tidak dapat menghapus listing. Periksa koneksi internet Anda, lalu coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ownerDeleteRetryButton')), findsOneWidget);
    expect(deletedId, isNull);

    failDelete = false;
    await tester.tap(find.byKey(const Key('ownerDeleteRetryButton')));
    await tester.pumpAndSettle();

    expect(deletedId, 'mine');
    expect(find.byKey(const Key('ownerKosList')), findsNothing);
    expect(find.text('Kos Saya'), findsOneWidget);
    expect(find.text('Anda belum memiliki listing kos'), findsOneWidget);
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
                  builder: (_) => ChangeNotifierProvider<KosProvider>.value(
                    value: kosProvider,
                    child: OwnerDashboardScreen(authProvider: authProvider),
                  ),
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
