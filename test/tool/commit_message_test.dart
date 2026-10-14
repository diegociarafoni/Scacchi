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
      'feat(game): XP e salvataggio in archivio a fine partita',
      'fix(archive): PGN con commenti annidati',
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
      'feat: ComputerPlayer con più livelli',
      'feat: Xp in maiuscolo irregolare',
      'feat: termina con il punto.',
      'chore: pulizia generica',
      'feat(Board): scope maiuscolo',
      'feat: titolo\ncorpo senza riga vuota',
      'feat: ${'x' * 100}',
      'Merge board and clock widgets',
    ]) {
      test(
        'rifiuta "$ko"',
        () => expect(validateCommitMessage(ko), isNotEmpty),
      );
    }

    test('dall\'editor ignora le righe di commento di git', () {
      expect(
        validateCommitMessage(
          'fix: corregge lo stallo\n# Please enter...',
          source: MessageSource.editor,
        ),
        isEmpty,
      );
    });

    test('nella cronologia una riga con # fa parte del messaggio', () {
      expect(validateCommitMessage('#42 feat: x'), isNotEmpty);
    });

    test('fixup e squash ammessi nei commit, sparisce con lo squash merge', () {
      for (final source in [MessageSource.editor, MessageSource.history]) {
        expect(
          validateCommitMessage('fixup! feat: qualcosa', source: source),
          isEmpty,
        );
        expect(
          validateCommitMessage('squash! fix: altro', source: source),
          isEmpty,
        );
      }
    });

    test('il titolo della PR diventa il commit su main: niente eccezioni', () {
      for (final title in [
        'fixup! feat: qualcosa',
        'Merge branch \'main\' into feat/orologio',
        '#42 feat: x',
      ]) {
        expect(
          validateCommitMessage(title, source: MessageSource.pullRequestTitle),
          isNotEmpty,
          reason: title,
        );
      }
    });

    test('fixup di un messaggio non valido resta non valido', () {
      expect(validateCommitMessage('fixup! aggiunge cose'), isNotEmpty);
    });

    group('niente attribuzione a Claude', () {
      for (final ko in [
        'feat: aggiunge x\n\nCo-Authored-By: Claude <noreply@anthropic.com>',
        'feat: aggiunge x\n\nCo-authored-by: Claude Sonnet 5.5 <noreply@anthropic.com>',
        'feat: aggiunge x\n\nClaude-Session: https://claude.ai/code/session_01abc',
        'feat: aggiunge x\n\nhttps://claude.ai/code/session_01abc',
        'feat: aggiunge x\n\nGenerated with Claude Code',
        'feat: aggiunge x\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)',
      ]) {
        for (final source in MessageSource.values) {
          test('rifiuta "${ko.split('\n').last}" ($source)', () {
            expect(validateCommitMessage(ko, source: source), isNotEmpty);
          });
        }
      }

      test('i co-autori umani restano ammessi', () {
        expect(
          validateCommitMessage(
            'fix: corregge x\n\nCo-authored-by: Mario <mario@example.com>',
          ),
          isEmpty,
        );
      });

      test('riconosce l\'identità di Claude come autore', () {
        expect(isClaudeIdentity('Claude', 'noreply@anthropic.com'), isTrue);
        expect(isClaudeIdentity('x', 'bot@anthropic.com'), isTrue);
        expect(isClaudeIdentity('Claude', 'a@example.com'), isTrue);
        expect(isClaudeIdentity('Claude Dupont', 'c@example.com'), isFalse);
        expect(isClaudeIdentity('Anna', 'claude.monet@example.com'), isFalse);
        expect(
          hasClaudeAttribution('Testo\n  Co-Authored-By: Claude <x>'),
          isTrue,
        );
        expect(hasClaudeAttribution('Nessun riferimento'), isFalse);
        expect(
          isClaudeIdentity('diegociarafoni', '1+d@users.noreply.github.com'),
          isFalse,
        );
      });
    });
  });
}
