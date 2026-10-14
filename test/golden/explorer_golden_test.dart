@Tags(['golden'])
library;

import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/openings/explorer_page.dart';
import 'package:rokko/openings/opening_book.dart';
import 'package:rokko/openings/opening_stats.dart';
import 'package:rokko/settings/notation.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

// Numeri di prova: il test controlla la grafica, non i dati reali.
const _rows =
    'Nf6:92500:35000:28000,d5:40700:16700:13000,e6:6800:2700:2100,'
    'd6:4700:1800:1650,g6:4500:1750:1700,f5:4100:1720:1250,c5:1900:800:690';

Future<void> _pump(
  WidgetTester tester,
  Device device, {
  Brightness brightness = Brightness.light,
}) async {
  device.apply(tester);
  await tester.runAsync(
    () => ChessgroundImages.instance.loadAll(
      const ChessboardSettings().pieceAssets,
    ),
  );
  final book = OpeningBook.parseTsv(
    File('assets/openings/openings.tsv').readAsStringSync(),
  );
  final after = Chess.initial.play(Move.parse('d2d4')!);
  final stats = OpeningStats.parseTsv(
    'chiave\tmosse\n${OpeningStats.keyOf(after)}\t$_rows\n',
  );
  await tester.pumpWidget(
    SettingsScope(
      // Notazione italiana: nei test i caratteri dei pezzi figurativi mancano.
      controller: SettingsController.defaults()
        ..value = AppSettings(notation: MoveNotation.italian),
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? RokkoTheme.dark()
            : RokkoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: ExplorerPage(
          book: Future.value(book),
          stats: Future.value(stats),
          initialMoves: [Move.parse('d2d4')!],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final device in Device.phones) {
    testWidgets(
      'esploratore delle aperture su ${device.name}',
      skip: _skip != null,
      (tester) async {
        await _pump(tester, device);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/esploratore-${device.name}.png'),
        );
      },
    );
  }

  testWidgets('esploratore delle aperture in tema scuro', skip: _skip != null, (
    tester,
  ) async {
    await _pump(tester, Device.phoneMedium, brightness: Brightness.dark);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/esploratore-scuro-telefono-medio.png'),
    );
  });
}
