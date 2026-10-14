import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/exchange/qr_transfer.dart';
import 'package:rokko/puzzles/friend_challenge.dart';
import 'package:rokko/puzzles/puzzle.dart';
import 'package:rokko/puzzles/puzzle_library.dart';
import 'package:rokko/puzzles/puzzle_run.dart';

Puzzle _p(String id, int rating) => Puzzle.parseCsv(
  '$id,7k/6pp/8/8/1n6/8/8/RR4K1 b - - 0 1,b4c2 a1a8,$rating,mateIn1',
);

PuzzleLibrary _library([int step = 20]) =>
    PuzzleLibrary([for (var r = 400; r < 3000; r += step) _p('p$r', r)]);

/// Frame con un testo qualunque, come lo produrrebbe un altro invio QR.
String _frame(String text) => encodeTransfer(text).single;

String _decode(String frame) {
  final assembler = TransferAssembler();
  return (assembler.add(frame) as TransferComplete).text;
}

void main() {
  final library = _library();
  final challenge = FriendChallenge(
    mode: PuzzleRunMode.rush3,
    seed: 123456789,
    library: libraryFingerprint(library),
  );

  group('RF-95 sfida a tempo tra amici', () {
    test('il lancio si legge identico dopo il passaggio nel QR', () {
      final frames = encodeChallenge(ChallengeInvite(challenge));
      expect(frames, hasLength(1));
      final parsed = parseChallenge(_decode(frames.single));
      expect(parsed, isA<ChallengeInvite>());
      expect((parsed! as ChallengeInvite).challenge, challenge);
    });

    test('il risultato porta la sfida e il punteggio', () {
      final frames = encodeChallenge(ChallengeResult(challenge, 17));
      final parsed = parseChallenge(_decode(frames.single));
      expect(parsed, isA<ChallengeResult>());
      final result = parsed! as ChallengeResult;
      expect(result.challenge, challenge);
      expect(result.score, 17);
      expect(result.answers(challenge), isTrue);
    });

    test('un risultato di un\'altra sfida non risponde a questa', () {
      final other = FriendChallenge(
        mode: challenge.mode,
        seed: challenge.seed + 1,
        library: challenge.library,
      );
      expect(ChallengeResult(other, 3).answers(challenge), isFalse);
      final otherMode = FriendChallenge(
        mode: PuzzleRunMode.rush5,
        seed: challenge.seed,
        library: challenge.library,
      );
      expect(ChallengeResult(otherMode, 3).answers(challenge), isFalse);
    });

    test('solo le prove a tempo si possono lanciare', () {
      expect(friendChallengeModes, [
        PuzzleRunMode.storm,
        PuzzleRunMode.rush3,
        PuzzleRunMode.rush5,
      ]);
      for (final m in friendChallengeModes) {
        expect(m.limit, isNotNull);
      }
    });

    test('lo stesso seme dà gli stessi puzzle sui due telefoni', () {
      List<String> sequence(PuzzleLibrary lib) {
        final run = PuzzleRun(
          challenge.mode,
          lib,
          clock: () => Duration.zero,
          random: SeededRandom(challenge.seed),
        );
        final ids = <String>[];
        for (var i = 0; i < 8; i++) {
          ids.add(run.current.puzzle.id);
          final solution = run.current.puzzle.solution.first;
          run.tryMove(solution);
        }
        return ids;
      }

      expect(sequence(_library()), sequence(_library()));
      final other = <String>[];
      final run = PuzzleRun(
        challenge.mode,
        _library(),
        clock: () => Duration.zero,
        random: SeededRandom(challenge.seed + 1),
      );
      for (var i = 0; i < 8; i++) {
        other.add(run.current.puzzle.id);
        run.tryMove(run.current.puzzle.solution.first);
      }
      expect(other, isNot(sequence(_library())));
    });

    test('il generatore dà sempre la stessa sequenza per un seme', () {
      final a = SeededRandom(7);
      final b = SeededRandom(7);
      final first = [for (var i = 0; i < 20; i++) a.nextInt(1000)];
      expect([for (var i = 0; i < 20; i++) b.nextInt(1000)], first);
      expect(first.toSet().length, greaterThan(10));
      expect(first.every((n) => n >= 0 && n < 1000), isTrue);
      // Valori fissi: se cambiano, i telefoni con versioni diverse non
      // sceglierebbero più gli stessi puzzle (aumentare _algorithm).
      expect(first.take(5).toList(), [532, 690, 334, 430, 375]);
      expect(SeededRandom(8).nextInt(1000), isNot(first.first));
      final d = SeededRandom(1).nextDouble();
      expect(d, inInclusiveRange(0, 1));
    });

    test('un punteggio diverso nella raccolta cambia l\'impronta', () {
      PuzzleLibrary withRating(int r) =>
          PuzzleLibrary([_p('a', r), _p('b', 900)]);
      expect(
        libraryFingerprint(withRating(500)),
        isNot(libraryFingerprint(withRating(501))),
      );
    });

    test('la raccolta diversa cambia l\'impronta', () {
      expect(libraryFingerprint(_library()), libraryFingerprint(_library()));
      expect(
        libraryFingerprint(_library(30)),
        isNot(libraryFingerprint(_library())),
      );
      expect(libraryFingerprint(library), matches(RegExp(r'^[0-9A-F]{8}$')));
    });

    test('chi vince, chi perde e il pareggio', () {
      expect(compareScores(mine: 9, theirs: 7), ChallengeOutcome.won);
      expect(compareScores(mine: 7, theirs: 9), ChallengeOutcome.lost);
      expect(compareScores(mine: 8, theirs: 8), ChallengeOutcome.draw);
    });
  });

  group('RF-95 i QR letti sono input non fidato', () {
    String json(Map<String, Object?> m) => _frame(jsonEncode(m));

    Map<String, Object?> invite() => {
      'k': 'sfida',
      'v': 1,
      'm': 'rush3',
      's': 5,
      'l': 'ABCDEF12',
    };

    Map<String, Object?> result() => {
      'k': 'risultato',
      'v': 1,
      'm': 'rush3',
      's': 5,
      'l': 'ABCDEF12',
      'p': 4,
    };

    ChallengeMessage? parse(Map<String, Object?> m) =>
        parseChallenge(jsonEncode(m));

    test('un testo che non è una sfida viene rifiutato', () {
      expect(parseChallenge('[White "Anna"]\n\n1. e4 *'), isNull);
      expect(parseChallenge('{non json'), isNull);
      expect(parseChallenge('[1,2,3]'), isNull);
      expect(parseChallenge('"sfida"'), isNull);
      expect(parseChallenge(''), isNull);
    });

    test('il caso valido passa', () {
      expect(parse(invite()), isA<ChallengeInvite>());
      expect(parse(result()), isA<ChallengeResult>());
    });

    test('tipo, versione o modalità sconosciuti vengono rifiutati', () {
      expect(parse({...invite(), 'k': 'altro'}), isNull);
      expect(parse({...invite(), 'v': 2}), isNull);
      expect(parse({...invite(), 'm': 'streak'}), isNull);
      expect(parse({...invite(), 'm': 'survival'}), isNull);
      expect(parse({...invite(), 'm': 7}), isNull);
    });

    test('seme, impronta e punteggio fuori intervallo vengono rifiutati', () {
      expect(parse({...invite(), 's': -1}), isNull);
      expect(parse({...invite(), 's': 4294967296}), isNull);
      expect(parse({...invite(), 's': '5'}), isNull);
      expect(parse({...invite(), 's': 1.5}), isNull);
      expect(parse({...invite(), 'l': 'abc'}), isNull);
      expect(parse({...invite(), 'l': 'ABCDEF1G'}), isNull);
      expect(parse({...result(), 'p': -1}), isNull);
      expect(parse({...result(), 'p': 100000}), isNull);
      expect(parse({...result(), 'p': '4'}), isNull);
      expect(parse({...result()}..remove('p')), isNull);
    });

    test('un testo troppo lungo non viene nemmeno analizzato', () {
      expect(parse({...invite(), 'x': 'a' * 2000}), isNull);
    });

    test('il frame passa dal ricompositore dei QR', () {
      expect(parseChallenge(_decode(json(invite()))), isA<ChallengeInvite>());
    });
  });
}
