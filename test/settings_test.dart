import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RP-04 valori predefiniti', () async {
    final settings = await SettingsController.load();
    expect(settings.value.showLegalMoves, isTrue);
    expect(settings.value.showCoordinates, isTrue);
    expect(settings.value.autoQueen, isFalse);
    expect(settings.value.drawShapes, isTrue);
    expect(settings.value.autoFlip, isFalse);
    expect(settings.value.animation, AnimationSpeed.normal);
    expect(settings.value.boardTheme, BoardTheme.green);
    expect(settings.value.pieceSet, PieceStyle.cburnett);
    expect(settings.value.sound, isTrue);
    expect(settings.value.volume, 1.0);
    expect(settings.value.haptics, isTrue);
    expect(settings.value.tableMode, isFalse);
    expect(settings.value.confirmMove, isFalse);
    expect(settings.value.colorBlind, isFalse);
    expect(settings.value.kidMode, isFalse);
    expect(settings.value.themeMode, ThemeMode.system);
  });

  test('RP-04 le impostazioni sono salvate in locale', () async {
    final settings = await SettingsController.load();
    await settings.update(
      settings.value.copyWith(
        showLegalMoves: false,
        showCoordinates: false,
        autoQueen: true,
        drawShapes: false,
        autoFlip: true,
        animation: AnimationSpeed.none,
        boardTheme: BoardTheme.blue,
        pieceSet: PieceStyle.merida,
        sound: false,
        volume: 0.4,
        haptics: false,
        tableMode: true,
        confirmMove: true,
        colorBlind: true,
        kidMode: true,
        themeMode: ThemeMode.dark,
      ),
    );
    final reloaded = await SettingsController.load();
    expect(reloaded.value, settings.value);
    expect(reloaded.value.themeMode, ThemeMode.dark);
    expect(reloaded.value.boardTheme, BoardTheme.blue);
    expect(reloaded.value.animation, AnimationSpeed.none);
  });

  test('RP-04 valori sconosciuti tornano al predefinito', () async {
    SharedPreferences.setMockInitialValues({'boardTheme': 'inesistente'});
    final settings = await SettingsController.load();
    expect(settings.value.boardTheme, BoardTheme.green);
  });

  test('RP-02 aspetto dell\'app salvato per nome', () async {
    final settings = await SettingsController.load();
    await settings.update(settings.value.copyWith(themeMode: ThemeMode.light));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'light');
    expect((await SettingsController.load()).value.themeMode, ThemeMode.light);
  });

  test('RP-02 aspetto sconosciuto torna a quello di sistema', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'seppia'});
    final settings = await SettingsController.load();
    expect(settings.value.themeMode, ThemeMode.system);
  });

  test('RF-12 durata delle animazioni', () {
    expect(AnimationSpeed.none.duration, Duration.zero);
    expect(
      AnimationSpeed.slow.duration > AnimationSpeed.normal.duration,
      isTrue,
    );
    expect(
      AnimationSpeed.fast.duration < AnimationSpeed.normal.duration,
      isTrue,
    );
  });

  test('RP-01 almeno quattro temi e tre set di pezzi', () {
    expect(BoardTheme.values.length, greaterThanOrEqualTo(4));
    expect(PieceStyle.values.length, greaterThanOrEqualTo(3));
  });

  test('RP-04 valori di tipo errato tornano al predefinito', () async {
    SharedPreferences.setMockInitialValues({
      'showCoordinates': 'true',
      'boardTheme': 3,
    });
    final settings = await SettingsController.load();
    expect(settings.value.showCoordinates, isTrue);
    expect(settings.value.boardTheme, BoardTheme.green);
  });

  test('RF-31 modalità tavolo capovolge i pezzi dell\'avversario', () async {
    final settings = await SettingsController.load();
    expect(
      settings.value.board.pieceOrientationBehavior,
      PieceOrientationBehavior.facingUser,
    );
    await settings.update(settings.value.copyWith(tableMode: true));
    expect(
      settings.value.board.pieceOrientationBehavior,
      PieceOrientationBehavior.opponentUpsideDown,
    );
  });

  test('RF-30 nomi dei giocatori salvati, senza spazi superflui', () async {
    final settings = await SettingsController.load();
    expect(settings.value.whiteName, '');
    expect(settings.value.blackName, '');
    await settings.update(
      settings.value.copyWith(whiteName: 'Anna', blackName: 'Bruno'),
    );
    final reloaded = await SettingsController.load();
    expect(reloaded.value.whiteName, 'Anna');
    expect(reloaded.value.blackName, 'Bruno');
    expect(reloaded.value.nameOf(Side.white), 'Anna');
    expect(AppSettings().nameOf(Side.black), isNull);
    expect(AppSettings(whiteName: '  ').nameOf(Side.white), isNull);
    expect(AppSettings(blackName: ' Bruno ').blackName, 'Bruno');
    expect(AppSettings(whiteName: 'x' * 40).whiteName.length, 24);
  });
}
