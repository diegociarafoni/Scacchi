import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/repertoire.dart';
import 'package:scacchi/storage/key_value_store.dart';

List<Move> uci(String moves) =>
    moves.split(' ').map((m) => Move.parse(m)!).toList();

void main() {
  final day0 = DateTime(2026, 10, 10, 9);

  Future<RepertoireTrainer> trainer({KeyValueStore? store, DateTime? now}) =>
      RepertoireTrainer.load(store ?? MemoryStore(), now: () => now ?? day0);

  group('RF-93 linee del repertorio', () {
    test(
      'aggiunge una linea e ne crea le carte per le mosse del giocatore',
      () async {
        final t = await trainer();
        expect(
          await t.addLine(
            Side.white,
            'Italiana',
            uci('e2e4 e7e5 g1f3 b8c6 f1c4'),
          ),
          isNull,
        );
        expect(t.lines(Side.white).single.name, 'Italiana');
        expect(t.cardCount(Side.white), 3);
        expect(t.dueCount(Side.white), 3);
        expect(t.cardCount(Side.black), 0);
      },
    );

    test(
      'rifiuta una linea con una risposta diversa nella stessa posizione',
      () async {
        final t = await trainer();
        await t.addLine(Side.white, 'Italiana', uci('e2e4 e7e5 g1f3'));
        final error = await t.addLine(
          Side.white,
          'Altra',
          uci('e2e4 e7e5 f2f4'),
        );
        expect(error?.kind, LineProblemKind.conflict);
        expect(error?.move, 'Nf3');
        expect(t.lines(Side.white), hasLength(1));
      },
    );

    test(
      'accetta linee che si diramano sulle mosse dell\'avversario',
      () async {
        final t = await trainer();
        await t.addLine(Side.white, 'e5', uci('e2e4 e7e5 g1f3'));
        expect(
          await t.addLine(Side.white, 'c5', uci('e2e4 c7c5 g1f3')),
          isNull,
        );
        // e4 è in comune: le carte sono e4, Cf3 contro e5, Cf3 contro c5.
        expect(t.cardCount(Side.white), 3);
      },
    );

    test('rifiuta linee illegali o vuote', () async {
      final t = await trainer();
      expect(await t.addLine(Side.white, 'x', uci('e2e5')), isNotNull);
      expect(await t.addLine(Side.white, 'x', const []), isNotNull);
    });

    test('per il Nero le carte sono le mosse del Nero', () async {
      final t = await trainer();
      await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5 g1f3 d7d6'));
      expect(t.cardCount(Side.black), 2);
    });

    test('rimuovere una linea toglie solo le sue carte', () async {
      final t = await trainer();
      await t.addLine(Side.white, 'e5', uci('e2e4 e7e5 g1f3'));
      await t.addLine(Side.white, 'c5', uci('e2e4 c7c5 g1f3'));
      await t.removeLine(Side.white, 0);
      expect(t.lines(Side.white).single.name, 'c5');
      expect(t.cardCount(Side.white), 2);
    });

    test('sopravvive al riavvio', () async {
      final store = MemoryStore();
      final t = await trainer(store: store);
      await t.addLine(Side.white, 'Italiana', uci('e2e4 e7e5 g1f3'));
      final again = await trainer(store: store);
      expect(again.lines(Side.white).single.moves, uci('e2e4 e7e5 g1f3'));
      expect(again.dueCount(Side.white), 2);
    });
  });

  group('RF-93 importazione PGN', () {
    test('ogni variante del PGN diventa una linea', () {
      final lines = linesFromPgn('1. e4 e5 (1... c5 2. Nf3) 2. Nf3 Nc6 *');
      expect(lines.map((l) => l.length), [4, 3]);
      expect(lines.last, uci('e2e4 c7c5 g1f3'));
    });

    test('un PGN illegale non produce linee', () {
      expect(linesFromPgn('1. e5 *'), isEmpty);
      expect(linesFromPgn(''), isEmpty);
    });
  });

  group('RF-93 allenamento a ripetizione dilazionata', () {
    test('l\'avversario muove da solo, il giocatore ripete la linea', () async {
      final t = await trainer();
      await t.addLine(Side.black, 'Siciliana', uci('e2e4 c7c5 g1f3 d7d6'));
      final drill = t.nextDrill(Side.black)!;
      expect(drill.position.turn, Side.black);
      expect(drill.lastMove, Move.parse('e2e4'));
      expect(drill.expected, Move.parse('c7c5'));
      expect(drill.isNew, isTrue);
      expect(await drill.tryMove(Move.parse('c7c5')!), DrillResult.correct);
      expect(drill.lastMove, Move.parse('g1f3'));
      expect(await drill.tryMove(Move.parse('d7d6')!), DrillResult.finished);
    });

    test(
      'una mossa sbagliata mostra quella giusta e la carta torna indietro',
      () async {
        var now = day0;
        final t = await RepertoireTrainer.load(MemoryStore(), now: () => now);
        await t.addLine(Side.white, 'Italiana', uci('e2e4 e7e5 g1f3'));
        var drill = t.nextDrill(Side.white)!;
        expect(await drill.tryMove(Move.parse('e2e4')!), DrillResult.correct);
        expect(await drill.tryMove(Move.parse('g1f3')!), DrillResult.finished);
        expect(t.dueCount(Side.white), 0);

        now = day0.add(const Duration(days: 1));
        expect(t.dueCount(Side.white), 2);
        drill = t.nextDrill(Side.white)!;
        expect(drill.isNew, isFalse);
        expect(await drill.tryMove(Move.parse('d2d4')!), DrillResult.wrong);
        expect(drill.position.turn, Side.white);
        expect(await drill.tryMove(Move.parse('e2e4')!), DrillResult.correct);
        expect(await drill.tryMove(Move.parse('g1f3')!), DrillResult.finished);

        // e4 sbagliata torna dopo un giorno, Cf3 giusta dopo tre.
        now = day0.add(const Duration(days: 2));
        expect(t.dueCount(Side.white), 1);
        now = day0.add(const Duration(days: 4));
        expect(t.dueCount(Side.white), 2);
      },
    );

    test('le carte senza linea non contano come da ripassare', () async {
      final store = MemoryStore();
      await store.write(
        RepertoireTrainer.queueKey,
        '{"white:orfana":{"b":0,"d":0}}',
      );
      final t = await RepertoireTrainer.load(store, now: () => day0);
      expect(t.dueCount(Side.white), 0);
      expect(t.nextDrill(Side.white), isNull);
    });

    test('nessun allenamento quando non ci sono carte in scadenza', () async {
      final t = await trainer();
      expect(t.nextDrill(Side.white), isNull);
    });
  });
}
