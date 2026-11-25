import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  const ownerId = 'owner-current';

  KosModel makeKos({
    String id = 'kos-1',
    String ownerId = 'owner-supplied',
    int roomsAvailable = 2,
  }) {
    return KosModel(
      id: id,
      ownerId: ownerId,
      name: 'Kos Sakura',
      area: 'Kukusan',
      price: 1000000,
      type: 'Putri',
      facilities: const ['Wi-Fi', 'AC'],
      roomsAvailable: roomsAvailable,
      contactName: 'Ibu Ani',
      contactPhone: '0811111111',
    );
  }

  Map<String, dynamic> persistedKos({
    String id = 'kos-1',
    String ownerId = ownerId,
    int roomsAvailable = 2,
  }) {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': 'Kos Sakura',
      'area': 'Kukusan',
      'price': 1000000,
      'type': 'Putri',
      'facilities': ['Wi-Fi', 'AC'],
      'rooms_available': roomsAvailable,
      'contact_name': 'Ibu Ani',
      'contact_phone': '0811111111',
    };
  }

  group('KosRepository CRUD', () {
    test('addKos inserts listing with authenticated owner id', () async {
      Map<String, dynamic>? inserted;
      final repository = KosRepository(
        currentUserIdFetcher: () => ownerId,
        customInserter: (payload) async {
          inserted = payload;
          return {...payload, 'id': 'kos-created'};
        },
      );

      final created = await repository.addKos(makeKos());

      expect(inserted?['owner_id'], ownerId);
      expect(inserted, isNot(contains('id')));
      expect(created.id, 'kos-created');
      expect(created.ownerId, ownerId);
    });

    test('addKos rejects unauthenticated owners', () async {
      final repository = KosRepository(
        currentUserIdFetcher: () => null,
        customInserter: (_) async => persistedKos(),
      );

      await expectLater(
        repository.addKos(makeKos()),
        throwsA(isA<KosRepositoryException>()),
      );
    });

    test('updateKos persists zero rooms without changing owner', () async {
      String? updatedId;
      Map<String, dynamic>? updatePayload;
      final repository = KosRepository(
        customUpdater: (id, payload) async {
          updatedId = id;
          updatePayload = payload;
          return persistedKos(roomsAvailable: 0);
        },
      );

      final updated =
          await repository.updateKos(makeKos(roomsAvailable: 0));

      expect(updatedId, 'kos-1');
      expect(updatePayload?['rooms_available'], 0);
      expect(updatePayload, isNot(contains('owner_id')));
      expect(updated.isAvailable, isFalse);
    });

    test('deleteKos targets the requested listing', () async {
      String? deletedId;
      final repository = KosRepository(
        customDeleter: (id) async => deletedId = id,
      );

      await repository.deleteKos('kos-1');

      expect(deletedId, 'kos-1');
    });

    test('provider updates local state only after successful CRUD', () async {
      final provider = KosProvider(
        repository: KosRepository(
          currentUserIdFetcher: () => ownerId,
          customInserter: (payload) async =>
              {...payload, 'id': 'kos-1'},
          customUpdater: (id, payload) async => persistedKos(
            id: id,
            ownerId: ownerId,
            roomsAvailable: payload['rooms_available'] as int,
          ),
          customDeleter: (_) async {
            throw const KosRepositoryException('Unauthorized / Forbidden');
          },
        ),
      );

      await provider.addKos(makeKos());
      expect(provider.kosList, hasLength(1));
      expect(provider.kosList.single.ownerId, ownerId);

      await provider.updateKos(makeKos(roomsAvailable: 0));
      expect(provider.kosList.single.roomsAvailable, 0);
      expect(provider.kosList.single.isAvailable, isFalse);

      await expectLater(
        provider.deleteKos('kos-1'),
        throwsA(
          isA<KosRepositoryException>().having(
            (error) => error.message,
            'message',
            'Unauthorized / Forbidden',
          ),
        ),
      );
      expect(provider.kosList, hasLength(1));
    });

    test('provider preserves listing when RLS rejects update or delete', () async {
      final original = persistedKos();
      final provider = KosProvider(
        repository: KosRepository(
          customFetcher: () async => [original],
          customUpdater: (_, _) async {
            throw const KosRepositoryException('Unauthorized / Forbidden');
          },
          customDeleter: (_) async {
            throw const KosRepositoryException('Unauthorized / Forbidden');
          },
        ),
      );
      await provider.fetchKosList();

      await expectLater(
        provider.updateKos(makeKos(roomsAvailable: 0)),
        throwsA(isA<KosRepositoryException>()),
      );
      await expectLater(
        provider.deleteKos('kos-1'),
        throwsA(isA<KosRepositoryException>()),
      );

      expect(provider.kosList.single.roomsAvailable, 2);
    });
  });
}
