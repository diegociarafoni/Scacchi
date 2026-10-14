@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/l10n/app_localizations.dart';
import 'package:rokko/settings/settings.dart';
import 'package:rokko/style/style_page.dart';
import 'package:rokko/theme/rokko_theme.dart';

import '../support/devices.dart';

// I riferimenti sono generati su Linux: altrove il rendering dei caratteri differisce.
final _skip = Platform.isLinux ? null : 'riferimenti generati solo su Linux';

/// Le immagini si decodificano fuori dal clock dei test: si attende che
/// pezzi e texture siano pronti prima dello scatto.
Future<void> _settleImages(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  Future<void> pumpStyle(
    WidgetTester tester,
    Device device, {
    AppSettings? settings,
    String? tab,
    Brightness brightness = Brightness.light,
  }) async {
    device.apply(tester);
    final controller = SettingsController.defaults()
      ..value = settings ?? AppSettings();
    await tester.pumpWidget(
      SettingsScope(
        controller: controller,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark
              ? RokkoTheme.dark()
              : RokkoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: StylePage(controller: controller),
        ),
      ),
    );
    if (tab != null) {
      await tester.tap(find.widgetWithText(Tab, tab));
    }
    await _settleImages(tester);
  }

  Future<void> golden(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );

  for (final device in Device.phones) {
    testWidgets('Stile, scacchiera, ${device.name}', (tester) async {
      await pumpStyle(
        tester,
        device,
        settings: AppSettings(boardTheme: BoardTheme.marmo),
      );
      await golden(tester, 'stile-scacchiera-${device.name}');
    }, skip: _skip != null);

    testWidgets('Stile, sfondo, ${device.name}', (tester) async {
      await pumpStyle(
        tester,
        device,
        settings: AppSettings(
          boardTheme: BoardTheme.vetro,
          backdrop: BoardBackdrop.tramonto,
        ),
        tab: 'Sfondo',
      );
      await golden(tester, 'stile-sfondo-${device.name}');
    }, skip: _skip != null);
  }

  testWidgets('Stile, pezzi, scuro, telefono medio', (tester) async {
    await pumpStyle(
      tester,
      Device.phoneMedium,
      settings: AppSettings(
        boardTheme: BoardTheme.metallo,
        pieceSet: PieceStyle.merida,
      ),
      tab: 'Pezzi',
      brightness: Brightness.dark,
    );
    await golden(tester, 'stile-pezzi-scuro-telefono-medio');
  }, skip: _skip != null);

  testWidgets('Stile, pezzi Staunton su Noce, telefono medio', (tester) async {
    await pumpStyle(
      tester,
      Device.phoneMedium,
      settings: AppSettings(
        boardTheme: BoardTheme.noce,
        pieceSet: PieceStyle.staunton,
      ),
      tab: 'Pezzi',
    );
    await golden(tester, 'stile-pezzi-staunton-noce-telefono-medio');
  }, skip: _skip != null);

  testWidgets('Stile, suoni, telefono medio', (tester) async {
    await pumpStyle(
      tester,
      Device.phoneMedium,
      settings: AppSettings(soundSet: SoundSet.cristallo),
      tab: 'Suoni',
    );
    await golden(tester, 'stile-suoni-telefono-medio');
  }, skip: _skip != null);
}
