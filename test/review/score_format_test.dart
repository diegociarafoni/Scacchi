import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/uci.dart';
import 'package:scacchi/l10n/app_localizations.dart';
import 'package:scacchi/review/score_format.dart';

final _it = lookupAppLocalizations(const Locale('it'));

void main() {
  test('la descrizione parla la lingua dell\'app', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      describeScore(en, const EngineScore.cp(150)),
      'White is ahead by 1.5',
    );
    expect(
      describeScore(en, const EngineScore.mate(-1)),
      'Black has mate in 1',
    );
    expect(describeScore(en, const EngineScore.cp(4)), 'Equal');
  });

  group('RF-50 valore numerico della valutazione', () {
    test('centipedoni in pedoni con segno', () {
      expect(formatScore(const EngineScore.cp(34)), '+0.3');
      expect(formatScore(const EngineScore.cp(-250)), '−2.5');
      expect(formatScore(const EngineScore.cp(0)), '0.0');
      // Arrotondato a zero: niente segno.
      expect(formatScore(const EngineScore.cp(4)), '0.0');
      expect(formatScore(const EngineScore.cp(-3)), '0.0');
    });

    test('matto in N', () {
      expect(formatScore(const EngineScore.mate(3)), 'M3');
      expect(formatScore(const EngineScore.mate(-2)), '−M2');
    });

    test('scacco matto avvenuto', () {
      expect(formatScore(const EngineScore.mate(0)), '#');
    });

    test('descrizione per i lettori di schermo', () {
      expect(
        describeScore(_it, const EngineScore.cp(150)),
        'Bianco avanti di 1.5',
      );
      expect(
        describeScore(_it, const EngineScore.cp(-40)),
        'Nero avanti di 0.4',
      );
      expect(describeScore(_it, const EngineScore.cp(4)), 'Parità');
      // Lettore di schermo e testo visibile dicono la stessa cosa.
      expect(
        describeScore(_it, const EngineScore.cp(8)),
        'Bianco avanti di 0.1',
      );
      expect(
        describeScore(_it, const EngineScore.mate(2)),
        'Matto in 2 per il Bianco',
      );
      expect(
        describeScore(_it, const EngineScore.mate(-1)),
        'Matto in 1 per il Nero',
      );
    });
  });
}
