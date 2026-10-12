import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'transport.dart';

/// Dimensione massima di un pacchetto: oltre si chiude il collegamento.
const maxLanFrame = 4096;

/// Canale in rete locale (stessa Wi-Fi o hotspot) su TCP. Ogni messaggio
/// viaggia con la sua lunghezza su 4 byte big-endian davanti. Chi ospita
/// ascolta, l'invitato si collega al primo invio e, se il collegamento cade,
/// si ricollega da solo con attese crescenti. Autenticità e riservatezza sono
/// garantite dal sigillo dei messaggi, non dal canale.
///
/// Limite noto: un invio riuscito vuol dire consegnato al sistema operativo,
/// non letto dall'altro telefono; se il collegamento era già morto senza
/// saperlo, la mossa riparte al ricollegamento grazie a `resendLast`.
class LanTransport implements MessageTransport, ConnectionAware {
  LanTransport._(this._server, this._remoteHost, this._remotePort, this._max);

  static Future<LanTransport> host({
    InternetAddress? address,
    int port = 0,
    int maxConnections = 4,
  }) async {
    final server = await ServerSocket.bind(
      address ?? InternetAddress.anyIPv4,
      port,
    );
    final t = LanTransport._(server, null, null, maxConnections);
    t._serverSub = server.listen(t._accept);
    return t;
  }

  factory LanTransport.connect(String host, int port) =>
      LanTransport._(null, host, port, 1);

  final ServerSocket? _server;
  final String? _remoteHost;
  final int? _remotePort;
  final int _max;
  StreamSubscription<Socket>? _serverSub;

  final _sockets = <Socket>[];
  final _incoming = StreamController<Uint8List>.broadcast();
  final _connected = StreamController<void>.broadcast();
  bool _closed = false;

  @override
  String get name => 'wifi';

  /// Porta su cui l'ospite ascolta.
  int get port => _server?.port ?? _remotePort!;

  int get connections => _sockets.length;

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  Stream<void> get connected => _connected.stream;

  // Oltre il limite si chiude il collegamento più vecchio: un telefono
  // uscito dalla Wi-Fi senza chiudere non deve bloccare il suo rientro.
  void _accept(Socket socket) {
    if (_sockets.length >= _max) _drop(_sockets.first);
    _attach(socket, notify: true);
  }

  void _attach(Socket socket, {required bool notify}) {
    if (_closed) {
      socket.destroy();
      return;
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    _sockets.add(socket);
    _backoff = _minBackoff;
    final decoder = _FrameDecoder();
    socket.listen(
      (chunk) {
        decoder.add(chunk).forEach(_incoming.add);
        if (decoder.failed) _drop(socket);
      },
      onDone: () => _drop(socket),
      onError: (Object _) => _drop(socket),
      cancelOnError: true,
    );
    if (notify && !_connected.isClosed) _connected.add(null);
  }

  void _drop(Socket socket) {
    if (!_sockets.remove(socket)) return;
    socket.destroy();
    if (_remoteHost != null) _scheduleRedial();
  }

  static const _minBackoff = Duration(seconds: 1);
  static const _maxBackoff = Duration(seconds: 15);
  Duration _backoff = _minBackoff;
  Timer? _redial;

  // L'invitato si ricollega da solo, anche senza nulla da inviare: altrimenti
  // l'ospite non potrebbe consegnargli la sua mossa.
  void _scheduleRedial() {
    if (_closed || _redial != null || _sockets.isNotEmpty) return;
    _redial = Timer(_backoff, () async {
      _redial = null;
      if (_closed || _sockets.isNotEmpty) return;
      await _dial(notify: true);
      if (_sockets.isEmpty) {
        final next = _backoff * 2;
        _backoff = next > _maxBackoff ? _maxBackoff : next;
        _scheduleRedial();
      }
    });
  }

  @override
  Future<void> send(Uint8List data) async {
    if (_closed) throw TransportUnavailable(name);
    if (_sockets.isEmpty && _remoteHost != null) await _dial(notify: false);
    final frame = _frame(data);
    var delivered = false;
    for (final s in List.of(_sockets)) {
      try {
        s.add(frame);
        // Chi non legge più non deve bloccare gli invii.
        await s.flush().timeout(const Duration(seconds: 5));
        delivered = true;
      } on SocketException {
        _drop(s);
      } on StateError {
        _drop(s);
      } on TimeoutException {
        _drop(s);
      }
    }
    if (!delivered) throw TransportUnavailable(name);
  }

  Future<void>? _dialing;

  // Un solo tentativo alla volta, anche con più invii contemporanei.
  Future<void> _dial({required bool notify}) =>
      _dialing ??= _connect(notify).whenComplete(() => _dialing = null);

  Future<void> _connect(bool notify) async {
    try {
      final socket = await Socket.connect(
        _remoteHost,
        _remotePort!,
        timeout: const Duration(seconds: 3),
      );
      if (_sockets.isNotEmpty) {
        socket.destroy();
        return;
      }
      _attach(socket, notify: notify);
    } on SocketException {
      // Ospite non raggiungibile ora: l'invio fallisce e si riproverà.
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    _redial?.cancel();
    await _serverSub?.cancel();
    await _server?.close();
    for (final s in List.of(_sockets)) {
      _drop(s);
    }
    await _incoming.close();
    await _connected.close();
  }
}

Uint8List _frame(Uint8List data) {
  final out = Uint8List(4 + data.length);
  ByteData.sublistView(out).setUint32(0, data.length);
  out.setRange(4, out.length, data);
  return out;
}

/// Ricompone i pacchetti da un flusso TCP spezzato in qualunque punto.
/// Dopo un pacchetto troppo grande [failed] diventa vero: i pacchetti validi
/// già ricomposti vengono comunque restituiti.
class _FrameDecoder {
  final _buffer = BytesBuilder();
  bool failed = false;

  List<Uint8List> add(List<int> chunk) {
    if (failed) return const [];
    _buffer.add(chunk);
    var bytes = _buffer.takeBytes();
    final frames = <Uint8List>[];
    while (bytes.length >= 4) {
      final length = ByteData.sublistView(bytes).getUint32(0);
      if (length > maxLanFrame) {
        failed = true;
        return frames;
      }
      if (bytes.length < 4 + length) break;
      frames.add(Uint8List.fromList(bytes.sublist(4, 4 + length)));
      bytes = bytes.sublist(4 + length);
    }
    _buffer.add(bytes);
    return frames;
  }
}
