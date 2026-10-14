import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/backup/backup.dart';

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

  group('dati aggiunti dopo la prima versione', () {
    const extra = ['week.json', 'masters.json', 'endgames.json'];

    test('settimana, maestri, finali e partita a due telefoni', () async {
      for (final n in extra) {
        data(n, '{"version":1,"n":"$n"}');
      }
      final backup = await Backup.collect(dir, {});
      expect(backup.files.keys, containsAll(extra));
      final copy = Backup.decode(backup.encode());
      expect(copy.files, backup.files);
    });

    test('la foto del profilo viaggia nel file come binario', () async {
      final bytes = List<int>.generate(256, (i) => i);
      File('${dir.path}/avatar_photo.jpg').writeAsBytesSync(bytes);
      final backup = await Backup.collect(dir, {});
      expect(backup.binaries['avatar_photo.jpg'], bytes);
      final copy = Backup.decode(backup.encode());
      expect(copy.binaries['avatar_photo.jpg'], bytes);
    });

    test('il ripristino riscrive file e foto', () async {
      data('week.json', '{"version":1,"n":1}');
      File('${dir.path}/avatar_photo.jpg').writeAsBytesSync([1, 2, 3]);
      final backup = await Backup.collect(dir, {});
      data('week.json', '{"version":1,"n":2}');
      File('${dir.path}/avatar_photo.jpg').writeAsBytesSync([9]);
      await backup.stage(dir);
      await Backup.applyPending(dir, (_) async {});
      expect(file('week.json'), '{"version":1,"n":1}');
      expect(File('${dir.path}/avatar_photo.jpg').readAsBytesSync(), [1, 2, 3]);
    });

    test('un backup vecchio non tocca i dati che non conosceva', () async {
      for (final n in extra) {
        data(n, '{"version":1}');
      }
      File('${dir.path}/avatar_photo.jpg').writeAsBytesSync([7]);
      data('games.json', '{"version":1,"games":[2]}');
      final old = jsonEncode({
        'app': 'scacchi',
        'version': 1,
        'files': {'games.json': '{"version":1,"games":[1]}'},
        'preferences': <String, Object?>{},
      });
      await Backup.decode(old).stage(dir);
      await Backup.applyPending(dir, (_) async {});
      expect(file('games.json'), '{"version":1,"games":[1]}');
      for (final n in extra) {
        expect(file(n), '{"version":1}');
      }
      expect(File('${dir.path}/avatar_photo.jpg').readAsBytesSync(), [7]);
    });

    test('un backup nuovo senza foto toglie quella locale', () async {
      final backup = await Backup.collect(dir, {});
      File('${dir.path}/avatar_photo.jpg').writeAsBytesSync([7]);
      await backup.stage(dir);
      await Backup.applyPending(dir, (_) async {});
      expect(File('${dir.path}/avatar_photo.jpg').existsSync(), isFalse);
    });

    test('il backup si chiama rokko e legge anche il vecchio nome', () async {
      final backup = await Backup.collect(dir, {});
      expect(jsonDecode(backup.encode())['app'], 'rokko');
      for (final app in ['rokko', 'scacchi']) {
        final json = jsonEncode({
          'app': app,
          'version': 1,
          'files': <String, Object?>{},
          'preferences': <String, Object?>{},
        });
        expect(() => Backup.decode(json), returnsNormally);
      }
    });

    test('rifiuta un binario fuori elenco o non base64', () {
      Map<String, Object?> json(Object blobs) => {
        'app': 'scacchi',
        'version': 2,
        'files': <String, Object?>{},
        'binaries': blobs,
        'preferences': <String, Object?>{},
      };
      expect(
        () => Backup.decode(jsonEncode(json({'../x.jpg': 'AAA='}))),
        throwsA(isA<BackupException>()),
      );
      for (final bad in ['%%%', null]) {
        expect(
          () => Backup.decode(jsonEncode(json({'avatar_photo.jpg': bad}))),
          throwsA(
            isA<BackupException>().having(
              (e) => e.problem,
              'problem',
              BackupProblem.invalidFile,
            ),
          ),
        );
      }
    });
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

    test(
      'multiplayer.json non entra nel backup ne viene ripristinato',
      () async {
        data('multiplayer.json', '{"version":1,"seed":"segreto"}');
        data('games.json', '{"version":1,"games":[1]}');
        final backup = await Backup.collect(dir, {});
        expect(backup.files.keys, isNot(contains('multiplayer.json')));
        expect(backup.encode(), isNot(contains('segreto')));

        final old = jsonEncode({
          'app': 'scacchi',
          'version': 2,
          'files': {'multiplayer.json': '{"version":1,"seed":"altrui"}'},
          'preferences': <String, Object?>{},
        });
        final decoded = Backup.decode(old);
        expect(decoded.files, isEmpty);
        await decoded.stage(dir);
        await Backup.applyPending(dir, (_) async {});
        expect(file('multiplayer.json'), '{"version":1,"seed":"segreto"}');
      },
    );

    test('un ripristino riuscito toglie le copie dei precedenti', () async {
      data('games.json', '{"version":1,"games":[1]}');
      final backup = await Backup.collect(dir, {});
      for (var i = 0; i < 3; i++) {
        await backup.stage(dir);
        await Backup.applyPending(dir, (_) async {});
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      final copies = dir.listSync().where(
        (e) => e.path.contains(Backup.previousSuffix),
      );
      // Solo le copie dell'ultimo ripristino (games.json sostituito).
      expect(copies, hasLength(1));
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
    rejects('versione futura', {...valid(), 'version': 3});
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
