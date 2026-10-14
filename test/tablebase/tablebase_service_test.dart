import 'dart:io';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/tablebase/tablebase.dart';
import 'package:rokko/tablebase/tablebase_service.dart';

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

Future<Map<String, Uint8List>> _inline(
  String material,
  Map<String, Uint8List> ready,
) async => buildTables(material, ready);

Future<Map<String, Uint8List>> _failing(
  String material,
  Map<String, Uint8List> ready,
) async => throw StateError('non deve calcolare');

void main() {
  late Directory dir;
  final mate = _pos('7k/8/6K1/8/8/1Q6/8/8 w - - 0 1');

  setUp(() => dir = Directory.systemTemp.createTempSync('tablebase'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<Directory> where() async => dir;

  test(
    'RF-97 la prima volta calcola e salva, la seconda legge dal disco',
    () async {
      final first = TablebaseService(where, builder: _inline);
      expect(await first.prepare(mate), isTrue);
      expect(first.tablebase.probe(mate), const TbEvaluation(TbOutcome.win, 1));
      expect(
        dir.listSync(recursive: true).whereType<File>().map((f) => f.path),
        contains(endsWith('KQvK.v$tablebaseFormat.tb')),
      );

      final second = TablebaseService(where, builder: _failing);
      expect(await second.prepare(mate), isTrue);
      expect(second.tablebase.bestMove(mate), Move.parse('b3b8'));
    },
  );

  test('RF-97 le tabelle dei materiali più piccoli si riusano', () async {
    final service = TablebaseService(where, builder: _inline);
    expect(
      await service.prepare(_pos('8/P7/8/8/8/2k5/8/K7 w - - 0 1')),
      isTrue,
    );
    // Il pedone può promuovere: servono anche le tabelle di re e donna, ecc.
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList();
    expect(files, hasLength(5));
    expect(files.any((n) => n.startsWith('KQvK.')), isTrue);
  });

  test('RF-97 un file danneggiato si rigenera', () async {
    final service = TablebaseService(where, builder: _inline);
    await service.prepare(mate);
    final file = dir
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere((f) => f.path.contains('KQvK.'));
    file.writeAsBytesSync([1, 2, 3]);
    final again = TablebaseService(where, builder: _inline);
    expect(await again.prepare(mate), isTrue);
    expect(again.tablebase.probe(mate)!.plies, 1);
  });

  test(
    'RF-97 se il calcolo fallisce la risposta è negativa, senza eccezioni',
    () async {
      final service = TablebaseService(where, builder: _failing);
      expect(await service.prepare(mate), isFalse);
      expect(service.tablebase.probe(mate), isNull);
    },
  );

  test('RF-97 posizioni con troppi pezzi non sono coperte', () async {
    final service = TablebaseService(where, builder: _failing);
    expect(await service.prepare(Chess.initial), isFalse);
  });

  test('RF-97 il calcolo in un isolate dà lo stesso risultato', () async {
    final service = TablebaseService(where);
    expect(await service.prepare(mate), isTrue);
    expect(service.tablebase.probe(mate)!.plies, 1);
  });

  test('RF-97 un calcolo fallito non si ritenta a ogni richiesta', () async {
    var calls = 0;
    final service = TablebaseService(
      where,
      builder: (m, r) async {
        calls++;
        throw StateError('no');
      },
    );
    expect(await service.prepare(mate), isFalse);
    expect(await service.prepare(mate), isFalse);
    expect(calls, 1);
  });
}
