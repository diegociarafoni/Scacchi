import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/backup/backup.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('backup'));
  tearDown(() => dir.deleteSync(recursive: true));

  File data(String name, String text) =>
      File('${dir.path}/$name')..writeAsStringSync(text);

  String file(String name) => File('${dir.path}/$name').readAsStringSync();

  test('raccoglie i file dei dati e le preferenze', () async {
    data('games.json', '{"version":1,"games":[]}');
    data('progress.json', '{"version":2}');
    data('altro.txt', 'ignorato');
    final backup = await Backup.collect(dir, {'sound': true, 'volume': 0.5});
    expect(backup.files.keys, unorderedEquals(['games.json', 'progress.json']));
    expect(backup.preferences, {'sound': true, 'volume': 0.5});
  });

  test('senza dati il backup è vuoto', () async {
    final backup = await Backup.collect(dir, {});
    expect(backup.files, isEmpty);
    expect(backup.preferences, isEmpty);
  });

  test('codifica e decodifica danno gli stessi dati', () async {
    data('games.json', '{"version":1,"games":[1]}');
    final original = await Backup.collect(dir, {
      'whiteName': 'Anna',
      'tags': ['a', 'b'],
    });
    final copy = Backup.decode(original.encode());
    expect(copy.files, original.files);
    expect(copy.preferences, original.preferences);
  });

  test('RG-13 il file della storia fa parte del backup', () async {
    data('story.json', '{"version":1,"beaten":["village"]}');
    final backup = await Backup.collect(dir, {});
    expect(backup.files.keys, contains('story.json'));
  });

  group('ripristino all\'avvio', () {
    test('sostituisce i dati e conserva quelli precedenti', () async {
      data('games.json', '{"version":1,"games":[1]}');
      final backup = await Backup.collect(dir, {'volume': 0.5});
      data('games.json', '{"version":1,"games":[2]}');
      data('path.json', '{"version":1}');
      await backup.stage(dir);
      // Prima dell'avvio nulla cambia.
      expect(file('games.json'), '{"version":1,"games":[2]}');

      Map<String, Object>? prefs;
      final applied = await Backup.applyPending(dir, (p) async => prefs = p);

      expect(applied, isTrue);
      expect(file('games.json'), '{"version":1,"games":[1]}');
      expect(prefs, {'volume': 0.5});
      // Il file assente dal backup viene tolto ma resta una copia.
      expect(File('${dir.path}/path.json').existsSync(), isFalse);
      final kept = dir.listSync().map((e) => e.path.split('/').last);
      expect(
        kept.where((n) => n.contains(Backup.previousSuffix)),
        hasLength(2),
      );
      expect(File('${dir.path}/${Backup.pendingName}').existsSync(), isFalse);
    });

    test('due ripristini conservano entrambe le copie', () async {
      data('games.json', '{"version":1,"games":[1]}');
      final backup = await Backup.collect(dir, {});
      for (var i = 0; i < 2; i++) {
        await backup.stage(dir);
        await Backup.applyPending(dir, (_) async {});
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      final copies = dir.listSync().where(
        (e) => e.path.contains(Backup.previousSuffix),
      );
      expect(copies, hasLength(2));
    });

    test('senza backup in attesa non fa nulla', () async {
      expect(await Backup.applyPending(dir, (_) async {}), isFalse);
    });

    test('un backup in attesa illeggibile viene scartato', () async {
      data(Backup.pendingName, 'rotto');
      await expectLater(
        Backup.applyPending(dir, (_) async {}),
        throwsA(isA<BackupException>()),
      );
      expect(File('${dir.path}/${Backup.pendingName}').existsSync(), isFalse);
    });
  });

  group('rifiuta un file non valido', () {
    Map<String, Object?> valid() => {
      'app': 'scacchi',
      'version': 1,
      'files': {'games.json': '{"version":1}'},
      'preferences': <String, Object?>{},
    };

    void rejects(String why, Map<String, Object?> json) => test(
      why,
      () => expect(
        () => Backup.decode(jsonEncode(json)),
        throwsA(isA<BackupException>()),
      ),
    );

    test('testo che non è JSON', () {
      expect(() => Backup.decode('ciao'), throwsA(isA<BackupException>()));
    });
    rejects('altra app', {...valid(), 'app': 'altro'});
    rejects('versione futura', {...valid(), 'version': 2});
    rejects('nome di file fuori dall\'elenco', {
      ...valid(),
      'files': {'../evil.json': '{"version":1}'},
    });
    rejects('file senza versione dello schema', {
      ...valid(),
      'files': {'games.json': '{}'},
    });
    rejects('contenuto del file non JSON', {
      ...valid(),
      'files': {'games.json': 'non json'},
    });
    rejects('preferenza di tipo non ammesso', {
      ...valid(),
      'preferences': {
        'x': {'a': 1},
      },
    });
  });
}
