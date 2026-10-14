import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La copia ridotta di chessground (third_party/chessground) porta solo i set
/// di pezzi che l'app offre e nessuna immagine di scacchiera: meno peso
/// nell'APK e nessun asset con licenza non compatibile nel pacchetto.
/// Procedura: docs/qualita.md, sezione «Dimensione».
void main() {
  const root = 'third_party/chessground';
  final pubspec = File('$root/pubspec.yaml').readAsStringSync();
  final declared = RegExp(
    r'^\s+- assets/piece_sets/([\w-]+)/$',
    multiLine: true,
  ).allMatches(pubspec).map((m) => m.group(1)!).toSet();

  // Cartella del set per ogni PieceSet usato in lib/.
  const folder = {
    'cburnett': 'cburnett',
    'merida': 'merida',
    'chessnut': 'chessnut',
    'fantasy': 'fantasy',
    'spatial': 'spatial',
    'celtic': 'celtic',
    'shapes': 'shapes',
    'firi': 'firi',
    'mpchess': 'mpchess',
    'kiwenSuwi': 'kiwen-suwi',
    'totoy': 'totoy',
    'rhosgfx': 'rhosgfx',
  };

  test('i set usati nel codice sono nella tabella del test', () {
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is File && f.path.endsWith('.dart')) {
        used.addAll(
          RegExp(r'PieceSet\.(\w+)')
              .allMatches(f.readAsStringSync())
              .map((m) => m.group(1)!)
              .where((n) => n != 'values' && !n.endsWith('Assets')),
        );
      }
    }
    expect(
      used.difference(folder.keys.toSet()),
      isEmpty,
      reason: 'aggiungere il set a third_party/chessground e a questo test',
    );
  });

  test('ogni set usato è dichiarato e presente', () {
    expect(declared, folder.values.toSet());
    for (final name in declared) {
      expect(Directory('$root/assets/piece_sets/$name').existsSync(), isTrue);
    }
  });

  test('nessuna cartella non dichiarata e nessuna immagine di scacchiera', () {
    final present = Directory('$root/assets/piece_sets')
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(present, declared);
    expect(pubspec, isNot(contains('assets/boards')));
    expect(Directory('$root/assets/boards').existsSync(), isFalse);
  });

  test('la licenza e la nota sulle modifiche accompagnano la copia', () {
    expect(File('$root/LICENSE').existsSync(), isTrue);
    final note = File('$root/MODIFICHE.md').readAsStringSync();
    expect(note, contains('10.3.0'));
  });

  test('pubspec.yaml dell\'app usa la copia ridotta', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('path: third_party/chessground'),
    );
  });
}
