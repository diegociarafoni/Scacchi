import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';

import '../game/clock.dart';

/// Versione del formato dell'invito.
const inviteVersion = 1;

/// Lunghezza oltre la quale un invito non viene nemmeno analizzato.
const maxInviteLength = 1024;

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
final _hostPattern = RegExp(r'^[0-9A-Za-z.\-]{1,253}$|^\[[0-9A-Fa-f:.]+\]$');

/// Limiti della cadenza accettata da un invito non fidato.
const maxInviteMinutes = 180;
const maxInviteIncrement = 60;

final _random = Random.secure();

Uint8List _randomBytes(int n) =>
    Uint8List.fromList(List.generate(n, (_) => _random.nextInt(256)));

/// UUID v4 (RFC 9562) da byte casuali crittograficamente sicuri.
String newGameId() {
  final b = _randomBytes(16);
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Segreto condiviso della partita, 256 bit.
Uint8List newSecret() => _randomBytes(32);

/// Invito a una partita: viaggia nel QR dell'abbinamento o in un link
/// condiviso. Contiene tutto il necessario per riconoscersi su qualunque
/// canale, quindi va trattato come una chiave.
class GameInvite {
  GameInvite({
    required this.gameId,
    required this.secret,
    required this.hostKey,
    required this.hostSide,
    this.lanAddress,
    this.timeControl,
  });

  final String gameId;
  final Uint8List secret;

  /// Chiave pubblica Ed25519 di chi ha creato la partita.
  final Uint8List hostKey;
  final Side hostSide;

  /// `host:porta` in rete locale, se l'ospite è raggiungibile così.
  final String? lanAddress;

  /// Cadenza scelta da chi crea la partita; `null` senza orologio.
  final TimeControl? timeControl;

  String toLink() => Uri(
    scheme: 'scacchi',
    host: 'partita',
    queryParameters: {
      'v': '$inviteVersion',
      'g': gameId,
      's': _b64(secret),
      'k': _b64(hostKey),
      'c': hostSide == Side.white ? 'w' : 'b',
      'lan': ?lanAddress,
      'tc': ?timeControl?.label,
    },
  ).toString();

  /// Legge un invito da testo non fidato (QR o link); `null` se non valido.
  static GameInvite? parse(String text) {
    if (text.length > maxInviteLength) return null;
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return null;
    if (uri.scheme != 'scacchi' || uri.host != 'partita') return null;
    final Map<String, String> q;
    try {
      q = uri.queryParameters;
    } on FormatException {
      return null;
    }
    if (q['v'] != '$inviteVersion') return null;
    final gameId = q['g'];
    if (gameId == null || !_uuidPattern.hasMatch(gameId)) return null;
    final secret = _unb64(q['s'], 32);
    final key = _unb64(q['k'], 32);
    if (secret == null || key == null) return null;
    final side = switch (q['c']) {
      'w' => Side.white,
      'b' => Side.black,
      _ => null,
    };
    if (side == null) return null;
    final lan = q['lan'];
    if (lan != null && !_validAddress(lan)) return null;
    final tcText = q['tc'];
    final control = tcText == null ? null : TimeControl.parse(tcText);
    if (tcText != null &&
        (control == null ||
            control.minutes > maxInviteMinutes ||
            control.increment > maxInviteIncrement)) {
      return null;
    }
    return GameInvite(
      gameId: gameId,
      secret: secret,
      hostKey: key,
      hostSide: side,
      lanAddress: lan,
      timeControl: control,
    );
  }
}

bool _validAddress(String text) {
  final i = text.lastIndexOf(':');
  if (i <= 0) return false;
  final port = int.tryParse(text.substring(i + 1));
  return port != null &&
      port > 0 &&
      port < 65536 &&
      _hostPattern.hasMatch(text.substring(0, i));
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

Uint8List? _unb64(String? text, int length) {
  if (text == null) return null;
  try {
    final bytes = base64Url.decode(base64Url.normalize(text));
    return bytes.length == length ? bytes : null;
  } on FormatException {
    return null;
  }
}
