import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/sounds.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sfondi', () {
    test(
      'ci sono almeno dieci sfondi oltre alla foto, il primo è standard',
      () {
        final fixed = BoardBackdrop.values.where(
          (b) => b != BoardBackdrop.photo,
        );
        expect(fixed.length, greaterThanOrEqualTo(10));
        expect(BoardBackdrop.values.first, BoardBackdrop.standard);
        expect(AppSettings().backdrop, BoardBackdrop.standard);
      },
    );

    test('gli sfondi con immagine usano file nostri che esistono', () {
      for (final b in BoardBackdrop.values.where((b) => b.asset != null)) {
        expect(File(b.asset!).existsSync(), isTrue, reason: b.name);
      }
    });

    test("ogni sfondo fisso ha un colore, un gradiente o un'immagine", () {
      for (final b in BoardBackdrop.values.where(
        (b) => b != BoardBackdrop.standard && b != BoardBackdrop.photo,
      )) {
        expect(
          b.gradient != null || b.color != null || b.asset != null,
          isTrue,
          reason: b.name,
        );
      }
    });

    test('scelta e foto si salvano e si ricaricano', () async {
      final c = await SettingsController.load();
      await c.update(
        c.value.copyWith(
          backdrop: BoardBackdrop.photo,
          backdropPhoto: '/dati/stile/sfondo.jpg',
        ),
      );
      final again = await SettingsController.load();
      expect(again.value.backdrop, BoardBackdrop.photo);
      expect(again.value.backdropPhoto, '/dati/stile/sfondo.jpg');
    });

    test('uno sfondo sconosciuto torna a standard', () async {
      SharedPreferences.setMockInitialValues({'backdrop': 'inesistente'});
      expect(
        (await SettingsController.load()).value.backdrop,
        BoardBackdrop.standard,
      );
    });

    test('impostazioni con sfondo diverso non sono uguali', () {
      expect(
        AppSettings() == AppSettings(backdrop: BoardBackdrop.graphite),
        isFalse,
      );
      expect(
        AppSettings(backdropPhoto: 'a') == AppSettings(backdropPhoto: 'b'),
        isFalse,
      );
    });
  });

  group('set di suoni', () {
    test('ci sono almeno tre set, il primo è quello di sempre', () {
      expect(SoundSet.values.length, greaterThanOrEqualTo(3));
      expect(SoundSet.values.first, SoundSet.classico);
      expect(AppSettings().soundSet, SoundSet.classico);
    });

    test('ogni set ha tutti i sette suoni su disco', () {
      for (final set in SoundSet.values) {
        for (final sound in GameSound.values) {
          final path = 'assets/${set.assetOf(sound)}';
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }
    });

    test('i suoni dei set sono leggeri', () {
      var total = 0;
      for (final set in SoundSet.values.skip(1)) {
        for (final sound in GameSound.values) {
          total += File('assets/${set.assetOf(sound)}').lengthSync();
        }
      }
      expect(total, lessThan(150 * 1024));
    });

    test('il set classico resta in assets/sounds', () {
      expect(SoundSet.classico.assetOf(GameSound.move), 'sounds/move.wav');
    });

    test('il set si salva, uno sconosciuto torna a classico', () async {
      final c = await SettingsController.load();
      await c.update(c.value.copyWith(soundSet: SoundSet.legno));
      expect((await SettingsController.load()).value.soundSet, SoundSet.legno);
      SharedPreferences.setMockInitialValues({'soundSet': 'xx'});
      expect(
        (await SettingsController.load()).value.soundSet,
        SoundSet.classico,
      );
    });

    test('il lettore usa il set scelto nelle impostazioni', () async {
      final c = await SettingsController.load();
      await c.update(c.value.copyWith(soundSet: SoundSet.cristallo));
      expect(SoundPlayer.activeSet, SoundSet.cristallo);
      await c.update(c.value.copyWith(soundSet: SoundSet.classico));
      expect(SoundPlayer.activeSet, SoundSet.classico);
    });
  });

  group('nuove scacchiere', () {
    test('marmo, metallo e vetro hanno texture; ci sono tinte unite nuove', () {
      final byName = BoardTheme.values.asNameMap();
      for (final n in ['marmo', 'metallo', 'vetro']) {
        expect(byName[n]!.textured, isTrue, reason: n);
        expect(File('assets/boards/$n.webp').existsSync(), isTrue, reason: n);
      }
      for (final n in ['menta', 'cipria', 'ardesia']) {
        expect(byName[n]!.textured, isFalse, reason: n);
      }
    });

    test('le scacchiere sono almeno venticinque', () {
      expect(BoardTheme.values.length, greaterThanOrEqualTo(25));
    });
  });
}
