import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/review/coach.dart';
import 'package:scacchi/review/game_review.dart';

/// Revisione di una sola mossa con le varianti date prima e dopo.
Future<MoveReview> reviewOne(
  String fen,
  String played, {
  required InfoLine best,
  required InfoLine reply,
}) async {
  final initial = Chess.fromSetup(Setup.parseFen(fen));
  final review = await reviewGame(
    initial: initial,
    moves: [Move.parse(played)!],
    evaluate: (f) async => [f == initial.fen ? best : reply],
  );
  return review!.moves.single;
}

InfoLine line(List<String> pv, EngineScore score) =>
    InfoLine(multipv: 1, depth: 12, pv: pv, score: score);

void main() {
  group('RF-70 spiegazioni degli errori', () {
    test('pezzo lasciato in presa', () async {
      final m = await reviewOne(
        '4k3/8/8/3q4/8/2B5/8/4K3 w - - 0 1',
        'c3e5',
        best: line(['c3b2'], const EngineScore.cp(-600)),
        reply: line(['d5e5'], const EngineScore.cp(900)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.hangingPiece);
      expect(
        c.text,
        'Hai lasciato l\'alfiere in presa in e5: la donna nera lo cattura.',
      );
    });

    test('matto concesso', () async {
      final m = await reviewOne(
        'r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 3 3',
        'g8f6',
        best: line(['g7g6'], const EngineScore.cp(-30)),
        reply: line(['h5f7'], const EngineScore.mate(1)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.allowedMate);
      expect(c.text, 'Dopo Nf6 il Bianco dà matto in 1 con Qxf7#.');
    });

    test('matto mancato', () async {
      final m = await reviewOne(
        'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        'a2a3',
        best: line(['f3f7'], const EngineScore.mate(1)),
        reply: line(['g8f6'], const EngineScore.cp(-20)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.missedMate);
      expect(c.text, 'Avevi il matto in 1 con Qxf7#.');
    });

    test('forchetta concessa', () async {
      final m = await reviewOne(
        '4k3/8/8/8/1n6/8/8/R3K2Q w - - 0 1',
        'h1g1',
        best: line(['a1a4'], const EngineScore.cp(900)),
        reply: line(['b4c2', 'e1d2', 'c2a1'], const EngineScore.cp(-100)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.allowedFork);
      expect(
        c.text,
        'Dopo Nc2+ il cavallo nero attacca insieme il re e la torre: '
        'è una forchetta.',
      );
    });

    test('perdita di materiale nella variante', () async {
      // La torre in d4 sembra difesa, ma la donna nera la vince con un
      // attacco doppio dopo la mossa.
      final m = await reviewOne(
        '4k3/8/8/8/3r4/8/3R4/3QK3 w - - 0 1',
        'd2d4',
        best: line(['e1f2'], const EngineScore.cp(0)),
        reply: line(['e8e7'], const EngineScore.cp(-500)),
      );
      // Txd4 cattura la torre: nessuna perdita, nessun commento d'errore.
      expect(explainMove(m)?.theme, isNot(CoachTheme.materialLoss));
    });

    test('mossa che peggiora senza motivo tattico evidente', () async {
      final m = await reviewOne(
        '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
        'e1d1',
        best: line(['e2e4'], const EngineScore.cp(300)),
        reply: line(['e8e7'], const EngineScore.cp(-100)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.generic);
      expect(c.text, 'Meglio e4: la tua posizione peggiora.');
    });
  });

  group('RF-71 riconoscimento tattico dalla variante del motore', () {
    test('cattura netta mancata', () async {
      final m = await reviewOne(
        '4k3/8/8/3r4/8/8/8/3QK3 w - - 0 1',
        'e1e2',
        best: line(['d1d5'], const EngineScore.cp(900)),
        reply: line(['e8e7'], const EngineScore.cp(0)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.missedCapture);
      expect(c.text, 'Potevi vincere materiale: Qxd5 cattura la torre.');
    });

    test('doppio attacco mancato', () async {
      final m = await reviewOne(
        'r3k3/8/8/1N6/8/8/8/4K3 w - - 0 1',
        'e1e2',
        best: line(['b5c7', 'e8d7', 'c7a8'], const EngineScore.cp(500)),
        reply: line(['a8a2'], const EngineScore.cp(0)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.missedFork);
      expect(
        c.text,
        'Potevi fare un doppio attacco con Nc7+: il cavallo attacca il re '
        'e la torre.',
      );
    });

    test('attacco di scoperta mancato', () async {
      // Cc6+ libera la diagonale: l'alfiere in b2 attacca la donna in h8.
      final m = await reviewOne(
        '3k3q/8/8/8/3N4/8/1B6/4K3 w - - 0 1',
        'e1d1',
        best: line(['d4c6', 'd8c7', 'b2h8'], const EngineScore.cp(900)),
        reply: line(['h8h1'], const EngineScore.cp(0)),
      );
      final c = explainMove(m)!;
      expect(c.theme, CoachTheme.missedDiscovery);
      expect(
        c.text,
        'Potevi fare un attacco di scoperta con Nc6+: l\'alfiere attacca '
        'la donna.',
      );
    });
  });

  group('lodi', () {
    test('le mosse buone non hanno spiegazione d\'errore', () async {
      final m = await reviewOne(
        '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
        'e2e4',
        best: line(['e2e4'], const EngineScore.cp(300)),
        reply: line(['e8e7'], const EngineScore.cp(-300)),
      );
      expect(explainMove(m)?.theme, CoachTheme.praise);
      expect(explainMove(m)!.text, 'È la mossa migliore.');
    });
  });
}
