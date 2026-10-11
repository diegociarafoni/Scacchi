import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/puzzles/mode_guide.dart';
import 'package:scacchi/puzzles/puzzle_run.dart';

void main() {
  group('spiegazione delle modalità', () {
    test('ogni modalità a serie ha obiettivo, regole e id propri', () {
      final ids = <String>{};
      for (final mode in PuzzleRunMode.values) {
        final g = PuzzleGuide.forRun(mode);
        expect(g.title, mode.label);
        expect(g.goal, isNotEmpty);
        expect(g.rules.length, greaterThanOrEqualTo(3));
        expect(ids.add(g.id), isTrue, reason: '${mode.name} ha un id unico');
      }
    });

    test('Combo a tempo spiega tempo, penalità, combo e punteggio', () {
      final g = PuzzleGuide.forRun(PuzzleRunMode.storm);
      final all = '${g.goal} ${g.rules.join(' ')}';
      expect(all, contains('3 minuti'));
      expect(all, contains('10 secondi'));
      expect(all, contains('combo'));
      expect(all, contains('1 punto'));
    });

    test('Corsa e Sopravvivenza spiegano le vite', () {
      for (final mode in [
        PuzzleRunMode.rush3,
        PuzzleRunMode.rush5,
        PuzzleRunMode.survival,
      ]) {
        final all = PuzzleGuide.forRun(mode).rules.join(' ');
        expect(all, contains('vita'), reason: mode.name);
        expect(all, contains('terza'), reason: mode.name);
      }
      expect(
        PuzzleGuide.forRun(PuzzleRunMode.rush5).goal,
        contains('5 minuti'),
      );
    });

    test('Serie finisce al primo errore e consente un salto', () {
      final g = PuzzleGuide.forRun(PuzzleRunMode.streak);
      expect(g.goal, contains('primo errore'));
      expect(g.rules.join(' '), contains('Salta'));
    });

    test('allenamento, tema, giorno e ripasso hanno una spiegazione', () {
      final ids = {
        for (final g in [
          PuzzleGuide.training,
          PuzzleGuide.theme,
          PuzzleGuide.daily,
          PuzzleGuide.review,
        ])
          g.id,
      };
      expect(ids.length, 4);
      expect(PuzzleGuide.review.rules.join(' '), contains('1, 3, 7, 14 e 30'));
    });

    test('i numeri del testo coincidono con le regole del codice', () {
      expect(PuzzleRun.wrongPenalty.inSeconds, 10);
      expect(PuzzleRun.comboBonus(5).inSeconds, 3);
      expect(PuzzleRun.comboBonus(12).inSeconds, 5);
      expect(PuzzleRun.comboBonus(20).inSeconds, 7);
      expect(PuzzleRun.comboBonus(30).inSeconds, 10);
    });
  });
}
