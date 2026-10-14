import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/analysis/variation_tree.dart';
import 'package:rokko/archive/game_archive.dart';
import 'package:rokko/archive/pgn.dart';
import 'package:rokko/archive/saved_game.dart';
import 'package:rokko/archive/tree_pgn.dart';
import 'package:rokko/game/move_note.dart';

const withVariations =
    '[White "Anna"]\n[Black "Bruno"]\n[Result "1-0"]\n\n'
    '1. e4 e5 ( 1... c5 {Siciliana} 2. Nf3 ) 2. Nf3 Nc6 3. Bb5 1-0\n';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('varianti'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('RF-52 varianti nell\'importazione', () {
    test('la partita usa la linea principale e il record porta l\'albero', () {
      final record = importPgn(withVariations).games.single;
      expect(
        [for (final m in record.game.moves) m.san],
        ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      );
      expect(record.tree!.hasVariations, isTrue);
    });

    test('senza varianti il record non ha albero', () {
      final record = importPgn('1. e4 e5 *').games.single;
      expect(record.tree, isNull);
    });

    test('annotare la linea principale conserva le varianti', () {
      final record = importPgn(withVariations).games.single;
      record.annotate(0, MoveNote.of(comment: 'Apertura del re'));
      final pgn = record.toPgn();
      expect(pgn, contains('1. e4 { Apertura del re }'));
      expect(pgn, contains('( 1... c5 { Siciliana }'));
      final back = importPgn(pgn).games.single;
      expect(back.game.moves.first.note?.comment, 'Apertura del re');
      expect(back.tree!.hasVariations, isTrue);
    });

    test('senza varianti toPgn esporta la partita', () {
      final record = importPgn('1. e4 e5 1/2-1/2').games.single;
      record.annotate(1, MoveNote.of(symbol: MoveSymbol.good));
      expect(record.toPgn(), contains('e5 \$1'));
    });

    test('l\'archivio conserva le varianti importate', () async {
      final archive = GameArchive(File('${dir.path}/games.json'));
      await archive.importPgn(withVariations);
      final saved = (await GameArchive(
        File('${dir.path}/games.json'),
      ).list()).single;
      expect(saved.pgn, contains('( 1... c5 { Siciliana }'));
      expect(saved.result, '1-0');
      expect(saved.toTree()!.hasVariations, isTrue);
      expect(saved.toGame().moves, hasLength(5));
      expect(await archive.exportPgn(), contains('( 1... c5'));
    });
  });

  group('RF-52 analisi salvata', () {
    VariationTree analysis() {
      final tree = VariationTree(Chess.initial)
        ..play(Move.parse('d2d4')!)
        ..play(Move.parse('d7d5')!)
        ..back()
        ..play(Move.parse('g8f6')!);
      tree.current.note = MoveNote.of(comment: 'Indiana');
      return tree;
    }

    test('si salva con il nome scelto e si riapre uguale', () async {
      final at = DateTime(2026, 10, 13, 18);
      final saved = SavedGame.fromTree(
        analysis(),
        id: 'analisi-1',
        name: 'Gambetto di donna',
        createdAt: at,
        updatedAt: at,
      );
      expect(saved.mode, SavedGame.analysis);
      expect(saved.title, 'Gambetto di donna');
      expect(saved.finished, isFalse);
      final archive = GameArchive(File('${dir.path}/games.json'));
      await archive.save(saved);
      final back = (await GameArchive(
        File('${dir.path}/games.json'),
      ).list()).single;
      expect(exportTreePgn(back.toTree()!), exportTreePgn(analysis()));
      expect(
        back.toTree()!.root.children.single.children[1].note?.comment,
        'Indiana',
      );
    });

    test('un\'analisi non si propone come partita da riprendere', () async {
      final at = DateTime(2026, 10, 13, 18);
      final archive = GameArchive(File('${dir.path}/games.json'));
      await archive.save(
        SavedGame.fromTree(
          analysis(),
          id: 'a',
          name: 'x',
          createdAt: at,
          updatedAt: at,
        ),
      );
      expect(await archive.unfinished(), isNull);
    });
  });
}
