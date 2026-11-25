import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';

Map<String, dynamic> _kosMap({
  required String id,
  String area = 'Kukusan, Beji',
  int price = 800000,
  String type = 'Putra',
  List<String> facilities = const [],
}) =>
    {
      'id': id,
      'owner_id': 'o1',
      'name': 'Kos $id',
      'area': area,
      'price': price,
      'type': type,
      'facilities': facilities,
      'rooms_available': 2,
      'contact_name': 'Pemilik',
      'contact_phone': '0812345678',
    };

KosProvider _provider(List<Map<String, dynamic>> data) {
  return KosProvider(
    repository: KosRepository(customFetcher: () async => data),
  );
}

Widget _buildApp(KosProvider provider) {
  return ChangeNotifierProvider<KosProvider>.value(
    value: provider,
    child: const MaterialApp(home: KosListScreen()),
  );
}

/// Opens filter modal and scrolls the bottom sheet so the target widget is
/// visible before tapping. Needed because the bottom-sheet can extend beyond
/// the default test canvas (800×600).
Future<void> _openModal(WidgetTester tester, KosProvider p) async {
  await tester.pumpWidget(_buildApp(p));
  await tester.pump();
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('filterButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('Filter Modal (T09)', () {
    testWidgets('filter button opens modal', (tester) async {
      final p = _provider([_kosMap(id: 'k1')]);
      await _openModal(tester, p);

      expect(find.text('Filter Kos'), findsOneWidget);
      expect(find.byKey(const Key('maxPriceField')), findsOneWidget);
    });

    testWidgets('modal shows all tipe kos chips', (tester) async {
      final p = _provider([_kosMap(id: 'k1')]);
      await _openModal(tester, p);

      expect(find.byKey(const Key('typeChip_Putra')), findsOneWidget);
      expect(find.byKey(const Key('typeChip_Putri')), findsOneWidget);
      expect(find.byKey(const Key('typeChip_Campur')), findsOneWidget);
    });

    testWidgets('modal shows all 6 fasilitas checkboxes', (tester) async {
      final p = _provider([_kosMap(id: 'k1')]);
      await _openModal(tester, p);

      for (final f in [
        'Wi-Fi',
        'Kasur',
        'Lemari',
        'Kamar Mandi Dalam',
        'AC',
        'Parkir Motor'
      ]) {
        expect(find.byKey(Key('facilityCheck_$f')), findsOneWidget);
      }
    });

    testWidgets('apply button and reset button exist in modal', (tester) async {
      final p = _provider([_kosMap(id: 'k1')]);
      await _openModal(tester, p);

      expect(find.byKey(const Key('applyFilterButton')), findsOneWidget);
      expect(find.byKey(const Key('resetFilterButton')), findsOneWidget);
    });

    // --- Behavior tests: drive provider directly (UI unit already tests modal open) ---

    testWidgets('applying type filter via provider shows only matching kos (US02-AC1)',
        (tester) async {
      final p = _provider([
        _kosMap(id: 'k1', type: 'Putra'),
        _kosMap(id: 'k2', type: 'Putri'),
      ]);
      await tester.pumpWidget(_buildApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      // Apply filter directly on provider (modal behavior tested in unit tests)
      p.setFilter(type: 'Putri');
      await tester.pumpAndSettle();

      expect(find.text('Kos k1'), findsNothing);
      expect(find.text('Kos k2'), findsOneWidget);
    });

    testWidgets('shows empty filter state message when no kos matches (US02-AC2)',
        (tester) async {
      final p = _provider([
        _kosMap(id: 'k1', type: 'Putra', price: 800000),
      ]);
      await tester.pumpWidget(_buildApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      p.setFilter(type: 'Putri');
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada kos yang cocok dengan kriteria filter Anda'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('resetFilterFromEmpty')), findsOneWidget);
    });

    testWidgets('Reset Filter button in empty state restores full list (US02-AC2)',
        (tester) async {
      final p = _provider([
        _kosMap(id: 'k1', type: 'Putra'),
        _kosMap(id: 'k2', type: 'Putri'),
      ]);
      await tester.pumpWidget(_buildApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      p.setFilter(type: 'Campur');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyFilterState')), findsOneWidget);

      await tester.tap(find.byKey(const Key('resetFilterFromEmpty')));
      await tester.pumpAndSettle();

      expect(find.text('Kos k1'), findsOneWidget);
      expect(find.text('Kos k2'), findsOneWidget);
    });

    testWidgets('inline Reset link in AppBar area resets filter', (tester) async {
      final p = _provider([_kosMap(id: 'k1', type: 'Putra')]);
      p.setFilter(type: 'Putra');
      await tester.pumpWidget(_buildApp(p));
      await tester.pump();
      await tester.pumpAndSettle();

      // "Filter aktif" summary + Reset link should appear
      expect(find.text('Filter aktif'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(p.selectedType, isNull);
      expect(find.text('Filter aktif'), findsNothing);
    });
  });
}
