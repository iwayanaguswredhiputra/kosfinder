import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  group('KosRepository Unit Tests', () {
    final sampleRawList = [
      {
        'id': 'kos-1',
        'owner_id': 'owner-1',
        'name': 'Kos Sakura',
        'area': 'Kukusan',
        'price': 1000000,
        'type': 'Putri',
        'facilities': ['Wi-Fi', 'AC'],
        'rooms_available': 2,
        'contact_name': 'Ibu Ani',
        'contact_phone': '0811111111',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'kos-2',
        'owner_id': 'owner-2',
        'name': 'Kos Bambu',
        'area': 'Margonda',
        'price': 750000,
        'type': 'Putra',
        'facilities': ['Wi-Fi'],
        'rooms_available': 0,
        'contact_name': 'Pak Budi',
        'contact_phone': '0822222222',
        'created_at': '2026-01-02T00:00:00.000Z',
        'updated_at': '2026-01-02T00:00:00.000Z',
      },
    ];

    test('getKosList returns List<KosModel> successfully when data is fetched', () async {
      final repository = KosRepository(
        customFetcher: () async => sampleRawList,
      );

      final result = await repository.getKosList();

      expect(result.length, 2);
      expect(result[0].id, 'kos-1');
      expect(result[0].name, 'Kos Sakura');
      expect(result[0].isAvailable, true);
      expect(result[1].id, 'kos-2');
      expect(result[1].name, 'Kos Bambu');
      expect(result[1].isAvailable, false);
    });

    test('getKosList returns empty list when response is empty', () async {
      final repository = KosRepository(
        customFetcher: () async => [],
      );

      final result = await repository.getKosList();
      expect(result, isEmpty);
    });

    test('getKosList throws KosRepositoryException with standard message on network/connection failure', () async {
      final repository = KosRepository(
        customFetcher: () async {
          throw const SocketException('No Internet Connection');
        },
      );

      expect(
        () async => await repository.getKosList(),
        throwsA(
          isA<KosRepositoryException>().having(
            (e) => e.message,
            'message',
            'Gagal memuat data, periksa koneksi Anda',
          ),
        ),
      );
    });

    test('getKosList sanitizes client, timeout, and DNS failures', () async {
      final networkErrors = <Object>[
        Exception('ClientException: Failed to fetch'),
        TimeoutException('request timed out'),
        Exception('Failed host lookup: example.invalid'),
      ];

      for (final error in networkErrors) {
        final repository = KosRepository(
          customFetcher: () async => throw error,
        );

        await expectLater(
          repository.getKosList(),
          throwsA(
            isA<KosRepositoryException>()
                .having(
                  (exception) => exception.message,
                  'friendly message',
                  'Gagal memuat data, periksa koneksi Anda',
                )
                .having(
                  (exception) => exception.message.contains('Exception:'),
                  'no exception prefix',
                  isFalse,
                ),
          ),
        );
      }
    });

    test('getKosList rethrows existing KosRepositoryException as is', () async {
      final repository = KosRepository(
        customFetcher: () async {
          throw const KosRepositoryException('Pesan error spesifik');
        },
      );

      expect(
        () async => await repository.getKosList(),
        throwsA(
          isA<KosRepositoryException>().having(
            (e) => e.message,
            'message',
            'Pesan error spesifik',
          ),
        ),
      );
    });
  });
}
