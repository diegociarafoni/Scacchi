import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/game/sounds.dart';
import 'package:scacchi/settings/settings.dart';
import 'package:scacchi/style/backdrop_photo.dart';
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
      final dir = Directory.systemTemp.createTempSync('sfondo');
      addTearDown(() => dir.deleteSync(recursive: true));
      final photo = File('${dir.path}/sfondo.jpg')..writeAsBytesSync([1]);
      Future<Directory> where() async => dir;
      final c = await SettingsController.load(photoDirectory: where);
      await c.update(
        c.value.copyWith(
          backdrop: BoardBackdrop.photo,
          backdropPhoto: photo.path,
        ),
      );
      // Nelle preferenze c'è solo il nome: il percorso cambia tra le installazioni.
      expect(
        (await SharedPreferences.getInstance()).getString('backdropPhoto'),
        'sfondo.jpg',
      );
      final again = await SettingsController.load(photoDirectory: where);
      expect(again.value.backdrop, BoardBackdrop.photo);
      expect(again.value.backdropPhoto, photo.path);
    });

    test('un percorso assoluto salvato da versioni vecchie si migra', () async {
      final dir = Directory.systemTemp.createTempSync('sfondo');
      addTearDown(() => dir.deleteSync(recursive: true));
      File('${dir.path}/sfondo-7.jpg').writeAsBytesSync([1]);
      SharedPreferences.setMockInitialValues({
        'backdrop': 'photo',
        'backdropPhoto': '/vecchio/contenitore/stile/sfondo-7.jpg',
      });
      final c = await SettingsController.load(photoDirectory: () async => dir);
      expect(c.value.backdrop, BoardBackdrop.photo);
      expect(c.value.backdropPhoto, '${dir.path}/sfondo-7.jpg');
      expect(
        (await SharedPreferences.getInstance()).getString('backdropPhoto'),
        'sfondo-7.jpg',
      );
    });

    test('una foto sparita riporta lo sfondo a standard', () async {
      SharedPreferences.setMockInitialValues({
        'backdrop': 'photo',
        'backdropPhoto': '/non/esiste/sfondo.jpg',
      });
      expect(
        (await SettingsController.load()).value.backdrop,
        BoardBackdrop.standard,
      );
    });

    test('le foto vecchie si tolgono solo dopo, e solo da stile/', () async {
      final root = Directory.systemTemp.createTempSync('prune');
      addTearDown(() => root.deleteSync(recursive: true));
      final dir = Directory('${root.path}/stile')..createSync();
      final old = File('${dir.path}/sfondo-1.jpg')..writeAsBytesSync([1]);
      final keep = File('${dir.path}/sfondo-2.jpg')..writeAsBytesSync([2]);
      final other = File('${root.path}/altro.jpg')..writeAsBytesSync([3]);
      await pruneBackdropPhotos(keep.path);
      expect(old.existsSync(), isFalse);
      expect(keep.existsSync(), isTrue);
      await pruneBackdropPhotos(other.path);
      expect(keep.existsSync(), isTrue, reason: 'cartella diversa: nulla');
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
