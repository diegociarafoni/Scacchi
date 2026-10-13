import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:scacchi/l10n/app_localizations.dart';

void main() {
  test('la data del trofeo in italiano resta gg/mm/aaaa', () {
    final l = lookupAppLocalizations(const Locale('it'));
    expect(
      DateFormat(l.tournamentDatePattern).format(DateTime(2026, 3, 5)),
      '05/03/2026',
    );
  });

  test('la data del trofeo in inglese è mm/gg/aaaa', () {
    final l = lookupAppLocalizations(const Locale('en'));
    expect(
      DateFormat(l.tournamentDatePattern).format(DateTime(2026, 3, 5)),
      '03/05/2026',
    );
  });
}
