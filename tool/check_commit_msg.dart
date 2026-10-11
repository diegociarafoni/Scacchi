import 'dart:io';

import 'src/commit_message.dart';

/// Uso: `check_commit_msg.dart <file>` (hook commit-msg),
/// `--range <base>..<head>` (CI) oppure `--text "<messaggio>"` (titolo della PR).
void main(List<String> args) {
  final messages = <String, String>{};
  var source = MessageSource.history;
  if (args.length == 2 && args[0] == '--range') {
    final log = Process.runSync('git', [
      'log',
      '--no-merges',
      '--format=%H%x00%B%x01',
      args[1],
    ]);
    if (log.exitCode != 0) _fail('git log: ${log.stderr}');
    for (final entry in (log.stdout as String).split('\x01')) {
      final parts = entry.trim().split('\x00');
      if (parts.length == 2) messages[parts[0].substring(0, 8)] = parts[1];
    }
  } else if (args.length == 2 && args[0] == '--text') {
    messages['titolo'] = args[1];
    source = MessageSource.pullRequestTitle;
  } else if (args.length == 1) {
    messages['messaggio'] = File(args[0]).readAsStringSync();
    source = MessageSource.editor;
  } else {
    _fail(
      'uso: check_commit_msg.dart <file> | --range a..b | --text "messaggio"',
    );
  }

  var failed = false;
  messages.forEach((id, message) {
    final errors = validateCommitMessage(message, source: source);
    if (errors.isEmpty) return;
    failed = true;
    stderr.writeln('✗ $id: ${message.split('\n').first}');
    for (final e in errors) {
      stderr.writeln('    - $e');
    }
  });
  if (failed) {
    stderr.writeln('\nConvenzione: docs/convenzioni-git.md');
    exit(1);
  }
  stdout.writeln('✓ ${messages.length} messaggi conformi alla convenzione');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
