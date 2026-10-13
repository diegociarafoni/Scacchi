import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'game_message.dart';
import 'player_identity.dart';

/// Dimensione massima di un messaggio sigillato: oltre non si decifra.
const maxSealedLength = 1024;

const _nonceLength = 12;
const _macLength = 16;

/// Messaggio aperto e verificato, con la chiave pubblica di chi l'ha firmato.
class OpenedMessage {
  const OpenedMessage(this.message, this.author);

  final GameMessage message;
  final Uint8List author;
}

/// Sigilla i messaggi di una partita: firma Ed25519 dell'autore, poi
/// cifratura AES-256-GCM con una chiave derivata dal segreto dell'invito.
/// Formato: nonce (12) | testo cifrato | MAC (16). Il canale e il relay
/// vedono solo byte casuali.
class MessageCodec {
  MessageCodec({required this.gameId, required List<int> secret})
    : _key = Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
        secretKey: SecretKey(secret),
        nonce: utf8.encode(gameId),
        info: utf8.encode('scacchi-messaggi-v1'),
      );

  final String gameId;
  final Future<SecretKey> _key;

  static final _aes = AesGcm.with256bits();

  Future<Uint8List> seal(GameMessage message, PlayerIdentity author) async {
    final body = utf8.encode(jsonEncode(message.toJson()));
    final signature = await author.sign(_signed(body, author.publicKey));
    final clear = utf8.encode(
      jsonEncode({
        'a': base64.encode(author.publicKey),
        'b': base64.encode(body),
        's': base64.encode(signature),
      }),
    );
    final box = await _aes.encrypt(
      clear,
      secretKey: await _key,
      aad: utf8.encode(gameId),
    );
    return box.concatenation();
  }

  /// `null` se i byte non sono un messaggio integro e firmato di questa
  /// partita: i dati del canale non sono fidati.
  Future<OpenedMessage?> open(Uint8List sealed) async {
    if (sealed.length < _nonceLength + _macLength + 2 ||
        sealed.length > maxSealedLength) {
      return null;
    }
    try {
      final box = SecretBox.fromConcatenation(
        sealed,
        nonceLength: _nonceLength,
        macLength: _macLength,
      );
      final clear = await _aes.decrypt(
        box,
        secretKey: await _key,
        aad: utf8.encode(gameId),
      );
      final outer = jsonDecode(utf8.decode(clear));
      if (outer case {
        'a': final String a,
        'b': final String b,
        's': final String s,
      }) {
        final author = base64.decode(a);
        final body = base64.decode(b);
        final ok = await verifySignature(
          _signed(body, author),
          base64.decode(s),
          author,
        );
        if (!ok) return null;
        final message = GameMessage.fromJson(jsonDecode(utf8.decode(body)));
        return message == null ? null : OpenedMessage(message, author);
      }
      return null;
    } on SecretBoxAuthenticationError {
      return null;
    } on FormatException {
      return null;
    }
  }

  // La firma lega messaggio, partita e autore: non si riusa altrove.
  List<int> _signed(List<int> body, List<int> author) => [
    ...utf8.encode('scacchi-mossa-v1|$gameId|'), // l10n-ok
    ...author,
    ...body,
  ];
}
