import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart' show Color, ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/settings/notation.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('RP-04 valori predefiniti', () async {
    final settings = await SettingsController.load();
    expect(settings.value.showLegalMoves, isTrue);
    expect(settings.value.showCoordinates, isTrue);
    expect(settings.value.showLastMove, isTrue);
    expect(settings.value.autoQueen, isFalse);
    expect(settings.value.drawShapes, isTrue);
    expect(settings.value.autoFlip, isFalse);
    expect(settings.value.animation, AnimationSpeed.normal);
    expect(settings.value.boardTheme, BoardTheme.spazio);
    expect(settings.value.pieceSet, PieceStyle.cburnett);
    expect(settings.value.sound, isTrue);
    expect(settings.value.volume, 1.0);
    expect(settings.value.haptics, isTrue);
    expect(settings.value.tableMode, isFalse);
    expect(settings.value.confirmMove, isFalse);
    expect(settings.value.premove, isTrue);
    expect(settings.value.evalBar, isFalse);
    expect(settings.value.colorBlind, isFalse);
    expect(settings.value.explainWhy, isFalse);
    expect(settings.value.kidMode, isFalse);
    expect(settings.value.themeMode, ThemeMode.system);
    expect(settings.value.notation, MoveNotation.figurine);
  });

  test(
    'RF-76 la notazione scelta è salvata e un valore ignoto vale figurativa',
    () async {
      final settings = await SettingsController.load();
      await settings.update(
        settings.value.copyWith(notation: MoveNotation.italian),
      );
      expect(
        (await SettingsController.load()).value.notation,
        MoveNotation.italian,
      );
      SharedPreferences.setMockInitialValues({'notation': 'inesistente'});
      expect(
        (await SettingsController.load()).value.notation,
        MoveNotation.figurine,
      );
    },
  );

  test('RP-04 le impostazioni sono salvate in locale', () async {
    final settings = await SettingsController.load();
    await settings.update(
      settings.value.copyWith(
        showLegalMoves: false,
        showCoordinates: false,
        autoQueen: true,
        drawShapes: false,
        markColor: MarkColor.blue,
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
        explainWhy: true,
        evalBar: true,
        kidMode: true,
        themeMode: ThemeMode.dark,
      ),
    );
    final reloaded = await SettingsController.load();
    expect(reloaded.value, settings.value);
    expect(reloaded.value.themeMode, ThemeMode.dark);
    expect(reloaded.value.boardTheme, BoardTheme.blue);
    expect(reloaded.value.animation, AnimationSpeed.none);
    expect(reloaded.value.markColor, MarkColor.blue);
    expect(reloaded.value.evalBar, isTrue);
  });

  test(
    'la scelta salvata di un altro tema non cambia col nuovo predefinito',
    () async {
      SharedPreferences.setMockInitialValues({'boardTheme': 'green'});
      final settings = await SettingsController.load();
      expect(settings.value.boardTheme, BoardTheme.green);
    },
  );

  test('RP-04 valori sconosciuti tornano al predefinito', () async {
    SharedPreferences.setMockInitialValues({'boardTheme': 'inesistente'});
    final settings = await SettingsController.load();
    expect(settings.value.boardTheme, BoardTheme.spazio);
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
    expect(settings.value.boardTheme, BoardTheme.spazio);
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

  test(
    'RP-04 l\'evidenziazione dell\'ultima mossa si spegne e si salva',
    () async {
      final settings = await SettingsController.load();
      final theme = settings.value.boardTheme.colorScheme;
      expect(settings.value.board.colorScheme.lastMove, theme.lastMove);
      await settings.update(settings.value.copyWith(showLastMove: false));
      final off = settings.value.board.colorScheme;
      expect(off.lastMove.solidColor!.a, 0);
      expect(off.lightSquare, theme.lightSquare);
      expect(off.darkSquare, theme.darkSquare);
      expect((await SettingsController.load()).value.showLastMove, isFalse);
      expect(
        settings.value.copyWith(showLastMove: true),
        isNot(settings.value),
      );
    },
  );

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

  test('la mossa sbagliata è rossa, arancione con i colori per daltonici', () {
    expect(AppSettings().wrongColor, const Color(0xffd32f2f));
    expect(
      AppSettings(colorBlind: true).wrongColor,
      isNot(AppSettings().wrongColor),
    );
  });
}
