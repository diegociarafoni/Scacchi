import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/content.dart';
import 'package:scacchi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content_support.dart';

void main() {
  testWidgets('i contenuti si caricano nella lingua scelta', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'french'});
    addTearDown(useContent);
    Content.reset();
    await tester.pumpWidget(const ScacchiApp());
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && Content.language != 'fr'; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pumpAndSettle();
    expect(Content.language, 'fr');
  });

  testWidgets('con lingua Automatica i contenuti seguono il telefono', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const [Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final loaded = <String>[];
    await tester.pumpWidget(
      ScacchiApp(contentLoader: (code) async => loaded.add(code)),
    );
    await tester.pumpAndSettle();
    expect(loaded, ['it']);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await tester.pumpAndSettle();
    expect(loaded, ['it', 'fr']);
  });

  testWidgets('due cambi lingua ravvicinati lasciano l\'ultima lingua', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.platformDispatcher.localesTestValue = const [Locale('it')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final gates = <String, Completer<void>>{};
    var current = '';
    await tester.pumpWidget(
      ScacchiApp(
        contentLoader: (code) async {
          if (code != 'it') await (gates[code] ??= Completer()).future;
          current = code;
        },
      ),
    );
    await tester.pumpAndSettle();
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    await tester.pump();
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    await tester.pump();
    // Il caricamento più recente finisce prima di quello vecchio.
    (gates['de'] ??= Completer()).complete();
    await tester.pump();
    (gates['fr'] ??= Completer()).complete();
    await tester.pumpAndSettle();
    expect(current, 'de');
  });
}
