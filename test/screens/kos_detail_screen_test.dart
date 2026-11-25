import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos_model.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';

void main() {
  group('KosDetailScreen Widget Tests', () {
    const sampleKosAvailable = KosModel(
      id: 'kos-detail-1',
      ownerId: 'owner-1',
      name: 'Kos Bunga Mawar',
      area: 'Srengseng Sawah, Jagakarsa',
      price: 1100000,
      type: 'Putri',
      facilities: ['Wi-Fi', 'AC', 'Kamar Mandi Dalam'],
      roomsAvailable: 2,
      contactName: 'Ibu Mawar',
      contactPhone: '081298765432',
    );

    const sampleKosFull = KosModel(
      id: 'kos-detail-2',
      ownerId: 'owner-2',
      name: 'Kos Bintang Timur',
      area: 'Kukusan Kelurahan',
      price: 950000,
      type: 'Putra',
      facilities: ['Wi-Fi', 'Kasur'],
      roomsAvailable: 0,
      contactName: 'Pak Bintang',
      contactPhone: '081300001111',
    );

    testWidgets('Displays all kos specifications and available room badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KosDetailScreen(kos: sampleKosAvailable),
        ),
      );

      // Verifikasi judul halaman dan spesifikasi kos
      expect(find.text('Detail Kos'), findsOneWidget);
      expect(find.text('Kos Bunga Mawar'), findsOneWidget);
      expect(find.text('Putri'), findsOneWidget);
      expect(find.text('Srengseng Sawah, Jagakarsa'), findsOneWidget);
      expect(find.text('Rp 1.100.000 / bulan'), findsOneWidget);
      expect(find.text('Sisa 2 Kamar'), findsOneWidget);
      final badge = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Sisa 2 Kamar'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((badge.decoration! as BoxDecoration).color, Colors.green.shade800);
      expect(
        tester.widget<Text>(find.text('Sisa 2 Kamar')).style?.color,
        Colors.white,
      );

      // Verifikasi fasilitas
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('AC'), findsOneWidget);
      expect(find.text('Kamar Mandi Dalam'), findsOneWidget);

      // Verifikasi informasi kontak
      expect(find.text('Ibu Mawar'), findsOneWidget);
      expect(find.text('081298765432'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Salin Nomor'), findsOneWidget);
    });

    testWidgets('Displays Penuh badge when rooms_available is 0 (US03-AC1)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KosDetailScreen(kos: sampleKosFull),
        ),
      );

      expect(find.text('Kos Bintang Timur'), findsOneWidget);
      expect(find.text('Penuh'), findsOneWidget);
      expect(find.text('Sisa 0 Kamar'), findsNothing);
      final badge = tester.widget<Container>(
        find
            .ancestor(of: find.text('Penuh'), matching: find.byType(Container))
            .first,
      );
      expect((badge.decoration! as BoxDecoration).color, Colors.red.shade800);
      expect(
        tester.widget<Text>(find.text('Penuh')).style?.color,
        Colors.white,
      );
    });

    testWidgets('Tapping Salin Nomor copies WhatsApp number to clipboard and shows SnackBar (US03-AC2)', (tester) async {
      String? copiedString;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final Map<dynamic, dynamic>? args = methodCall.arguments as Map<dynamic, dynamic>?;
          copiedString = args?['text'] as String?;
          return null;
        } else if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': copiedString};
        }
        return null;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: KosDetailScreen(kos: sampleKosAvailable),
        ),
      );

      final copyButton = find.widgetWithText(ElevatedButton, 'Salin Nomor');
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump(); // memicu SnackBar

      // Cek apakah snackbar muncul
      expect(find.text('Nomor WhatsApp berhasil disalin'), findsOneWidget);

      // Verifikasi isi clipboard
      expect(copiedString, '081298765432');
    });
  });
}
