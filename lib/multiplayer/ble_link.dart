import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

import 'ble_transport.dart';
import 'game_invite.dart';
import 'transport.dart';

/// Perché il Bluetooth non è utilizzabile.
enum BluetoothProblem { unsupported, denied, off }

class BluetoothUnavailable implements Exception {
  const BluetoothUnavailable(this.problem);

  final BluetoothProblem problem;

  @override
  String toString() => 'BluetoothUnavailable($problem)';
}

// Caratteristiche fisse: il servizio cambia da una partita all'altra.
final _rxUuid = UUID.fromString('7d1c2a54-9b0e-4c5a-8f63-5e2b1a9d4c01');
final _txUuid = UUID.fromString('7d1c2a54-9b0e-4c5a-8f63-5e2b1a9d4c02');

/// Dimensione di un pacchetto finché la MTU non è nota (MTU minima 23 - 3).
const defaultBleChunk = 20;

/// Oltre questo limite un pacchetto in arrivo è sicuramente estraneo.
const _maxIncomingChunk = 512;

/// Altri telefoni che possono restare collegati all'ospite: oltre, esce il
/// più vecchio, così un estraneo non può occupare il posto dell'avversario.
const maxBleCentrals = 3;

/// Chiede i permessi e attende che il Bluetooth sia acceso; lancia
/// [BluetoothUnavailable] se non si può usare.
Future<void> ensureBluetoothReady(
  BluetoothLowEnergyManager manager, {
  Duration wait = const Duration(seconds: 3),
}) async {
  var state = manager.state;
  if (state == BluetoothLowEnergyState.unknown) {
    // Su iOS lo stato arriva appena il sistema ha risposto.
    state = await manager.stateChanged
        .map((e) => e.state)
        .firstWhere((s) => s != BluetoothLowEnergyState.unknown)
        .timeout(wait, onTimeout: () => manager.state);
  }
  if (state == BluetoothLowEnergyState.unauthorized) {
    final granted = await manager.authorize();
    if (!granted) throw const BluetoothUnavailable(BluetoothProblem.denied);
    state = manager.state;
  }
  switch (state) {
    case BluetoothLowEnergyState.poweredOn:
      return;
    case BluetoothLowEnergyState.unsupported:
      throw const BluetoothUnavailable(BluetoothProblem.unsupported);
    case BluetoothLowEnergyState.unauthorized:
      throw const BluetoothUnavailable(BluetoothProblem.denied);
    case BluetoothLowEnergyState.poweredOff:
    case BluetoothLowEnergyState.unknown:
      throw const BluetoothUnavailable(BluetoothProblem.off);
  }
}

bool _sameUuid(UUID a, UUID b) => a == b;

/// Un pacchetto sta tra il minimo del BLE e il limite che il ricevente accetta.
int _clampChunk(int size) => size < defaultBleChunk
    ? defaultBleChunk
    : size > _maxIncomingChunk
    ? _maxIncomingChunk
    : size;

void _log(String what, Object e) {
  if (kDebugMode) debugPrint('Bluetooth, $what: $e');
}

/// Lato dell'ospite: annuncia il servizio della partita e riceve le
/// scritture dell'invitato; risponde con notifiche.
class BlePeripheralLink implements BleLink {
  BlePeripheralLink._(this._manager, this._service);

  /// Apre il servizio della partita [gameId] e comincia ad annunciarsi.
  static Future<BlePeripheralLink> open(
    String gameId, {
    PeripheralManager? manager,
  }) async {
    final m = manager ?? PeripheralManager();
    await ensureBluetoothReady(m);
    final link = BlePeripheralLink._(
      m,
      UUID.fromString(bleServiceUuid(gameId)),
    );
    try {
      await link._start();
    } catch (_) {
      await link.close();
      rethrow;
    }
    return link;
  }

  final PeripheralManager _manager;
  final UUID _service;
  final _subs = <StreamSubscription<Object?>>[];
  final _chunks = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  final _listening = <Central, int>{};
  // Iscritti secondo il sistema, anche mentre se ne legge ancora la lunghezza.
  final _wanted = <Central>{};
  late GATTCharacteristic _tx;
  bool _closed = false;

  @override
  Stream<Uint8List> get chunks => _chunks.stream;

  @override
  Stream<void> get connected => _connected.stream;

  @override
  bool get isLinked => _listening.isNotEmpty;

  @override
  int get chunkSize => _listening.isEmpty
      ? defaultBleChunk
      : _listening.values.reduce((a, b) => a < b ? a : b);

  Future<void> _start() async {
    _subs
      ..add(
        _manager.characteristicWriteRequested.listen((e) async {
          if (!_sameUuid(e.characteristic.uuid, _rxUuid)) return;
          // Chi non si è iscritto alle risposte non fa parte della partita.
          if (!_listening.containsKey(e.central)) return;
          try {
            await _manager.respondWriteRequest(e.request);
          } on Object catch (err) {
            _log('risposta alla scrittura', err);
          }
          final value = e.request.value;
          if (value.length <= _maxIncomingChunk && !_chunks.isClosed) {
            _chunks.add(value);
          }
        }),
      )
      ..add(
        _manager.characteristicNotifyStateChanged.listen((e) async {
          if (!_sameUuid(e.characteristic.uuid, _txUuid)) return;
          if (!e.state) {
            _wanted.remove(e.central);
            _listening.remove(e.central);
            return;
          }
          _wanted.add(e.central);
          await _subscribe(e.central);
        }),
      )
      ..add(
        _manager.connectionStateChanged.listen((e) async {
          if (e.state != ConnectionState.disconnected) return;
          _wanted.remove(e.central);
          _listening.remove(e.central);
          // Alcuni telefoni smettono di annunciarsi quando qualcuno si collega.
          await _advertise();
        }),
      )
      ..add(
        _manager.mtuChanged.listen((e) {
          if (_listening.containsKey(e.central)) {
            _listening[e.central] = _clampChunk(_payload(e.mtu));
          }
        }),
      )
      ..add(
        _manager.stateChanged.listen((e) async {
          if (e.state != BluetoothLowEnergyState.poweredOn) {
            _wanted.clear();
            _listening.clear();
            return;
          }
          // Spento e riacceso: servizio e annuncio vanno rifatti.
          await _publish();
        }),
      );
    await _publish();
  }

  static int _payload(int mtu) => mtu - 3;

  Future<void> _subscribe(Central central) async {
    var length = defaultBleChunk;
    try {
      length = await _manager.getMaximumNotifyLength(central);
    } on Object catch (e) {
      _log('lunghezza massima', e);
    }
    if (_closed) return;
    while (_listening.length >= maxBleCentrals &&
        !_listening.containsKey(central)) {
      final oldest = _listening.keys.first;
      _listening.remove(oldest);
      try {
        await _manager.disconnect(oldest);
      } on Object catch (e) {
        _log('scollegamento', e);
      }
    }
    if (!_wanted.contains(central)) return;
    _listening[central] = _clampChunk(length);
    if (!_connected.isClosed) _connected.add(null);
  }

  Future<void> _publish() async {
    final rx = GATTCharacteristic.mutable(
      uuid: _rxUuid,
      properties: [
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
      ],
      permissions: [GATTCharacteristicPermission.write],
      descriptors: [],
    );
    _tx = GATTCharacteristic.mutable(
      uuid: _txUuid,
      properties: [GATTCharacteristicProperty.notify],
      permissions: [GATTCharacteristicPermission.read],
      descriptors: [],
    );
    await _manager.removeAllServices();
    await _manager.addService(
      GATTService(
        uuid: _service,
        isPrimary: true,
        includedServices: [],
        characteristics: [rx, _tx],
      ),
    );
    await _advertise();
  }

  // Senza nome: non c'è motivo di far leggere il nome del telefono a chi passa.
  Future<void> _advertise() async {
    if (_closed) return;
    try {
      await _manager.startAdvertising(Advertisement(serviceUUIDs: [_service]));
    } on Object catch (e) {
      _log('annuncio', e);
    }
  }

  @override
  Future<void> write(Uint8List chunk) async {
    if (_closed || _listening.isEmpty) {
      throw const TransportUnavailable('bluetooth');
    }
    var delivered = false;
    for (final central in List.of(_listening.keys)) {
      try {
        await _manager.notifyCharacteristic(central, _tx, value: chunk);
        delivered = true;
      } on Object catch (e) {
        _log('notifica', e);
        _listening.remove(central);
      }
    }
    if (!delivered) throw const TransportUnavailable('bluetooth');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final s in _subs) {
      await s.cancel();
    }
    try {
      await _manager.stopAdvertising();
      await _manager.removeAllServices();
    } on Object catch (e) {
      _log('chiusura', e);
    }
    for (final central in List.of(_listening.keys)) {
      try {
        await _manager.disconnect(central);
      } on Object catch (e) {
        _log('chiusura', e);
      }
    }
    _listening.clear();
    await _chunks.close();
    await _connected.close();
  }
}

/// Lato dell'invitato: cerca l'ospite dal servizio della partita, si collega
/// e, se il collegamento cade, ricomincia da solo con attese crescenti.
class BleCentralLink implements BleLink {
  BleCentralLink._(this._manager, this._service);

  static Future<BleCentralLink> open(
    String gameId, {
    CentralManager? manager,
    Duration scanTimeout = const Duration(seconds: 20),
  }) async {
    final m = manager ?? CentralManager();
    await ensureBluetoothReady(m);
    final link = BleCentralLink._(m, UUID.fromString(bleServiceUuid(gameId)))
      .._scanTimeout = scanTimeout;
    link._subs.add(
      m.characteristicNotified.listen((e) {
        final p = link._peripheral;
        if (p == null || !_sameUuid(e.peripheral.uuid, p.uuid)) return;
        if (!_sameUuid(e.characteristic.uuid, _txUuid)) return;
        if (e.value.length <= _maxIncomingChunk && !link._chunks.isClosed) {
          link._chunks.add(e.value);
        }
      }),
    );
    link._subs.add(
      m.mtuChanged.listen((e) {
        final p = link._peripheral;
        if (p != null && _sameUuid(e.peripheral.uuid, p.uuid)) {
          link._chunkSize = _clampChunk(e.mtu - 3);
        }
      }),
    );
    unawaited(link._run());
    return link;
  }

  final CentralManager _manager;
  final UUID _service;
  Duration _scanTimeout = const Duration(seconds: 20);
  final _subs = <StreamSubscription<Object?>>[];
  final _chunks = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  final _closing = Completer<void>();
  Peripheral? _peripheral;
  GATTCharacteristic? _rx;
  int _chunkSize = defaultBleChunk;
  bool _closed = false;

  @override
  Stream<Uint8List> get chunks => _chunks.stream;

  @override
  Stream<void> get connected => _connected.stream;

  @override
  bool get isLinked => _peripheral != null && _rx != null;

  @override
  int get chunkSize => _chunkSize;

  Future<void> _run() async {
    var wait = const Duration(seconds: 1);
    while (!_closed) {
      Peripheral? found;
      StreamSubscription<Object?>? watch;
      var linked = false;
      try {
        found = await _find();
        if (found != null) {
          // Prima di collegarsi: una caduta durante la scoperta del servizio
          // non deve passare inosservata.
          final gone = Completer<void>();
          final peripheral = found;
          watch = _manager.connectionStateChanged.listen((e) {
            if (_sameUuid(e.peripheral.uuid, peripheral.uuid) &&
                e.state == ConnectionState.disconnected &&
                !gone.isCompleted) {
              gone.complete();
            }
          });
          await _link(found, gone);
          linked = true;
          wait = const Duration(seconds: 1);
          await Future.any([gone.future, _closing.future]);
        }
      } on Object catch (e) {
        _log('collegamento', e);
      }
      await watch?.cancel();
      _peripheral = null;
      _rx = null;
      if (found != null) {
        try {
          await _manager.disconnect(found);
        } on Object catch (e) {
          _log('scollegamento', e);
        }
      }
      if (_closed) break;
      await Future.any([Future<void>.delayed(wait), _closing.future]);
      // Ricerca vuota o collegamento mai riuscito: attese crescenti, per non
      // scaricare la batteria né far limitare le ricerche da Android.
      if (!linked) {
        final next = wait * 2;
        wait = next > const Duration(seconds: 8)
            ? const Duration(seconds: 8)
            : next;
      }
    }
  }

  Future<Peripheral?> _find() async {
    final hit = Completer<Peripheral>();
    final sub = _manager.discovered.listen((e) {
      if (hit.isCompleted) return;
      if (e.advertisement.serviceUUIDs.any((u) => _sameUuid(u, _service))) {
        hit.complete(e.peripheral);
      }
    });
    try {
      await _manager.startDiscovery(serviceUUIDs: [_service]);
      return await Future.any<Peripheral?>([
        hit.future,
        _closing.future.then((_) => null),
      ]).timeout(_scanTimeout, onTimeout: () => null);
    } finally {
      await sub.cancel();
      try {
        await _manager.stopDiscovery();
      } on Object catch (e) {
        _log('fine ricerca', e);
      }
    }
  }

  Future<void> _link(Peripheral p, Completer<void> gone) async {
    await _manager.connect(p).timeout(const Duration(seconds: 15));
    final services = await _manager.discoverGATT(p);
    final service = services.where((s) => _sameUuid(s.uuid, _service));
    if (service.isEmpty) throw StateError('servizio assente');
    GATTCharacteristic? rx;
    GATTCharacteristic? tx;
    for (final c in service.first.characteristics) {
      if (_sameUuid(c.uuid, _rxUuid)) rx = c;
      if (_sameUuid(c.uuid, _txUuid)) tx = c;
    }
    if (rx == null || tx == null) throw StateError('caratteristiche assenti');
    await _manager.setCharacteristicNotifyState(p, tx, state: true);
    try {
      final size = await _manager.getMaximumWriteLength(
        p,
        type: GATTCharacteristicWriteType.withResponse,
      );
      _chunkSize = _clampChunk(size);
    } on Object catch (e) {
      _log('lunghezza massima', e);
      _chunkSize = defaultBleChunk;
    }
    if (_closed) return;
    if (gone.isCompleted) throw StateError('collegamento perso');
    _rx = rx;
    _peripheral = p;
    if (!_connected.isClosed) _connected.add(null);
  }

  @override
  Future<void> write(Uint8List chunk) async {
    final p = _peripheral;
    final rx = _rx;
    if (_closed || p == null || rx == null) {
      throw const TransportUnavailable('bluetooth');
    }
    try {
      await _manager.writeCharacteristic(
        p,
        rx,
        value: chunk,
        type: GATTCharacteristicWriteType.withResponse,
      );
    } on Object catch (e) {
      _log('scrittura', e);
      throw const TransportUnavailable('bluetooth');
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_closing.isCompleted) _closing.complete();
    for (final s in _subs) {
      await s.cancel();
    }
    final p = _peripheral;
    _peripheral = null;
    _rx = null;
    if (p != null) {
      try {
        await _manager.disconnect(p);
      } on Object catch (e) {
        _log('chiusura', e);
      }
    }
    await _chunks.close();
    await _connected.close();
  }
}

/// Controlla permessi e Bluetooth prima di creare o unirsi a una partita
/// Bluetooth, così l'errore arriva subito alla schermata.
Future<void> checkBluetooth({required bool isHost}) =>
    ensureBluetoothReady(isHost ? PeripheralManager() : CentralManager());

/// Canale Bluetooth LE della partita, per `extraChannelFactories`: si apre
/// solo se l'invito lo prevede (`ble=1`), così una partita in Wi-Fi non
/// chiede permessi Bluetooth.
Future<MessageTransport?> openBleChannel(
  GameInvite invite, {
  required bool isHost,
}) async {
  if (!invite.ble) return null;
  final BleLink link = isHost
      ? await BlePeripheralLink.open(invite.gameId)
      : await BleCentralLink.open(invite.gameId);
  return BleTransport(link);
}
