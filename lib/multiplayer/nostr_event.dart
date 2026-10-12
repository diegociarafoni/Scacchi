import 'dart:convert';
import 'dart:math';

import 'package:bip340/bip340.dart' as schnorr;
import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:dartchess/dartchess.dart';

/// Tipo di evento Nostr "sostituibile con parametro" (NIP-33/NIP-78): per
/// ogni (autore, tipo, tag `d`) il relay tiene solo l'ultimo evento.
const nostrGameKind = 30078;

/// Slot per lato: poche mosse sono in volo alla volta, ma un messaggio di
/// servizio non deve cancellare l'ultima mossa ancora da consegnare.
const relaySlots = 4;

/// Lunghezza massima del contenuto di un evento (base64 di un messaggio
/// sigillato di al più 1024 byte): oltre l'evento si scarta.
const maxEventContent = 2048;

final _hex64 = RegExp(r'^[0-9a-f]{64}$');
final _hex128 = RegExp(r'^[0-9a-f]{128}$');

String _hex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

/// Evento Nostr (NIP-01). Per i relay è un oggetto qualsiasi con id e firma;
/// il contenuto è il messaggio già sigillato della partita.
class NostrEvent {
  const NostrEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  final String id;
  final String pubkey;
  final int createdAt;
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  /// Serializzazione da cui si calcola l'id: compatta, senza spazi.
  static String serialize(
    String pubkey,
    int createdAt,
    int kind,
    List<List<String>> tags,
    String content,
  ) => jsonEncode([0, pubkey, createdAt, kind, tags, content]);

  static String computeId(
    String pubkey,
    int createdAt,
    int kind,
    List<List<String>> tags,
    String content,
  ) => hash.sha256
      .convert(utf8.encode(serialize(pubkey, createdAt, kind, tags, content)))
      .toString();

  /// Valore del primo tag [name], se c'è.
  String? tag(String name) {
    for (final t in tags) {
      if (t.length >= 2 && t[0] == name) return t[1];
    }
    return null;
  }

  /// L'id corrisponde al contenuto e la firma Schnorr (BIP-340) è dell'autore.
  bool get isValid {
    if (id != computeId(pubkey, createdAt, kind, tags, content)) return false;
    try {
      return schnorr.verify(pubkey, id, sig);
    } on Object {
      return false;
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'pubkey': pubkey,
    'created_at': createdAt,
    'kind': kind,
    'tags': tags,
    'content': content,
    'sig': sig,
  };

  /// `null` se [json] (dato del relay, non fidato) non ha la forma di un
  /// evento: la validità della firma si controlla a parte con [isValid].
  static NostrEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final pubkey = json['pubkey'];
    final createdAt = json['created_at'];
    final kind = json['kind'];
    final tags = json['tags'];
    final content = json['content'];
    final sig = json['sig'];
    if (id is! String || !_hex64.hasMatch(id)) return null;
    if (pubkey is! String || !_hex64.hasMatch(pubkey)) return null;
    if (createdAt is! int || kind is! int) return null;
    if (content is! String || content.length > maxEventContent) return null;
    if (sig is! String || !_hex128.hasMatch(sig)) return null;
    if (tags is! List || tags.length > 16) return null;
    final parsed = <List<String>>[];
    for (final t in tags) {
      if (t is! List || t.isEmpty || t.length > 8) return null;
      if (t.any((x) => x is! String || x.length > 128)) return null;
      parsed.add([for (final x in t) x as String]);
    }
    return NostrEvent(
      id: id,
      pubkey: pubkey,
      createdAt: createdAt,
      kind: kind,
      tags: parsed,
      content: content,
      sig: sig,
    );
  }
}

final _random = Random.secure();

/// Chiave Nostr e slot di una partita, derivati dal segreto dell'invito: i
/// due telefoni li ricavano uguali senza scambiarsi altro. Il relay vede
/// una chiave pubblica casuale per partita e nient'altro; l'autenticità delle
/// mosse non dipende da questa chiave ma dalla firma dei messaggi sigillati.
class RelayKeys {
  RelayKeys._(this._privateKey, this.publicKey, this._slots);

  final String _privateKey;

  /// Chiave pubblica (x-only, esadecimale) con cui si firmano gli eventi.
  final String publicKey;
  final Map<Side, List<String>> _slots;

  static Future<List<int>> _derive(
    String gameId,
    List<int> secret,
    String info,
    int length,
  ) async {
    final key = await Hkdf(hmac: Hmac.sha256(), outputLength: length).deriveKey(
      secretKey: SecretKey(secret),
      nonce: utf8.encode(gameId),
      info: utf8.encode(info),
    );
    return key.extractBytes();
  }

  static Future<RelayKeys> derive(String gameId, List<int> secret) async {
    // Una chiave fuori dalla curva è praticamente impossibile; in tal caso
    // si passa al contatore successivo, uguale per entrambi i telefoni.
    String? priv;
    String? pub;
    for (var i = 0; pub == null; i++) {
      final candidate = _hex(
        await _derive(gameId, secret, 'scacchi-relay-chiave-v1|$i', 32),
      );
      try {
        pub = schnorr.getPublicKey(candidate);
        priv = candidate;
      } on Object {
        pub = null;
      }
    }
    final slots = <Side, List<String>>{};
    for (final side in Side.values) {
      slots[side] = [
        for (var i = 0; i < relaySlots; i++)
          _hex(
            await _derive(
              gameId,
              secret,
              'scacchi-relay-slot-v1|${side.name}|$i',
              16,
            ),
          ),
      ];
    }
    return RelayKeys._(priv!, pub, slots);
  }

  /// Valori del tag `d` che appartengono al lato [side].
  List<String> slots(Side side) => _slots[side]!;

  NostrEvent sign({
    required String slot,
    required String content,
    int? createdAt,
  }) {
    final at = createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = [
      ['d', slot],
    ];
    final id = NostrEvent.computeId(
      publicKey,
      at,
      nostrGameKind,
      tags,
      content,
    );
    final aux = _hex(List.generate(32, (_) => _random.nextInt(256)));
    return NostrEvent(
      id: id,
      pubkey: publicKey,
      createdAt: at,
      kind: nostrGameKind,
      tags: tags,
      content: content,
      sig: schnorr.sign(_privateKey, id, aux),
    );
  }
}
