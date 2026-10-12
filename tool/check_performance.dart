import 'dart:convert';
import 'dart:io';

import 'src/budget.dart';

/// Applica il budget dei fotogrammi di `tool/policy.json` al rapporto scritto da
/// `performance_test/fluidita_test.dart` (predefinito: build/performance.json).
void main(List<String> args) {
  final file = File(args.isEmpty ? 'build/performance.json' : args.single);
  if (!file.existsSync()) {
    stderr.writeln(
      '${file.path} manca: eseguire performance_test/fluidita_test.dart',
    );
    exit(2);
  }
  final report = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final budget = FrameBudget.fromJson(
    (policy['budget'] as Map<String, dynamic>)['frames']
        as Map<String, dynamic>,
  );
  stdout.writeln(
    'Fotogrammi: ${report['frame_count']}, costruzione: media '
    '${report['average_frame_build_time_millis']} ms, '
    'p90 ${report['90th_percentile_frame_build_time_millis']} ms, '
    'p99 ${report['99th_percentile_frame_build_time_millis']} ms, '
    'peggiore ${report['worst_frame_build_time_millis']} ms',
  );
  final violations = frameViolations(report, budget);
  for (final v in violations) {
    stderr.writeln('✗ $v');
  }
  if (violations.isNotEmpty) exit(1);
  stdout.writeln('✓ fluidità entro il budget');
}
