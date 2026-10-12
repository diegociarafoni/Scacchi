import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/physical/board_photo.dart';

import 'board_render.dart';

Position after(Position pos, List<String> sans) {
  var p = pos;
  for (final san in sans) {
    p = p.play(p.parseSan(san)!);
  }
  return p;
}

String? best(Position pos, BoardFrame a, BoardFrame b, {BoardQuad? quad}) {
  final guesses = guessMoves(
    pos,
    before: a,
    after: b,
    quad: quad ?? BoardQuad.full,
  );
  return guesses.isEmpty ? null : pos.makeSan(guesses.first.move).$2;
}

void main() {
  const start = Chess.initial;

  test('riconosce una mossa semplice dal confronto delle due foto', () {
    final next = after(start, ['e4']);
    expect(best(start, render(start), render(next)), 'e4');
  });

  test('riconosce una mossa dal lato del Nero', () {
    final mid = after(start, ['e4']);
    final next = after(mid, ['c5']);
    expect(best(mid, render(mid), render(next)), 'c5');
  });

  test('distingue un cavallo da un altro dalle caselle di partenza', () {
    final mid = after(start, ['Nf3', 'Nf6', 'e3', 'e6', 'Nc3', 'Nc6']);
    final next = after(mid, ['Nd4']);
    expect(best(mid, render(mid), render(next)), 'Nd4');
  });

  test('riconosce una presa', () {
    final mid = after(start, ['e4', 'd5']);
    final next = after(mid, ['exd5']);
    expect(best(mid, render(mid), render(next)), 'exd5');
  });

  test('riconosce l\'arrocco con le quattro caselle cambiate', () {
    final mid = after(start, ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5']);
    final next = after(mid, ['O-O']);
    expect(best(mid, render(mid), render(next)), 'O-O');
  });

  test('riconosce la presa en passant', () {
    final mid = after(start, ['e4', 'a6', 'e5', 'd5']);
    final next = after(mid, ['exd6']);
    expect(best(mid, render(mid), render(next)), 'exd6');
  });

  test('per una promozione propone prima la donna e poi gli altri pezzi', () {
    final pos = Chess.fromSetup(
      Setup.parseFen('8/P6k/8/8/8/8/6K1/8 w - - 0 1'),
    );
    final next = after(pos, ['a8=Q']);
    final guesses = guessMoves(pos, before: render(pos), after: render(next));
    expect(
      [
        for (final g in guesses.take(4))
          pos.makeSan(g.move).$2.split('+').first,
      ],
      ['a8=Q', 'a8=R', 'a8=B', 'a8=N'],
    );
  });

  test('topGuesses tiene una sola promozione per casella di arrivo', () {
    final pos = Chess.fromSetup(
      Setup.parseFen('8/P6k/8/8/8/8/6K1/8 w - - 0 1'),
    );
    final guesses = guessMoves(
      pos,
      before: render(pos),
      after: render(after(pos, ['a8=Q'])),
    );
    final top = topGuesses(guesses, 3);
    expect(top, hasLength(3));
    expect(pos.makeSan(top.first.move).$2.split('+').first, 'a8=Q');
    final squares = {
      for (final g in top)
        (g.move as NormalMove).from.value * 64 +
            (g.move as NormalMove).to.value,
    };
    expect(squares, hasLength(3));
  });

  test('l\'arrocco in una posizione 960 usa le torri vere', () {
    final pos = Chess.fromSetup(
      Setup.parseFen('4k3/8/8/8/8/8/8/1K5R w H - 0 1'),
    );
    final next = pos.play(const NormalMove(from: Square.b1, to: Square.h1));
    expect(best(pos, render(pos), render(next)), isNotNull);
  });

  test('regge un cambio di luce, rumore e un piccolo spostamento', () {
    final mid = after(start, ['d4', 'd5', 'c4', 'e6']);
    final next = after(mid, ['Nc3']);
    final a = render(mid, noise: 6);
    final b = render(next, gain: 25, noise: 6, shiftX: 3);
    expect(best(mid, a, b), 'Nc3');
  });

  test('usa il riquadro della scacchiera quando c\'è sfondo attorno', () {
    final next = after(start, ['Nf3']);
    final quad = BoardQuad.inset(.1);
    final a = render(start, inset: .1);
    final b = render(next, inset: .1);
    expect(best(start, a, b, quad: quad), 'Nf3');
  });

  test('legge anche la scacchiera vista dal Nero', () {
    final next = after(start, ['d4']);
    final guesses = guessMoves(
      start,
      before: render(start, view: Side.black),
      after: render(next, view: Side.black),
      view: Side.black,
    );
    expect(start.makeSan(guesses.first.move).$2, 'd4');
  });

  test('due foto uguali non producono alcuna mossa', () {
    final f = render(start, noise: 4);
    expect(
      guessMoves(start, before: f, after: render(start, noise: 4)),
      isEmpty,
    );
  });

  test('le mosse sono ordinate dalla più alla meno probabile', () {
    final next = after(start, ['e4']);
    final guesses = guessMoves(
      start,
      before: render(start),
      after: render(next),
    );
    for (var i = 1; i < guesses.length; i++) {
      expect(guesses[i].cost, greaterThanOrEqualTo(guesses[i - 1].cost));
    }
    expect(guesses.first.cost, lessThan(guesses[1].cost));
  });

  test('il riquadro mappa gli angoli e il centro', () {
    const quad = BoardQuad(
      topLeft: PhotoPoint(.1, .2),
      topRight: PhotoPoint(.9, .2),
      bottomRight: PhotoPoint(.8, .9),
      bottomLeft: PhotoPoint(.2, .9),
    );
    expect(quad.at(0, 0), const PhotoPoint(.1, .2));
    expect(quad.at(1, 1), const PhotoPoint(.8, .9));
    final c = quad.at(.5, .5);
    expect(c.x, closeTo(.5, 1e-9));
    expect(c.y, closeTo(.55, 1e-9));
  });
}
