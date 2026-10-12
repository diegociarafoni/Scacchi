import 'dart:convert';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/multiplayer/nostr_event.dart';

void main() {
  final secret = Uint8List.fromList(List.generate(32, (i) => i));
  const gameId = '3f1c2b9e-5d1a-4c7e-8b0a-1f2e3d4c5b6a';

  test('RMP-30 la chiave del relay è la stessa per i due telefoni', () async {
    final a = await RelayKeys.derive(gameId, secret);
    final b = await RelayKeys.derive(gameId, secret);
    expect(a.publicKey, b.publicKey);
    expect(a.publicKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(a.slots(Side.white), b.slots(Side.white));
  });

  test(
    'RMP-30 partita o segreto diversi danno chiavi e slot diversi',
    () async {
      final a = await RelayKeys.derive(gameId, secret);
      final other = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final b = await RelayKeys.derive(gameId, other);
      final c = await RelayKeys.derive(
        '3f1c2b9e-5d1a-4c7e-8b0a-1f2e3d4c5b6b',
        secret,
      );
      expect(b.publicKey, isNot(a.publicKey));
      expect(c.publicKey, isNot(a.publicKey));
      expect(b.slots(Side.white), isNot(a.slots(Side.white)));
    },
  );

  test(
    'RMP-30 ogni lato ha quattro slot distinti da quelli dell\'altro',
    () async {
      final k = await RelayKeys.derive(gameId, secret);
      final all = {...k.slots(Side.white), ...k.slots(Side.black)};
      expect(k.slots(Side.white), hasLength(relaySlots));
      expect(all, hasLength(2 * relaySlots));
    },
  );

  test('RMP-30 un evento firmato è valido e riconosciuto', () async {
    final k = await RelayKeys.derive(gameId, secret);
    final e = k.sign(
      slot: k.slots(Side.white).first,
      content: 'AAEC',
      createdAt: 100,
    );
    expect(e.isValid, isTrue);
    expect(e.kind, nostrGameKind);
    expect(e.pubkey, k.publicKey);
    final back = NostrEvent.fromJson(jsonDecode(jsonEncode(e.toJson())));
    expect(back, isNotNull);
    expect(back!.id, e.id);
    expect(back.isValid, isTrue);
  });

  test(
    'RMP-30 id e firma seguono NIP-01: sha256 della serializzazione',
    () async {
      final k = await RelayKeys.derive(gameId, secret);
      final e = k.sign(slot: 'ab', content: 'x', createdAt: 5);
      expect(
        e.id,
        NostrEvent.computeId(k.publicKey, 5, nostrGameKind, [
          ['d', 'ab'],
        ], 'x'),
      );
      // Serializzazione compatta e senza spazi, come chiedono i relay.
      expect(
        NostrEvent.serialize(k.publicKey, 5, nostrGameKind, [
          ['d', 'ab'],
        ], 'x'),
        '[0,"${k.publicKey}",5,30078,[["d","ab"]],"x"]',
      );
    },
  );

  test(
    'RMP-30 contenuto, id o firma alterati rendono l\'evento non valido',
    () async {
      final k = await RelayKeys.derive(gameId, secret);
      final e = k.sign(slot: 'ab', content: 'AAEC', createdAt: 7);
      Map<String, Object?> json() => Map.of(e.toJson());
      expect(
        NostrEvent.fromJson(json()..['content'] = 'AAED')!.isValid,
        isFalse,
      );
      expect(NostrEvent.fromJson(json()..['created_at'] = 8)!.isValid, isFalse);
      final other = k.sign(slot: 'ab', content: 'AAED', createdAt: 7);
      expect(
        NostrEvent.fromJson(json()..['sig'] = other.sig)!.isValid,
        isFalse,
      );
      expect(
        NostrEvent.fromJson(json()..['sig'] = 'zz')?.isValid ?? false,
        isFalse,
      );
    },
  );

  test(
    'RMP-30 un evento di un\'altra chiave non passa per valido di questa',
    () async {
      final k = await RelayKeys.derive(gameId, secret);
      final stranger = await RelayKeys.derive(gameId, Uint8List(32));
      final e = stranger.sign(slot: 'ab', content: 'AAEC', createdAt: 7);
      expect(e.isValid, isTrue);
      expect(e.pubkey, isNot(k.publicKey));
    },
  );

  test('RMP-30 le forme sbagliate si scartano senza eccezioni', () {
    expect(NostrEvent.fromJson(null), isNull);
    expect(NostrEvent.fromJson('x'), isNull);
    expect(NostrEvent.fromJson(<String, Object?>{}), isNull);
    final ok = {
      'id': 'a' * 64,
      'pubkey': 'b' * 64,
      'created_at': 1,
      'kind': nostrGameKind,
      'tags': [
        ['d', 'x'],
      ],
      'content': 'AA',
      'sig': 'c' * 128,
    };
    expect(NostrEvent.fromJson(ok), isNotNull);
    expect(NostrEvent.fromJson({...ok, 'id': 'zz'}), isNull);
    expect(NostrEvent.fromJson({...ok, 'created_at': '1'}), isNull);
    expect(NostrEvent.fromJson({...ok, 'tags': 'd'}), isNull);
    expect(
      NostrEvent.fromJson({
        ...ok,
        'tags': [
          [1, 2],
        ],
      }),
      isNull,
    );
    expect(NostrEvent.fromJson({...ok, 'content': 'A' * 5000}), isNull);
    expect(NostrEvent.fromJson({...ok, 'sig': 'c' * 10}), isNull);
  });
}
