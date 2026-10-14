import 'dart:io';

import 'src/commit_message.dart';

/// Blocca il commit se autore o committer sono l'identità di Claude.
void main() {
  var failed = false;
  for (final role in ['GIT_AUTHOR_IDENT', 'GIT_COMMITTER_IDENT']) {
    final out = Process.runSync('git', ['var', role]);
    final ident = (out.stdout as String).trim();
    final match = RegExp(r'^(.*) <(.*)> ').firstMatch(ident);
    if (out.exitCode != 0 || match == null) {
      stderr.writeln('✗ identità di git non leggibile ($role)');
      failed = true;
      continue;
    }
    if (isClaudeIdentity(match.group(1)!, match.group(2)!)) {
      stderr.writeln(
        '✗ ${match.group(1)} <${match.group(2)}>: i commit non portano '
        "l'attribuzione a Claude; impostare la propria identità con "
        'git config user.name e git config user.email.',
      );
      failed = true;
    }
  }
  if (failed) exit(1);
}
