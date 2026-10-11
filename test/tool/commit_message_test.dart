import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/commit_message.dart';

void main() {
  group('messaggi di commit (convenzione Angular)', () {
    for (final ok in [
      'feat: aggiunge la promozione del pedone',
      'fix(board): corregge il trascinamento',
      'docs: aggiorna la guida',
      'refactor!: rinomina ChessGame',
      'test(game): copre lo stallo\n\nCorpo del messaggio.',
      'chore(main): release 1.1.0',
      'build(deps): bump dartchess from 0.14.0 to 0.15.0',
      'Merge branch \'main\' into feat/orologio',
      'Revert "feat: aggiunge l\'orologio"\n\nThis reverts commit abc.',
    ]) {
      test('accetta "$ok"', () => expect(validateCommitMessage(ok), isEmpty));
    }

    for (final ko in [
      'aggiunge la promozione',
      'feature: tipo non previsto',
      'feat:manca lo spazio',
      'feat: ',
      'feat: Maiuscola iniziale',
      'feat: termina con il punto.',
      'chore: pulizia generica',
      'feat(Board): scope maiuscolo',
      'feat: titolo\ncorpo senza riga vuota',
      'feat: ${'x' * 100}',
      'fixup! feat: qualcosa',
    ]) {
      test(
        'rifiuta "$ko"',
        () => expect(validateCommitMessage(ko), isNotEmpty),
      );
    }

    test('ignora le righe di commento di git', () {
      expect(
        validateCommitMessage('fix: corregge lo stallo\n# Please enter...'),
        isEmpty,
      );
    });
  });
}
