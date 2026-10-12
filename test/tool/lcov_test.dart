import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/lcov.dart';

const _lcov = '''
SF:lib/game/chess_game.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:lib/game/game_page.dart
DA:1,0
LF:1
LH:0
end_of_record
''';

void main() {
  test('legge righe trovate e coperte per file', () {
    final files = parseLcov(_lcov);
    expect(files.keys, ['lib/game/chess_game.dart', 'lib/game/game_page.dart']);
    expect(files['lib/game/chess_game.dart']!.found, 2);
    expect(files['lib/game/chess_game.dart']!.hit, 1);
  });

  test('somma la copertura di un insieme di file', () {
    final files = parseLcov(_lcov);
    expect(coveragePercent(files.values), closeTo(33.3, 0.1));
    expect(coveragePercent(const []), 100);
  });

  group('logica di gioco', () {
    test('è il codice che non dipende da Flutter', () {
      expect(isGameLogic("import 'package:dartchess/dartchess.dart';"), isTrue);
      expect(isGameLogic("import 'package:flutter/material.dart';"), isFalse);
      expect(isGameLogic("import 'dart:ui';"), isFalse);
    });

    test('esclude il codice generato', () {
      expect(isGameLogic('// GENERATED CODE - DO NOT MODIFY BY HAND'), isFalse);
    });
  });
}
