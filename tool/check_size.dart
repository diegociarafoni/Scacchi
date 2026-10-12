import 'dart:convert';
import 'dart:io';

import 'src/budget.dart';

/// Verifica che l'APK non superi il limite di `tool/policy.json` (budget.apkMaxMegabytes).
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('uso: dart run tool/check_size.dart <apk>');
    exit(2);
  }
  final apk = File(args.single);
  if (!apk.existsSync()) {
    stderr.writeln('${args.single} non esiste');
    exit(2);
  }
  final policy = jsonDecode(
    File('tool/policy.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final max = budgetValue(policy, ['apkMaxMegabytes']);
  final verdict = checkApkSize(apk.lengthSync(), maxMegabytes: max);
  stdout.writeln('${verdict.ok ? '✓' : '✗'} ${verdict.message}');
  if (!verdict.ok) exit(1);
}
