import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthRepository extends AuthRepository {
  final authChanges = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get authStateChanges => authChanges.stream;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final session = _testSession();
    return AuthResponse(session: session, user: session.user);
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

void main() {
  late _FakeAuthRepository authRepository;
  late AuthProvider authProvider;
  late KosProvider kosProvider;

  setUp(() async {
    authRepository = _FakeAuthRepository();
    authProvider = AuthProvider(repository: authRepository);
    await authProvider.signIn(email: 'owner@example.com', password: 'secret1');
    kosProvider = KosProvider(
      repository: KosRepository(
        currentUserIdFetcher: () => 'owner-current',
        customFetcher: () async => [],
        customInserter: (payload) async => {...payload, 'id': 'kos-created'},
      ),
    );
  });

  tearDown(() async {
    authProvider.dispose();
    kosProvider.dispose();
    await authRepository.authChanges.close();
  });

  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<KosProvider>.value(
        value: kosProvider,
        child: MaterialApp(
          home: OwnerDashboardScreen(authProvider: authProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Kos Sekarang'));
    await tester.pumpAndSettle();
  }

  Future<void> enterField(WidgetTester tester, String key, String value) async {
    final field = find.byKey(Key(key));
    await tester.scrollUntilVisible(
      field,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.enterText(field, value);
  }

  Future<void> selectType(WidgetTester tester) async {
    final field = find.byKey(const Key('kosTypeField'));
    await tester.scrollUntilVisible(
      field,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Putri').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectFacility(WidgetTester tester, String facility) async {
    final checkbox = find.byKey(Key('kosFacility_$facility'));
    await tester.scrollUntilVisible(
      checkbox,
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(checkbox);
  }

  Future<void> enterValidForm(WidgetTester tester) async {
    await enterField(tester, 'kosNameField', 'Kos Sakura');
    await enterField(tester, 'kosAreaField', 'Kukusan');
    await enterField(tester, 'kosPriceField', '1000000');
    await selectType(tester);
    await selectFacility(tester, 'Wi-Fi');
    await selectFacility(tester, 'AC');
    await enterField(tester, 'kosRoomsField', '3');
    await enterField(tester, 'kosContactNameField', 'Ibu Ani');
    await enterField(tester, 'kosContactPhoneField', '0812345678');
  }

  testWidgets('validates missing name and negative room count', (tester) async {
    await openForm(tester);
    await enterField(tester, 'kosAreaField', 'Kukusan');
    await enterField(tester, 'kosPriceField', '1000000');
    await selectType(tester);
    await enterField(tester, 'kosRoomsField', '-1');
    await enterField(tester, 'kosContactNameField', 'Ibu Ani');
    await enterField(tester, 'kosContactPhoneField', '0812345678');
    await tester.scrollUntilVisible(
      find.byKey(const Key('kosSaveButton')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('kosSaveButton')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Nama kos wajib diisi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('kosRoomsField')),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sisa kamar tidak boleh negatif'), findsOneWidget);
    expect(kosProvider.kosList, isEmpty);
    expect(find.byType(KosFormScreen), findsOneWidget);
  });

  testWidgets(
    'saves listing with selected facilities and shows it on dashboard',
    (tester) async {
      await openForm(tester);
      await enterValidForm(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('kosSaveButton')),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('kosSaveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(OwnerDashboardScreen), findsOneWidget);
      expect(find.text('Kos Sakura'), findsOneWidget);
      expect(find.text('Anda belum memiliki listing kos'), findsNothing);
      expect(kosProvider.kosList.single.ownerId, 'owner-current');
      expect(
        kosProvider.kosList.single.facilities,
        containsAll(['Wi-Fi', 'AC']),
      );
    },
  );
}
