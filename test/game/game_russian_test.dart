import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/game_page.dart';
import 'package:scacchi/minigames/minigames_page.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/storage/key_value_store.dart';

import '../localized_app.dart';

void main() {
  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('ru'),
        home: GamePage(
          settings: SettingsController.defaults(),
          store: MemoryStore(),
          now: () => DateTime(2026, 10, 13, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Il russo è più lungo dell'inglese: nessun overflow su telefono piccolo.
  for (final size in const [Size(960, 2000), Size(1170, 2532)]) {
    testWidgets('la partita in russo ${size.width.toInt()}px', (tester) async {
      await open(tester, size);
      expect(
        find.text('Нажми на фигуру, потом на поле, куда хочешь её поставить.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Другие действия'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('il foglio Новая партия ${size.width.toInt()}px', (
      tester,
    ) async {
      await open(tester, size);
      await tester.tap(find.text('Новая'));
      await tester.pumpAndSettle();
      expect(find.text('Новая партия'), findsOneWidget);
      expect(find.text('Начать партию'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('i minigiochi in russo', (tester) async {
    await tester.pumpWidget(
      localizedApp(locale: const Locale('ru'), home: const MinigamesPage()),
    );
    expect(find.text('Мини-игры'), findsOneWidget);
    expect(find.text('Координаты на время'), findsOneWidget);
  });
}
