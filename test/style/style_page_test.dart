import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/game/sounds.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/style/style_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/devices.dart';

void main() {
  late SettingsController settings;
  late List<GameSound> played;
  var picked = <String?>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsController.defaults();
    played = [];
    picked = [null];
  });

  Future<void> show(
    WidgetTester tester, {
    Device device = Device.phoneMedium,
    double textScale = 1,
  }) async {
    device.apply(tester);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: StylePage(
          controller: settings,
          pickPhoto: () async => picked.removeAt(0),
          preview: (sound, set) async => played.add(sound),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(Tab, label));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('in alto c\'è l\'anteprima e sotto le quattro schede', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Stile'), findsWidgets);
    expect(find.byKey(const Key('board-preview')), findsOneWidget);
    for (final tab in ['Scacchiera', 'Pezzi', 'Sfondo', 'Suoni']) {
      expect(find.widgetWithText(Tab, tab), findsOneWidget, reason: tab);
    }
  });

  testWidgets('la scheda Scacchiera offre tutti i temi e cambia l\'anteprima', (
    tester,
  ) async {
    await show(tester);
    for (final t in BoardTheme.values) {
      expect(
        find.byKey(Key('theme-tile-${t.name}'), skipOffstage: false),
        findsOneWidget,
        reason: t.name,
      );
    }
    await choose(tester, const Key('theme-tile-marmo'));
    expect(settings.value.boardTheme, BoardTheme.marmo);
    final board = tester.widget<StaticChessboard>(
      find.byType(StaticChessboard),
    );
    expect(board.settings.colorScheme, BoardTheme.marmo.colorScheme);
  });

  testWidgets('la scheda Pezzi mostra il cavallo di ogni set', (tester) async {
    await show(tester);
    await openTab(tester, 'Pezzi');
    for (final p in PieceStyle.values) {
      expect(
        find.byKey(Key('piece-icon-${p.name}'), skipOffstage: false),
        findsOneWidget,
        reason: p.name,
      );
    }
    await choose(tester, const Key('piece-tile-merida'));
    expect(settings.value.pieceSet, PieceStyle.merida);
  });

  testWidgets('la scheda Sfondo cambia lo sfondo dietro la scacchiera', (
    tester,
  ) async {
    await show(tester);
    await openTab(tester, 'Sfondo');
    expect(find.byKey(const Key('board-backdrop')), findsNothing);
    await choose(tester, const Key('backdrop-tile-graphite'));
    expect(settings.value.backdrop, BoardBackdrop.graphite);
    expect(find.byKey(const Key('board-backdrop')), findsOneWidget);
    await choose(tester, const Key('backdrop-tile-standard'));
    expect(settings.value.backdrop, BoardBackdrop.standard);
  });

  testWidgets('scegliere una foto la usa come sfondo', (tester) async {
    await show(tester);
    await openTab(tester, 'Sfondo');
    picked = ['/dati/stile/sfondo.jpg'];
    await choose(tester, const Key('backdrop-photo-add'));
    expect(settings.value.backdrop, BoardBackdrop.photo);
    expect(settings.value.backdropPhoto, '/dati/stile/sfondo.jpg');
    expect(
      find.text('La foto resta solo sul tuo telefono.', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('annullare la scelta della foto non cambia nulla', (
    tester,
  ) async {
    await show(tester);
    await openTab(tester, 'Sfondo');
    await choose(tester, const Key('backdrop-photo-add'));
    expect(settings.value.backdrop, BoardBackdrop.standard);
  });

  testWidgets('la scheda Suoni sceglie il set e ne fa sentire un campione', (
    tester,
  ) async {
    await show(tester);
    await openTab(tester, 'Suoni');
    for (final s in SoundSet.values) {
      expect(find.byKey(Key('sound-tile-${s.name}')), findsOneWidget);
    }
    await choose(tester, const Key('sound-tile-legno'));
    expect(settings.value.soundSet, SoundSet.legno);
    expect(played, [GameSound.move, GameSound.capture]);
  });

  testWidgets('la scheda scelta resta con il tema scuro e con testo grande', (
    tester,
  ) async {
    await show(tester, device: Device.phoneSmall, textScale: 1.3);
    await openTab(tester, 'Sfondo');
    expect(tester.takeException(), isNull);
  });

  for (final device in Device.phones) {
    testWidgets('nessun overflow su ${device.name}', (tester) async {
      await show(tester, device: device);
      for (final tab in ['Pezzi', 'Sfondo', 'Suoni', 'Scacchiera']) {
        await openTab(tester, tab);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('le tessere hanno nome e stato per i lettori di schermo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await show(tester);
    await openTab(tester, 'Sfondo');
    expect(
      tester.getSemantics(find.byKey(const Key('backdrop-tile-standard'))),
      matchesSemantics(
        label: 'Standard',
        isButton: true,
        isSelected: true,
        isEnabled: true,
        hasEnabledState: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
