import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/widgets/kos_card.dart';

void main() {
  group('Widget Tests for KosFinder UI', () {
    testWidgets('KosCard displays kos information accurately', (tester) async {
      const kos = KosModel(
        id: 'kos-test-1',
        ownerId: 'owner-test',
        name: 'Kos Sejahtera Indah',
        area: 'Kukusan, Depok',
        price: 900000,
        type: 'Putri',
        facilities: ['Wi-Fi', 'AC'],
        roomsAvailable: 3,
        contactName: 'Ibu Budi',
        contactPhone: '08123456789',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KosCard(kos: kos),
          ),
        ),
      );

      expect(find.text('Kos Sejahtera Indah'), findsOneWidget);
      expect(find.text('Kukusan, Depok'), findsOneWidget);
      expect(find.text('Putri'), findsOneWidget);
      expect(find.text('Rp 900.000 / bulan'), findsOneWidget);
      expect(find.text('Sisa 3 Kamar'), findsOneWidget);
    });

    testWidgets('KosCard displays Penuh badge when rooms_available is 0', (tester) async {
      const kos = KosModel(
        id: 'kos-test-2',
        ownerId: 'owner-test',
        name: 'Kos Penuh Damai',
        area: 'Margonda',
        price: 1200000,
        type: 'Putra',
        facilities: ['Wi-Fi'],
        roomsAvailable: 0,
        contactName: 'Pak Joko',
        contactPhone: '08123456788',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KosCard(kos: kos),
          ),
        ),
      );

      expect(find.text('Kos Penuh Damai'), findsOneWidget);
      expect(find.text('Penuh'), findsOneWidget);
    });

    testWidgets('KosListScreen displays error message and Coba Lagi button on network failure', (tester) async {
      final repository = KosRepository(
        customFetcher: () async {
          throw const KosRepositoryException('Gagal memuat data, periksa koneksi Anda');
        },
      );
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(MyApp(kosProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('KosFinder'), findsOneWidget);
      expect(find.text('Gagal memuat data, periksa koneksi Anda'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Coba Lagi'), findsOneWidget);
    });

    testWidgets('KosListScreen displays list of cards on successful fetch', (tester) async {
      final repository = KosRepository(
        customFetcher: () async => [
          {
            'id': 'kos-101',
            'owner_id': 'owner-101',
            'name': 'Kos Asri Emerald',
            'area': 'Tanah Baru',
            'price': 750000,
            'type': 'Campur',
            'facilities': ['Wi-Fi'],
            'rooms_available': 1,
            'contact_name': 'Pak Asri',
            'contact_phone': '0899999999',
          }
        ],
      );
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(MyApp(kosProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('KosFinder'), findsOneWidget);
      expect(find.text('Kos Asri Emerald'), findsOneWidget);
      expect(find.text('Tanah Baru'), findsOneWidget);
      expect(find.text('Campur'), findsOneWidget);
      expect(find.text('Rp 750.000 / bulan'), findsOneWidget);
      expect(find.text('Sisa 1 Kamar'), findsOneWidget);
    });
  });
}
