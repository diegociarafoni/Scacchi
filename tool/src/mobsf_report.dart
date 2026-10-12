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
    return MobsfPolicy(
      minScore: score.toInt(),
      acceptedHigh: accepted.map((k, v) => MapEntry(k, v as String)),
    );
  }

  /// Punteggio di sicurezza minimo (0-100).
  final int minScore;

  /// Avvisi gravi accettati: titolo → motivo.
  final Map<String, String> acceptedHigh;
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
  final score = report['security_score'];
  if (high == null || score is! num) {
    return ['rapporto incompleto: mancano appsec.high o security_score'];
  }
  return [
    for (final title in high)
      if (!policy.acceptedHigh.containsKey(title))
        'avviso grave non accettato: $title',
    if (score < policy.minScore)
      'punteggio di sicurezza $score (minimo ${policy.minScore})',
  ];
}

/// Avvisi accettati nella policy che il rapporto non contiene più: da togliere.
List<String> staleAccepted(Map<String, dynamic> report, MobsfPolicy policy) {
  final present = (_highTitles(report) ?? const <String>[]).toSet();
  return [
    for (final title in policy.acceptedHigh.keys)
      if (!present.contains(title)) title,
  ];
}
