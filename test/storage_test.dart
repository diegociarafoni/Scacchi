import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/storage/key_value_store.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('store'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('JsonFileStore conserva i valori tra le aperture', () async {
    final file = File('${dir.path}/training.json');
    final store = JsonFileStore(file);
    await store.write('a', '1');
    await store.write('b', '2');
    await store.write('a', '3');
    final again = JsonFileStore(file);
    expect(await again.read('a'), '3');
    expect(await again.read('b'), '2');
    expect(await again.read('c'), isNull);
  });

  for (final content in ['{x', '{"a": 1}']) {
    test(
      'JsonFileStore mette da parte un file illeggibile: $content',
      () async {
        final file = File('${dir.path}/training.json')
          ..writeAsStringSync(content);
        final store = JsonFileStore(file);
        expect(await store.read('a'), isNull);
        final backups = dir.listSync().where((f) => f.path.contains('.bad-'));
        expect((backups.single as File).readAsStringSync(), content);
        await store.write('a', '1');
        expect(await JsonFileStore(file).read('a'), '1');
      },
    );
  }

  test(
    'JsonFileStore: due letture iniziali concorrenti non perdono scritture',
    () async {
      final file = File('${dir.path}/training.json');
      await JsonFileStore(file).write('a', '1');
      final store = JsonFileStore(file);
      final first = store.read('a');
      final second = store.write('b', '2');
      await Future.wait([first, second]);
      await store.write('c', '3');
      final again = JsonFileStore(file);
      expect(await again.read('a'), '1');
      expect(await again.read('b'), '2');
      expect(await again.read('c'), '3');
    },
  );

  test('JsonFileStore mette da parte un file con byte non UTF-8', () async {
    final file = File('${dir.path}/training.json')
      ..writeAsBytesSync([0xff, 0xfe, 0xfd]);
    expect(await JsonFileStore(file).read('a'), isNull);
    expect(dir.listSync().where((f) => f.path.contains('.bad-')), hasLength(1));
  });
}
