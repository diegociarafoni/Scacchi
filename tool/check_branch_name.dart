import 'dart:io';

import 'src/branch_name.dart';

/// Uso: `check_branch_name.dart <ramo>`, oppure `--pre-push` con l'input del
/// hook pre-push di git su stdin (controlla i rami di destinazione).
void main(List<String> args) {
  final List<String> names;
  if (args.length == 1 && args.first == '--pre-push') {
    final input = StringBuffer();
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      input.writeln(line);
    }
    names = pushedBranches(input.toString());
  } else if (args.length == 1) {
    names = [args.first];
  } else {
    stderr.writeln('uso: check_branch_name.dart <ramo> | --pre-push');
    exit(2);
  }

  var failed = false;
  for (final name in names) {
    final error = validateBranchName(name);
    if (error == null) {
      stdout.writeln('✓ ramo "$name" conforme');
    } else {
      failed = true;
      stderr.writeln('✗ $error');
    }
  }
  if (failed) {
    stderr.writeln('Convenzione: docs/convenzioni-git.md');
    exit(1);
  }
}
