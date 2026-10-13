import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/minigames/blind.dart';
import 'package:scacchi/minigames/capture_all.dart';
import 'package:scacchi/minigames/coordinates.dart';
import 'package:scacchi/minigames/material_quiz.dart';
import 'package:scacchi/minigames/minigame.dart';

final it = lookupAppLocalizations(const Locale('it'));

void main() {
  test('RG-10 quattro minigiochi con identificativi stabili e unici', () {
    expect(Minigame.values.map((m) => m.id).toSet(), hasLength(4));
    for (final m in Minigame.values) {
      expect(m.title(it), isNotEmpty);
      expect(m.description(it), isNotEmpty);
    }
    expect(Minigame.byId('coordinate'), Minigame.coordinates);
    expect(Minigame.byId('sconosciuto'), isNull);
  });

  group('allenatore delle coordinate', () {
    test('risposta giusta: punto e nuova casa diversa', () {
      final drill = CoordinateDrill(Random(1));
      for (var i = 0; i < 50; i++) {
        final target = drill.target;
        expect(drill.answer(target), isTrue);
        expect(drill.target, isNot(target));
      }
      expect(drill.score, 50);
      expect(drill.mistakes, 0);
    });

    test('risposta sbagliata: errore, la casa resta', () {
      final drill = CoordinateDrill(Random(2));
      final target = drill.target;
      final wrong = Square((target.value + 1) % 64);
      expect(drill.answer(wrong), isFalse);
      expect(drill.target, target);
      expect(drill.mistakes, 1);
      expect(drill.score, 0);
    });

    test('durata di 30 secondi', () {
      expect(CoordinateDrill.duration, const Duration(seconds: 30));
    });
  });

  group('cattura tutto', () {
    test('scacchiere risolvibili, pedoni distinti e lontani dal pezzo', () {
      for (var seed = 0; seed < 40; seed++) {
        final random = Random(seed);
        for (var round = 0; round < CaptureAllSession.rounds; round++) {
          final e = CaptureAllBoard.random(random, round: round);
          expect(e.targets.toSet(), hasLength(e.targets.length));
          expect(e.targets, isNot(contains(e.start)));
          expect(e.targets.length, inInclusiveRange(3, 6));
          expect(e.optimalMoves, greaterThan(0), reason: 'seme $seed');
          final run = CaptureAllRun(e);
          for (final to in e.solution) {
            expect(run.move(to), isTrue);
          }
          expect(run.done, isTrue);
          if (e.role == Role.bishop) {
            for (final s in e.targets) {
              expect(_light(s), _light(e.start));
            }
          }
        }
      }
    });

    test('pezzi diversi nei turni e più pedoni andando avanti', () {
      final random = Random(3);
      final boards = [
        for (var r = 0; r < CaptureAllSession.rounds; r++)
          CaptureAllBoard.random(random, round: r),
      ];
      expect(boards.map((b) => b.role).toSet().length, greaterThan(2));
      expect(
        boards.last.targets.length,
        greaterThan(boards.first.targets.length),
      );
    });

    test('la torre non scavalca un pedone: il primo si cattura', () {
      const board = CaptureAllBoard(
        role: Role.rook,
        start: Square.a1,
        targets: [Square.a4, Square.a8],
      );
      final run = CaptureAllRun(board);
      expect(run.validMoves, contains(Square.a4));
      expect(run.validMoves, isNot(contains(Square.a8)));
      expect(run.move(Square.a8), isFalse);
      expect(run.move(Square.a4), isTrue);
      expect(run.move(Square.a8), isTrue);
      expect(run.done, isTrue);
      expect(board.optimalMoves, 2);
      expect(run.stars, 3);
    });

    test('mosse in più tolgono stelle', () {
      final run = CaptureAllRun(
        const CaptureAllBoard(
          role: Role.rook,
          start: Square.a1,
          targets: [Square.h8],
        ),
      );
      for (final to in [Square.b1, Square.c1, Square.h1, Square.h8]) {
        expect(run.move(to), isTrue);
      }
      expect(run.stars, 2);
    });

    test('la sessione somma le stelle dei turni', () {
      final session = CaptureAllSession(Random(4));
      expect(session.done, isFalse);
      for (var r = 0; r < CaptureAllSession.rounds; r++) {
        session.finishRound(3 - r % 3);
      }
      expect(session.done, isTrue);
      expect(session.score, 3 + 2 + 1 + 3 + 2);
      expect(CaptureAllSession.maxScore, 15);
    });
  });

  group('alla cieca', () {
    test('mosse legali dalla posizione iniziale e risposta corretta', () {
      for (var seed = 0; seed < 30; seed++) {
        final q = BlindQuestion.generate(Random(seed));
        Position pos = Chess.initial;
        for (final san in q.sans) {
          final move = pos.parseSan(san);
          expect(move, isNotNull, reason: '$san seme $seed');
          pos = pos.play(move!);
        }
        expect(pos.board.pieceAt(q.square), q.answer);
        expect(q.choices, contains(q.answer));
        expect(q.choices.toSet(), hasLength(4));
        expect(q.position.fen, pos.fen);
      }
    });

    test('testo della domanda con le mosse numerate', () {
      final q = BlindQuestion.generate(Random(5), plies: 4);
      expect(q.sans, hasLength(4));
      expect(q.movesText, startsWith('1. '));
      expect(q.movesText, contains(' 2. '));
      expect(q.prompt(it), contains(q.square.name));
    });

    test('nomi dei pezzi in italiano', () {
      expect(
        pieceLabel(it, const Piece(color: Side.white, role: Role.knight)),
        'Cavallo bianco',
      );
      expect(
        pieceLabel(it, const Piece(color: Side.black, role: Role.queen)),
        'Donna nera',
      );
      expect(pieceLabel(it, null), 'Casa vuota');
    });
  });

  group('conta del materiale', () {
    test('bilancio dal punto di vista del bianco', () {
      final board = Board.parseFen('4k3/8/8/8/8/8/1P6/RN2K3');
      expect(materialBalance(board), 9);
      expect(materialBalance(Board.standard), 0);
    });

    test('arrocco una sola volta tra le mosse legali', () {
      final pos = Chess.fromSetup(
        Setup.parseFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1'),
      );
      final kingMoves = legalMoves(pos).where((m) => m.from == Square.e1);
      expect(kingMoves.where((m) => m.to == Square.h1), isEmpty);
      expect(kingMoves.where((m) => m.to == Square.g1), hasLength(1));
    });

    test('etichette', () {
      expect(balanceLabel(it, 0), 'Pari');
      expect(balanceLabel(it, 3), 'Bianco +3');
      expect(balanceLabel(it, -2), 'Nero +2');
    });

    test('domande con quattro scelte diverse e risposta tra queste', () {
      final seen = <int>{};
      for (var seed = 0; seed < 30; seed++) {
        final q = MaterialQuestion.generate(Random(seed));
        expect(q.choices.toSet(), hasLength(4));
        expect(q.choices, contains(q.answer));
        expect(q.answer, materialBalance(q.position.board));
        expect(q.position.isGameOver, isFalse);
        seen.add(q.answer);
      }
      expect(seen.length, greaterThan(3), reason: 'bilanci vari');
    });
  });
}

bool _light(Square s) => (s.file + s.rank) % 2 == 1;
