import 'dart:convert';
import 'dart:io';

import 'src/lcov.dart';

/// Verifica la soglia di copertura sulla logica di gioco (`coverage/lcov.info`).
void main() {
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final min =
      ((policy['coverage'] as Map<String, dynamic>)['gameLogicMinPercent']
              as num)
          .toDouble();
  final report = parseLcov(File('coverage/lcov.info').readAsStringSync());

  // I file mai caricati dai test non compaiono in lcov: contano come scoperti.
  final logic = <String, FileCoverage>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.contains('/generated/') || path.contains('/app_localizations')) {
      continue;
    }
    if (!isGameLogic(entity.readAsStringSync())) continue;
    logic[path] = report[path] ?? FileCoverage(_lines(entity), 0);
  }

  for (final MapEntry(key: path, value: c) in logic.entries) {
    final pct = coveragePercent([c]).toStringAsFixed(1);
    stdout.writeln('  $pct%\t${c.hit}/${c.found}\t$path');
  }
  final total = coveragePercent(logic.values);
  final summary =
      'Copertura logica di gioco: ${total.toStringAsFixed(1)}% '
      '(minimo ${min.toStringAsFixed(0)}%)';
  if (total < min) {
    stderr.writeln('✗ $summary');
    exit(1);
  }
  stdout.writeln('✓ $summary');
}

int _lines(File file) => file
    .readAsLinesSync()
    .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('//'))
    .length;
