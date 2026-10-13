import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/coach/opening_coach.dart';
import 'package:scacchi/openings/opening_book.dart';
import 'package:scacchi/openings/opening_stats.dart';

final book = OpeningBook.parseTsv(
  'eco\tname\tuci\n'
  'C40\tKing\'s Knight Opening\te2e4 e7e5 g1f3\n'
  'C60\tRuy Lopez\te2e4 e7e5 g1f3 b8c6 f1b5\n'
  'B20\tSicilian Defense\te2e4 c7c5\n',
);

String key(String uci) {
  Position pos = Chess.initial;
  for (final m in uci.split(' ').where((s) => s.isNotEmpty)) {
    pos = pos.play(Move.parse(m)!);
  }
  return OpeningStats.keyOf(pos);
}

final stats = OpeningStats.parseTsv(
  'chiave\tmosse\n'
  '${key('')}\te4:1000:450:350,d4:800:400:280,c4:100:50:30,Nf3:50:20:20\n'
  '${key('e2e4')}\tc5:600:240:210,e5:400:180:120\n',
);

List<Move> moves(String uci) => [
  for (final m in uci.split(' ').where((s) => s.isNotEmpty)) Move.parse(m)!,
];

void main() {
  test('nella posizione iniziale propone le mosse più giocate', () {
    final note = openingNote(book, stats, const []) as InBookNote;
    expect(note.opening, isNull);
    expect([for (final c in note.choices) c.san], ['e4', 'd4', 'c4']);
    expect(note.choices.first.percent, 51);
    expect(note.choices.first.games, 1000);
  });

  test('in apertura dà il nome e le mosse da stats', () {
    final note = openingNote(book, stats, moves('e2e4')) as InBookNote;
    // Dopo 1.e4 la posizione non ha ancora un nome, la risposta sì.
    expect(note.opening, isNull);
    expect([for (final c in note.choices) c.san], ['c5', 'e5']);
    expect([for (final c in note.choices) c.percent], [60, 40]);
    expect(note.choices.first.opening?.name, 'Sicilian Defense');
  });

  test('senza statistiche usa le continuazioni del libro', () {
    final note = openingNote(book, null, moves('e2e4 e7e5 g1f3')) as InBookNote;
    expect(note.choices.single.san, 'Nc6');
    expect(note.choices.single.percent, 100);
    expect(note.opening?.name, "King's Knight Opening");
  });

  test('uscire dal libro lo segnala una volta, con ciò che si giocava', () {
    final note = openingNote(book, stats, moves('e2e4 a7a6')) as LeftBookNote;
    expect(note.playedSan, 'a6');
    expect(note.by, Side.black);
    expect([for (final c in note.expected) c.san], ['c5', 'e5']);
    expect(note.opening, isNull);
    // Una mossa dopo non c'è più niente da dire.
    expect(openingNote(book, stats, moves('e2e4 a7a6 d2d4')), isNull);
  });

  test('chi esce dal libro è chi ha mosso per ultimo', () {
    final note = openingNote(book, stats, moves('a2a3')) as LeftBookNote;
    expect(note.by, Side.white);
    expect(note.playedSan, 'a3');
  });

  test('una mossa illegale non produce note', () {
    expect(openingNote(book, stats, moves('e2e4 e2e4')), isNull);
  });

  test('una posizione nota solo alle statistiche resta nel libro', () {
    final onlyStats = OpeningStats.parseTsv(
      'chiave\tmosse\n${key('a2a3')}\ta6:100:50:40\n',
    );
    final note = openingNote(book, onlyStats, moves('a2a3')) as InBookNote;
    expect(note.choices.single.san, 'a6');
  });
}
