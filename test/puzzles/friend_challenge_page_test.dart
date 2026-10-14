import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/exchange/qr_code_view.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/puzzles/friend_challenge.dart';
import 'package:rokko/puzzles/friend_challenge_page.dart';
import 'package:rokko/puzzles/puzzle_hub_page.dart';
import 'package:rokko/puzzles/puzzle_run.dart';
import 'package:rokko/puzzles/puzzle_run_page.dart';
import 'package:rokko/puzzles/puzzle_trainer.dart';

import 'puzzle_run_page_test.dart' as run_test;

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// Lettore finto: espone le callback che il lettore vero chiamerebbe.
class _FakeScanner {
  ValueChanged<String>? onCode;

  Widget build(
    BuildContext context, {
    required ValueChanged<String> onCode,
    required ValueChanged<Object> onError,
  }) {
    this.onCode = onCode;
    return const SizedBox(key: Key('fakeScanner'), width: 200, height: 200);
  }

  void see(Iterable<String> frames) => frames.forEach(onCode!);
}

/// Messaggio di sfida letto dal QR mostrato sullo schermo.
ChallengeMessage _shown(WidgetTester tester) {
  final view = tester.widget<QrCodeView>(find.byType(QrCodeView));
  final event = TransferAssembler().add(view.data) as TransferComplete;
  return parseChallenge(event.text)!;
}

Future<FriendChallenge> _challengeFor(
  PuzzleTrainer trainer, {
  PuzzleRunMode mode = PuzzleRunMode.rush3,
  int seed = 42,
}) async => FriendChallenge(
  mode: mode,
  seed: seed,
  library: libraryFingerprint(trainer.library),
);

void main() {
  testWidgets('RF-95 la scheda Puzzle offre Sfida un amico', (tester) async {
    final trainer = await run_test.phone(tester);
    await tester.pumpWidget(
      _app(PuzzleHubPage(trainer: Future.value(trainer))),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sfida un amico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sfida un amico'));
    await tester.pumpAndSettle();
    expect(find.text('Prepara la sfida'), findsOneWidget);
    expect(find.text('Ricevi una sfida'), findsOneWidget);
  });

  group('lanciare la sfida', () {
    testWidgets('RF-95 il QR porta prova, seme e raccolta', (tester) async {
      final trainer = await run_test.phone(tester);
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, newSeed: () => 777)),
      );
      await tester.tap(find.text('Prepara la sfida'));
      await tester.pumpAndSettle();
      expect(find.text('Sfida pronta: Corsa 3 minuti'), findsOneWidget);
      await tester.tap(find.text("Mostra il QR all'amico"));
      await tester.pumpAndSettle();
      final message = _shown(tester);
      expect(message, isA<ChallengeInvite>());
      expect(message.challenge.seed, 777);
      expect(message.challenge.mode, PuzzleRunMode.rush3);
      expect(message.challenge.library, libraryFingerprint(trainer.library));
    });

    testWidgets('RF-95 si sceglie la prova prima di prepararla', (
      tester,
    ) async {
      final trainer = await run_test.phone(tester);
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, newSeed: () => 1)),
      );
      await tester.tap(find.text('Corsa 5 minuti'));
      await tester.pump();
      await tester.tap(find.text('Prepara la sfida'));
      await tester.pumpAndSettle();
      expect(find.text('Sfida pronta: Corsa 5 minuti'), findsOneWidget);
    });

    testWidgets('RF-95 chi lancia gioca la stessa prova', (tester) async {
      final trainer = await run_test.phone(tester);
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, newSeed: () => 5)),
      );
      await tester.tap(find.text('Prepara la sfida'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gioca la tua prova'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleRunPage), findsOneWidget);
      expect(
        tester.widget<PuzzleRunPage>(find.byType(PuzzleRunPage)).challenge,
        FriendChallenge(
          mode: PuzzleRunMode.rush3,
          seed: 5,
          library: libraryFingerprint(trainer.library),
        ),
      );
    });
  });

  group('ricevere la sfida', () {
    testWidgets('RF-95 il QR della sfida avvia la stessa prova', (
      tester,
    ) async {
      final trainer = await run_test.phone(tester);
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, scanner: scanner.build)),
      );
      await tester.tap(find.text('Ricevi una sfida'));
      await tester.pumpAndSettle();
      final challenge = await _challengeFor(trainer, seed: 99);
      scanner.see(encodeChallenge(ChallengeInvite(challenge)));
      await tester.pumpAndSettle();
      final page = tester.widget<PuzzleRunPage>(find.byType(PuzzleRunPage));
      expect(page.challenge, challenge);
      expect(page.mode, PuzzleRunMode.rush3);
    });

    testWidgets('RF-95 un QR estraneo non avvia nulla e lo dice', (
      tester,
    ) async {
      final trainer = await run_test.phone(tester);
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, scanner: scanner.build)),
      );
      await tester.tap(find.text('Ricevi una sfida'));
      await tester.pumpAndSettle();
      scanner.see(encodeTransfer('[White "A"]\n\n1. e4 *'));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleRunPage), findsNothing);
      expect(find.textContaining('non è una sfida'), findsOneWidget);
    });

    testWidgets('RF-95 raccolte diverse: nessuna prova, avviso chiaro', (
      tester,
    ) async {
      final trainer = await run_test.phone(tester);
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        _app(FriendChallengePage(trainer: trainer, scanner: scanner.build)),
      );
      await tester.tap(find.text('Ricevi una sfida'));
      await tester.pumpAndSettle();
      const other = FriendChallenge(
        mode: PuzzleRunMode.storm,
        seed: 1,
        library: 'DEADBEEF',
      );
      scanner.see(encodeChallenge(const ChallengeInvite(other)));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleRunPage), findsNothing);
      expect(find.textContaining('puzzle diversi'), findsOneWidget);
    });
  });

  group('confronto a fine prova', () {
    Future<(PuzzleTrainer, FriendChallenge, _FakeScanner)> finish(
      WidgetTester tester, {
      int solved = 2,
    }) async {
      final trainer = await run_test.phone(tester);
      final challenge = await _challengeFor(trainer);
      final scanner = _FakeScanner();
      var elapsed = Duration.zero;
      await tester.pumpWidget(
        _app(
          PuzzleRunPage(
            trainer: trainer,
            mode: challenge.mode,
            challenge: challenge,
            scanner: scanner.build,
            clock: () => elapsed,
          ),
        ),
      );
      await run_test.begin(tester);
      if (solved >= 1) await run_test.tapMove(tester, 'a1a8');
      if (solved >= 2) await run_test.tapMove(tester, 'b1b8');
      elapsed = const Duration(minutes: 3);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      return (trainer, challenge, scanner);
    }

    testWidgets('RF-95 senza sfida il confronto non compare', (tester) async {
      final trainer = await run_test.phone(tester);
      var elapsed = Duration.zero;
      await tester.pumpWidget(
        _app(
          PuzzleRunPage(
            trainer: trainer,
            mode: PuzzleRunMode.rush3,
            clock: () => elapsed,
          ),
        ),
      );
      await run_test.begin(tester);
      elapsed = const Duration(minutes: 3);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Serie conclusa'), findsOneWidget);
      expect(find.text('Mostra il mio risultato'), findsNothing);
      expect(find.text('Gioca ancora'), findsOneWidget);
    });

    testWidgets('RF-95 il secondo QR mostra il mio punteggio', (tester) async {
      final (_, challenge, _) = await finish(tester);
      expect(find.text('Serie conclusa'), findsOneWidget);
      expect(find.text('Sfida con l\'amico'), findsOneWidget);
      // Rigiocare darebbe lo stesso seme: in una sfida si gioca una volta.
      expect(find.text('Gioca ancora'), findsNothing);
      await tester.tap(find.text('Mostra il mio risultato'));
      await tester.pumpAndSettle();
      final message = _shown(tester);
      expect(message, isA<ChallengeResult>());
      expect((message as ChallengeResult).score, 2);
      expect(message.answers(challenge), isTrue);
    });

    testWidgets('RF-95 il risultato dell\'amico decide chi ha vinto', (
      tester,
    ) async {
      final (_, challenge, scanner) = await finish(tester);
      await tester.tap(find.text("Leggi il risultato dell'amico"));
      await tester.pumpAndSettle();
      scanner.see(encodeChallenge(ChallengeResult(challenge, 1)));
      await tester.pumpAndSettle();
      expect(find.text('Hai vinto: 2 a 1'), findsOneWidget);
    });

    testWidgets('RF-95 sconfitta e pareggio', (tester) async {
      final (_, challenge, scanner) = await finish(tester);
      await tester.tap(find.text("Leggi il risultato dell'amico"));
      await tester.pumpAndSettle();
      scanner.see(encodeChallenge(ChallengeResult(challenge, 5)));
      await tester.pumpAndSettle();
      expect(find.text("Ha vinto l'amico: 5 a 2"), findsOneWidget);

      await tester.tap(find.text("Leggi il risultato dell'amico"));
      await tester.pumpAndSettle();
      scanner.see(encodeChallenge(ChallengeResult(challenge, 2)));
      await tester.pumpAndSettle();
      expect(find.text('Pareggio: 2 a 2'), findsOneWidget);
    });

    testWidgets('RF-95 il risultato di un\'altra sfida viene respinto', (
      tester,
    ) async {
      final (trainer, challenge, scanner) = await finish(tester);
      final other = await _challengeFor(trainer, seed: challenge.seed + 1);
      await tester.tap(find.text("Leggi il risultato dell'amico"));
      await tester.pumpAndSettle();
      scanner.see(encodeChallenge(ChallengeResult(other, 9)));
      await tester.pumpAndSettle();
      expect(find.text("Il risultato è di un'altra sfida."), findsOneWidget);
      expect(find.text('Hai vinto: 9 a 2'), findsNothing);
    });

    testWidgets('RF-95 un QR di lancio non è un risultato', (tester) async {
      final (_, challenge, scanner) = await finish(tester);
      await tester.tap(find.text("Leggi il risultato dell'amico"));
      await tester.pumpAndSettle();
      scanner.see(encodeChallenge(ChallengeInvite(challenge)));
      await tester.pumpAndSettle();
      expect(find.textContaining('non è un risultato'), findsOneWidget);
    });
  });
}
