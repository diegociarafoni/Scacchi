import 'dart:convert';
import 'dart:io';

import 'src/mobsf_report.dart';

/// Applica la sezione `mobsf` di `tool/policy.json` al rapporto JSON di MobSF
/// (predefinito: build/mobsf/report.json).
void main(List<String> args) {
  final file = File(args.isEmpty ? 'build/mobsf/report.json' : args.single);
  if (!file.existsSync()) {
    stderr.writeln('${file.path} manca: eseguire prima la scansione MobSF');
    exit(2);
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('✗ ${file.path} non è JSON: ${e.message}');
    exit(1);
  }
  if (decoded is! Map<String, dynamic>) {
    stderr.writeln('✗ ${file.path} non contiene un rapporto MobSF');
    exit(1);
  }
  final report = decoded;
  final policy = MobsfPolicy.fromJson(
    jsonDecode(File('tool/policy.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  stdout.writeln('Punteggio di sicurezza: ${mobsfScore(report)}');
  final appsec = report['appsec'];
  if (appsec is Map<String, dynamic>) {
    for (final level in ['high', 'warning', 'info', 'secure', 'hotspot']) {
      final items = appsec[level];
      if (items is! List) continue;
      stdout.writeln('${level.padRight(8)} ${items.length}');
      if (level == 'high') {
        for (final f in items.whereType<Map<String, dynamic>>()) {
          stdout.writeln('  - ${f['title']}');
        }
      }
    }
  }
  for (final title in staleAccepted(report, policy)) {
    stdout.writeln('! accettato ma non più presente (da togliere): $title');
  }
  final violations = mobsfViolations(report, policy);
  for (final v in violations) {
    stderr.writeln('✗ $v');
  }
  if (violations.isNotEmpty) exit(1);
  stdout.writeln('✓ MobSF entro la policy');
}
