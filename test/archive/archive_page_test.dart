import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/analysis/variation_tree.dart';
import 'package:rokko/archive/archive_page.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/archive/pgn.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/exchange/qr_send_page.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/game/chess_game.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/theme/rokko_mascot.dart';

ChessGame play(List<String> uci) {
  final game = ChessGame();
  for (final m in uci) {
    game.play(Move.parse(m)!);
  }
  return game;
}

/// Lascia completare l'I/O reale su file, che i test di widget non simulano.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  late Directory dir;
  late GameArchive archive;
  final shared = <String>[];
  final opened = <String>[];
  final analysed = <String>[];
  ValueChanged<String>? scan;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('archive_page');
    archive = GameArchive(File('${dir.path}/games.json'));
    shared.clear();
    opened.clear();
    analysed.clear();
    final t = DateTime(2026, 10, 10, 9);
    await archive.save(
      SavedGame.fromGame(
        play(['f2f3', 'e7e5', 'g2g4', 'd8h4']),
        id: 'matto',
        white: 'Anna',
        black: 'Bruno',
        mode: 'locale',
        createdAt: t,
        updatedAt: t,
      ),
    );
    await archive.save(
      SavedGame.fromGame(
        play(['e2e4']),
        id: 'corso',
        white: 'Carla',
        black: 'Dario',
        mode: 'locale',
        createdAt: t,
        updatedAt: t.add(const Duration(hours: 1)),
      ),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> show(
    WidgetTester tester, {
    GameArchive? using,
    String locale = 'it',
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ArchivePage(
          archive: using ?? archive,
          share: (text) async => shared.add(text),
          onOpen: (g) => opened.add(g.id),
          onAnalyse: (g) => analysed.add(g.id),
          scanner: (context, {required onCode, required onError}) {
            scan = onCode;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('archivio vuoto: la torre e il testo', (tester) async {
    await show(tester, using: GameArchive(File('${dir.path}/vuoto.json')));
    expect(find.byType(RokkoMascot), findsOneWidget);
    expect(find.text('Nessuna partita salvata.'), findsOneWidget);
  });

  testWidgets('RF-101 storico con giocatori e risultato', (tester) async {
    await show(tester);
    expect(find.text('Carla – Dario'), findsOneWidget);
    expect(find.text('Anna – Bruno'), findsOneWidget);
    expect(find.textContaining('0-1'), findsOneWidget);
    expect(find.textContaining('In corso'), findsOneWidget);
  });

  testWidgets('la data segue la lingua dell\'app', (tester) async {
    await show(tester, locale: 'de');
    expect(find.textContaining('10.10.2026'), findsWidgets);
  });

  testWidgets('disco pieno su importazione ed eliminazione: avviso', (
    tester,
  ) async {
    final full = _FullDisk(File('${dir.path}/games.json'));
    // Lettura anticipata: l'I/O reale non avanza dentro pumpAndSettle.
    await tester.runAsync(full.list);
    await show(tester, using: full);
    await tester.tap(find.byTooltip('Importa PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pgnInput')), '1. d4 d5 *');
    await tester.tap(find.text('Importa'));
    await settle(tester);
    expect(find.textContaining('non si possono leggere'), findsOneWidget);

    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await settle(tester);
    expect(find.textContaining('non si possono leggere'), findsOneWidget);
    expect(find.text('Anna – Bruno'), findsOneWidget);
  });

  testWidgets('RF-101 ricerca per nome', (tester) async {
    await show(tester);
    await tester.enterText(find.byType(TextField), 'anna');
    await tester.pumpAndSettle();
    expect(find.text('Anna – Bruno'), findsOneWidget);
    expect(find.text('Carla – Dario'), findsNothing);
  });

  testWidgets('apre una partita', (tester) async {
    await show(tester);
    await tester.tap(find.text('Anna – Bruno'));
    expect(opened, ['matto']);
  });

  testWidgets('RF-52 apre una partita nell\'analisi', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apri nell\'analisi'));
    await tester.pumpAndSettle();
    expect(analysed, ['matto']);
  });

  group('RF-52 analisi salvata', () {
    setUp(() async {
      final t = DateTime(2026, 10, 13, 9);
      await archive.save(
        SavedGame.fromTree(
          VariationTree(Chess.initial)..play(Move.parse('d2d4')!),
          id: 'an',
          name: 'Gambetto',
          createdAt: t,
          updatedAt: t.add(const Duration(days: 1)),
        ),
      );
    });

    testWidgets('si riconosce dal tipo e si apre con un tocco', (tester) async {
      await show(tester);
      expect(find.text('Gambetto'), findsOneWidget);
      expect(find.textContaining('analisi'), findsOneWidget);
      await tester.tap(find.text('Gambetto'));
      expect(opened, ['an']);
    });
  });

  testWidgets('RF-102 condivide il PGN di una partita', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Condividi PGN'));
    await tester.pumpAndSettle();
    expect(shared.single, contains('1. f3 e5 2. g4 Qh4# 0-1'));
  });

  testWidgets('RF-102 esporta tutto l\'archivio', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Esporta tutto in PGN'));
    await settle(tester);
    expect('[Event'.allMatches(shared.single), hasLength(2));
  });

  testWidgets('RF-102 importa un PGN incollato', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Importa PGN'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pgnInput')),
      '[White "Elena"]\n[Black "Franco"]\n\n1. d4 d5 *',
    );
    await tester.tap(find.text('Importa'));
    await settle(tester);
    expect(find.text('Elena – Franco'), findsOneWidget);
    expect(find.text('1 partita importata'), findsOneWidget);
  });

  testWidgets('elimina una partita dopo conferma', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await settle(tester);
    expect(find.text('Anna – Bruno'), findsNothing);
  });

  testWidgets('copia il PGN negli appunti', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copia PGN'));
    await tester.pumpAndSettle();
    expect(copied, contains('Qh4#'));
  });

  testWidgets('Cap. 7 scambio QR: passa una partita con QR', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Azioni per Anna – Bruno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Passa con QR'));
    await tester.pumpAndSettle();
    final page = tester.widget<QrSendPage>(find.byType(QrSendPage));
    final assembler = TransferAssembler();
    final event = page.frames.map(assembler.add).last;
    expect((event as TransferComplete).text, contains('2. g4 Qh4# 0-1'));
  });

  testWidgets('Cap. 7 scambio QR: riceve una partita e la importa', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byTooltip('Ricevi con QR'));
    await tester.pumpAndSettle();
    encodeTransfer('[White "Elena"]\n[Black "Franco"]\n\n1. d4 d5 *')
        .forEach(scan!);
    await settle(tester);
    expect(find.text('Elena – Franco'), findsOneWidget);
    expect(find.text('1 partita importata'), findsOneWidget);
  });

  testWidgets('Cap. 7 scambio QR: un testo che non è una partita non si '
      'importa', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Ricevi con QR'));
    await tester.pumpAndSettle();
    encodeTransfer('ciao').forEach(scan!);
    await settle(tester);
    expect(find.text('Il QR non contiene una partita valida.'), findsOneWidget);
    expect(await tester.runAsync(archive.list), hasLength(2));
  });
}

/// Archivio il cui disco rifiuta ogni scrittura.
class _FullDisk extends GameArchive {
  _FullDisk(super.file);

  @override
  Future<PgnImport> importPgn(String text, {DateTime? now}) =>
      throw const FileSystemException('No space left on device');

  @override
  Future<void> delete(String id) =>
      throw const FileSystemException('No space left on device');
}
