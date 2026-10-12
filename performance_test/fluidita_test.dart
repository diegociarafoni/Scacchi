// ignore_for_file: invalid_use_of_visible_for_testing_member
// Come negli altri test su dispositivo: i valori iniziali di SharedPreferences sono solo per i test.

import 'dart:convert';
import 'dart:io';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Offset _square(WidgetTester tester, String name) {
  final rect = tester.getRect(find.byType(Chessboard));
  final size = rect.width / 8;
  final file = name.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final rank = int.parse(name[1]);
  return rect.topLeft + Offset((file + 0.5) * size, (8 - rank + 0.5) * size);
}

const _moves = ['e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', 'g8f6', 'd2d3', 'f8c5'];

/// Misura i tempi di costruzione dei fotogrammi in una partita e tra le schede;
/// il rapporto va in build/performance.json per `tool/check_performance.dart`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fluidità: partita e navigazione', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScacchiApp());
    await tester.pumpAndSettle();

    await binding.watchPerformance(() async {
      for (final m in _moves) {
        await tester.tapAt(_square(tester, m.substring(0, 2)));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tapAt(_square(tester, m.substring(2, 4)));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Tu'));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -600),
        1500,
      );
      await tester.pumpAndSettle();
    });

    final report = binding.reportData!['performance'] as Map<String, dynamic>;
    File('build/performance.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(report));
  });
}
