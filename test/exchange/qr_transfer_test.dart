import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/exchange/qr_transfer.dart';

const shortPgn =
    '[Event "Amichevole"]\n[White "Città"]\n[Black "Più"]\n'
    '[Result "1-0"]\n\n1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7# 1-0';

/// PGN lungo e poco comprimibile: obbliga a usare più fotogrammi.
String longPgn() {
  final rnd = Random(7);
  const files = 'abcdefgh';
  const pieces = ['', 'N', 'B', 'R', 'Q', 'K'];
  final b = StringBuffer('[Event "Torneo di Città di Castello"]\n\n');
  for (var i = 1; i <= 200; i++) {
    String move() =>
        '${pieces[rnd.nextInt(6)]}${files[rnd.nextInt(8)]}${rnd.nextInt(8) + 1}';
    b.write('$i. ${move()} ${move()} {perché è così} ');
  }
  return '$b*';
}

/// Fotogramma con dati arbitrari ma ID coerente con essi.
List<String> framesFor(List<int> bytes) {
  final id = crc32(bytes).toRadixString(16).toUpperCase().padLeft(8, '0');
  return ['$transferPrefix/$id/1/1/${base32Encode(bytes)}'];
}

TransferEvent feed(TransferAssembler a, Iterable<String> frames) {
  late TransferEvent last;
  for (final f in frames) {
    last = a.add(f);
  }
  return last;
}

Matcher rejected(RejectReason reason) =>
    isA<FrameRejected>().having((e) => e.reason, 'reason', reason);

Matcher completedWith(String text) =>
    isA<TransferComplete>().having((e) => e.text, 'text', text);

void main() {
  test('Cap. 7 scambio QR: CRC-32 rispetta il vettore standard', () {
    expect(crc32(ascii.encode('123456789')), 0xCBF43926);
    expect(crc32(const []), 0);
  });

  test('Cap. 7 scambio QR: Base32 rispetta i vettori della RFC 4648', () {
    const vectors = {
      '': '',
      'f': 'MY',
      'fo': 'MZXQ',
      'foo': 'MZXW6',
      'foob': 'MZXW6YQ',
      'fooba': 'MZXW6YTB',
      'foobar': 'MZXW6YTBOI',
    };
    vectors.forEach((plain, encoded) {
      expect(base32Encode(ascii.encode(plain)), encoded);
      expect(base32Decode(encoded), ascii.encode(plain));
    });
    expect(base32Decode('MZ1Q'), isNull);
    expect(base32Decode('M'), isNull);
  });

  test('Cap. 7 scambio QR: un PGN breve sta in un solo fotogramma', () {
    final frames = encodeTransfer(shortPgn);
    expect(frames, hasLength(1));
    expect(frames.single, matches(RegExp(r'^SC1/[0-9A-F]{8}/1/1/[A-Z2-7]+$')));
    final a = TransferAssembler();
    expect(a.add(frames.single), completedWith(shortPgn));
    expect(a.complete, isTrue);
    expect(a.received, 1);
    expect(a.total, 1);
  });

  test('Cap. 7 scambio QR: un PGN lungo si divide e si ricompone', () {
    final text = longPgn();
    final frames = encodeTransfer(text, maxDataLength: 200);
    expect(frames.length, greaterThan(3));
    final a = TransferAssembler();
    for (var i = 0; i < frames.length - 1; i++) {
      expect(
        a.add(frames[i]),
        isA<FrameAccepted>()
            .having((e) => e.received, 'received', i + 1)
            .having((e) => e.total, 'total', frames.length),
      );
      expect(a.complete, isFalse);
    }
    expect(a.add(frames.last), completedWith(text));
  });

  test('Cap. 7 scambio QR: ordine casuale e doppioni non contano', () {
    final text = longPgn();
    final frames = encodeTransfer(text, maxDataLength: 150);
    final shuffled = [...frames, ...frames.take(3)]..shuffle(Random(3));
    final a = TransferAssembler();
    final events = [for (final f in shuffled) a.add(f)];
    expect(events.whereType<TransferComplete>().single.text, text);
    expect(events.whereType<FrameDuplicate>(), hasLength(3));
    expect(a.add(frames.first), isA<FrameDuplicate>());
  });

  test(
    'Cap. 7 scambio QR: i fotogrammi usano solo la modalità alfanumerica',
    () {
      const maxData = 120;
      final frames = encodeTransfer(longPgn(), maxDataLength: maxData);
      for (final f in frames) {
        expect(f, matches(RegExp(r'^[0-9A-Z $%*+\-./:]+$')));
        final header = f.lastIndexOf('/') + 1;
        expect(f.length, lessThanOrEqualTo(maxData + header));
      }
    },
  );

  test('Cap. 7 scambio QR: anche il testo vuoto fa il giro completo', () {
    final frames = encodeTransfer('');
    expect(frames, hasLength(1));
    expect(TransferAssembler().add(frames.single), completedWith(''));
  });

  test('Cap. 7 scambio QR: maxDataLength deve essere positivo', () {
    expect(() => encodeTransfer('x', maxDataLength: 0), throwsArgumentError);
    expect(() => encodeTransfer('x', maxDataLength: -5), throwsArgumentError);
  });

  test('Cap. 7 scambio QR: un QR estraneo viene ignorato', () {
    final a = TransferAssembler();
    expect(a.add('https://example.com'), rejected(RejectReason.foreign));
    expect(a.add(''), rejected(RejectReason.foreign));
    expect(a.received, 0);
    expect(a.total, isNull);
  });

  test('Cap. 7 scambio QR: i fotogrammi malformati vengono scartati', () {
    const bad = [
      'SC1/',
      'SC1/0A1B2C3D/1/2',
      'SC1/0A1B2C3D/1/2/MY/X',
      'SC1/0a1b2c3d/1/2/MY',
      'SC1/0A1B2C3/1/2/MY',
      'SC1/0A1B2C3G/1/2/MY',
      'SC1/0A1B2C3D/0/2/MY',
      'SC1/0A1B2C3D/-1/2/MY',
      'SC1/0A1B2C3D/01/2/MY',
      'SC1/0A1B2C3D/1/0/MY',
      'SC1/0A1B2C3D/x/2/MY',
      'SC1/0A1B2C3D/3/2/MY',
      'SC1/0A1B2C3D/1/2/',
      'SC1/0A1B2C3D/1/2/my',
      'SC1/0A1B2C3D/1/2/MY8',
      'SC1/0A1B2C3D/1/2/MY=',
    ];
    final a = TransferAssembler();
    for (final f in bad) {
      expect(a.add(f), rejected(RejectReason.malformed), reason: f);
    }
    expect(a.received, 0);
  });

  test('Cap. 7 scambio QR: n diverso o dati diversi per lo stesso ID', () {
    final frames = encodeTransfer(longPgn(), maxDataLength: 200);
    final parts = frames.first.split('/');
    final a = TransferAssembler();
    expect(a.add(frames.first), isA<FrameAccepted>());
    final otherTotal = [...parts]..[3] = '${frames.length + 1}';
    expect(a.add(otherTotal.join('/')), rejected(RejectReason.malformed));
    final otherData = [...parts]..[4] = 'AAAA';
    expect(a.add(otherData.join('/')), rejected(RejectReason.malformed));
    expect(a.received, 1);
    expect(feed(a, frames.skip(1)), isA<TransferComplete>());
  });

  test('Cap. 7 scambio QR: troppi fotogrammi o fotogramma enorme', () {
    final a = TransferAssembler(maxFrames: 4);
    expect(a.add('SC1/0A1B2C3D/1/5/MY'), rejected(RejectReason.tooLarge));
    expect(
      TransferAssembler().add('SC1/0A1B2C3D/1/999999/MY'),
      rejected(RejectReason.tooLarge),
    );
    expect(
      a.add('SC1/0A1B2C3D/1/1/${'A' * 5000}'),
      rejected(RejectReason.tooLarge),
    );
  });

  test('Cap. 7 scambio QR: dati alterati danno corrupted e si ricomincia', () {
    final frames = encodeTransfer(longPgn(), maxDataLength: 200);
    final parts = frames.first.split('/');
    parts[4] = (parts[4][0] == 'A' ? 'B' : 'A') + parts[4].substring(1);
    final a = TransferAssembler();
    expect(
      feed(a, [parts.join('/'), ...frames.skip(1)]),
      rejected(RejectReason.corrupted),
    );
    expect(a.received, 0);
    expect(a.complete, isFalse);
    expect(feed(a, frames), isA<TransferComplete>());
  });

  test('Cap. 7 scambio QR: zlib o UTF-8 non validi danno corrupted', () {
    final notZlib = framesFor([1, 2, 3, 4, 5]);
    expect(
      TransferAssembler().add(notZlib.single),
      rejected(RejectReason.corrupted),
    );
    final badUtf8 = framesFor(ZLibCodec().encode([0xC3, 0x28, 0xFF]));
    expect(
      TransferAssembler().add(badUtf8.single),
      rejected(RejectReason.corrupted),
    );
  });

  test('Cap. 7 scambio QR: una zip bomb viene fermata', () {
    final frames = encodeTransfer('a' * (1024 * 1024));
    final a = TransferAssembler(maxTextBytes: 1024);
    expect(feed(a, frames), rejected(RejectReason.tooLarge));
    expect(a.complete, isFalse);
    expect(a.received, 0);
  });

  test('Cap. 7 scambio QR: un ID diverso fa ricominciare', () {
    final first = encodeTransfer(longPgn(), maxDataLength: 200);
    final second = encodeTransfer('${longPgn()} altro', maxDataLength: 200);
    final a = TransferAssembler();
    feed(a, first.take(2));
    expect(a.received, 2);
    expect(
      a.add(second[1]),
      isA<TransferRestarted>()
          .having((e) => e.received, 'received', 1)
          .having((e) => e.total, 'total', second.length),
    );
    expect(feed(a, second), isA<TransferComplete>());
    expect(a.add(second.first), isA<FrameDuplicate>());
    expect(a.add(encodeTransfer(shortPgn).single), completedWith(shortPgn));
    a.reset();
    expect(a.received, 0);
    expect(a.total, isNull);
  });
}
