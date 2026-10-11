import 'dart:io';

import 'src/branch_name.dart';

/// Uso: `check_branch_name.dart [ramo]`; senza argomenti usa il ramo corrente.
void main(List<String> args) {
  final name = args.isNotEmpty
      ? args.first
      : (Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']).stdout
                as String)
            .trim();
  final error = validateBranchName(name);
  if (error != null) {
    stderr.writeln('✗ $error\nConvenzione: docs/convenzioni-git.md');
    exit(1);
  }
  stdout.writeln('✓ ramo "$name" conforme');
}
