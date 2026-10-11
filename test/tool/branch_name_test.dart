import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/branch_name.dart';

void main() {
  group('nomi dei rami', () {
    for (final ok in [
      'feat/orologio',
      'fix/arrocco-lungo',
      'docs/guida-sviluppo',
      'build/aggiorna-dipendenze',
      'refactor/motore.v2',
      'dependabot/pub/dartchess-0.15.0',
      'release-please--branches--main',
      'claude/project-thread-3b4wlf',
    ]) {
      test('accetta "$ok"', () => expect(validateBranchName(ok), isNull));
    }

    for (final ko in [
      'main',
      'master',
      'orologio',
      'feature/orologio',
      'feat/',
      'feat/Orologio',
      'fix/spazi non ammessi',
      // chore non è un tipo Angular: anche i commit lo rifiutano.
      'chore/aggiorna-dipendenze',
    ]) {
      test('rifiuta "$ko"', () => expect(validateBranchName(ko), isNotNull));
    }
  });

  group('rami di destinazione del pre-push', () {
    const zero = '0000000000000000000000000000000000000000';
    test('controlla il ramo remoto, non quello corrente', () {
      expect(
        pushedBranches(
          'refs/heads/feat/x abc refs/heads/main def\n'
          'refs/heads/feat/x abc refs/heads/feat/x $zero\n',
        ),
        ['main', 'feat/x'],
      );
    });

    test('ignora tag e cancellazioni', () {
      expect(
        pushedBranches(
          'refs/tags/v1.0.0 abc refs/tags/v1.0.0 $zero\n'
          '(delete) $zero refs/heads/feat/vecchio abc\n',
        ),
        isEmpty,
      );
    });
  });
}
