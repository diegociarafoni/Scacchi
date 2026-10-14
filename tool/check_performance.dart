import 'dart:convert';
import 'dart:io';

import 'src/budget.dart';

/// Applica il budget dei fotogrammi di `tool/policy.json` al rapporto scritto da
/// `integration_test/fluidita_perf.dart` (predefinito: build/performance.json).
void main(List<String> args) {
  final file = File(args.isEmpty ? 'build/performance.json' : args.single);
  if (!file.existsSync()) {
    stderr.writeln(
      '${file.path} manca: eseguire integration_test/fluidita_perf.dart',
    );
    exit(2);
  }
  final report = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final budget = FrameBudget.fromJson(policy);
  stdout.writeln(
    'Fotogrammi: ${report['frame_count']}, costruzione: media '
    '${report['average_frame_build_time_millis']} ms, '
    'p90 ${report['90th_percentile_frame_build_time_millis']} ms, '
    'p99 ${report['99th_percentile_frame_build_time_millis']} ms, '
    'peggiore ${report['worst_frame_build_time_millis']} ms',
  );
  final startupMax = budgetValue(policy, ['startupMaxMs']);
  stdout.writeln('Avvio: ${report['startup_ms']} ms');
  final violations = [
    ...frameViolations(report, budget),
    ...startupViolations(report, maxMs: startupMax),
  ];
  for (final v in violations) {
    stderr.writeln('✗ $v');
  }
  if (violations.isNotEmpty) exit(1);
  stdout.writeln('✓ fluidità e avvio entro il budget');
}
