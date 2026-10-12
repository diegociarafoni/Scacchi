import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/ble_transport.dart';
import 'package:scacchi/multiplayer/transport.dart';

/// Due estremi di un collegamento Bluetooth in memoria.
class FakeBleLink implements BleLink {
  FakeBleLink({this.chunkSize = 23});

  static (FakeBleLink, FakeBleLink) pair({int chunkSize = 23}) {
    final a = FakeBleLink(chunkSize: chunkSize);
    final b = FakeBleLink(chunkSize: chunkSize);
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  @override
  int chunkSize;

  /// Falso finché i due telefoni non si sono trovati.
  @override
  bool isLinked = false;

  FakeBleLink? _peer;
  final writes = <Uint8List>[];
  final _chunks = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  bool closed = false;

  @override
  Stream<Uint8List> get chunks => _chunks.stream;

  @override
  Stream<void> get connected => _connected.stream;

  /// I due telefoni si trovano.
  void link() {
    for (final l in [this, _peer!]) {
      l.isLinked = true;
      l._connected.add(null);
    }
  }

  void drop() {
    isLinked = false;
    _peer!.isLinked = false;
  }

  /// Un frammento arriva dall'esterno, come da un telefono estraneo.
  void inject(Uint8List chunk) => _chunks.add(chunk);

  @override
  Future<void> write(Uint8List chunk) async {
    if (!isLinked) throw const TransportUnavailable('fake');
    writes.add(chunk);
    _peer!._chunks.add(chunk);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _chunks.close();
    await _connected.close();
  }
}

Uint8List bytes(int n, [int seed = 3]) {
  final r = Random(seed);
  return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  group('RMP-20 canale Bluetooth', () {
    test(
      'porta un messaggio grande spezzato nel limite del collegamento',
      () async {
        final (la, lb) = FakeBleLink.pair();
        final a = BleTransport(la);
        final b = BleTransport(lb);
        la.link();
        final got = <Uint8List>[];
        b.incoming.listen(got.add);
        final msg = bytes(900);
        await a.send(msg);
        await settle();
        expect(got, [msg]);
        expect(la.writes.length, greaterThan(1));
        expect(la.writes.every((w) => w.length <= 23), isTrue);
        expect(a.name, 'bluetooth');
      },
    );

    test(
      'usa il limite del momento: dopo una MTU più larga, meno pacchetti',
      () async {
        final (la, lb) = FakeBleLink.pair();
        final a = BleTransport(la);
        BleTransport(lb);
        la.link();
        await a.send(bytes(400));
        final small = la.writes.length;
        la.writes.clear();
        la.chunkSize = 185;
        await a.send(bytes(400));
        expect(la.writes.length, lessThan(small));
      },
    );

    test('senza telefono collegato l\'invio fallisce', () async {
      final (la, _) = FakeBleLink.pair();
      final a = BleTransport(la);
      await expectLater(
        a.send(bytes(10)),
        throwsA(isA<TransportUnavailable>()),
      );
      la.link();
      la.drop();
      await expectLater(
        a.send(bytes(10)),
        throwsA(isA<TransportUnavailable>()),
      );
    });

    test('segnala il collegamento nuovo (ConnectionAware)', () async {
      final (la, _) = FakeBleLink.pair();
      final a = BleTransport(la);
      var n = 0;
      a.connected.listen((_) => n++);
      la.link();
      la.drop();
      la.link();
      await settle();
      expect(n, 2);
    });

    test('scarta i frammenti estranei e continua', () async {
      final (la, lb) = FakeBleLink.pair();
      final a = BleTransport(la);
      final b = BleTransport(lb);
      la.link();
      final got = <Uint8List>[];
      b.incoming.listen(got.add);
      lb.inject(Uint8List.fromList([1]));
      lb.inject(Uint8List.fromList([0, 0, 9, 1, 5]));
      await a.send(bytes(30));
      await settle();
      expect(got, [bytes(30)]);
    });

    test('invii in parallelo non mescolano i frammenti', () async {
      final (la, lb) = FakeBleLink.pair();
      final a = BleTransport(la);
      final b = BleTransport(lb);
      la.link();
      final got = <Uint8List>[];
      b.incoming.listen(got.add);
      await Future.wait([
        a.send(bytes(100, 1)),
        a.send(bytes(100, 2)),
        a.send(bytes(100)),
      ]);
      await settle();
      expect(got, [bytes(100, 1), bytes(100, 2), bytes(100)]);
    });

    test('un messaggio troppo grande non parte', () async {
      final (la, _) = FakeBleLink.pair();
      final a = BleTransport(la);
      la.link();
      await expectLater(
        a.send(bytes(5000)),
        throwsA(isA<TransportUnavailable>()),
      );
    });

    test('chiudere chiude il collegamento e il flusso', () async {
      final (la, _) = FakeBleLink.pair();
      final a = BleTransport(la);
      var done = false;
      a.incoming.listen((_) {}, onDone: () => done = true);
      await a.close();
      await settle();
      expect(la.closed, isTrue);
      expect(done, isTrue);
      await expectLater(a.send(bytes(3)), throwsA(isA<TransportUnavailable>()));
    });

    test('lavora dentro MultiTransport insieme ad altri canali', () async {
      final (la, lb) = FakeBleLink.pair();
      final multi = MultiTransport([BleTransport(la)]);
      final other = BleTransport(lb);
      final got = <Uint8List>[];
      other.incoming.listen(got.add);
      var connected = 0;
      multi.connected.listen((_) => connected++);
      la.link();
      await multi.send(bytes(60));
      await settle();
      expect(got, [bytes(60)]);
      expect(connected, 1);
    });
  });

  group('RMP-20 UUID del servizio', () {
    const id = '3f2b8c1e-5d4a-4f6b-9a7c-1e2d3c4b5a69';

    test('è deterministico e ben formato', () {
      expect(bleServiceUuid(id), bleServiceUuid(id));
      expect(
        bleServiceUuid(id),
        matches(RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')),
      );
    });

    test('cambia da una partita all\'altra e non svela l\'id', () {
      const other = '3f2b8c1e-5d4a-4f6b-9a7c-1e2d3c4b5a6a';
      expect(bleServiceUuid(id), isNot(bleServiceUuid(other)));
      expect(bleServiceUuid(id), isNot(id));
    });
  });
}
