import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/bot_gallery/bot_gallery_page.dart';
import 'package:scacchi/bot_gallery/game_options.dart';
import 'package:scacchi/engine/bot_collection.dart';
import 'package:scacchi/game/clock.dart';
import 'package:scacchi/game/handicap.dart';
import 'package:scacchi/game/opponent_picker.dart';
import 'package:scacchi/game/variant.dart';
import 'package:scacchi/story/story.dart';
import 'package:scacchi/theme/rokko_theme.dart';

import '../localized_app.dart';
import '../support/devices.dart';

BotCollection _beat(List<String> ids) =>
    BotCollection({for (final id in ids) id: DateTime(2026, 10)});

/// Apre la galleria da una pagina e raccoglie ciò che restituisce.
Future<BotGalleryResult?> _open(
  WidgetTester tester, {
  BotCollection collection = const BotCollection(),
  StoryState story = const StoryState(),
  bool kid = false,
  Locale locale = const Locale('it'),
  String? initialBotId,
  Device device = Device.phoneMedium,
  double textScale = 1,
  Future<void> Function()? act,
}) async {
  device.apply(tester);
  BotGalleryResult? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: RokkoTheme.light(),
      localizationsDelegates: localizedApp(home: const SizedBox())
          .localizationsDelegates,
      supportedLocales: localizedApp(home: const SizedBox()).supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => result = await Navigator.push(
                context,
                MaterialPageRoute<BotGalleryResult>(
                  builder: (_) => BotGalleryPage(
                    collection: collection,
                    story: story,
                    kidMode: kid,
                    initialBotId: initialBotId,
                    adaptiveLevel: 4,
                  ),
                ),
              ),
              child: const Text('apri'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('apri'));
  await tester.pumpAndSettle();
  if (act != null) {
    await act();
    await tester.pumpAndSettle();
  }
  return result;
}

Future<void> _tapOption(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
}

void main() {
  group('RG-18 galleria dei bot', () {
    testWidgets('in alto c\'è il bot scelto con nome, Elo e saluto', (
      tester,
    ) async {
      await _open(tester, initialBotId: 'pino');
      expect(find.byKey(const Key('gallery-name')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Pino',
      );
      expect(find.byKey(const Key('gallery-elo')), findsOneWidget);
      expect(find.text('700 Elo'), findsWidgets);
      expect(find.byKey(const Key('gallery-greeting')), findsOneWidget);
    });

    testWidgets('senza scelta iniziale parte dal primo bot da battere', (
      tester,
    ) async {
      await _open(tester, collection: _beat(['lia', 'pino', 'nico']));
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Chiara',
      );
    });

    testWidgets('le fasce hanno il titolo con il numero di bot', (
      tester,
    ) async {
      await _open(tester);
      expect(find.text('Neofita · 3'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Maestro · 2'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Maestro · 2'), findsOneWidget);
    });

    testWidgets('toccare un bot sbloccato cambia il bot in alto', (
      tester,
    ) async {
      await _open(
        tester,
        initialBotId: 'pino',
        act: () async => tester.tap(find.byKey(const Key('bot-nico'))),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Nico',
      );
    });

    testWidgets('un bot bloccato si vede ma non si può giocare', (
      tester,
    ) async {
      await _open(
        tester,
        initialBotId: 'pino',
        act: () async {
          await tester.scrollUntilVisible(
            find.byKey(const Key('bot-rocco')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const Key('bot-rocco')));
        },
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Rocco',
      );
      expect(find.byKey(const Key('gallery-unlock-hint')), findsOneWidget);
      final play = tester.widget<FilledButton>(
        find.byKey(const Key('gallery-play')),
      );
      expect(play.onPressed, isNull);
    });

    testWidgets('i bot bloccati hanno il lucchetto, i battuti la corona', (
      tester,
    ) async {
      await _open(tester, collection: _beat(['lia']));
      expect(
        find.descendant(
          of: find.byKey(const Key('bot-stella')),
          matching: find.byIcon(Icons.lock),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('bot-lia')),
          matching: find.byIcon(Icons.workspace_premium),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('bot-pino')),
          matching: find.byIcon(Icons.workspace_premium),
        ),
        findsNothing,
      );
    });

    testWidgets('ogni bot ha un nome per i lettori di schermo', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, collection: _beat(['lia']));
      expect(
        find.bySemanticsLabel(RegExp(r'^Lia, 400 Elo, battuto$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Pino, 700 Elo, disponibile$')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Pino, 700 Elo, disponibile, custode non ancora incontrato$',
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Gioca restituisce bot e colore scelti', (tester) async {
      final result = await _open(
        tester,
        initialBotId: 'pino',
        act: () async {
          await tester.tap(find.byKey(const Key('side-black')));
          await tester.tap(find.byKey(const Key('gallery-play')));
        },
      );
      expect(result, isNotNull);
      expect(result!.botId, 'pino');
      expect(result.sideChoice, SideChoice.black);
      expect(result.adaptive, isFalse);
    });

    testWidgets('il colore parte a sorte', (tester) async {
      final result = await _open(
        tester,
        initialBotId: 'pino',
        act: () async => tester.tap(find.byKey(const Key('gallery-play'))),
      );
      expect(result!.sideChoice, SideChoice.random);
    });

    testWidgets('la carta Adattivo sceglie il computer adattivo', (
      tester,
    ) async {
      final result = await _open(
        tester,
        act: () async {
          await tester.scrollUntilVisible(
            find.byKey(const Key('bot-adaptive')),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const Key('bot-adaptive')));
          await tester.tap(find.byKey(const Key('gallery-play')));
        },
      );
      expect(result!.adaptive, isTrue);
    });

    testWidgets('i custodi della Storia mostrano l\'avanzamento', (
      tester,
    ) async {
      await _open(
        tester,
        story: const StoryState(beaten: {'prologue', 'village'}),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('guardians-progress')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('I custodi della Storia'), findsOneWidget);
      expect(find.text('2 di 9 custodi incontrati'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('guardians-progress')),
      );
      expect(bar.value, closeTo(2 / 9, 0.001));
    });

    testWidgets('Tino si sceglie solo dopo il Capitolo 0', (tester) async {
      await _open(
        tester,
        initialBotId: 'pino',
        act: () async {
          await tester.scrollUntilVisible(
            find.byKey(const Key('guardian-tino')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const Key('guardian-tino')));
        },
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Tino',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('gallery-play')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Tino gioca dopo il Capitolo 0', (tester) async {
      final result = await _open(
        tester,
        story: const StoryState(beaten: {'prologue'}),
        act: () async {
          await tester.scrollUntilVisible(
            find.byKey(const Key('guardian-tino')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.byKey(const Key('guardian-tino')));
          await tester.tap(find.byKey(const Key('gallery-play')));
        },
      );
      expect(result!.botId, 'tino');
    });

    testWidgets('un bot iniziale che non si vede cade sul primo disponibile', (
      tester,
    ) async {
      await _open(tester, kid: true, initialBotId: 'stella');
      expect(
        tester.widget<Text>(find.byKey(const Key('gallery-name'))).data,
        'Pino',
      );
    });

    testWidgets('Tino ha la corona se il suo capitolo è concluso', (
      tester,
    ) async {
      await _open(tester, story: const StoryState(beaten: {'prologue'}));
      await tester.scrollUntilVisible(
        find.byKey(const Key('guardian-tino')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('guardian-tino')),
          matching: find.byIcon(Icons.workspace_premium),
        ),
        findsOneWidget,
      );
    });

    group('opzioni della partita', () {
      testWidgets('senza scelte le opzioni sono quelle di base', (
        tester,
      ) async {
        final result = await _open(
          tester,
          initialBotId: 'pino',
          act: () async => tester.tap(find.byKey(const Key('gallery-play'))),
        );
        expect(result!.options.control, isNull);
        expect(result.options.variant, Variant.standard);
        expect(result.options.handicap, isNull);
        expect(result.options.coach, isFalse);
      });

      testWidgets('Opzioni apre il pannello con cadenza e variante', (
        tester,
      ) async {
        await _open(
          tester,
          act: () async => tester.tap(find.byKey(const Key('gallery-options'))),
        );
        expect(find.text('Nessun timer'), findsOneWidget);
        expect(find.text('Bullet'), findsOneWidget);
        expect(find.text('Blitz'), findsOneWidget);
        expect(find.text('Rapid'), findsOneWidget);
        expect(find.byKey(const Key('option-time-5+0')), findsOneWidget);
        expect(
          find.byKey(const Key('option-variant-chess960')),
          findsOneWidget,
        );
      });

      testWidgets(
        'cadenza, variante, handicap e allenatore arrivano al risultato',
        (tester) async {
          final result = await _open(
            tester,
            initialBotId: 'pino',
            act: () async {
              await tester.tap(find.byKey(const Key('gallery-options')));
              await tester.pumpAndSettle();
              await _tapOption(tester, const Key('option-time-5+0'));
              await tester.tap(
                find.byKey(const Key('option-handicap-piece-knight')),
              );
              await _tapOption(tester, const Key('option-handicap-time-2'));
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const Key('option-handicap-giver-opponent')),
              );
              await tester.scrollUntilVisible(
                find.byKey(const Key('option-coach')),
                200,
                scrollable: find.descendant(
                  of: find.byType(BottomSheet),
                  matching: find.byType(Scrollable),
                ),
              );
              await _tapOption(tester, const Key('option-coach'));
              await tester.tap(find.byKey(const Key('options-done')));
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(const Key('gallery-play')));
            },
          );
          expect(result!.options.control, const TimeControl(minutes: 5));
          expect(result.options.handicap!.piece, HandicapPiece.knight);
          expect(result.options.handicap!.giverMinutes, 2);
          expect(result.options.handicap!.giver, HandicapGiver.opponent);
          expect(result.options.coach, isTrue);
        },
      );

      testWidgets(
        'una variante diversa dalla classica toglie il pezzo in meno',
        (tester) async {
          final result = await _open(
            tester,
            initialBotId: 'pino',
            act: () async {
              await tester.tap(find.byKey(const Key('gallery-options')));
              await tester.pumpAndSettle();
              await tester.tap(
                find.byKey(const Key('option-handicap-piece-rook')),
              );
              await tester.tap(
                find.byKey(const Key('option-variant-chess960')),
              );
              await tester.tap(find.byKey(const Key('options-done')));
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(const Key('gallery-play')));
            },
          );
          expect(result!.options.variant, Variant.chess960);
          expect(result.options.handicap, isNull);
        },
      );

      testWidgets('le opzioni scelte restano riaprendo il pannello', (
        tester,
      ) async {
        await _open(
          tester,
          act: () async {
            await tester.tap(find.byKey(const Key('gallery-options')));
            await tester.pumpAndSettle();
            await _tapOption(tester, const Key('option-time-3+2'));
            await tester.tap(find.byKey(const Key('options-done')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('gallery-options')));
          },
        );
        final chip = tester.widget<ChoiceChip>(
          find.byKey(const Key('option-time-3+2')),
        );
        expect(chip.selected, isTrue);
      });

      testWidgets('profilo bambino: solo senza tempo o cadenza lenta', (
        tester,
      ) async {
        final result = await _open(
          tester,
          kid: true,
          act: () async {
            await tester.tap(find.byKey(const Key('gallery-options')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('option-variant-chess960')),
              findsNothing,
            );
            expect(find.byKey(const Key('option-coach')), findsNothing);
            expect(find.byKey(const Key('option-time-1+0')), findsNothing);
            await _tapOption(tester, const Key('option-time-slow'));
            await tester.tap(find.byKey(const Key('options-done')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('gallery-play')));
          },
        );
        expect(
          result!.options.control,
          const TimeControl(minutes: 15, increment: 10),
        );
        expect(result.options.variant, Variant.standard);
      });

      testWidgets('un handicap già scelto resta nel pannello', (tester) async {
        Device.phoneMedium.apply(tester);
        BotGalleryResult? result;
        await tester.pumpWidget(
          localizedApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute<BotGalleryResult>(
                    builder: (_) => const BotGalleryPage(
                      collection: BotCollection(),
                      initialBotId: 'pino',
                      initialOptions: GameOptions(
                        control: TimeControl(minutes: 5),
                        handicap: Handicap(piece: HandicapPiece.queen),
                      ),
                    ),
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('apri'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gallery-play')));
        await tester.pumpAndSettle();
        expect(result!.options.handicap!.piece, HandicapPiece.queen);
        expect(result!.options.control, const TimeControl(minutes: 5));
      });

      testWidgets('profilo bambino: una cadenza non adatta torna senza tempo', (
        tester,
      ) async {
        Device.phoneMedium.apply(tester);
        BotGalleryResult? result;
        await tester.pumpWidget(
          localizedApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await Navigator.push(
                  context,
                  MaterialPageRoute<BotGalleryResult>(
                    builder: (_) => const BotGalleryPage(
                      collection: BotCollection(),
                      kidMode: true,
                      initialOptions: GameOptions(
                        control: TimeControl(minutes: 3, increment: 2),
                      ),
                    ),
                  ),
                ),
                child: const Text('apri'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('apri'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gallery-play')));
        await tester.pumpAndSettle();
        expect(result!.options.control, isNull);
      });

      testWidgets('il pannello è in inglese con la lingua inglese', (
        tester,
      ) async {
        await _open(
          tester,
          locale: const Locale('en'),
          act: () async => tester.tap(find.byKey(const Key('gallery-options'))),
        );
        expect(find.text('No timer'), findsOneWidget);
        expect(find.text('Standard'), findsOneWidget);
      });

      testWidgets(
        'il pannello non si vede se la galleria sceglie solo il bot',
        (tester) async {
          Device.phoneMedium.apply(tester);
          await tester.pumpWidget(
            localizedApp(
              home: const BotGalleryPage(
                collection: BotCollection(),
                showOptions: false,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('gallery-options')), findsNothing);
        },
      );
    });

    testWidgets('profilo bambino: solo i bot amici, niente numeri', (
      tester,
    ) async {
      await _open(tester, kid: true);
      expect(find.byKey(const Key('bot-pino')), findsOneWidget);
      expect(find.byKey(const Key('bot-chiara')), findsOneWidget);
      expect(find.byKey(const Key('bot-rocco')), findsOneWidget);
      expect(find.byKey(const Key('bot-stella')), findsNothing);
      expect(find.byKey(const Key('guardians-progress')), findsNothing);
      expect(find.byKey(const Key('bot-adaptive')), findsNothing);
      expect(find.textContaining('Elo'), findsNothing);
      expect(find.byKey(const Key('gallery-elo')), findsNothing);
    });

    testWidgets('i testi sono in inglese con la lingua inglese', (
      tester,
    ) async {
      await _open(tester, locale: const Locale('en'), initialBotId: 'pino');
      expect(find.text('Novice · 3'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Neofita · 3'), findsNothing);
    });

    for (final device in Device.phones) {
      testWidgets('nessun overflow su ${device.name} con testo al 130%', (
        tester,
      ) async {
        await _open(
          tester,
          device: device,
          textScale: 1.3,
          collection: _beat(['lia', 'pino']),
          story: const StoryState(beaten: {'prologue'}),
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(const Key('guardians-progress')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('i bersagli tattili sono almeno 48 dp', (tester) async {
      await _open(tester, device: Device.phoneSmall);
      for (final id in ['lia', 'pino', 'nico']) {
        final size = tester.getSize(find.byKey(Key('bot-$id')));
        expect(size.width, greaterThanOrEqualTo(48), reason: id);
        expect(size.height, greaterThanOrEqualTo(48), reason: id);
      }
      for (final key in ['side-white', 'side-random', 'side-black']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
      }
    });

    testWidgets('l\'entrata di Rokko carica la storia da sola', (tester) async {
      Device.phoneMedium.apply(tester);
      await tester.pumpWidget(
        localizedApp(
          home: BotGalleryPage(
            collection: const BotCollection(),
            loadStory: () async => const StoryState(beaten: {'prologue'}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('guardians-progress')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 di 9 custodi incontrati'), findsOneWidget);
    });
  });
}
