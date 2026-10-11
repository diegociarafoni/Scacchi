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

  test(
    'il ripristino sostituisce i dati e conserva quelli precedenti',
    () async {
      data('games.json', '{"version":1,"games":[1]}');
      final backup = await Backup.collect(dir, {});
      data('games.json', '{"version":1,"games":[2]}');
      data('path.json', '{"version":1}');
      await backup.restore(dir);
      expect(file('games.json'), '{"version":1,"games":[1]}');
      expect(
        file('games.json.prima-del-ripristino'),
        '{"version":1,"games":[2]}',
      );
      expect(File('${dir.path}/path.json').existsSync(), isTrue);
    },
  );

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
