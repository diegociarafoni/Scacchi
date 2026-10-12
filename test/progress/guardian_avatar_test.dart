import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/bots.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/guardian_avatar.dart';
import 'package:scacchi/story/story.dart';

void main() {
  group('RP-08 custodi della Storia', () {
    test('ogni custode della Storia ha il suo personaggio, tutti diversi', () {
      final guardians = [
        for (final c in storyChapters)
          if (c.botId != 'tino') c.botId,
      ];
      final characters = [for (final id in guardians) guardianCharacter(id)];
      expect(characters, everyElement(isNotNull));
      expect(characters.toSet(), hasLength(guardians.length));
    });

    test('i bot senza personaggio disegnato mostrano la loro emoji', () {
      for (final id in ['lia', 'nico', 'viola', 'ettore', 'bruna']) {
        expect(guardianCharacter(id), isNull, reason: id);
      }
    });

    test('un bot sconosciuto non ha un personaggio', () {
      expect(guardianCharacter('nessuno'), isNull);
    });

    testWidgets('ogni custode si disegna con ogni espressione e dimensione', (
      tester,
    ) async {
      for (final bot in bots) {
        for (final e in AvatarExpression.values) {
          for (final size in [40.0, 96.0]) {
            await tester.pumpWidget(
              MaterialApp(
                home: Center(
                  child: GuardianAvatar(bot: bot, expression: e, size: size),
                ),
              ),
            );
            expect(tester.takeException(), isNull, reason: '${bot.id} $e');
          }
        }
      }
    });

    testWidgets('è decorativo: nessun testo per i lettori di schermo', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(home: GuardianAvatar(bot: bots.first)),
      );
      expect(find.bySemanticsLabel(RegExp('Pino')), findsNothing);
      semantics.dispose();
    });

    testWidgets('senza sfondo si può posare su qualsiasi superficie', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuardianAvatar(
            bot: bots.first,
            expression: AvatarExpression.greeting,
            background: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
