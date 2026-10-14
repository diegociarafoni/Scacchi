import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/clock.dart';
import 'package:rokko/physical/physical_game.dart';

void main() {
  late DateTime now;
  DateTime clockNow() => now;

  setUp(() => now = DateTime(2026));

  PhysicalGame game({TimeControl? control}) =>
      PhysicalGame(control: control, now: clockNow);

  group('suggerimenti', () {
    test('senza testo elenca tutte le mosse legali', () {
      expect(game().suggestions(''), hasLength(20));
    });

    test(
      'filtrano per inizio della notazione, senza badare alle maiuscole',
      () {
        final names = game().suggestions('nf').map((s) => s.san);
        expect(names, ['Nf3']);
        expect(game().suggestions('e').map((s) => s.san), ['e3', 'e4']);
      },
    );

    test('accettano anche la notazione italiana', () {
      expect(game().suggestions('Cf').map((s) => s.san), ['Nf3']);
    });

    test('la promozione si scrive anche in italiano', () {
      final g = game();
      for (final m in ['h4', 'g5', 'hxg5', 'h6', 'gxh6', 'Nf6', 'h7', 'Ng8']) {
        expect(g.playText(m), PhysicalInput.played, reason: m);
      }
      expect(g.suggestions('hxg8=D').map((s) => s.san), ['hxg8=Q']);
      expect(g.suggestions('hxg8=').map((s) => s.san), hasLength(4));
    });

    test('testo senza mosse dà un elenco vuoto', () {
      expect(game().suggestions('zz'), isEmpty);
    });
  });

  group('inserimento', () {
    test('la mossa scritta viene giocata', () {
      final g = game();
      expect(g.playText('e4'), PhysicalInput.played);
      expect(g.moves.map((m) => m.san), ['e4']);
      expect(g.turn, Side.black);
    });

    test('la mossa non legale o ambigua non cambia nulla', () {
      final g = game();
      expect(g.playText('e5'), PhysicalInput.invalid);
      expect(g.playText('R'), PhysicalInput.invalid);
      expect(g.moves, isEmpty);
    });

    test('con lo scacco matto l\'orologio si ferma', () {
      final g = game(control: const TimeControl(minutes: 3))..start();
      for (final m in ['f3', 'e5', 'g4', 'Qh4#']) {
        g.playText(m);
      }
      expect(g.clock!.isRunning, isFalse);
    });

    test('dopo lo scacco matto la partita è finita e non accetta mosse', () {
      final g = game();
      for (final m in ['f3', 'e5', 'g4', 'Qh4#']) {
        expect(g.playText(m), PhysicalInput.played);
      }
      expect(g.isOver, isTrue);
      expect(g.result, '0-1');
      expect(g.playText('a3'), PhysicalInput.invalid);
    });
  });

  group('orologio', () {
    test('senza cadenza non c\'è orologio', () {
      expect(game().clock, isNull);
    });

    test('parte con il bianco e passa all\'avversario a ogni mossa', () {
      final g = game(control: const TimeControl(minutes: 3, increment: 2))
        ..start();
      now = now.add(const Duration(seconds: 10));
      g.playText('e4');
      expect(g.clock!.active, Side.black);
      // 3:00 - 10 s + 2 s di incremento.
      expect(g.clock!.remaining(Side.white), const Duration(seconds: 172));
      now = now.add(const Duration(seconds: 5));
      expect(g.clock!.remaining(Side.black), const Duration(seconds: 175));
    });

    test('il tempo esaurito chiude la partita con la vittoria dell\'altro', () {
      final g = game(control: const TimeControl(minutes: 1))..start();
      now = now.add(const Duration(seconds: 61));
      g.checkFlag();
      expect(g.isOver, isTrue);
      expect(g.result, '0-1');
    });

    test('la pausa ferma l\'orologio e la ripresa lo riavvia', () {
      final g = game(control: const TimeControl(minutes: 1))..start();
      now = now.add(const Duration(seconds: 10));
      g.pause();
      now = now.add(const Duration(minutes: 5));
      expect(g.clock!.remaining(Side.white), const Duration(seconds: 50));
      g.resume();
      expect(g.clock!.active, Side.white);
    });
  });

  group('annullamento', () {
    test('toglie l\'ultima mossa e restituisce i tempi', () {
      final g = game(control: const TimeControl(minutes: 3, increment: 2))
        ..start();
      now = now.add(const Duration(seconds: 10));
      g.playText('e4');
      g.undo();
      expect(g.moves, isEmpty);
      expect(g.clock!.active, Side.white);
      expect(g.clock!.remaining(Side.white), const Duration(seconds: 170));
    });

    test('dopo un abbandono lo revoca e riavvia l\'orologio', () {
      final g = game(control: const TimeControl(minutes: 1))
        ..start()
        ..resign(Side.white);
      expect(g.clock!.isRunning, isFalse);
      g.undo();
      expect(g.isOver, isFalse);
      expect(g.clock!.active, Side.white);
    });

    test('lascia in pausa l\'orologio che lo era', () {
      final g = game(control: const TimeControl(minutes: 3))..start();
      g.playText('e4');
      g.pause();
      g.undo();
      expect(g.clock!.isRunning, isFalse);
    });

    test('dopo un tempo scaduto l\'orologio resta fermo', () {
      final g = game(control: const TimeControl(minutes: 1))..start();
      now = now.add(const Duration(seconds: 61));
      g.checkFlag();
      g.undo();
      expect(g.isOver, isFalse);
      expect(g.clock!.isRunning, isFalse);
    });

    test('senza mosse non fa nulla', () {
      final g = game()..undo();
      expect(g.moves, isEmpty);
    });
  });

  group('fine partita', () {
    test('abbandono e patta concordata', () {
      final a = game()..resign(Side.white);
      expect(a.result, '0-1');
      final b = game()..agreeDraw();
      expect(b.result, '1/2-1/2');
    });

    test('il PGN riporta mosse, risultato e nomi', () {
      final g = game()
        ..playText('e4')
        ..playText('e5')
        ..resign(Side.black);
      final pgn = g.pgnText(
        white: 'Anna',
        black: 'Luca',
        date: DateTime(2026, 3, 4),
      );
      expect(pgn, contains('[White "Anna"]'));
      expect(pgn, contains('[Black "Luca"]'));
      expect(pgn, contains('[Result "1-0"]'));
      expect(pgn, contains('1. e4 e5'));
    });

    test('in corso il risultato è un asterisco', () {
      expect(game().result, '*');
    });
  });
}
