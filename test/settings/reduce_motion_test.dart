import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/main.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/theme/no_transitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RNF-07 ridurre le animazioni', () {
    test('con «riduci animazioni» i pezzi non si animano', () {
      expect(
        AppSettings().board.animationDuration,
        AnimationSpeed.normal.duration,
      );
      expect(
        AppSettings(reduceMotion: true).board.animationDuration,
        Duration.zero,
      );
      expect(
        AppSettings(
          animation: AnimationSpeed.slow,
          reduceMotion: true,
        ).board.animationDuration,
        Duration.zero,
      );
    });

    test('il valore del sistema segue copyWith e confronta diverso', () {
      final s = AppSettings().copyWith(reduceMotion: true);
      expect(s.reduceMotion, isTrue);
      expect(s, isNot(AppSettings()));
      expect(s.copyWith(sound: false).reduceMotion, isTrue);
    });

    test('lo segue il controller e non lo salva tra le preferenze', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = await SettingsController.load();
      var notified = 0;
      controller.addListener(() => notified++);
      controller.setReduceMotion(true);
      expect(controller.value.reduceMotion, isTrue);
      expect(notified, 1);
      controller.setReduceMotion(true);
      expect(notified, 1);
      final again = await SettingsController.load();
      expect(again.value.reduceMotion, isFalse);
    });

    testWidgets('l\'app segue l\'impostazione di sistema e toglie le '
        'transizioni tra le pagine', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ScacchiApp());
      await tester.pumpAndSettle();
      BuildContext context() => tester.element(find.byType(Scaffold).first);
      expect(SettingsScope.maybeOf(context())!.reduceMotion, isFalse);
      expect(
        Theme.of(context()).pageTransitionsTheme.builders.values,
        isNot(everyElement(isA<NoTransitionsBuilder>())),
      );

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      expect(SettingsScope.maybeOf(context())!.reduceMotion, isTrue);
      expect(
        Theme.of(context()).pageTransitionsTheme.builders.values,
        everyElement(isA<NoTransitionsBuilder>()),
      );

      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pumpAndSettle();
      expect(SettingsScope.maybeOf(context())!.reduceMotion, isFalse);
    });
  });
}
