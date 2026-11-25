import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';

void main() {
  group('KosModel Unit Tests', () {
    final sampleJson = {
      'id': 'kos-123',
      'owner_id': 'owner-456',
      'name': 'Kos Melati Indah',
      'area': 'Kukusan, Beji',
      'price': 850000,
      'type': 'Putri',
      'facilities': ['Wi-Fi', 'Kasur', 'AC'],
      'rooms_available': 3,
      'contact_name': 'Ibu Siti',
      'contact_phone': '081234567890',
      'created_at': '2026-01-15T08:00:00.000Z',
      'updated_at': '2026-01-16T10:00:00.000Z',
    };

    test('fromJson creates KosModel instance correctly', () {
      final model = KosModel.fromJson(sampleJson);

      expect(model.id, 'kos-123');
      expect(model.ownerId, 'owner-456');
      expect(model.name, 'Kos Melati Indah');
      expect(model.area, 'Kukusan, Beji');
      expect(model.price, 850000);
      expect(model.type, 'Putri');
      expect(model.facilities, ['Wi-Fi', 'Kasur', 'AC']);
      expect(model.roomsAvailable, 3);
      expect(model.contactName, 'Ibu Siti');
      expect(model.contactPhone, '081234567890');
      expect(model.createdAt, DateTime.parse('2026-01-15T08:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-01-16T10:00:00.000Z'));
      expect(model.isAvailable, true);
    });

    test('fromJson handles null facilities gracefully', () {
      final jsonWithoutFacilities = Map<String, dynamic>.from(sampleJson);
      jsonWithoutFacilities.remove('facilities');

      final model = KosModel.fromJson(jsonWithoutFacilities);
      expect(model.facilities, isEmpty);
    });

    test('toJson produces correct map structure for Supabase', () {
      final model = KosModel.fromJson(sampleJson);
      final jsonOutput = model.toJson();

      expect(jsonOutput['id'], 'kos-123');
      expect(jsonOutput['owner_id'], 'owner-456');
      expect(jsonOutput['name'], 'Kos Melati Indah');
      expect(jsonOutput['area'], 'Kukusan, Beji');
      expect(jsonOutput['price'], 850000);
      expect(jsonOutput['type'], 'Putri');
      expect(jsonOutput['facilities'], ['Wi-Fi', 'Kasur', 'AC']);
      expect(jsonOutput['rooms_available'], 3);
      expect(jsonOutput['contact_name'], 'Ibu Siti');
      expect(jsonOutput['contact_phone'], '081234567890');
      expect(jsonOutput['created_at'], '2026-01-15T08:00:00.000Z');
      expect(jsonOutput['updated_at'], '2026-01-16T10:00:00.000Z');
    });

    test('isAvailable returns false when rooms_available is 0', () {
      final model = KosModel.fromJson({
        ...sampleJson,
        'rooms_available': 0,
      });

      expect(model.isAvailable, false);
    });

    test('copyWith creates new KosModel with updated values', () {
      final model = KosModel.fromJson(sampleJson);
      final updated = model.copyWith(
        name: 'Kos Melati Baru',
        roomsAvailable: 0,
      );

      expect(updated.name, 'Kos Melati Baru');
      expect(updated.roomsAvailable, 0);
      expect(updated.isAvailable, false);
      expect(updated.id, model.id);
      expect(updated.ownerId, model.ownerId);
      expect(updated.area, model.area);
    });
  });
}
