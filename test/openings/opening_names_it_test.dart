import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/openings/opening_names_it.dart';

void main() {
  group('nomi delle aperture in italiano', () {
    test('famiglie comuni', () {
      expect(openingNameIt("King's Pawn Game"), 'Partita di pedone di re');
      expect(openingNameIt("Queen's Pawn Game"), 'Partita di pedone di donna');
      expect(openingNameIt('English Opening'), 'Apertura inglese');
      expect(openingNameIt('Zukertort Opening'), 'Apertura Zukertort');
      expect(openingNameIt('Sicilian Defense'), 'Difesa siciliana');
      expect(openingNameIt('Ruy Lopez'), 'Partita spagnola');
    });

    test('accettato e rifiutato concordano con il nome', () {
      expect(
        openingNameIt("Queen's Gambit Declined"),
        'Gambetto di donna rifiutato',
      );
      expect(
        openingNameIt("King's Gambit Accepted"),
        'Gambetto di re accettato',
      );
      expect(
        openingNameIt('Semi-Slav Defense Accepted'),
        'Difesa semislava accettata',
      );
    });

    test('varianti: nome comune davanti, nomi propri invariati', () {
      expect(
        openingNameIt('Sicilian Defense: Najdorf Variation'),
        'Difesa siciliana: variante Najdorf',
      );
      expect(
        openingNameIt('French Defense: Classical Variation'),
        'Difesa francese: variante classica',
      );
      expect(
        openingNameIt('Ruy Lopez: Open Variation, Main Line'),
        'Partita spagnola: variante aperta, linea principale',
      );
      expect(
        openingNameIt('Italian Game: Two Knights Defense'),
        'Partita italiana: difesa dei due cavalli',
      );
      expect(
        openingNameIt('Sicilian Defense: Yugoslav Attack'),
        'Difesa siciliana: attacco jugoslavo',
      );
    });

    test('aggettivi senza sostantivo si accordano con la famiglia', () {
      expect(openingNameIt('Ruy Lopez: Open'), 'Partita spagnola: aperta');
      expect(
        openingNameIt('Sicilian Defense: Closed, Smyslov Variation'),
        'Difesa siciliana: chiusa, variante Smyslov',
      );
      expect(
        openingNameIt('Danish Gambit: Classical'),
        'Gambetto danese: classico',
      );
    });

    test('prefissi neo, anti e semi', () {
      expect(
        openingNameIt('Modern Defense: Neo-Modern Defense'),
        'Difesa moderna: difesa neo-moderna',
      );
      expect(
        openingNameIt('Dutch Defense: Manhattan Gambit, Anti-Classical Line'),
        'Difesa olandese: gambetto Manhattan, linea anti-classica',
      );
    });

    test('due sostantivi di fila: il primo diventa complemento', () {
      expect(
        openingNameIt('Center Game: Paulsen Attack Variation'),
        'Partita del centro: variante attacco Paulsen',
      );
    });

    test('suffissi "with" e mosse nel nome', () {
      expect(
        openingNameIt("Queen's Indian Defense, with e3, Bb4+ Line"),
        'Difesa indiana di donna, con e3, linea Bb4+',
      );
    });

    test('un nome senza traduzione resta in inglese', () {
      expect(
        openingNameIt('Flying Spaghetti Monster'),
        'Flying Spaghetti Monster',
      );
    });

    test('nessun nome del libro lascia parole comuni in inglese', () {
      final names = File('assets/openings/openings.tsv')
          .readAsLinesSync()
          .skip(1)
          .map((l) => l.split('\t'))
          .where((f) => f.length >= 3)
          .map((f) => f[1])
          .toSet();
      final english = RegExp(
        r'\b(Defense|Gambit|Opening|Attack|Game|Variation|Variations|System|'
        r'Line|Countergambit|Classical|Accepted|Declined|Main|Closed|Open|'
        r'Modern|Exchange|with)\b',
      );
      final bad = [
        for (final n in names)
          if (english.hasMatch(openingNameIt(n))) '$n -> ${openingNameIt(n)}',
      ];
      expect(bad, isEmpty);
    });
  });
}
