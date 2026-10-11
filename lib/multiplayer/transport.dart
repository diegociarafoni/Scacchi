import 'dart:async';
import 'dart:typed_data';

/// Il canale non può consegnare in questo momento.
class TransportUnavailable implements Exception {
  const TransportUnavailable(this.channel);

  final String channel;

  @override
  String toString() => 'TransportUnavailable($channel)';
}

/// Un "postino" che porta byte opachi all'altro telefono: Wi-Fi locale,
/// Bluetooth LE o relay. Non garantisce la consegna né l'ordine.
abstract interface class MessageTransport {
  String get name;
  Stream<Uint8List> get incoming;

  /// Lancia [TransportUnavailable] se il canale non è raggiungibile.
  Future<void> send(Uint8List data);

  Future<void> close();
}

/// Tutti i canali disponibili insieme: si invia su ognuno e si riceve da
/// tutti. I doppioni li scarta il registro della partita.
class MultiTransport implements MessageTransport {
  MultiTransport(Iterable<MessageTransport> channels) {
    channels.forEach(add);
  }

  final _channels = <MessageTransport>[];
  final _subs = <StreamSubscription<Uint8List>>[];
  final _incoming = StreamController<Uint8List>.broadcast();

  @override
  String get name => _channels.map((c) => c.name).join('+');

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  /// Aggiunge un canale appena diventa disponibile, anche a partita in corso.
  void add(MessageTransport channel) {
    if (_incoming.isClosed) {
      unawaited(channel.close());
      return;
    }
    _channels.add(channel);
    _subs.add(channel.incoming.listen(_incoming.add, onError: (_) {}));
  }

  @override
  Future<void> send(Uint8List data) async {
    final results = await Future.wait([
      for (final c in _channels)
        c.send(data).then((_) => true, onError: (Object _) => false),
    ]);
    if (!results.contains(true)) throw TransportUnavailable(name);
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    for (final c in _channels) {
      await c.close();
    }
    await _incoming.close();
  }
}

/// Canale in memoria per i test e per giocare su due istanze nello stesso
/// processo; [online] simula la perdita del collegamento.
class LoopbackTransport implements MessageTransport {
  LoopbackTransport._(this.name);

  static (LoopbackTransport, LoopbackTransport) pair({String name = 'loop'}) {
    final a = LoopbackTransport._(name);
    final b = LoopbackTransport._(name);
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  @override
  final String name;

  /// Vale per entrambi i versi: un collegamento caduto non porta nulla.
  bool online = true;

  late LoopbackTransport _peer;
  final _incoming = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Future<void> send(Uint8List data) async {
    if (!online || !_peer.online || _peer._incoming.isClosed) {
      throw TransportUnavailable(name);
    }
    _peer._incoming.add(data);
  }

  @override
  Future<void> close() => _incoming.close();
}
