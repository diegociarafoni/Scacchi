import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show PieceKind, Side;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/board_frame.dart';
import 'package:scacchi/settings/color_blind.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un asset dell'app esiste su disco, con la variante ad alta densità.
void expectAppAsset(AssetImage image, {String? reason}) {
  expect(image.package, isNull, reason: reason);
  final file = File(image.assetName);
  expect(file.existsSync(), isTrue, reason: '${image.assetName} ($reason)');
  final hiRes = File('${file.parent.path}/3.0x/${file.uri.pathSegments.last}');
  expect(hiRes.existsSync(), isTrue, reason: '${hiRes.path} ($reason)');
}

const _blackKinds = [
  PieceKind.blackKing,
  PieceKind.blackQueen,
  PieceKind.blackRook,
  PieceKind.blackBishop,
  PieceKind.blackKnight,
  PieceKind.blackPawn,
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('RP-01 pezzi disegnati per Rokko e set aggiunti', () {
    test('ci sono i cinque set scelti, con autore e licenza', () {
      final byName = PieceStyle.values.asNameMap();
      expect(byName['rokko']!.license, 'GPL-3.0+');
      expect(byName['pixel']!.license, 'GPL-3.0+');
      expect(byName['arcano']!.license, 'GPL-3.0+');
      expect(byName['papercut']!.author, 'Nikolay Anzarov');
      expect(byName['papercut']!.license, 'CC BY 4.0');
      expect(byName['noto']!.license, 'OFL-1.1');
    });

    test('ogni set nostro ha i dodici pezzi in assets/pieces', () {
      for (final style in PieceStyle.values.where((p) => p.pieceSet == null)) {
        expect(style.assets.length, 12, reason: style.name);
        for (final image in style.assets.values) {
          expect(image.assetName, startsWith('assets/pieces/${style.name}/'));
          expectAppAsset(image, reason: style.name);
        }
      }
    });
  });

  group('alone per i temi scuri', () {
    test('ogni set ha la versione con alone dei pezzi neri', () {
      for (final style in PieceStyle.values) {
        final halo = style.assetsOn(BoardTheme.spazio);
        for (final kind in _blackKinds) {
          expect(
            halo[kind]!.assetName,
            'assets/pieces/halo/${style.name}/${_code(kind)}.webp',
          );
          expectAppAsset(halo[kind]!, reason: '${style.name} ${kind.name}');
        }
        expect(
          halo[PieceKind.whiteKing],
          style.assets[PieceKind.whiteKing],
          reason: 'i bianchi restano uguali',
        );
      }
    });

    test('solo i temi scuri usano l\'alone', () {
      final dim = BoardTheme.values.where((t) => t.dim).toSet();
      expect(dim, {
        BoardTheme.night,
        BoardTheme.crepuscolo,
        BoardTheme.castello,
        BoardTheme.spazio,
      });
      const style = PieceStyle.merida;
      expect(style.assetsOn(BoardTheme.green), style.assets);
      final s = AppSettings(boardTheme: BoardTheme.castello, pieceSet: style);
      expect(s.board.pieceAssets, style.assetsOn(BoardTheme.castello));
    });
  });

  group('RP-01 scacchiere con texture', () {
    test('ci sono le dieci scacchiere scelte', () {
      final names = BoardTheme.values.map((t) => t.name).toSet();
      expect(
        names.containsAll({
          'arancia',
          'crepuscolo',
          'pergamena',
          'castello',
          'bosco',
          'noce',
          'spazio',
          'retro',
          'giardino',
          'terracotta',
        }),
        isTrue,
      );
    });

    test('le immagini sono solo nostre, mai quelle AGPL di chessground', () {
      for (final t in BoardTheme.values) {
        final background = t.colorScheme.background;
        if (t.image == null) {
          expect(background, isA<SolidColorChessboardBackground>());
          continue;
        }
        expect(background, isA<ImageChessboardBackground>(), reason: t.name);
        final image = (background as ImageChessboardBackground).image;
        expect(image.package, isNull, reason: t.name);
        expect(image.assetName, 'assets/boards/${t.name}.webp');
        expect(File(image.assetName).existsSync(), isTrue, reason: t.name);
      }
    });
  });

  test('fuori dalla scacchiera i pezzi non hanno alone', () {
    final s = AppSettings(
      boardTheme: BoardTheme.spazio,
      pieceSet: PieceStyle.rokko,
      coordinatesOutside: true,
    );
    expect(s.pieceAssets, PieceStyle.rokko.assets);
    expect(s.editorBoard.pieceAssets, PieceStyle.rokko.assets);
    expect(s.editorBoard.enableCoordinates, isTrue, reason: 'senza cornice');
  });

  test('RNF-07 le evidenziazioni si vedono su ogni scacchiera con texture', () {
    for (final t in BoardTheme.values.where((t) => t.textured)) {
      final s = t.colorScheme;
      for (final h in [s.lastMove.solidColor!, s.selected.solidColor!]) {
        expect(
          highlightContrast(h, t.light!, t.dark!),
          greaterThanOrEqualTo(1.25),
          reason: t.name,
        );
      }
    }
  });

  group('coordinate fuori dalla scacchiera', () {
    test('sono spente all\'inizio e restano salvate', () async {
      final c = await SettingsController.load();
      expect(c.value.coordinatesOutside, isFalse);
      await c.update(c.value.copyWith(coordinatesOutside: true));
      expect((await SettingsController.load()).value.coordinatesOutside, true);
    });

    test('quelle disegnate da chessground si spengono', () {
      final s = AppSettings(coordinatesOutside: true);
      expect(s.board.enableCoordinates, isFalse);
      expect(s.outsideCoordinates, isTrue);
      final hidden = AppSettings(
        coordinatesOutside: true,
        showCoordinates: false,
      );
      expect(hidden.outsideCoordinates, isFalse);
      expect(hidden.board.enableCoordinates, isFalse);
    });

    Future<Size> pumpFrame(
      WidgetTester tester, {
      required bool outside,
      Side orientation = Side.white,
    }) async {
      late Size inner;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: BoardFrame(
              size: 320,
              outside: outside,
              orientation: orientation,
              theme: BoardTheme.noce,
              builder: (size) {
                inner = Size.square(size);
                return SizedBox.square(dimension: size);
              },
            ),
          ),
        ),
      );
      return inner;
    }

    testWidgets('lasciano più piccola la scacchiera e mostrano lettere e '
        'numeri', (tester) async {
      final inner = await pumpFrame(tester, outside: true);
      expect(inner.width, lessThan(320));
      expect(tester.getSize(find.byType(BoardFrame)), const Size(320, 320));
      for (final label in ['a', 'h', '1', '8']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final a = tester.getCenter(find.text('a'));
      final h = tester.getCenter(find.text('h'));
      expect(a.dx, lessThan(h.dx));
      final one = tester.getCenter(find.text('1'));
      final eight = tester.getCenter(find.text('8'));
      expect(one.dy, greaterThan(eight.dy));
    });

    testWidgets('si girano con la scacchiera', (tester) async {
      await pumpFrame(tester, outside: true, orientation: Side.black);
      final a = tester.getCenter(find.text('a'));
      final h = tester.getCenter(find.text('h'));
      expect(a.dx, greaterThan(h.dx));
    });

    testWidgets('senza coordinate esterne la scacchiera resta intera', (
      tester,
    ) async {
      final inner = await pumpFrame(tester, outside: false);
      expect(inner.width, 320);
      expect(find.text('a'), findsNothing);
    });
  });
}

String _code(PieceKind kind) =>
    '${kind.side == Side.white ? 'w' : 'b'}${kind.role.letter.toUpperCase()}';
