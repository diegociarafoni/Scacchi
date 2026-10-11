import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/endgames/drill.dart';
import 'package:scacchi/endgames/drills.dart';

Move _m(String uci) => Move.parse(uci)!;

void main() {
  group('stelle', () {
    test('RF-86 tre entro il par, due con poco scarto, poi una', () {
      expect(drillStars(10, 10), 3);
      expect(drillStars(15, 10), 2);
      expect(drillStars(16, 10), 1);
    });
  });

  group('obiettivo matto', () {
    const drill = EndgameDrill(
      id: 'prova.matto',
      title: 'Prova',
      intro: 'Dai matto.',
      fen: '7k/8/6K1/8/8/1Q6/8/8 w - - 0 1',
      goal: DrillGoal.mate,
      par: 1,
    );

    test('RF-86 il matto dell\'utente completa la posizione', () {
      final run = DrillRun(drill);
      expect(run.side, Side.white);
      expect(run.userToMove, isTrue);
      expect(run.play(_m('b3b8')), isTrue);
      expect(run.state, DrillState.success);
      expect(run.stars, 3);
    });

    test('una mossa illegale non si gioca', () {
      final run = DrillRun(drill);
      expect(run.play(_m('b3h8')), isFalse);
      expect(run.moves, 0);
    });

    test('lo stallo fa fallire', () {
      final run = DrillRun(drill);
      run.play(_m('b3f7'));
      expect(run.state, DrillState.failure);
      expect(run.stars, 0);
    });

    test('dopo la mossa dell\'utente tocca al motore', () {
      final run = DrillRun(drill);
      run.play(_m('b3c3'));
      expect(run.userToMove, isFalse);
      expect(run.reply(_m('h8h7')), isFalse);
      expect(run.reply(_m('h8g8')), isTrue);
      expect(run.userToMove, isTrue);
      expect(run.history, [_m('b3c3'), _m('h8g8')]);
    });
  });

  group('obiettivo promozione', () {
    const drill = EndgameDrill(
      id: 'prova.promozione',
      title: 'Prova',
      intro: 'Promuovi.',
      fen: '8/4P3/8/8/8/8/k7/4K3 w - - 0 1',
      goal: DrillGoal.promote,
      par: 1,
    );

    test('RF-86 promuovere al sicuro completa la posizione', () {
      final run = DrillRun(drill);
      run.play(
        const NormalMove(from: Square.e7, to: Square.e8, promotion: Role.queen),
      );
      expect(run.state, DrillState.success);
    });

    test('una promozione che si fa catturare non basta', () {
      const near = EndgameDrill(
        id: 'prova.vicino',
        title: 'Prova',
        intro: 'Promuovi.',
        fen: '8/4Pk2/8/8/8/8/8/K7 w - - 0 1',
        goal: DrillGoal.promote,
        par: 1,
      );
      final run = DrillRun(near);
      run.play(
        const NormalMove(from: Square.e7, to: Square.e8, promotion: Role.queen),
      );
      expect(run.state, DrillState.playing);
      run.reply(_m('f7e8'));
      expect(run.state, DrillState.failure);
    });
  });

  group('promozione al sicuro', () {
    test('una torre lasciata vicino al re nemico non basta', () {
      const drill = EndgameDrill(
        id: 'prova.indifesa',
        title: 'Prova',
        intro: 'Promuovi.',
        fen: '7r/1kP5/8/8/8/8/8/2R1K3 w - - 0 1',
        goal: DrillGoal.promote,
        par: 5,
      );
      final run = DrillRun(drill);
      run.play(_m('c7c8q'));
      expect(run.state, DrillState.playing);
      run.reply(_m('h8c8'));
      run.play(_m('c1c8'));
      expect(run.state, DrillState.playing);
      run.reply(_m('b7c8'));
      expect(run.state, DrillState.failure);
    });

    test('una donna infilata da uno scacco non basta', () {
      const drill = EndgameDrill(
        id: 'prova.infilata',
        title: 'Prova',
        intro: 'Promuovi.',
        fen: '8/3P4/8/8/4k3/r7/8/3K4 w - - 0 1',
        goal: DrillGoal.promote,
        par: 5,
      );
      final run = DrillRun(drill);
      // Dopo Td3+ difesa dal re, la donna in d8 va persa.
      run.play(
        const NormalMove(from: Square.d7, to: Square.d8, promotion: Role.queen),
      );
      expect(run.state, DrillState.playing);
    });
  });

  group('Lucena', () {
    final lucena = endgameDrills.firstWhere((d) => d.id == 'lucena');

    test(
      'RF-86 promuovere vale anche se il motore può dare la torre per la donna',
      () {
        final run = DrillRun(lucena);
        for (final (user, engine) in [('b8c7', 'a2b2'), ('c1c6', 'b2b1')]) {
          expect(run.play(_m(user)), isTrue);
          expect(run.state, DrillState.playing);
          run.reply(_m(engine));
        }
        // Txb8 Rxb8 lascia torre contro re solo: la promozione basta.
        run.play(_m('b7b8q'));
        expect(run.state, DrillState.success);
        expect(run.stars, 3);
      },
    );
  });

  group('patta', () {
    test('la ripetizione della posizione fa fallire il matto', () {
      const drill = EndgameDrill(
        id: 'prova.ripetizione',
        title: 'Prova',
        intro: 'Dai matto.',
        fen: '7k/8/8/8/8/8/8/K3Q3 w - - 0 1',
        goal: DrillGoal.mate,
        par: 20,
      );
      final run = DrillRun(drill);
      for (var i = 0; i < 2; i++) {
        run.play(_m('a1a2'));
        run.reply(_m('h8g8'));
        run.play(_m('a2a1'));
        run.reply(_m('g8h8'));
      }
      expect(run.state, DrillState.failure);
    });

    test('superare il triplo del par fa fallire', () {
      const drill = EndgameDrill(
        id: 'prova.limite',
        title: 'Prova',
        intro: 'Dai matto.',
        fen: '7k/8/8/8/8/8/8/K3Q3 w - - 0 1',
        goal: DrillGoal.mate,
        par: 1,
      );
      final run = DrillRun(drill);
      run.play(_m('a1a2'));
      run.reply(_m('h8g8'));
      run.play(_m('a2a3'));
      run.reply(_m('g8f7'));
      expect(run.state, DrillState.playing);
      run.play(_m('a3a4'));
      expect(run.state, DrillState.failure);
    });
  });

  test('perdere l\'ultimo pedone fa fallire la promozione', () {
    const drill = EndgameDrill(
      id: 'prova.pedone',
      title: 'Prova',
      intro: 'Promuovi.',
      fen: '7k/8/8/8/8/r7/7P/K7 w - - 0 1',
      goal: DrillGoal.promote,
      par: 5,
    );
    final run = DrillRun(drill);
    run.play(_m('a1b1'));
    run.reply(_m('a3h3'));
    run.play(_m('b1c1'));
    run.reply(_m('h3h2'));
    expect(run.state, DrillState.failure);
  });

  group('obiettivo patta', () {
    const drill = EndgameDrill(
      id: 'prova.patta',
      title: 'Prova',
      intro: 'Resisti.',
      fen: '4k3/8/8/8/8/r7/3PK3/8 b - - 0 1',
      goal: DrillGoal.hold,
      par: 2,
    );

    test('RF-86 si gioca con il Nero e resistere completa la posizione', () {
      final run = DrillRun(drill);
      expect(run.side, Side.black);
      run.play(_m('e8e7'));
      run.reply(_m('e2f2'));
      expect(run.state, DrillState.playing);
      run.play(_m('e7e6'));
      expect(run.state, DrillState.playing);
      run.reply(_m('f2e2'));
      expect(run.state, DrillState.success);
      expect(run.stars, 3);
    });

    test('restare con il re solo fa fallire', () {
      const rook = EndgameDrill(
        id: 'prova.torre',
        title: 'Prova',
        intro: 'Resisti.',
        fen: '7k/8/8/8/8/8/1r6/R3K3 b - - 0 1',
        goal: DrillGoal.hold,
        par: 5,
      );
      final run = DrillRun(rook);
      run.play(_m('b2b1'));
      run.reply(_m('a1b1'));
      expect(run.state, DrillState.failure);
    });

    test('una donna nuova catturata subito non fa perdere', () {
      const pawn = EndgameDrill(
        id: 'prova.ripresa',
        title: 'Prova',
        intro: 'Resisti.',
        fen: 'k7/8/8/8/8/8/7p/1R2K3 w - - 0 1',
        goal: DrillGoal.hold,
        par: 5,
      );
      final run = DrillRun(pawn);
      run.play(_m('e1e2'));
      run.reply(
        const NormalMove(from: Square.h2, to: Square.h1, promotion: Role.queen),
      );
      expect(run.state, DrillState.playing);
      run.play(_m('b1h1'));
      expect(run.state, DrillState.playing);
    });

    test('se l\'avversario promuove la patta è persa', () {
      const pawn = EndgameDrill(
        id: 'prova.persa',
        title: 'Prova',
        intro: 'Resisti.',
        fen: 'k7/8/8/8/8/8/3PK2p/8 w - - 0 1',
        goal: DrillGoal.hold,
        par: 5,
      );
      final run = DrillRun(pawn);
      expect(run.side, Side.white);
      run.play(_m('d2d3'));
      run.reply(
        const NormalMove(from: Square.h2, to: Square.h1, promotion: Role.queen),
      );
      run.play(_m('d3d4'));
      expect(run.state, DrillState.failure);
    });
  });

  group('catalogo', () {
    test('RF-86 matti elementari, re e pedone, Lucena, Philidor, '
        'alfiere e cavallo', () {
      expect(
        endgameDrills.map((d) => d.id),
        containsAll([
          'queen-mate',
          'rook-mate',
          'king-pawn',
          'lucena',
          'philidor',
          'bishop-knight',
        ]),
      );
      expect(
        endgameDrills.map((d) => d.id).toSet(),
        hasLength(endgameDrills.length),
      );
    });

    for (final d in endgameDrills) {
      test('posizione valida: ${d.id}', () {
        final pos = Chess.fromSetup(Setup.parseFen(d.fen));
        expect(pos.isGameOver, isFalse);
        expect(d.title, isNotEmpty);
        expect(d.intro, isNotEmpty);
        expect(d.par, greaterThan(0));
      });
    }
  });
}
