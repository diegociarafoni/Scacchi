import 'dart:async';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';

import 'ble_fragmenter.dart';
import 'transport.dart';

/// Estremo di un collegamento Bluetooth LE verso l'altro telefono: porta
/// pacchetti di al più [chunkSize] byte, senza sapere cosa contengono.
abstract interface class BleLink {
  /// Pacchetti arrivati dall'altro telefono.
  Stream<Uint8List> get chunks;

  /// L'altro telefono si è (ri)collegato.
  Stream<void> get connected;

  bool get isLinked;

  /// Byte massimi di un pacchetto, secondo l'MTU negoziata.
  int get chunkSize;

  /// Lancia [TransportUnavailable] se l'altro telefono non è collegato.
  Future<void> write(Uint8List chunk);

  Future<void> close();
}

/// UUID del servizio GATT di una partita: derivato dall'id con SHA-256, così
/// chi cerca ritrova solo l'ospite giusto e chi ascolta l'etere non ricava
/// l'id dall'annuncio.
String bleServiceUuid(String gameId) {
  final hash = const DartSha256()
      .hashSync('scacchi-ble-v1|$gameId'.codeUnits)
      .bytes;
  final h = [for (final b in hash.take(16)) b.toRadixString(16).padLeft(2, '0')]
      .join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Canale Bluetooth LE: spezza ogni messaggio sigillato nei pacchetti del
/// collegamento e li ricompone dall'altra parte. Funziona senza Wi-Fi né
/// rete; autenticità e riservatezza vengono dal sigillo, non dal canale.
class BleTransport implements MessageTransport, ConnectionAware {
  BleTransport(this._link) {
    _sub = _link.chunks.listen((chunk) {
      final message = _reassembler.add(chunk);
      if (message != null && !_incoming.isClosed) _incoming.add(message);
    }, onError: (Object _) {});
    _connSub = _link.connected.listen((_) {
      if (!_connected.isClosed) _connected.add(null);
    });
  }

  final BleLink _link;
  final _fragmenter = BleFragmenter();
  final _reassembler = BleReassembler();
  late final StreamSubscription<Uint8List> _sub;
  late final StreamSubscription<void> _connSub;
  final _incoming = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  Future<void> _writes = Future.value();
  bool _closed = false;

  @override
  String get name => 'bluetooth';

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Stream<void> get connected => _connected.stream;

  @override
  Future<void> send(Uint8List data) {
    if (_closed || !_link.isLinked) {
      return Future.error(TransportUnavailable(name));
    }
    final List<Uint8List> parts;
    try {
      parts = _fragmenter.split(data, _link.chunkSize);
    } on ArgumentError {
      return Future.error(TransportUnavailable(name));
    }
    // Un messaggio alla volta: i suoi pacchetti non si mescolano con altri.
    final done = _writes.then((_) async {
      for (final part in parts) {
        await _link.write(part);
      }
    });
    _writes = done.then((_) {}, onError: (Object _) {});
    return done;
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _sub.cancel();
    await _connSub.cancel();
    await _link.close();
    await _incoming.close();
    await _connected.close();
  }
}
