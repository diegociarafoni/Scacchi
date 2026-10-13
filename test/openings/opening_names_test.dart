import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/content.dart';
import 'package:scacchi/openings/opening_names.dart';

import '../content_support.dart';

void main() {
  tearDown(useContent);

  group('nomi delle aperture in italiano', () {
    test('famiglie comuni', () {
      expect(localOpeningName("King's Pawn Game"), 'Partita di pedone di re');
      expect(
        localOpeningName("Queen's Pawn Game"),
        'Partita di pedone di donna',
      );
      expect(localOpeningName('English Opening'), 'Apertura inglese');
      expect(localOpeningName('Zukertort Opening'), 'Apertura Zukertort');
      expect(localOpeningName('Sicilian Defense'), 'Difesa siciliana');
      expect(localOpeningName('Ruy Lopez'), 'Partita spagnola');
    });

    test('accettato e rifiutato concordano con il nome', () {
      expect(
        localOpeningName("Queen's Gambit Declined"),
        'Gambetto di donna rifiutato',
      );
      expect(
        localOpeningName("King's Gambit Accepted"),
        'Gambetto di re accettato',
      );
      expect(
        localOpeningName('Semi-Slav Defense Accepted'),
        'Difesa semislava accettata',
      );
    });

    test('varianti: nome comune davanti, nomi propri invariati', () {
      expect(
        localOpeningName('Sicilian Defense: Najdorf Variation'),
        'Difesa siciliana: variante Najdorf',
      );
      expect(
        localOpeningName('French Defense: Classical Variation'),
        'Difesa francese: variante classica',
      );
      expect(
        localOpeningName('Ruy Lopez: Open Variation, Main Line'),
        'Partita spagnola: variante aperta, linea principale',
      );
      expect(
        localOpeningName('Italian Game: Two Knights Defense'),
        'Partita italiana: difesa dei due cavalli',
      );
      expect(
        localOpeningName('Sicilian Defense: Yugoslav Attack'),
        'Difesa siciliana: attacco jugoslavo',
      );
    });

    test('aggettivi senza sostantivo si accordano con la famiglia', () {
      expect(localOpeningName('Ruy Lopez: Open'), 'Partita spagnola: aperta');
      expect(
        localOpeningName('Sicilian Defense: Closed, Smyslov Variation'),
        'Difesa siciliana: chiusa, variante Smyslov',
      );
      expect(
        localOpeningName('Danish Gambit: Classical'),
        'Gambetto danese: classico',
      );
    });

    test('prefissi neo, anti e semi', () {
      expect(
        localOpeningName('Modern Defense: Neo-Modern Defense'),
        'Difesa moderna: difesa neo-moderna',
      );
      expect(
        localOpeningName(
          'Dutch Defense: Manhattan Gambit, Anti-Classical Line',
        ),
        'Difesa olandese: gambetto Manhattan, linea anti-classica',
      );
    });

    test('due sostantivi di fila: il primo diventa complemento', () {
      expect(
        localOpeningName('Center Game: Paulsen Attack Variation'),
        'Partita del centro: variante attacco Paulsen',
      );
    });

    test('suffissi "with" e mosse nel nome', () {
      expect(
        localOpeningName("Queen's Indian Defense, with e3, Bb4+ Line"),
        'Difesa indiana di donna, con e3, linea Bb4+',
      );
    });

    test('un nome senza traduzione resta in inglese', () {
      expect(
        localOpeningName('Flying Spaghetti Monster'),
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
      // Sostantivi e aggettivi del glossario: se ne resta uno, manca una regola.
      final english = RegExp(
        r'\b(Defense|Gambit|Opening|Attack|Game|Variations?|System|Line|'
        r'Countergambit|Counterattack|Formation|Trap|Sacrifice|Endgame|'
        r'Retreat|Classical|Accepted|Declined|Main|Closed|Open|Modern|'
        r'Exchange|Advance|Normal|Orthodox|Symmetrical|Reversed|Accelerated|'
        r'Delayed|Deferred|Quiet|Traditional|Positional|Double|Central|'
        r'Slav|Move Order|Counter|with)\b',
      );
      final bad = [
        for (final n in names)
          if (english.hasMatch(localOpeningName(n)))
            '$n -> ${localOpeningName(n)}',
      ];
      expect(bad, isEmpty);
    });
  });

  group('altre lingue', () {
    test('in inglese il nome resta quello del libro', () {
      useContent('en');
      expect(localOpeningName('Sicilian Defense'), 'Sicilian Defense');
      expect(
        localOpeningName('Sicilian Defense: Najdorf Variation'),
        'Sicilian Defense: Najdorf Variation',
      );
    });

    test('una lingua nuova si aggiunge con le sue famiglie e parole', () {
      Content.use({
        'opening_names': ContentText.fromMaps({
          'it': <String, Object>{},
          'es': <String, Object>{
            'family.Sicilian Defense': 'Defensa siciliana',
            'noun.Variation': ['variante', 'f'],
            'adjective.Classical': ['clasico', 'clasica'],
            'grammar.with': 'con',
            'grammar.feminine': ['Defensa'],
          },
        }, language: 'es'),
      });
      expect(localOpeningName('Sicilian Defense'), 'Defensa siciliana');
      expect(
        localOpeningName('Sicilian Defense: Classical Variation'),
        'Defensa siciliana: variante clasica',
      );
      expect(localOpeningName('Ruy Lopez'), 'Ruy Lopez');
    });
  });
}
