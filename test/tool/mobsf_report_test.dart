import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/mobsf_report.dart';

Map<String, dynamic> _report({
  List<String> high = const [],
  List<String> warning = const [],
  Object? score = 70,
}) => {
  'security_score': score,
  'appsec': {
    'high': [
      for (final t in high) {'title': t, 'section': 'manifest'},
    ],
    'warning': [
      for (final t in warning) {'title': t, 'section': 'code'},
    ],
    'info': <Object>[],
    'secure': <Object>[],
    'hotspot': <Object>[],
  },
};

void main() {
  const policy = MobsfPolicy(
    minScore: 60,
    acceptedHigh: {
      'App può essere installata su Android vulnerabile':
          'minSdk deciso dal progetto',
    },
  );

  test('nessuna violazione senza avvisi gravi e con punteggio sufficiente', () {
    expect(mobsfViolations(_report(warning: ['Log']), policy), isEmpty);
  });

  test('un avviso grave accettato nella policy non è una violazione', () {
    final r = _report(
      high: ['App può essere installata su Android vulnerabile'],
    );
    expect(mobsfViolations(r, policy), isEmpty);
  });

  test('un avviso grave non accettato è una violazione', () {
    final v = mobsfViolations(_report(high: ['Componente esportato']), policy);
    expect(v, hasLength(1));
    expect(v.single, contains('Componente esportato'));
  });

  test('un punteggio sotto il minimo è una violazione', () {
    final v = mobsfViolations(_report(score: 59), policy);
    expect(v.single, contains('59'));
  });

  test('un rapporto senza appsec o punteggio non è valido', () {
    expect(mobsfViolations({}, policy), isNotEmpty);
    expect(
      mobsfViolations({'appsec': <String, dynamic>{}}, policy),
      isNotEmpty,
    );
  });

  test('la policy si legge da policy.json e segnala le chiavi mancanti', () {
    final p = MobsfPolicy.fromJson({
      'mobsf': {
        'minSecurityScore': 55,
        'acceptedHigh': {'Titolo': 'Motivo'},
      },
    });
    expect(p.minScore, 55);
    expect(p.acceptedHigh, {'Titolo': 'Motivo'});
    expect(() => MobsfPolicy.fromJson({}), throwsA(isA<FormatException>()));
  });

  test('i titoli accettati ormai assenti dal rapporto si segnalano', () {
    final stale = staleAccepted(_report(), policy);
    expect(stale, ['App può essere installata su Android vulnerabile']);
  });
}
