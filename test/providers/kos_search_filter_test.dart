import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

// Helper to build a raw kos map
Map<String, dynamic> _kosMap({
  String id = 'k1',
  String area = 'Kukusan, Beji',
  int price = 800000,
  String type = 'Putra',
  List<String> facilities = const ['Wi-Fi', 'AC'],
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

KosProvider _buildProvider(List<Map<String, dynamic>> data) {
  final repo = KosRepository(customFetcher: () async => data);
  return KosProvider(repository: repo);
}

void main() {
  group('KosProvider – Search & Filter (T07)', () {
    // ── US01-AC2: case-insensitive area search ──────────────────────────────
    test('setSearchQuery filters by area case-insensitively (US01-AC2)', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', area: 'Kukusan, Beji'),
        _kosMap(id: 'k2', area: 'Margonda, Depok'),
      ]);
      await provider.fetchKosList();

      provider.setSearchQuery('KUKUSAN');
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, 'k1');

      provider.setSearchQuery('kukusan');
      expect(provider.filteredKosList.length, 1);
    });

    // ── US01-AC3: empty result when no area matches ─────────────────────────
    test('setSearchQuery returns empty list when no area matches (US01-AC3)', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', area: 'Kukusan, Beji'),
      ]);
      await provider.fetchKosList();

      provider.setSearchQuery('Ciputat');
      expect(provider.filteredKosList, isEmpty);
    });

    // ── US02-AC1: filter by type ────────────────────────────────────────────
    test('setFilter – type filter only returns matching type', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', type: 'Putra'),
        _kosMap(id: 'k2', type: 'Putri'),
        _kosMap(id: 'k3', type: 'Campur'),
      ]);
      await provider.fetchKosList();

      provider.setFilter(type: 'Putri');
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, 'k2');
    });

    // ── US02-AC1: filter by maxPrice ────────────────────────────────────────
    test('setFilter – maxPrice filters out expensive kos', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', price: 800000),
        _kosMap(id: 'k2', price: 1500000),
      ]);
      await provider.fetchKosList();

      provider.setFilter(maxPrice: 1000000);
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, 'k1');
    });

    // ── US02-AC1: filter by facilities checklist ────────────────────────────
    test('setFilter – facilities filter requires ALL selected facilities', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', facilities: ['Wi-Fi', 'AC']),
        _kosMap(id: 'k2', facilities: ['Wi-Fi']),
        _kosMap(id: 'k3', facilities: ['AC', 'Kasur']),
      ]);
      await provider.fetchKosList();

      provider.setFilter(facilities: {'Wi-Fi', 'AC'});
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, 'k1');
    });

    // ── US02-AC1: combined filter (type + maxPrice + facilities) ────────────
    test('setFilter – combined type + maxPrice + facilities (US02-AC1)', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', type: 'Putri', price: 900000, facilities: ['Wi-Fi', 'AC']),
        _kosMap(id: 'k2', type: 'Putri', price: 1200000, facilities: ['Wi-Fi', 'AC']),
        _kosMap(id: 'k3', type: 'Putra', price: 900000, facilities: ['Wi-Fi', 'AC']),
        _kosMap(id: 'k4', type: 'Putri', price: 900000, facilities: ['Wi-Fi']),
      ]);
      await provider.fetchKosList();

      provider.setFilter(
        type: 'Putri',
        maxPrice: 1000000,
        facilities: {'Wi-Fi', 'AC'},
      );
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, 'k1');
    });

    // ── US02-AC2: empty filter result ───────────────────────────────────────
    test('setFilter – returns empty list when no kos matches (US02-AC2)', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', type: 'Putra', price: 800000, facilities: ['Wi-Fi']),
      ]);
      await provider.fetchKosList();

      provider.setFilter(type: 'Putri', maxPrice: 500000);
      expect(provider.filteredKosList, isEmpty);
    });

    // ── resetFilter restores full list ──────────────────────────────────────
    test('resetFilter clears all filters and restores full list', () async {
      final provider = _buildProvider([
        _kosMap(id: 'k1', type: 'Putra'),
        _kosMap(id: 'k2', type: 'Putri'),
      ]);
      await provider.fetchKosList();

      provider.setFilter(type: 'Putra');
      expect(provider.filteredKosList.length, 1);

      provider.resetFilter();
      expect(provider.filteredKosList.length, 2);
      expect(provider.maxPrice, isNull);
      expect(provider.selectedType, isNull);
      expect(provider.selectedFacilities, isEmpty);
    });

    // ── notifyListeners on setSearchQuery ───────────────────────────────────
    test('setSearchQuery notifies listeners', () async {
      final provider = _buildProvider([]);
      await provider.fetchKosList();

      var notified = false;
      provider.addListener(() => notified = true);
      provider.setSearchQuery('test');
      expect(notified, isTrue);
    });

    // ── notifyListeners on setFilter ────────────────────────────────────────
    test('setFilter notifies listeners', () async {
      final provider = _buildProvider([]);
      await provider.fetchKosList();

      var notified = false;
      provider.addListener(() => notified = true);
      provider.setFilter(maxPrice: 500000);
      expect(notified, isTrue);
    });
  });
}
