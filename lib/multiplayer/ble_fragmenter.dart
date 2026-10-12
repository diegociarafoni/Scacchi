import 'dart:typed_data';

/// Dimensione massima di un messaggio ricomposto: oltre si scarta.
const maxBleMessage = 2048;

/// Messaggi incompleti tenuti in memoria insieme.
const maxPendingBleMessages = 4;

const _header = 4;

/// Spezza un messaggio nei pacchetti che il collegamento Bluetooth LE porta
/// in una volta (MTU meno 3 byte). Intestazione: identificatore del messaggio
/// su 2 byte, indice e numero dei frammenti su 1 byte ciascuno.
class BleFragmenter {
  int _next = 0;

  List<Uint8List> split(Uint8List data, int chunkSize) {
    if (chunkSize <= _header) throw ArgumentError('frammento troppo piccolo');
    if (data.length > maxBleMessage) {
      throw ArgumentError('messaggio troppo grande');
    }
    final room = chunkSize - _header;
    final count = data.isEmpty ? 1 : (data.length + room - 1) ~/ room;
    if (count > 255) throw ArgumentError('troppi frammenti');
    final id = _next;
    _next = (_next + 1) & 0xffff;
    return [
      for (var i = 0; i < count; i++)
        Uint8List(_header + _span(data.length, room, i))
          ..[0] = id >> 8
          ..[1] = id & 0xff
          ..[2] = i
          ..[3] = count
          ..setRange(
            _header,
            _header + _span(data.length, room, i),
            data.sublist(i * room, i * room + _span(data.length, room, i)),
          ),
    ];
  }

  static int _span(int total, int room, int i) =>
      (total - i * room).clamp(0, room);
}

class _Partial {
  _Partial(this.count);

  final int count;
  final parts = <int, Uint8List>{};
  int bytes = 0;
}

/// Ricompone i messaggi dai frammenti, in qualunque ordine e con doppioni.
/// L'ingresso è non fidato: ciò che non torna si scarta senza errori.
class BleReassembler {
  final _partials = <int, _Partial>{};

  int get pending => _partials.length;

  /// Restituisce il messaggio quando l'ultimo frammento è arrivato.
  Uint8List? add(Uint8List chunk) {
    if (chunk.length < _header) return null;
    final id = (chunk[0] << 8) | chunk[1];
    final index = chunk[2];
    final count = chunk[3];
    if (count == 0 || index >= count) return null;

    var partial = _partials[id];
    if (partial != null && partial.count != count) {
      _partials.remove(id);
      partial = null;
    }
    if (partial == null) {
      // Il più vecchio lascia posto: un mittente non può riempire la memoria.
      while (_partials.length >= maxPendingBleMessages) {
        _partials.remove(_partials.keys.first);
      }
      partial = _partials[id] = _Partial(count);
    }
    if (partial.parts.containsKey(index)) return null;
    partial.bytes += chunk.length - _header;
    if (partial.bytes > maxBleMessage) {
      _partials.remove(id);
      return null;
    }
    partial.parts[index] = Uint8List.sublistView(chunk, _header);
    if (partial.parts.length < count) return null;

    _partials.remove(id);
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < count; i++) {
      out.add(partial.parts[i]!);
    }
    return out.takeBytes();
  }
}
