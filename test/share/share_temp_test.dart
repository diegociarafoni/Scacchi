import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/share/share_temp.dart';

void main() {
  late Directory base;
  setUp(() => base = Directory.systemTemp.createTempSync('share'));
  tearDown(() => base.deleteSync(recursive: true));

  test('il file resta finché non parte la condivisione successiva', () async {
    final first = await newShareTempFile('a.png', base: base);
    first.writeAsStringSync('x');
    // Dopo share() il file deve esistere ancora per chi lo legge.
    expect(first.existsSync(), isTrue);

    final second = await newShareTempFile('b.json', base: base);
    expect(first.existsSync(), isFalse);
    expect(second.parent.existsSync(), isTrue);
  });

  test('la pulizia all\'avvio toglie i file rimasti', () async {
    final file = await newShareTempFile('a.png', base: base);
    file.writeAsStringSync('x');
    await clearShareTemp(base: base);
    expect(file.existsSync(), isFalse);
    // Senza nulla da togliere non fa errori.
    await clearShareTemp(base: base);
  });
}
