import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/archive/saved_game.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/personal_tree.dart';

final _t = DateTime(2026, 10, 10);

SavedGame game(
  String moves, {
  String result = '1-0',
  Side? side = Side.white,
  String opponent = 'Bot',
  String mode = SavedGame.computer,
}) {
  const me = 'Io';
  return SavedGame(
    id: '${moves.hashCode}-$result-$opponent-$side',
    createdAt: _t,
    updatedAt: _t,
    white: side == Side.black ? opponent : me,
    black: side == Side.black ? me : opponent,
    mode: mode,
    result: result,
    pgn: '$moves $result',
    playerSide: side,
  );
}

PersonalMove? find(List<PersonalMove> list, String san) {
  for (final m in list) {
    if (m.san == san) return m;
  }
  return null;
}

void main() {
  const start = Chess.initial;

  test('RF-96 conta quante volte è stata giocata ogni mossa e i risultati', () {
    final tree = PersonalOpeningTree.build([
      game('1. e4 e5'),
      game('1. e4 c5', result: '0-1'),
      game('1. e4 e5', result: '1/2-1/2'),
      game('1. d4 d5'),
    ]);
    expect(tree.games, 4);
    final moves = tree.continuationsAt(start);
    expect([for (final m in moves) m.san], ['e4', 'd4']);
    final e4 = find(moves, 'e4')!;
    expect((e4.games, e4.wins, e4.draws, e4.losses), (3, 1, 1, 1));
    final d4 = find(moves, 'd4')!;
    expect((d4.games, d4.wins, d4.draws, d4.losses), (1, 1, 0, 0));
    expect(e4.move, Move.parse('e2e4'));
  });

  test('RF-96 i risultati sono dal punto di vista di chi ha giocato', () {
    final tree = PersonalOpeningTree.build([
      game('1. e4 e5', result: '0-1', side: Side.black, opponent: 'Anna'),
    ]);
    final e4 = tree.continuationsAt(start).single;
    expect((e4.wins, e4.losses), (1, 0));
  });

  test('RF-96 le mosse seguono la posizione, anche dopo una trasposizione', () {
    final tree = PersonalOpeningTree.build([
      game('1. Nf3 d5 2. d4 Nf6'),
      game('1. d4 d5 2. Nf3 Nf6'),
    ]);
    final pos = OpeningBook.replay([
      for (final u in ['g1f3', 'd7d5', 'd2d4']) Move.parse(u)!,
    ]).last;
    final alt = OpeningBook.replay([
      for (final u in ['d2d4', 'd7d5', 'g1f3']) Move.parse(u)!,
    ]).last;
    expect(OpeningBook.key(pos), OpeningBook.key(alt));
    final next = tree.continuationsAt(pos).single;
    expect((next.san, next.games), ('Nf6', 2));
  });

  test('RF-96 si filtra per colore', () {
    final games = [
      game('1. e4 e5'),
      game('1. d4 d5', side: Side.black, opponent: 'Anna', result: '0-1'),
    ];
    expect(PersonalOpeningTree.build(games, side: Side.white).games, 1);
    final black = PersonalOpeningTree.build(games, side: Side.black);
    expect(black.games, 1);
    expect(black.continuationsAt(start).single.san, 'd4');
    expect(PersonalOpeningTree.build(games).games, 2);
  });

  test('RF-96 si filtra per avversario', () {
    final games = [
      game('1. e4 e5', opponent: 'Anna'),
      game('1. d4 d5'),
      game('1. c4 e5', side: Side.black, opponent: 'Anna', result: '0-1'),
    ];
    final anna = PersonalOpeningTree.build(games, opponent: 'Anna');
    expect(anna.games, 2);
    expect([for (final m in anna.continuationsAt(start)) m.san], ['c4', 'e4']);
    expect(PersonalOpeningTree.build(games, opponent: 'Zeno').games, 0);
  });

  test('RF-96 elenco degli avversari senza doppioni, in ordine', () {
    expect(
      PersonalGames.from([
        game('1. e4 e5', opponent: 'bruno'),
        game('1. d4 d5', opponent: 'Anna'),
        game('1. c4 e5', opponent: 'Anna'),
        game('1. e4 e5', side: null, opponent: 'Zeno'),
        game('1. e4 e5', result: '*', opponent: 'Carla'),
      ]).opponents,
      ['Anna', 'bruno'],
    );
  });

  test('RF-96 partite in corso, importate, senza colore o senza mosse '
      'sono escluse', () {
    final tree = PersonalOpeningTree.build([
      game('1. e4 e5', result: '*'),
      game('1. e4 e5', mode: SavedGame.imported),
      game('1. e4 e5', side: null),
      game(''),
      game('1. e4 e5'),
    ]);
    expect(tree.games, 1);
    expect(tree.continuationsAt(start).single.games, 1);
  });

  test('RF-96 una posizione mai giocata non ha mosse', () {
    final tree = PersonalOpeningTree.build([game('1. e4 e5')]);
    final pos = Chess.initial.play(Move.parse('a2a3')!);
    expect(tree.continuationsAt(pos), isEmpty);
  });
}
