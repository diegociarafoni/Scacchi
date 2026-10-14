import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/app_localizations.dart';

AppLocalizations _l(String code) => lookupAppLocalizations(Locale(code));

void main() {
  group('plurali di stelle, capitoli e passi', () {
    test('italiano', () {
      final l = _l('it');
      expect(l.pathStars(1, 3), '1 stella su 3');
      expect(l.pathStars(2, 3), '2 stelle su 3');
      expect(l.pathStageDone(1), '1 stella su 3');
      expect(l.mastersStars(3), '3 stelle su 3');
      expect(l.storyProgress(1, 5), '1 capitolo su 5');
      expect(l.storyProgress(2, 5), '2 capitoli su 5');
      expect(l.storyChapterSteps(1, 4), '1 passo su 4');
    });

    test('inglese', () {
      final l = _l('en');
      expect(l.pathStars(1, 3), '1 star out of 3');
      expect(l.storyProgress(1, 5), '1 chapter out of 5');
      expect(l.storyChapterSteps(2, 4), '2 steps out of 4');
      expect(l.mastersStars(1), '1 star out of 3');
    });

    test('portoghese: zero non è singolare', () {
      final l = _l('pt');
      expect(l.pathStageDone(1), '1 estrela de 3');
      expect(l.pathStageDone(0), '0 estrelas de 3');
      expect(l.storyProgress(1, 5), '1 capítulo de 5');
    });

    test('spagnolo, francese e olandese', () {
      expect(_l('es').storyChapterSteps(1, 4), '1 paso de 4');
      expect(_l('es').mastersStars(1), '1 estrella de 3');
      expect(_l('fr').storyProgress(1, 5), '1 chapitre sur 5');
      expect(_l('fr').pathStars(1, 3), '1 étoile sur 3');
      expect(_l('nl').pathStars(1, 3), '1 ster van 3');
      expect(_l('nl').storyProgress(1, 5), '1 hoofdstuk van de 5');
    });

    test('russo e polacco: le forme restano corrette per ogni numero', () {
      for (final n in [1, 2, 5, 21]) {
        expect(_l('ru').mastersStars(n), isNot(contains('{')));
        expect(_l('pl').mastersStars(n), isNot(contains('{')));
      }
      expect(_l('ru').mastersStars(2), '2 звезды из 3');
      expect(_l('ru').mastersStars(5), '5 звёзд из 3');
      expect(_l('pl').mastersStars(1), '1 gwiazdka z 3');
      expect(_l('pl').mastersStars(5), '5 gwiazdek z 3');
      expect(_l('ru').pathStars(1, 3), '1 звезда из 3');
      expect(_l('pl').storyProgress(1, 5), '1 rozdział z 5');
      expect(_l('pl').storyProgress(22, 30), '22 rozdziały z 30');
      expect(_l('pl').storyChapterSteps(5, 9), '5 kroków z 9');
      expect(_l('ru').storyProgress(5, 7), '5 глав из 7');
      expect(_l('ru').storyChapterSteps(3, 9), '3 шага из 9');
      expect(_l('ru').pathStageDone(1), '1 звезда из 3');
    });

    test('orologio degli altri: minuti e secondi al singolare', () {
      expect(
        _l('it').multiplayerClockSemantics('Anna', 1, 1),
        'Orologio di Anna: 1 minuto e 1 secondo',
      );
      expect(
        _l('en').multiplayerClockSemantics('Anna', 2, 1),
        "Anna's clock: 2 minutes and 1 second",
      );
      expect(
        _l('pt').multiplayerClockSemantics('Ana', 1, 0),
        'Relógio de Ana: 1 minuto e 0 segundos',
      );
    });
  });
}
