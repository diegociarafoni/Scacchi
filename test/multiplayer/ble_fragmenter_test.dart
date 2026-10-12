import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/ble_fragmenter.dart';

Uint8List bytes(int n, [int seed = 1]) {
  final r = Random(seed);
  return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
}

void main() {
  group('RMP-20 frammentazione Bluetooth', () {
    test('un messaggio piccolo sta in un solo frammento', () {
      final f = BleFragmenter();
      final parts = f.split(bytes(10), 20);
      expect(parts, hasLength(1));
      expect(parts.single.length, lessThanOrEqualTo(20));
      expect(BleReassembler().add(parts.single), bytes(10));
    });

    test('un messaggio grande si spezza nel limite e si ricompone', () {
      final data = bytes(1000);
      for (final size in [20, 23, 100, 185, 512]) {
        final parts = BleFragmenter().split(data, size);
        expect(parts.every((p) => p.length <= size), isTrue, reason: '$size');
        final r = BleReassembler();
        Uint8List? out;
        for (final p in parts) {
          out = r.add(p) ?? out;
        }
        expect(out, data, reason: '$size');
      }
    });

    test('i frammenti fuori ordine e doppi si ricompongono lo stesso', () {
      final data = bytes(300);
      final parts = BleFragmenter().split(data, 40);
      final shuffled = [...parts.reversed, parts.first, parts[2]];
      final r = BleReassembler();
      final done = [for (final p in shuffled) r.add(p)].nonNulls.toList();
      expect(done, [data]);
    });

    test('messaggi intrecciati restano separati', () {
      final a = bytes(120);
      final b = bytes(120, 2);
      final f = BleFragmenter();
      final pa = f.split(a, 30);
      final pb = f.split(b, 30);
      final r = BleReassembler();
      final done = <Uint8List>[];
      for (var i = 0; i < pa.length; i++) {
        final x = r.add(pa[i]);
        if (x != null) done.add(x);
        final y = r.add(pb[i]);
        if (y != null) done.add(y);
      }
      expect(done, [a, b]);
    });

    test('identificatori diversi per messaggi successivi', () {
      final f = BleFragmenter();
      final one = f.split(bytes(5), 20).single;
      final two = f.split(bytes(5), 20).single;
      expect(one.sublist(0, 2), isNot(two.sublist(0, 2)));
    });

    test('frammenti non validi si scartano in silenzio', () {
      final r = BleReassembler();
      expect(r.add(Uint8List(0)), isNull);
      expect(r.add(Uint8List.fromList([0, 1, 0])), isNull);
      // Conteggio zero e indice oltre il conteggio.
      expect(r.add(Uint8List.fromList([0, 1, 0, 0, 9])), isNull);
      expect(r.add(Uint8List.fromList([0, 1, 5, 2, 9])), isNull);
      // Dopo gli scarti un messaggio buono passa.
      final good = BleFragmenter().split(bytes(8), 20).single;
      expect(r.add(good), bytes(8));
    });

    test('un conteggio che cambia a metà azzera il messaggio', () {
      final r = BleReassembler();
      expect(r.add(Uint8List.fromList([0, 7, 0, 2, 1])), isNull);
      expect(r.add(Uint8List.fromList([0, 7, 1, 3, 2])), isNull);
      expect(r.add(Uint8List.fromList([0, 7, 0, 3, 1])), isNull);
      expect(r.add(Uint8List.fromList([0, 7, 1, 3, 2])), isNull);
      expect(r.add(Uint8List.fromList([0, 7, 2, 3, 3])), [1, 2, 3]);
    });

    test('la memoria è limitata: troppi messaggi incompleti', () {
      final r = BleReassembler();
      for (var id = 0; id < 50; id++) {
        r.add(Uint8List.fromList([0, id, 0, 2, 1, 2, 3]));
      }
      expect(r.pending, lessThanOrEqualTo(maxPendingBleMessages));
    });

    test('un messaggio oltre il limite si scarta', () {
      final r = BleReassembler();
      Uint8List? out;
      final chunk = Uint8List(4 + 200)
        ..[1] = 3
        ..[3] = 200;
      for (var i = 0; i < 200; i++) {
        chunk[2] = i;
        out = r.add(chunk) ?? out;
      }
      expect(out, isNull);
      expect(r.pending, lessThanOrEqualTo(maxPendingBleMessages));
    });

    test('rifiuta messaggi troppo grandi per il frammentatore', () {
      expect(
        () => BleFragmenter().split(bytes(maxBleMessage + 1), 20),
        throwsArgumentError,
      );
      expect(() => BleFragmenter().split(bytes(5), 4), throwsArgumentError);
    });
  });
}
