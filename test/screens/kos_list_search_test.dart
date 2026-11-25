import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';

Map<String, dynamic> _kosMap(String id, String area) => {
      'id': id,
      'owner_id': 'o1',
      'name': 'Kos $id',
      'area': area,
      'price': 800000,
      'type': 'Putra',
      'facilities': <String>[],
      'rooms_available': 2,
      'contact_name': 'Pemilik',
      'contact_phone': '0812345678',
    };

Widget _buildTestApp(KosProvider provider) {
  return ChangeNotifierProvider<KosProvider>.value(
    value: provider,
    child: const MaterialApp(home: KosListScreen()),
  );
}

KosProvider _provider(List<Map<String, dynamic>> data) {
  return KosProvider(
    repository: KosRepository(customFetcher: () async => data),
  );
}

void main() {
  group('KosListScreen – Search (T08)', () {
    testWidgets('search field is visible', (tester) async {
      final p = _provider([_kosMap('k1', 'Kukusan, Beji')]);
      await tester.pumpWidget(_buildTestApp(p));
      await tester.pump(); // let initState schedule
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('searchField')), findsOneWidget);
    });

    testWidgets('typing in search field filters by area (US01-AC2)', (tester) async {
      final p = _provider([
        _kosMap('k1', 'Kukusan, Beji'),
        _kosMap('k2', 'Margonda, Depok'),
      ]);
      await tester.pumpWidget(_buildTestApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchField')), 'KUKUSAN');
      await tester.pumpAndSettle();

      expect(find.text('Kos k1'), findsOneWidget);
      expect(find.text('Kos k2'), findsNothing);
    });

    testWidgets('shows empty message when search has no match (US01-AC3)', (tester) async {
      final p = _provider([_kosMap('k1', 'Kukusan, Beji')]);
      await tester.pumpWidget(_buildTestApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchField')), 'Ciputat');
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada kos yang ditemukan di area ini'),
        findsOneWidget,
      );
    });

    testWidgets('clear button clears search and restores list', (tester) async {
      final p = _provider([
        _kosMap('k1', 'Kukusan, Beji'),
        _kosMap('k2', 'Margonda, Depok'),
      ]);
      await tester.pumpWidget(_buildTestApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchField')), 'kukusan');
      await tester.pumpAndSettle();
      expect(find.text('Kos k2'), findsNothing);

      await tester.tap(find.byKey(const Key('clearSearchButton')));
      await tester.pumpAndSettle();
      expect(find.text('Kos k1'), findsOneWidget);
      expect(find.text('Kos k2'), findsOneWidget);
    });
  });
}
