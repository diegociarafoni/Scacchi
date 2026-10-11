import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Prefisso di ogni fotogramma: distingue i nostri QR da quelli estranei.
const transferPrefix = 'SC1';

/// Lunghezza oltre la quale un fotogramma non viene nemmeno analizzato.
const maxFrameLength = 4096;

/// Numero massimo di parti accettate da chi riceve.
const maxTransferFrames = 64;

const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
}, growable: false);

/// CRC-32 IEEE di [bytes].
int crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return c ^ 0xFFFFFFFF;
}

/// Base32 maiuscolo senza padding (RFC 4648).
String base32Encode(List<int> bytes) {
  final out = StringBuffer();
  var buffer = 0;
  var bits = 0;
  for (final b in bytes) {
    buffer = (buffer << 8 | b) & 0xFFFF;
    bits += 8;
    while (bits >= 5) {
      bits -= 5;
      out.write(_alphabet[(buffer >> bits) & 31]);
    }
  }
  if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
  return out.toString();
}

/// Inverso di [base32Encode]; `null` se [text] non è Base32 valido.
Uint8List? base32Decode(String text) {
  // Lunghezze 1, 3 e 6 modulo 8 non nascono da nessuna sequenza di byte.
  if (const {1, 3, 6}.contains(text.length % 8)) return null;
  final out = BytesBuilder(copy: false);
  var buffer = 0;
  var bits = 0;
  for (final ch in text.codeUnits) {
    final v = _alphabet.indexOf(String.fromCharCode(ch));
    if (v < 0) return null;
    buffer = (buffer << 5 | v) & 0xFFF;
    bits += 5;
    if (bits >= 8) {
      bits -= 8;
      out.addByte((buffer >> bits) & 0xFF);
    }
  }
  return out.takeBytes();
}

/// Divide [text] in fotogrammi QR. Il testo viene compresso (zlib, UTF-8) e
/// codificato in Base32 maiuscolo senza padding (RFC 4648), così ogni
/// fotogramma usa solo caratteri della modalità alfanumerica dei QR, più densa
/// della modalità byte.
///
/// Formato: `SC1/<ID>/<i>/<n>/<DATI>` con ID = CRC-32 dei byte compressi in 8
/// cifre esadecimali maiuscole, i da 1 a n in decimale. [maxDataLength] è il
/// numero massimo di caratteri Base32 per fotogramma.
List<String> encodeTransfer(String text, {int maxDataLength = 640}) {
  if (maxDataLength <= 0) {
    throw ArgumentError.value(
      maxDataLength,
      'maxDataLength',
      'deve essere > 0',
    );
  }
  final packed = ZLibCodec(level: 9).encode(utf8.encode(text));
  final id = _hexId(crc32(packed));
  final data = base32Encode(packed);
  final n = (data.length / maxDataLength).ceil();
  return [
    for (var i = 0; i < n; i++)
      '$transferPrefix/$id/${i + 1}/$n/${_slice(data, i, maxDataLength)}',
  ];
}

String _slice(String s, int i, int size) {
  final end = (i + 1) * size;
  return s.substring(i * size, end < s.length ? end : s.length);
}

String _hexId(int crc) => crc.toRadixString(16).toUpperCase().padLeft(8, '0');

/// Esito di [TransferAssembler.add].
sealed class TransferEvent {
  const TransferEvent();
}

/// Fotogramma nuovo memorizzato.
class FrameAccepted extends TransferEvent {
  const FrameAccepted(this.received, this.total);

  final int received;
  final int total;
}

/// Fotogramma già letto: il lettore vede lo stesso QR più volte.
class FrameDuplicate extends TransferEvent {
  const FrameDuplicate(this.received, this.total);

  final int received;
  final int total;
}

/// ID diverso: un'altra partita, si ricomincia da questo fotogramma.
class TransferRestarted extends TransferEvent {
  const TransferRestarted(this.received, this.total);

  final int received;
  final int total;
}

/// Tutti i fotogrammi sono arrivati e il testo è integro.
class TransferComplete extends TransferEvent {
  const TransferComplete(this.text);

  final String text;
}

/// Fotogramma scartato per il motivo [reason].
class FrameRejected extends TransferEvent {
  const FrameRejected(this.reason);

  final RejectReason reason;
}

/// Perché un fotogramma è stato scartato.
enum RejectReason { foreign, malformed, tooLarge, corrupted }

final _idPattern = RegExp(r'^[0-9A-F]{8}$');
final _numberPattern = RegExp(r'^[1-9][0-9]{0,8}$');
final _dataPattern = RegExp(r'^[A-Z2-7]+$');

class _TooLarge implements Exception {}

/// Ricompone i fotogrammi letti in qualunque ordine. I dati scansionati sono
/// considerati non affidabili: ogni fotogramma viene validato e il testo
/// decompresso non può superare [maxTextBytes].
class TransferAssembler {
  TransferAssembler({
    this.maxFrames = maxTransferFrames,
    this.maxTextBytes = 256 * 1024,
  });

  final int maxFrames;
  final int maxTextBytes;

  String? _id;
  int? _total;
  final _parts = <int, String>{};
  bool _complete = false;

  int get received => _parts.length;
  int? get total => _total;
  bool get complete => _complete;

  void reset() {
    _id = null;
    _total = null;
    _parts.clear();
    _complete = false;
  }

  TransferEvent add(String frame) {
    if (frame.length > maxFrameLength) {
      return const FrameRejected(RejectReason.tooLarge);
    }
    if (!frame.startsWith('$transferPrefix/')) {
      return const FrameRejected(RejectReason.foreign);
    }
    final f = frame.split('/');
    if (f.length != 5 ||
        !_idPattern.hasMatch(f[1]) ||
        !_numberPattern.hasMatch(f[2]) ||
        !_numberPattern.hasMatch(f[3])) {
      return const FrameRejected(RejectReason.malformed);
    }
    final (id, i, n, data) = (f[1], int.parse(f[2]), int.parse(f[3]), f[4]);
    if (n > maxFrames) return const FrameRejected(RejectReason.tooLarge);
    if (i > n || !_dataPattern.hasMatch(data)) {
      return const FrameRejected(RejectReason.malformed);
    }

    var restarted = false;
    if (id != _id) {
      restarted = _id != null;
      reset();
      _id = id;
      _total = n;
    } else if (n != _total) {
      return const FrameRejected(RejectReason.malformed);
    } else if (_complete) {
      return FrameDuplicate(n, n);
    }

    final stored = _parts[i];
    if (stored != null) {
      // Un dato diverso con lo stesso indice è sospetto: si tiene il primo.
      return stored == data
          ? FrameDuplicate(received, n)
          : const FrameRejected(RejectReason.malformed);
    }
    _parts[i] = data;
    if (received < n) {
      return restarted
          ? TransferRestarted(received, n)
          : FrameAccepted(received, n);
    }
    final result = _assemble(id, n);
    if (result is TransferComplete) {
      _complete = true;
    } else {
      // Si azzera così l'utente può ripetere la scansione da capo.
      reset();
    }
    return result;
  }

  TransferEvent _assemble(String id, int n) {
    final packed = base32Decode(
      [for (var i = 1; i <= n; i++) _parts[i]].join(),
    );
    if (packed == null || _hexId(crc32(packed)) != id) {
      return const FrameRejected(RejectReason.corrupted);
    }
    final out = BytesBuilder(copy: false);
    final limited = _LimitedSink(out, maxTextBytes);
    try {
      // Decompressione a blocchi: ci si ferma appena si supera il limite,
      // senza mai tenere in memoria una zip bomb intera.
      final decoder = ZLibCodec().decoder.startChunkedConversion(limited);
      for (var s = 0; s < packed.length; s += 1024) {
        final e = s + 1024 < packed.length ? s + 1024 : packed.length;
        decoder.addSlice(packed, s, e, false);
      }
      decoder.close();
      return TransferComplete(utf8.decode(out.takeBytes()));
    } on _TooLarge {
      return const FrameRejected(RejectReason.tooLarge);
    } on FormatException {
      return const FrameRejected(RejectReason.corrupted);
    }
  }
}

class _LimitedSink implements Sink<List<int>> {
  _LimitedSink(this._out, this._limit);

  final BytesBuilder _out;
  final int _limit;

  @override
  void add(List<int> chunk) {
    if (_out.length + chunk.length > _limit) throw _TooLarge();
    _out.add(chunk);
  }

  @override
  void close() {}
}
