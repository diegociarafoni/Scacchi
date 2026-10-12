/// Soglie sul rapporto JSON di MobSF (`/api/v1/report_json`) in `tool/policy.json`.
class MobsfPolicy {
  const MobsfPolicy({required this.minScore, required this.acceptedHigh});

  factory MobsfPolicy.fromJson(Map<String, dynamic> policy) {
    final section = policy['mobsf'];
    final score = section is Map<String, dynamic>
        ? section['minSecurityScore']
        : null;
    final accepted = section is Map<String, dynamic>
        ? section['acceptedHigh']
        : null;
    if (score is! num || accepted is! Map<String, dynamic>) {
      throw const FormatException(
        'tool/policy.json: mancano mobsf.minSecurityScore o mobsf.acceptedHigh',
      );
    }
    if (accepted.values.any((v) => v is! String || v.trim().isEmpty)) {
      throw const FormatException(
        'tool/policy.json: ogni mobsf.acceptedHigh ha bisogno di un motivo',
      );
    }
    return MobsfPolicy(
      minScore: score.toInt(),
      acceptedHigh: accepted.map((k, v) => MapEntry(k, v as String)),
    );
  }

  /// Punteggio di sicurezza minimo (0-100).
  final int minScore;

  /// Avvisi gravi accettati: inizio del titolo → motivo. L'inizio basta perché
  /// MobSF aggiunge ai titoli parti variabili (versione, valori letti dal manifest).
  final Map<String, String> acceptedHigh;

  bool isAccepted(String title) => acceptedHigh.keys.any(title.startsWith);
}

/// Il punteggio sta in `appsec.security_score` nelle versioni recenti, in cima al rapporto nelle precedenti.
Object? _score(Map<String, dynamic> report) {
  final appsec = report['appsec'];
  return report['security_score'] ??
      (appsec is Map<String, dynamic> ? appsec['security_score'] : null);
}

List<String>? _highTitles(Map<String, dynamic> report) {
  final appsec = report['appsec'];
  final high = appsec is Map<String, dynamic> ? appsec['high'] : null;
  if (high is! List) return null;
  return [
    for (final f in high)
      if (f is Map<String, dynamic> && f['title'] is String)
        f['title'] as String,
  ];
}

/// Violazioni della policy in un rapporto MobSF; vuota se è rispettata.
List<String> mobsfViolations(Map<String, dynamic> report, MobsfPolicy policy) {
  final high = _highTitles(report);
  final score = _score(report);
  if (high == null || score is! num) {
    return ['rapporto incompleto: mancano appsec.high o security_score'];
  }
  return [
    for (final title in high)
      if (!policy.isAccepted(title)) 'avviso grave non accettato: $title',
    if (score < policy.minScore)
      'punteggio di sicurezza $score (minimo ${policy.minScore})',
  ];
}

/// Punteggio di sicurezza del rapporto, se presente.
Object? mobsfScore(Map<String, dynamic> report) => _score(report);

/// Avvisi accettati nella policy che il rapporto non contiene più: da togliere.
List<String> staleAccepted(Map<String, dynamic> report, MobsfPolicy policy) {
  final present = _highTitles(report) ?? const <String>[];
  return [
    for (final prefix in policy.acceptedHigh.keys)
      if (!present.any((t) => t.startsWith(prefix))) prefix,
  ];
}
