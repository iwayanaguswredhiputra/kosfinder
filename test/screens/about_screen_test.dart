import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/about_screen.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    testWidgets('Displays application title, description, and developer identity', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      expect(find.text('Tentang KosFinder'), findsOneWidget);
      expect(find.text('KosFinder'), findsOneWidget);
      expect(
        find.text('Aplikasi pencarian kos yang cepat dan efisien untuk Anda yang butuh kos tanpa ribet.'),
        findsOneWidget,
      );
      expect(
        find.text('2415051007 - I Wayan Agus Wredhi Putra'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping info icon in KosListScreen navigates to AboutScreen', (tester) async {
      final repository = KosRepository(customFetcher: () async => []);
      final provider = KosProvider(repository: repository);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: KosListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final infoButton = find.byIcon(Icons.info_outline);
      expect(infoButton, findsOneWidget);

      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('2415051007 - I Wayan Agus Wredhi Putra'), findsOneWidget);
    });
  });
}
