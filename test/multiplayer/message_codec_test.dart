import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/multiplayer/game_message.dart';
import 'package:rokko/multiplayer/message_codec.dart';
import 'package:rokko/multiplayer/player_identity.dart';

const gameId = '0f8e2c1a-3b4d-4e5f-8a9b-1c2d3e4f5a6b';
final secret = Uint8List.fromList(List.generate(32, (i) => i));

void main() {
  late PlayerIdentity alice;
  late MessageCodec codec;

  setUpAll(() async {
    alice = await PlayerIdentity.generate();
  });
  setUp(() => codec = MessageCodec(gameId: gameId, secret: secret));

  const move = MoveMessage(seq: 1, uci: 'e2e4', positionHash: 'abcd');

  test(
    'RMP-03 RMP-04 un messaggio sigillato si riapre con autore e contenuto',
    () async {
      final sealed = await codec.seal(move, alice);
      final opened = await codec.open(sealed);
      expect(opened, isNotNull);
      expect(opened!.author, alice.publicKey);
      expect(opened.message, move);
    },
  );

  test('RMP-04 il contenuto viaggia cifrato', () async {
    final sealed = await codec.seal(move, alice);
    final text = String.fromCharCodes(sealed);
    expect(text, isNot(contains('e2e4')));
    expect(text, isNot(contains(gameId)));
  });

  test('RMP-04 due sigilli dello stesso messaggio sono diversi', () async {
    final a = await codec.seal(move, alice);
    final b = await codec.seal(move, alice);
    expect(a, isNot(b));
  });

  test('RMP-04 un byte alterato fa scartare il messaggio', () async {
    final sealed = await codec.seal(move, alice);
    for (final i in [0, 13, sealed.length ~/ 2, sealed.length - 1]) {
      final bad = Uint8List.fromList(sealed)..[i] ^= 1;
      expect(await codec.open(bad), isNull, reason: 'byte $i');
    }
  });

  test('RMP-04 con un altro segreto il messaggio non si apre', () async {
    final sealed = await codec.seal(move, alice);
    final other = MessageCodec(
      gameId: gameId,
      secret: Uint8List.fromList(List.filled(32, 1)),
    );
    expect(await other.open(sealed), isNull);
  });

  test('RMP-04 un messaggio di un\'altra partita non si apre', () async {
    final sealed = await codec.seal(move, alice);
    final other = MessageCodec(
      gameId: '11111111-2222-4333-8444-555555555555',
      secret: secret,
    );
    expect(await other.open(sealed), isNull);
  });

  test('RMP-04 dati corti, vuoti o enormi vengono scartati', () async {
    expect(await codec.open(Uint8List(0)), isNull);
    expect(await codec.open(Uint8List(20)), isNull);
    expect(await codec.open(Uint8List(maxSealedLength + 1)), isNull);
  });

  test('RMP-03 tutti i tipi di messaggio sopravvivono al viaggio', () async {
    const messages = <GameMessage>[
      JoinMessage(),
      MoveMessage(seq: 12, uci: 'e7e8q', positionHash: 'ff00'),
      SyncRequest(fromSeq: 3),
    ];
    for (final m in messages) {
      final opened = await codec.open(await codec.seal(m, alice));
      expect(opened?.message, m);
    }
  });

  test(
    'RMP-03 la firma copre l\'autore: chiave sostituita, messaggio rifiutato',
    () async {
      final mallory = await PlayerIdentity.generate();
      final forged = await codec.seal(move, _Impostor(alice, mallory));
      expect(await codec.open(forged), isNull);
    },
  );

  test('RMP-03 l\'identità si salva e si ripristina', () async {
    final restored = await PlayerIdentity.fromSeed(await alice.seed());
    expect(restored.publicKey, alice.publicKey);
    final opened = await codec.open(await codec.seal(move, restored));
    expect(opened?.author, alice.publicKey);
  });
}

/// Dichiara la chiave di [claimed] ma firma con quella di [signer].
class _Impostor implements PlayerIdentity {
  _Impostor(this.claimed, this.signer);

  final PlayerIdentity claimed;
  final PlayerIdentity signer;

  @override
  Uint8List get publicKey => claimed.publicKey;

  @override
  Future<Uint8List> sign(List<int> data) => signer.sign(data);

  @override
  Future<Uint8List> seed() => signer.seed();
}
