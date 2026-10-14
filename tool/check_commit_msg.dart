import 'dart:io';

import 'src/commit_message.dart';

/// Uso: `check_commit_msg.dart <file>` (hook commit-msg),
/// `--range <base>..<head>` (CI), `--text "<messaggio>"` (titolo della PR)
/// oppure `--attribuzione "<testo>"` (descrizione della PR).
void main(List<String> args) {
  final messages = <String, String>{};
  final identities = <String, String>{};
  var source = MessageSource.history;
  if (args.length == 2 && args[0] == '--range') {
    final log = Process.runSync('git', [
      'log',
      '--no-merges',
      '--format=%H%x00%an%x00%ae%x00%cn%x00%ce%x00%B%x01',
      args[1],
    ]);
    if (log.exitCode != 0) _fail('git log: ${log.stderr}');
    for (final entry in (log.stdout as String).split('\x01')) {
      final parts = entry.trim().split('\x00');
      if (parts.length != 6) {
        if (entry.trim().isNotEmpty) _fail('commit non leggibile: $entry');
        continue;
      }
      final id = parts[0].substring(0, 8);
      messages[id] = parts[5];
      for (final (name, email) in [
        (parts[1], parts[2]),
        (parts[3], parts[4]),
      ]) {
        if (isClaudeIdentity(name, email)) {
          identities[id] = '$name <$email>';
        }
      }
    }
  } else if (args.length == 2 && args[0] == '--attribuzione') {
    if (hasClaudeAttribution(args[1])) {
      stderr.writeln(
        '✗ la descrizione della PR attribuisce il lavoro a Claude',
      );
      exit(1);
    }
    stdout.writeln('✓ nessuna attribuzione a Claude nella descrizione');
    return;
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
  identities.forEach((id, who) {
    failed = true;
    stderr.writeln('✗ $id: autore o committer è $who');
    stderr.writeln(
      '    - usare la propria identità: git config user.name / user.email',
    );
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
