import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/storage/json_file.dart';

void main() {
  late Directory dir;
  late File file;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('jsonfile');
    file = File('${dir.path}/dati.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  void put(int version, Map<String, Object?> data) =>
      file.writeAsStringSync(jsonEncode({'version': version, ...data}));

  List<String> aside() => [
    for (final f in dir.listSync())
      if (f.path.contains('.bad-')) f.path,
  ];

  Map<String, Object?> v2(Map<String, Object?> j) =>
      {...j, 'nome': j['name']}..remove('name');

  Map<String, Object?> v3(Map<String, Object?> j) => {...j, 'extra': 1};

  group('RNF-08 migrazioni dello schema', () {
    test(
      'un file vecchio passa dalla catena fino alla versione corrente',
      () async {
        put(1, {'name': 'Ada'});
        final json = JsonFile(file, version: 3, migrations: {1: v2, 2: v3});
        final read = await json.read((j) => j);
        expect(read, containsPair('nome', 'Ada'));
        expect(read, containsPair('extra', 1));
        expect(read, isNot(contains('name')));
        expect(aside(), isEmpty);
      },
    );

    test('prima di migrare si tiene una copia del file originale', () async {
      put(1, {'name': 'Ada'});
      final json = JsonFile(file, version: 2, migrations: {1: v2});
      await json.read((j) => j);
      final backup = File('${file.path}.v1.bak');
      expect(backup.existsSync(), isTrue);
      expect(jsonDecode(backup.readAsStringSync()), {
        'version': 1,
        'name': 'Ada',
      });
      // Una seconda lettura non sovrascrive la copia.
      backup.writeAsStringSync('{"version":1,"name":"originale"}');
      await json.read((j) => j);
      expect(backup.readAsStringSync(), contains('originale'));
    });

    test(
      'la lettura non riscrive il file: lo fa il primo salvataggio',
      () async {
        put(1, {'name': 'Ada'});
        final json = JsonFile(file, version: 2, migrations: {1: v2});
        await json.read((j) => j);
        expect(jsonDecode(file.readAsStringSync()), containsPair('version', 1));
        await json.write({'nome': 'Ada'});
        expect(jsonDecode(file.readAsStringSync()), containsPair('version', 2));
      },
    );

    test('un file già aggiornato non passa dalle migrazioni', () async {
      put(2, {'nome': 'Ada'});
      var calls = 0;
      final json = JsonFile(
        file,
        version: 2,
        migrations: {
          1: (j) {
            calls++;
            return j;
          },
        },
      );
      expect(await json.read((j) => j['nome']), 'Ada');
      expect(calls, 0);
      expect(File('${file.path}.v2.bak').existsSync(), isFalse);
    });

    test('se manca un passo della catena il file si mette da parte', () async {
      put(1, {'name': 'Ada'});
      final json = JsonFile(file, version: 3, migrations: {2: v3});
      expect(await json.read((j) => j), isNull);
      expect(aside(), hasLength(1));
      expect(file.existsSync(), isFalse);
      // Senza catena completa non si fa nemmeno la copia.
      expect(File('${file.path}.v1.bak').existsSync(), isFalse);
    });

    test(
      'se la copia non si può scrivere l\'errore sale e il file resta',
      () async {
        put(1, {'name': 'Ada'});
        // Una cartella al posto della copia: la scrittura fallisce.
        Directory('${file.path}.v1.bak').createSync();
        final json = JsonFile(file, version: 2, migrations: {1: v2});
        await expectLater(
          json.read((j) => j),
          throwsA(isA<FileSystemException>()),
        );
        expect(file.existsSync(), isTrue);
        expect(aside(), isEmpty);
      },
    );

    test('se una migrazione fallisce il file si mette da parte', () async {
      put(1, {'name': 'Ada'});
      final json = JsonFile(
        file,
        version: 2,
        migrations: {1: (j) => throw const FormatException('rotto')},
      );
      expect(await json.read((j) => j), isNull);
      expect(aside(), hasLength(1));
      expect(File('${file.path}.v1.bak').existsSync(), isTrue);
    });

    test('una versione futura o assente si mette da parte', () async {
      put(5, {'a': 1});
      final json = JsonFile(file, version: 2, migrations: {1: v2});
      expect(await json.read((j) => j), isNull);
      expect(aside(), hasLength(1));
      file.writeAsStringSync('{"a": 1}');
      expect(await json.read((j) => j), isNull);
      expect(aside(), hasLength(2));
    });
  });
}
