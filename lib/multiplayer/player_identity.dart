import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Chiave Ed25519 di un giocatore: firma le sue mosse così l'avversario sa
/// che vengono da lui, su qualunque canale arrivino.
abstract interface class PlayerIdentity {
  static final _ed25519 = Ed25519();

  static Future<PlayerIdentity> generate() async =>
      _Ed25519Identity.from(await _ed25519.newKeyPair());

  /// Ripristina l'identità dal seme salvato nel portachiavi di sistema.
  static Future<PlayerIdentity> fromSeed(List<int> seed) async =>
      _Ed25519Identity.from(await _ed25519.newKeyPairFromSeed(seed));

  Uint8List get publicKey;

  Future<Uint8List> sign(List<int> data);

  /// Seme privato di 32 byte, da conservare solo in un archivio sicuro.
  Future<Uint8List> seed();
}

/// Verifica una firma Ed25519 di [publicKey] su [data].
Future<bool> verifySignature(
  List<int> data,
  List<int> signature,
  List<int> publicKey,
) async {
  if (signature.length != 64 || publicKey.length != 32) return false;
  return PlayerIdentity._ed25519.verify(
    data,
    signature: Signature(
      signature,
      publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
    ),
  );
}

class _Ed25519Identity implements PlayerIdentity {
  _Ed25519Identity(this._pair, this.publicKey);

  static Future<_Ed25519Identity> from(SimpleKeyPair pair) async {
    final pub = await pair.extractPublicKey();
    return _Ed25519Identity(pair, Uint8List.fromList(pub.bytes));
  }

  final SimpleKeyPair _pair;

  @override
  final Uint8List publicKey;

  @override
  Future<Uint8List> sign(List<int> data) async {
    final s = await PlayerIdentity._ed25519.sign(data, keyPair: _pair);
    return Uint8List.fromList(s.bytes);
  }

  @override
  Future<Uint8List> seed() async =>
      Uint8List.fromList(await _pair.extractPrivateKeyBytes());
}
