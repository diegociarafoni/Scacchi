import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/progress/avatar.dart';
import 'package:scacchi/progress/avatar_photo.dart';
import 'package:scacchi/progress/profile_page.dart';
import 'package:scacchi/progress/progress_controller.dart';
import 'package:scacchi/progress/progress_store.dart';

import '../kids/no_numbers_test.dart' show kidApp, setPhone;

/// PNG 1×1, la più piccola immagine valida.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00,
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xff, 0xff, 0x3f,
  0x00, 0x05, 0xfe, 0x02, 0xfe, 0xa7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

class _FakePicker implements PhotoPicker {
  _FakePicker([this.result]);

  Uint8List? result;
  PhotoUnavailable? error;
  final asked = <PhotoSource>[];

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    asked.add(source);
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  late Directory dir;
  late File photoFile;

  ProgressController open() => ProgressController(
    ProgressStore(File('${dir.path}/p.json')),
    photoFile: photoFile,
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('avatarphoto');
    photoFile = File('${dir.path}/avatar_photo.jpg');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('RP-09 foto del profilo nel controller', () {
    test('senza foto salvata non c\'è nulla', () async {
      final c = open();
      await c.load();
      expect(c.photo, isNull);
    });

    test('la foto si salva in locale e si ritrova al riavvio', () async {
      final c = open();
      await c.load();
      await c.setPhoto(_png);
      expect(c.photo, _png);
      expect(photoFile.readAsBytesSync(), _png);

      final again = open();
      await again.load();
      expect(again.photo, _png);
    });

    test('rimuoverla cancella il file', () async {
      final c = open();
      await c.load();
      await c.setPhoto(_png);
      await c.removePhoto();
      expect(c.photo, isNull);
      expect(photoFile.existsSync(), isFalse);
    });

    test(
      'non entra nel file dei progressi, quindi nemmeno nel backup',
      () async {
        final c = open();
        await c.load();
        await c.setPhoto(_png);
        await c.updateSettings(c.settings.copyWith(unlockAll: true));
        expect(
          File('${dir.path}/p.json').readAsStringSync(),
          isNot(contains('photo')),
        );
      },
    );

    test('se non si riesce a scrivere la foto resta solo in memoria', () async {
      final c = ProgressController(
        ProgressStore(File('${dir.path}/p.json')),
        photoFile: File('${dir.path}/manca/avatar_photo.jpg'),
      );
      await c.load();
      await c.setPhoto(_png);
      expect(c.photo, _png);
    });
  });

  group('RP-09 foto del profilo nella schermata', () {
    late ProgressController controller;
    late _FakePicker picker;

    setUp(() async {
      controller = open();
      await controller.load();
      picker = _FakePicker(_png);
    });

    Future<void> openPicker(WidgetTester tester, {bool kid = false}) async {
      setPhone(tester);
      await tester.pumpWidget(
        kidApp(
          kid: kid,
          ProfilePage(controller: controller, photoPicker: picker),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('avatar')));
      await tester.pumpAndSettle();
    }

    testWidgets('dalla galleria: la foto diventa l\'avatar', (tester) async {
      await openPicker(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-gallery')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo-gallery')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(picker.asked, [PhotoSource.gallery]);
      expect(controller.photo, _png);
      expect(find.byKey(const Key('photo-remove')), findsOneWidget);
    });

    testWidgets('dalla fotocamera', (tester) async {
      await openPicker(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-camera')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo-camera')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(picker.asked, [PhotoSource.camera]);
      expect(controller.photo, _png);
    });

    testWidgets('se si annulla non cambia nulla', (tester) async {
      picker.result = null;
      await openPicker(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-gallery')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo-gallery')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.photo, isNull);
      expect(find.byKey(const Key('photo-remove')), findsNothing);
    });

    testWidgets('permesso negato: messaggio chiaro, nessun blocco', (
      tester,
    ) async {
      picker.error = const PhotoUnavailable();
      await openPicker(tester);
      await tester.ensureVisible(find.byKey(const Key('photo-camera')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo-camera')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Non riesco a usare'), findsOneWidget);
      expect(controller.photo, isNull);
    });

    testWidgets('«Rimuovi la foto» torna all\'avatar scelto', (tester) async {
      await tester.runAsync(() => controller.setPhoto(_png));
      await openPicker(tester);
      expect(find.byKey(const Key('photo-remove')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('photo-remove')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('photo-remove')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(controller.photo, isNull);
      expect(find.byKey(const Key('photo-remove')), findsNothing);
    });

    testWidgets('scegliere un avatar dopo la foto la mette da parte', (
      tester,
    ) async {
      await tester.runAsync(() => controller.setPhoto(_png));
      expect(controller.activePhoto, _png);
      await openPicker(tester);
      await tester.tap(find.bySemanticsLabel(RegExp('^Pino')));
      await tester.pumpAndSettle();
      expect(controller.settings.avatar, Avatar.chick);
      expect(controller.activePhoto, isNull);
      expect(controller.photo, _png);
      expect(find.byKey(const Key('photo-remove')), findsOneWidget);
    });

    testWidgets('rimuovere subito dopo aver scelto non riporta la foto', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await Future.wait([
          controller.setPhoto(_png),
          controller.removePhoto(),
        ]);
      });
      expect(photoFile.existsSync(), isFalse);
      expect(controller.photo, isNull);
    });

    testWidgets('profilo bambino: nessuna scelta di foto e foto non mostrata', (
      tester,
    ) async {
      await tester.runAsync(() => controller.setPhoto(_png));
      await openPicker(tester, kid: true);
      expect(find.byKey(const Key('photo-gallery')), findsNothing);
      expect(find.byKey(const Key('photo-camera')), findsNothing);
      expect(find.byKey(const Key('photo-remove')), findsNothing);
      expect(find.byKey(const Key('avatar-photo')), findsNothing);
    });
  });
}
