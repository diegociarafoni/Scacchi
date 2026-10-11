import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/backup/backup.dart';
import 'package:scacchi/backup/backup_page.dart';

void main() {
  late Directory dir;
  String? shared;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('backup-page');
    File('${dir.path}/games.json').writeAsStringSync('{"version":1}');
    shared = null;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  // Le operazioni su file non avanzano con il tempo finto dei test.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: BackupPage(
        directory: () async => dir,
        preferences: () => {'sound': true},
        share: (text, name) async => shared = text,
      ),
    ),
  );

  testWidgets('esporta il backup con i dati e le preferenze', (tester) async {
    await open(tester);
    await tester.tap(find.text('Condividi il backup'));
    await settle(tester);
    final backup = Backup.decode(shared!);
    expect(backup.files.keys, ['games.json']);
    expect(backup.preferences, {'sound': true});
  });

  testWidgets('il backup incollato resta in attesa del riavvio', (
    tester,
  ) async {
    final text = (await tester.runAsync(
      () => Backup.collect(dir, {'volume': 0.5}),
    ))!.encode();
    File('${dir.path}/games.json').writeAsStringSync('{"version":1,"x":1}');
    await open(tester);
    await tester.tap(find.text('Ripristina da testo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text('Ripristina'));
    await settle(tester);
    expect(File('${dir.path}/${Backup.pendingName}').existsSync(), isTrue);
    expect(File('${dir.path}/games.json').readAsStringSync(), contains('"x"'));
    expect(find.textContaining('riapri'), findsOneWidget);
  });

  testWidgets('un backup non valido non cambia nulla', (tester) async {
    await open(tester);
    await tester.tap(find.text('Ripristina da testo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.tap(find.text('Ripristina'));
    await settle(tester);
    expect(find.text('Backup non leggibile'), findsOneWidget);
    expect(File('${dir.path}/${Backup.pendingName}').existsSync(), isFalse);
    expect(File('${dir.path}/games.json').readAsStringSync(), '{"version":1}');
  });
}
