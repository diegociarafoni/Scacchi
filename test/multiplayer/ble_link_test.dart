// ignore_for_file: close_sinks
import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/ble_link.dart';
import 'package:scacchi/multiplayer/ble_transport.dart';
import 'package:scacchi/multiplayer/transport.dart';

/// Radio in memoria tra un ospite (periferica) e un invitato (centrale).
class _Peer implements Central, Peripheral {
  _Peer(this.uuid);

  @override
  final UUID uuid;
}

class _WriteRequest implements GATTWriteRequest {
  _WriteRequest(this.value);

  @override
  final Uint8List value;
  @override
  int get offset => 0;
}

class FakePeripheralManager implements PeripheralManager {
  FakePeripheralManager({
    this.fakeState = BluetoothLowEnergyState.poweredOn,
    this.notifyLength = 100,
  });

  BluetoothLowEnergyState fakeState;
  final int notifyLength;
  Duration notifyDelay = Duration.zero;
  Advertisement? advertised;
  GATTService? service;
  final disconnected = <Central>[];
  final responses = <GATTWriteRequest>[];
  FakeCentralManager? radio;

  final _write =
      StreamController<GATTCharacteristicWriteRequestedEventArgs>.broadcast();
  final _notifyState =
      StreamController<
        GATTCharacteristicNotifyStateChangedEventArgs
      >.broadcast();
  final _conn =
      StreamController<CentralConnectionStateChangedEventArgs>.broadcast();
  final _mtu = StreamController<CentralMTUChangedEventArgs>.broadcast();
  final _state =
      StreamController<BluetoothLowEnergyStateChangedEventArgs>.broadcast();

  @override
  BluetoothLowEnergyState get state => fakeState;
  @override
  Stream<BluetoothLowEnergyStateChangedEventArgs> get stateChanged =>
      _state.stream;
  @override
  Future<bool> authorize() async => true;
  @override
  Stream<GATTCharacteristicWriteRequestedEventArgs>
  get characteristicWriteRequested => _write.stream;
  @override
  Stream<GATTCharacteristicNotifyStateChangedEventArgs>
  get characteristicNotifyStateChanged => _notifyState.stream;
  @override
  Stream<CentralConnectionStateChangedEventArgs> get connectionStateChanged =>
      _conn.stream;
  @override
  Stream<CentralMTUChangedEventArgs> get mtuChanged => _mtu.stream;
  @override
  Future<void> removeAllServices() async => service = null;
  @override
  Future<void> addService(GATTService s) async => service = s;
  @override
  Future<void> startAdvertising(Advertisement a) async => advertised = a;
  @override
  Future<void> stopAdvertising() async => advertised = null;
  @override
  Future<int> getMaximumNotifyLength(Central central) async {
    await Future<void>.delayed(notifyDelay);
    return notifyLength;
  }

  @override
  Future<void> respondWriteRequest(GATTWriteRequest r) async =>
      responses.add(r);
  @override
  Future<void> disconnect(Central central) async {
    disconnected.add(central);
    _conn.add(
      CentralConnectionStateChangedEventArgs(
        central,
        ConnectionState.disconnected,
      ),
    );
  }

  @override
  Future<void> notifyCharacteristic(
    Central central,
    GATTCharacteristic c, {
    required Uint8List value,
  }) async {
    radio?.deliverNotification(c, value);
  }

  GATTCharacteristic char(int i) => service!.characteristics[i];

  void subscribe(Central c, {int index = 1}) => _notifyState.add(
    GATTCharacteristicNotifyStateChangedEventArgs(c, char(index), true),
  );
  void write(Central c, Uint8List v, {int index = 0}) => _write.add(
    GATTCharacteristicWriteRequestedEventArgs(c, char(index), _WriteRequest(v)),
  );
  void drop(Central c) => _conn.add(
    CentralConnectionStateChangedEventArgs(c, ConnectionState.disconnected),
  );
  void powerOff() => _state.add(
    BluetoothLowEnergyStateChangedEventArgs(BluetoothLowEnergyState.poweredOff),
  );
  void unsubscribe(Central c) => _notifyState.add(
    GATTCharacteristicNotifyStateChangedEventArgs(c, char(1), false),
  );
  void powerCycle() => _state.add(
    BluetoothLowEnergyStateChangedEventArgs(BluetoothLowEnergyState.poweredOn),
  );

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

class FakeCentralManager implements CentralManager {
  FakeCentralManager(
    this.host, {
    this.fakeState = BluetoothLowEnergyState.poweredOn,
  });

  final FakePeripheralManager host;
  BluetoothLowEnergyState fakeState;
  final peer = _Peer(UUID.short(0x1234));
  final writes = <Uint8List>[];
  int scans = 0;
  int connects = 0;
  bool hostVisible = true;
  bool failNextConnect = false;
  bool failConnect = false;
  void Function()? duringDiscover;
  bool? authorized;

  final _discovered = StreamController<DiscoveredEventArgs>.broadcast();
  final _conn =
      StreamController<PeripheralConnectionStateChangedEventArgs>.broadcast();
  final _notified =
      StreamController<GATTCharacteristicNotifiedEventArgs>.broadcast();
  final _state =
      StreamController<BluetoothLowEnergyStateChangedEventArgs>.broadcast();

  @override
  BluetoothLowEnergyState get state => fakeState;
  @override
  Stream<BluetoothLowEnergyStateChangedEventArgs> get stateChanged =>
      _state.stream;
  @override
  Future<bool> authorize() async {
    if (authorized ?? true) fakeState = BluetoothLowEnergyState.poweredOn;
    return authorized ?? true;
  }

  @override
  Stream<DiscoveredEventArgs> get discovered => _discovered.stream;
  @override
  Stream<PeripheralConnectionStateChangedEventArgs>
  get connectionStateChanged => _conn.stream;
  @override
  Stream<GATTCharacteristicNotifiedEventArgs> get characteristicNotified =>
      _notified.stream;

  @override
  Future<void> startDiscovery({List<UUID>? serviceUUIDs}) async {
    scans++;
    final adv = host.advertised;
    if (!hostVisible || adv == null) return;
    scheduleMicrotask(
      () => _discovered.add(DiscoveredEventArgs(peer, -50, adv)),
    );
  }

  @override
  Future<void> stopDiscovery() async {}
  @override
  Future<void> connect(Peripheral p) async {
    connects++;
    if (failConnect) throw StateError('connessione fallita');
    if (failNextConnect) {
      failNextConnect = false;
      throw StateError('connessione fallita');
    }
  }

  @override
  Future<void> disconnect(Peripheral p) async {}
  @override
  Future<List<GATTService>> discoverGATT(Peripheral p) async {
    final hook = duringDiscover;
    duringDiscover = null;
    hook?.call();
    await Future<void>.delayed(Duration.zero);
    return [host.service!];
  }

  @override
  Stream<PeripheralMTUChangedEventArgs> get mtuChanged => const Stream.empty();
  @override
  Future<void> setCharacteristicNotifyState(
    Peripheral p,
    GATTCharacteristic c, {
    required bool state,
  }) async {
    host.subscribe(peer);
  }

  @override
  Future<int> getMaximumWriteLength(
    Peripheral p, {
    required GATTCharacteristicWriteType type,
  }) async => 185;
  @override
  Future<void> writeCharacteristic(
    Peripheral p,
    GATTCharacteristic c, {
    required Uint8List value,
    required GATTCharacteristicWriteType type,
  }) async {
    writes.add(value);
    host.write(peer, value);
  }

  void deliverNotification(GATTCharacteristic c, Uint8List v) =>
      _notified.add(GATTCharacteristicNotifiedEventArgs(peer, c, v));
  void drop() => _conn.add(
    PeripheralConnectionStateChangedEventArgs(
      peer,
      ConnectionState.disconnected,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('${i.memberName}');
}

const gameId = '3f2b8c1e-5d4a-4f6b-9a7c-1e2d3c4b5a69';

/// Attende la condizione (al massimo 8 secondi): i tempi dei ricollegamenti
/// variano con il carico della macchina.
Future<void> until(bool Function() ok) async {
  final end = DateTime.now().add(const Duration(seconds: 8));
  while (!ok() && DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> settle([int ms = 50]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

Uint8List bytes(int n) => Uint8List.fromList(List.generate(n, (i) => i % 251));

Future<(BleTransport, BleTransport, FakePeripheralManager, FakeCentralManager)>
open() async {
  final host = FakePeripheralManager();
  final guest = FakeCentralManager(host);
  host.radio = guest;
  final h = BleTransport(await BlePeripheralLink.open(gameId, manager: host));
  final g = BleTransport(await BleCentralLink.open(gameId, manager: guest));
  return (h, g, host, guest);
}

void main() {
  group('RMP-20 Bluetooth sul sistema (radio finta)', () {
    test('l\'ospite annuncia il servizio della partita senza nome', () async {
      final host = FakePeripheralManager();
      final link = await BlePeripheralLink.open(gameId, manager: host);
      expect(
        host.advertised!.serviceUUIDs.single.toString(),
        bleServiceUuid(gameId),
      );
      expect(host.advertised!.name, isNull);
      expect(host.service!.uuid.toString(), bleServiceUuid(gameId));
      await link.close();
      expect(host.advertised, isNull);
    });

    test('l\'invitato trova l\'ospite, si collega e i messaggi vanno nei due versi', () async {
      final (h, g, _, guestMgr) = await open();
      var hostConnected = 0;
      var guestConnected = 0;
      h.connected.listen((_) => hostConnected++);
      g.connected.listen((_) => guestConnected++);
      final atHost = <Uint8List>[];
      final atGuest = <Uint8List>[];
      h.incoming.listen(atHost.add);
      g.incoming.listen(atGuest.add);
      await settle();
      expect(hostConnected, 1);
      expect(guestConnected, 1);

      await g.send(bytes(700));
      await h.send(bytes(500));
      await settle();
      expect(atHost, [bytes(700)]);
      expect(atGuest, [bytes(500)]);
      // I pacchetti rispettano la lunghezza massima di ciascun verso.
      expect(guestMgr.writes.every((w) => w.length <= 185), isTrue);
      await h.close();
      await g.close();
    });

    test('un collegamento caduto si rifà da solo', () async {
      final (h, g, _, guestMgr) = await open();
      var guestConnected = 0;
      g.connected.listen((_) => guestConnected++);
      await settle();
      expect(guestConnected, 1);
      guestMgr.drop();
      await until(() => guestConnected >= 2);
      expect(guestConnected, 2);
      expect(guestMgr.scans, 2);
      final got = <Uint8List>[];
      h.incoming.listen(got.add);
      await g.send(bytes(40));
      await settle();
      expect(got, [bytes(40)]);
      await h.close();
      await g.close();
    });

    test('se la connessione fallisce riprova', () async {
      final host = FakePeripheralManager();
      final guestMgr = FakeCentralManager(host)..failNextConnect = true;
      host.radio = guestMgr;
      final h = BleTransport(
        await BlePeripheralLink.open(gameId, manager: host),
      );
      final g = BleTransport(
        await BleCentralLink.open(gameId, manager: guestMgr),
      );
      var guestConnected = 0;
      g.connected.listen((_) => guestConnected++);
      await until(() => guestConnected >= 1);
      expect(guestMgr.connects, 2);
      expect(guestConnected, 1);
      await h.close();
      await g.close();
    });

    test('senza collegamento l\'invio fallisce', () async {
      final host = FakePeripheralManager();
      final guestMgr = FakeCentralManager(host)..hostVisible = false;
      final h = BleTransport(
        await BlePeripheralLink.open(gameId, manager: host),
      );
      final g = BleTransport(
        await BleCentralLink.open(gameId, manager: guestMgr),
      );
      await settle();
      await expectLater(g.send(bytes(5)), throwsA(isA<TransportUnavailable>()));
      await expectLater(h.send(bytes(5)), throwsA(isA<TransportUnavailable>()));
      await h.close();
      await g.close();
    });

    test(
      'una caduta durante la scoperta del servizio fa ricominciare',
      () async {
        final host = FakePeripheralManager();
        final guestMgr = FakeCentralManager(host);
        host.radio = guestMgr;
        guestMgr.duringDiscover = guestMgr.drop;
        final h = BleTransport(
          await BlePeripheralLink.open(gameId, manager: host),
        );
        final g = BleTransport(
          await BleCentralLink.open(gameId, manager: guestMgr),
        );
        var connected = 0;
        g.connected.listen((_) => connected++);
        await until(() => connected >= 1);
        expect(connected, 1);
        expect(guestMgr.scans, 2);
        await h.close();
        await g.close();
      },
    );

    test('se il collegamento non riesce mai le attese crescono', () async {
      final host = FakePeripheralManager();
      final guestMgr = FakeCentralManager(host)..failConnect = true;
      final h = BleTransport(
        await BlePeripheralLink.open(gameId, manager: host),
      );
      final g = BleTransport(
        await BleCentralLink.open(gameId, manager: guestMgr),
      );
      await settle(3300);
      // Tentativi a 0, 1 e 3 secondi: non uno al secondo (4 o più).
      expect(guestMgr.connects, inInclusiveRange(2, 3));
      await h.close();
      await g.close();
    });

    test('i pacchetti non superano il limite del ricevente', () async {
      final host = FakePeripheralManager(notifyLength: 1000);
      final link = await BlePeripheralLink.open(gameId, manager: host);
      host.subscribe(_Peer(UUID.short(1)));
      await settle();
      expect(link.chunkSize, 512);
      await link.close();
    });

    test('chi si disiscrive mentre si legge la lunghezza non resta', () async {
      final host = FakePeripheralManager()
        ..notifyDelay = const Duration(milliseconds: 30);
      final link = await BlePeripheralLink.open(gameId, manager: host);
      final p = _Peer(UUID.short(1));
      host.subscribe(p);
      host.unsubscribe(p);
      await settle(100);
      expect(link.isLinked, isFalse);
      await link.close();
    });

    test('Bluetooth spento: l\'ospite non risulta più collegato', () async {
      final host = FakePeripheralManager();
      final link = await BlePeripheralLink.open(gameId, manager: host);
      host.subscribe(_Peer(UUID.short(1)));
      await settle();
      expect(link.isLinked, isTrue);
      host.powerOff();
      await settle();
      expect(link.isLinked, isFalse);
      await link.close();
    });

    test(
      'l\'ospite scarta scritture su altre caratteristiche e troppo grandi',
      () async {
        final host = FakePeripheralManager();
        final link = await BlePeripheralLink.open(gameId, manager: host);
        final t = BleTransport(link);
        final got = <Uint8List>[];
        t.incoming.listen(got.add);
        final stranger = _Peer(UUID.short(0x9999));
        // Senza iscrizione alle risposte la scrittura non conta.
        host.write(stranger, Uint8List.fromList([0, 1, 0, 1, 9]));
        await settle();
        expect(got, isEmpty);
        host.subscribe(stranger);
        await settle();
        host.write(stranger, Uint8List.fromList([0, 1, 0, 1, 7]), index: 1);
        host.write(stranger, Uint8List(600));
        host.write(stranger, Uint8List.fromList([0, 1, 0, 1, 7]));
        await settle();
        expect(got, [
          Uint8List.fromList([7]),
        ]);
        expect(host.responses, hasLength(2));
        await t.close();
      },
    );

    test('oltre il limite esce l\'ospite più vecchio', () async {
      final host = FakePeripheralManager();
      final link = await BlePeripheralLink.open(gameId, manager: host);
      final peers = [
        for (var i = 0; i < maxBleCentrals + 1; i++)
          _Peer(UUID.short(0x100 + i)),
      ];
      for (final p in peers) {
        host.subscribe(p);
        await settle(5);
      }
      expect(host.disconnected, [peers.first]);
      expect(link.isLinked, isTrue);
      await link.close();
    });

    test('l\'ospite usa la lunghezza più piccola tra i collegati', () async {
      final host = FakePeripheralManager(notifyLength: 60);
      final link = await BlePeripheralLink.open(gameId, manager: host);
      expect(link.chunkSize, 20);
      host.subscribe(_Peer(UUID.short(1)));
      await settle();
      expect(link.chunkSize, 60);
      await link.close();
    });

    test('dopo un\'uscita l\'ospite si annuncia di nuovo', () async {
      final host = FakePeripheralManager();
      final link = await BlePeripheralLink.open(gameId, manager: host);
      final p = _Peer(UUID.short(1));
      host.subscribe(p);
      await settle();
      host.advertised = null;
      host.drop(p);
      await settle();
      expect(host.advertised, isNotNull);
      expect(link.isLinked, isFalse);
      host.service = null;
      host.advertised = null;
      host.powerCycle();
      await settle();
      expect(host.service, isNotNull);
      expect(host.advertised, isNotNull);
      await link.close();
    });
  });

  group('RMP-20 Bluetooth spento o negato', () {
    test('spento', () async {
      final host = FakePeripheralManager(
        fakeState: BluetoothLowEnergyState.poweredOff,
      );
      await expectLater(
        BlePeripheralLink.open(gameId, manager: host),
        throwsA(
          isA<BluetoothUnavailable>().having(
            (e) => e.problem,
            'problem',
            BluetoothProblem.off,
          ),
        ),
      );
    });

    test('non supportato', () async {
      final host = FakePeripheralManager(
        fakeState: BluetoothLowEnergyState.unsupported,
      );
      await expectLater(
        BleCentralLink.open(
          gameId,
          manager: FakeCentralManager(
            host,
            fakeState: BluetoothLowEnergyState.unsupported,
          ),
        ),
        throwsA(
          isA<BluetoothUnavailable>().having(
            (e) => e.problem,
            'problem',
            BluetoothProblem.unsupported,
          ),
        ),
      );
    });

    test('permessi negati', () async {
      final host = FakePeripheralManager();
      final m = FakeCentralManager(
        host,
        fakeState: BluetoothLowEnergyState.unauthorized,
      )..authorized = false;
      await expectLater(
        BleCentralLink.open(gameId, manager: m),
        throwsA(
          isA<BluetoothUnavailable>().having(
            (e) => e.problem,
            'problem',
            BluetoothProblem.denied,
          ),
        ),
      );
    });

    test('permessi concessi alla richiesta', () async {
      final host = FakePeripheralManager();
      final m = FakeCentralManager(
        host,
        fakeState: BluetoothLowEnergyState.unauthorized,
      );
      final link = await BleCentralLink.open(
        gameId,
        manager: m,
        scanTimeout: const Duration(milliseconds: 50),
      );
      await link.close();
    });

    test('stato sconosciuto: attende la risposta del sistema', () async {
      final host = FakePeripheralManager(
        fakeState: BluetoothLowEnergyState.unknown,
      );
      final f = BlePeripheralLink.open(gameId, manager: host);
      await settle();
      host.fakeState = BluetoothLowEnergyState.poweredOn;
      host._state.add(
        BluetoothLowEnergyStateChangedEventArgs(
          BluetoothLowEnergyState.poweredOn,
        ),
      );
      final link = await f;
      await link.close();
    });
  });
}
