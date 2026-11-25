import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  group('KosProvider Unit Tests', () {
    test('Initial state is correct', () {
      final provider = KosProvider(
        repository: KosRepository(customFetcher: () async => []),
      );

      expect(provider.kosList, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('fetchKosList updates state and notifies listeners on success', () async {
      final repository = KosRepository(
        customFetcher: () async => [
          {
            'id': 'kos-1',
            'owner_id': 'owner-1',
            'name': 'Kos Sejahtera',
            'area': 'Kukusan',
            'price': 800000,
            'type': 'Putra',
            'facilities': ['Wi-Fi'],
            'rooms_available': 2,
            'contact_name': 'Pak RT',
            'contact_phone': '0812345678',
          }
        ],
      );

      final provider = KosProvider(repository: repository);
      final listenerStates = <bool>[];
      provider.addListener(() {
        listenerStates.add(provider.isLoading);
      });

      await provider.fetchKosList();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.kosList.length, 1);
      expect(provider.kosList.first.name, 'Kos Sejahtera');
      expect(listenerStates, [true, false]);
    });

    test('fetchKosList sets errorMessage on connection/repository failure', () async {
      final repository = KosRepository(
        customFetcher: () async {
          throw const KosRepositoryException('Gagal memuat data, periksa koneksi Anda');
        },
      );

      final provider = KosProvider(repository: repository);
      await provider.fetchKosList();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, 'Gagal memuat data, periksa koneksi Anda');
      expect(provider.kosList, isEmpty);
    });

    test('fetchKosList sanitizes network details in repository exceptions', () async {
      final repository = KosRepository(
        customFetcher: () async {
          throw const KosRepositoryException(
            'SocketException: Failed host lookup: example.invalid',
          );
        },
      );
      final provider = KosProvider(repository: repository);

      await provider.fetchKosList();

      expect(provider.errorMessage, 'Gagal memuat data, periksa koneksi Anda');
      expect(provider.errorMessage, isNot(contains('SocketException')));
      expect(provider.errorMessage, isNot(contains('example.invalid')));
    });

    test('fetchKosList clears errorMessage on retry success', () async {
      var shouldFail = true;
      final repository = KosRepository(
        customFetcher: () async {
          if (shouldFail) {
            throw const KosRepositoryException('Gagal memuat data, periksa koneksi Anda');
          }
          return [
            {
              'id': 'kos-1',
              'owner_id': 'owner-1',
              'name': 'Kos Sejahtera',
              'area': 'Kukusan',
              'price': 800000,
              'type': 'Putra',
              'facilities': ['Wi-Fi'],
              'rooms_available': 2,
              'contact_name': 'Pak RT',
              'contact_phone': '0812345678',
            }
          ];
        },
      );

      final provider = KosProvider(repository: repository);

      // 1. Initial attempt fails
      await provider.fetchKosList();
      expect(provider.errorMessage, isNotNull);
      expect(provider.kosList, isEmpty);

      // 2. Retry succeeds
      shouldFail = false;
      await provider.fetchKosList();
      expect(provider.errorMessage, isNull);
      expect(provider.kosList.length, 1);
    });
  });
}
