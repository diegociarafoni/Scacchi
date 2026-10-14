import 'dart:io';

import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/settings/settings.dart';

void main() {
  final byName = PieceStyle.values.asNameMap();

  test('Staunton, Morbido e Stampa sono set nostri con licenza GPL', () {
    for (final n in ['staunton', 'morbido', 'stampa']) {
      final style = byName[n];
      expect(style, isNotNull, reason: n);
      expect(style!.pieceSet, isNull, reason: '$n sta in assets/pieces');
      expect(style.author, 'Progetto Rokko', reason: n);
      expect(style.license, 'GPL-3.0+', reason: n);
    }
  });

  test('ogni set nuovo ha i dodici pezzi in due risoluzioni e gli aloni', () {
    for (final n in ['staunton', 'morbido', 'stampa']) {
      final style = byName[n]!;
      expect(style.assets.length, 12, reason: n);
      for (final kind in PieceKind.values) {
        final name = style.assets[kind]!.assetName;
        expect(File(name).existsSync(), isTrue, reason: name);
        expect(
          File(name.replaceFirst('/$n/', '/$n/3.0x/')).existsSync(),
          isTrue,
          reason: '$name a 3.0x',
        );
      }
      final halo = style.assetsOn(BoardTheme.spazio);
      expect(
        halo[PieceKind.blackKing]!.assetName,
        contains('assets/pieces/halo/$n/'),
      );
    }
  });

  test('i set nuovi pesano poco: meno di 800 KB con aloni', () {
    var total = 0;
    for (final n in ['staunton', 'morbido', 'stampa']) {
      for (final dir in ['assets/pieces/$n', 'assets/pieces/halo/$n']) {
        for (final f in Directory(dir).listSync(recursive: true)) {
          if (f is File) total += f.lengthSync();
        }
      }
    }
    expect(total, lessThan(800 * 1024));
  });
}
