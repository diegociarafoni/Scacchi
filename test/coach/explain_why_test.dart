import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/coach/explain_why.dart';
import 'package:rokko/l10n/app_localizations.dart';

final it = lookupAppLocalizations(const Locale('it'));
final en = lookupAppLocalizations(const Locale('en'));

Position fen(String f) => Chess.fromSetup(Setup.parseFen(f));

String? why(
  String f,
  String uci, {
  String? next,
  bool showSquares = true,
  AppLocalizations? l,
}) => explainComputerMove(
  l ?? it,
  fen(f),
  Move.parse(uci)!,
  followUp: next == null ? null : Move.parse(next) as NormalMove,
  showSquares: showSquares,
);

void main() {
  group('RF-122 spiegami perché', () {
    test('cattura: dice cosa prende e con cosa', () {
      expect(
        why('4k3/8/8/3p4/8/4N3/8/4K3 w - - 0 1', 'e3d5'),
        'Cattura il pedone con il cavallo.',
      );
    });

    test('cattura che dà scacco: aggiunge lo scacco', () {
      expect(
        why('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1', 'a1a8'),
        'Cattura la torre con la torre. Dà scacco al tuo re.',
      );
    });

    test('scacco semplice', () {
      expect(
        why('4k3/8/8/8/8/8/8/R3K3 w - - 0 1', 'a1a8'),
        'Dà scacco al tuo re.',
      );
    });

    test('scacco matto', () {
      expect(why('6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1', 'a1a8'), 'Scacco matto!');
    });

    test('arrocco (re sulla torre, come in dartchess)', () {
      expect(
        why('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1', 'e1h1'),
        'Arrocca: mette il re al sicuro.',
      );
    });

    test('promozione', () {
      expect(
        why('8/P6k/8/8/8/8/8/K7 w - - 0 1', 'a7a8q'),
        'Promuove il pedone: diventa una donna.',
      );
    });

    test('pezzo attaccato messo al sicuro', () {
      expect(
        why('7k/3r4/8/8/8/8/8/K2N4 w - - 0 1', 'd1c3'),
        'Mette al sicuro il cavallo, che era sotto attacco.',
      );
    });

    test('un pezzo ben difeso non è «messo al sicuro»', () {
      expect(
        why('7k/3r4/8/8/8/8/8/2KN4 w - - 0 1', 'd1c3'),
        'Sviluppa il cavallo: entra in gioco.',
      );
    });

    test('promozione con cattura e scacco li cita', () {
      expect(
        why('r6k/1P6/8/8/8/8/8/K7 w - - 0 1', 'b7a8q'),
        'Promuove il pedone: diventa una donna. '
        'Cattura la torre con il pedone. Dà scacco al tuo re.',
      );
    });

    test('un pedone già oltre la quarta traversa non «prende il centro»', () {
      expect(
        why('4k3/8/8/8/3P4/8/8/4K3 w - - 0 1', 'd4d5'),
        'Sposta il pedone su una casa più utile.',
      );
      expect(
        why('4k3/8/8/4p3/8/8/8/4K3 b - - 0 1', 'e5e4'),
        'Sposta il pedone su una casa più utile.',
      );
    });

    test('minaccia di cattura dalla mossa successiva, con la casa', () {
      const f = '7k/8/8/4r3/8/8/8/K5N1 w - - 0 1';
      expect(
        why(f, 'g1f3', next: 'f3e5'),
        'Minaccia di catturare la torre in e5.',
      );
    });

    test('nel profilo bambino la minaccia non cita la casa', () {
      const f = '7k/8/8/4r3/8/8/8/K5N1 w - - 0 1';
      expect(
        why(f, 'g1f3', next: 'f3e5', showSquares: false),
        'Minaccia di catturare la torre.',
      );
    });

    test('minaccia di scacco', () {
      expect(
        why('4k3/8/8/8/8/8/8/R3K3 w - - 0 1', 'a1a2', next: 'a2a8'),
        'Prepara uno scacco al tuo re.',
      );
    });

    test('sviluppo di un pezzo', () {
      expect(
        why(Chess.initial.fen, 'g1f3'),
        'Sviluppa il cavallo: entra in gioco.',
      );
    });

    test('pedone centrale', () {
      expect(why(Chess.initial.fen, 'e2e4'), 'Prende spazio al centro.');
    });

    test('mossa tranquilla: frase generica', () {
      expect(
        why('4k3/8/8/8/8/8/8/R3K3 w - - 0 1', 'a1a2'),
        'Sposta la torre su una casa più utile.',
      );
    });

    test('esiste anche in inglese', () {
      expect(
        why(Chess.initial.fen, 'g1f3', l: en),
        'Develops the knight: it joins the game.',
      );
    });

    test('una mossa senza pezzo sulla casa non dà testo', () {
      expect(why(Chess.initial.fen, 'e4e5'), isNull);
    });
  });
}
