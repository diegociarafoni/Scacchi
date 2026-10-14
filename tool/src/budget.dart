/// Esito di un controllo con il messaggio da stampare.
class Verdict {
  const Verdict(this.ok, this.message);

  final bool ok;
  final String message;
}

const _mib = 1024 * 1024;

/// Confronta la dimensione dell'APK con il limite in megabyte (MiB).
Verdict checkApkSize(int bytes, {required num maxMegabytes}) {
  final size = (bytes / _mib).toStringAsFixed(1).replaceAll('.', ',');
  final ok = bytes <= maxMegabytes * _mib;
  return Verdict(ok, 'APK di $size MB (massimo $maxMegabytes MB)');
}

/// Limiti sul tempo di costruzione dei fotogrammi, in millisecondi.
class FrameBudget {
  const FrameBudget({
    required this.minFrames,
    required this.p90BuildMs,
    required this.p99BuildMs,
  });

  factory FrameBudget.fromJson(Map<String, dynamic> json) => FrameBudget(
    minFrames: budgetValue(json, ['frames', 'minFrames']).toInt(),
    p90BuildMs: budgetValue(json, ['frames', 'p90BuildMs']),
    p99BuildMs: budgetValue(json, ['frames', 'p99BuildMs']),
  );

  final int minFrames;
  final num p90BuildMs;
  final num p99BuildMs;
}

/// Violazioni del budget in un rapporto di `watchPerformance`; vuota se è rispettato.
/// Solo il tempo di costruzione: sul runner senza GPU la rasterizzazione non è significativa.
List<String> frameViolations(Map<String, dynamic> report, FrameBudget budget) {
  final frames = report['frame_count'];
  final p90 = report['90th_percentile_frame_build_time_millis'];
  final p99 = report['99th_percentile_frame_build_time_millis'];
  if (frames is! num || p90 is! num || p99 is! num) {
    return ['rapporto incompleto: mancano i campi dei fotogrammi'];
  }
  if (frames < budget.minFrames) {
    return [
      'misurati solo $frames fotogrammi (minimo ${budget.minFrames}): la misura non è affidabile',
    ];
  }
  return [
    if (p90 > budget.p90BuildMs)
      '90° percentile della costruzione $p90 ms (massimo ${budget.p90BuildMs} ms)',
    if (p99 > budget.p99BuildMs)
      '99° percentile della costruzione $p99 ms (massimo ${budget.p99BuildMs} ms)',
  ];
}

/// Legge un valore numerico dalla sezione `budget` di `tool/policy.json`, con un
/// messaggio chiaro se la chiave manca.
num budgetValue(Map<String, dynamic> policy, List<String> path) {
  Object? node = policy['budget'];
  for (final key in path) {
    node = node is Map<String, dynamic> ? node[key] : null;
  }
  if (node is! num) {
    throw FormatException(
      'tool/policy.json: manca il valore numerico budget.${path.join('.')}',
    );
  }
  return node;
}

/// Violazioni del tempo di avvio (dal lancio alla Home pronta a giocare) in un
/// rapporto con il campo `startup_ms`; vuota se è entro [maxMs].
List<String> startupViolations(
  Map<String, dynamic> report, {
  required num maxMs,
}) {
  final ms = report['startup_ms'];
  if (ms is! num) return ['rapporto incompleto: manca il tempo di avvio'];
  if (ms > maxMs) return ['avvio in $ms ms (massimo $maxMs ms)'];
  return [];
}
