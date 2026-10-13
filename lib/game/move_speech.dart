import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';

const _roles = {
  'K': 'king',
  'Q': 'queen',
  'R': 'rook',
  'B': 'bishop',
  'N': 'knight',
};

final _sanPattern = RegExp(
  r'^([KQRBN])?([a-h]?[1-8]?)(x)?([a-h][1-8])(?:=([QRBN]))?([+#])?$',
);

/// Frase per annunciare una mossa SAN con il lettore di schermo, nella lingua
/// di [l10n]; [name] sostituisce il colore.
String describeSan(
  AppLocalizations l10n,
  String san,
  Side side, {
  String? name,
}) {
  final who = name ?? l10n.gameSideName(side.name);
  final check = san.endsWith('#')
      ? 'mate'
      : san.endsWith('+')
      ? 'check'
      : 'none';
  if (san.startsWith('O-O-O')) return l10n.gameSpeechCastleLong(who, check);
  if (san.startsWith('O-O')) return l10n.gameSpeechCastleShort(who, check);
  final m = _sanPattern.firstMatch(san);
  if (m == null) return '$who: $san';
  String piece(String? letter) =>
      l10n.gamePieceName(letter == null ? 'pawn' : _roles[letter]!);
  final origin = m[2]!;
  final from = switch (origin.length) {
    0 => 'none',
    2 => 'square',
    _ when origin.contains(RegExp('[a-h]')) => 'file',
    _ => 'rank',
  };
  return l10n.gameSpeechMove(
    who,
    piece(m[1]),
    from,
    origin,
    m[3] == null ? 'no' : 'yes',
    m[4]!,
    m[5] == null ? 'none' : piece(m[5]),
    check,
  );
}
