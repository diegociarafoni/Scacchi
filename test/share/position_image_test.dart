import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/share/position_image.dart';

void main() {
  group('cleanCaption', () {
    test('senza testo non c\'è didascalia', () {
      expect(cleanCaption(null), isNull);
      expect(cleanCaption(''), isNull);
      expect(cleanCaption('  \n\t '), isNull);
    });

    test('toglie gli spazi ai bordi e unisce le righe', () {
      expect(
        cleanCaption('  Matto in 2 \n  del Bianco '),
        'Matto in 2 del Bianco',
      );
    });

    test('taglia al massimo e non lascia spazi in coda', () {
      final long = '${'a' * (maxCaptionLength - 1)} bbbbbbbb';
      final cut = cleanCaption(long)!;
      expect(cut.length, lessThanOrEqualTo(maxCaptionLength));
      expect(cut, isNot(endsWith(' ')));
      expect(cut, startsWith('a'));
    });

    test('non spezza le coppie surrogate', () {
      final emoji = '♞' * (maxCaptionLength + 5);
      expect(cleanCaption(emoji)!.runes.length, maxCaptionLength);
    });
  });

  group('exportPixelRatio', () {
    test('porta l\'immagine alla larghezza di esportazione', () {
      expect(exportPixelRatio(360), closeTo(exportWidth / 360, 1e-9));
    });

    test('non riduce mai sotto 1 e regge una larghezza nulla', () {
      expect(exportPixelRatio(5000), 1);
      expect(exportPixelRatio(0), 1);
    });
  });

  group('PositionImage', () {
    test('ha un nome di file fisso e riconoscibile', () {
      expect(positionImageFileName, 'rokko-posizione.png');
    });

    test('valori predefiniti: Bianco in basso, niente frecce', () {
      const image = PositionImage(fen: kInitialFEN);
      expect(image.orientation, Side.white);
      expect(image.shapes, isEmpty);
      expect(image.lastMove, isNull);
    });
  });
}
