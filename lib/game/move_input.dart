import 'package:dartchess/dartchess.dart';

import 'chess_game.dart';

/// Esito della lettura di una mossa scritta.
sealed class MoveInputResult {
  const MoveInputResult();
}

class MoveInputOk extends MoveInputResult {
  const MoveInputOk(this.move);

  final Move move;
}

/// `R` vale sia re (italiano) sia torre (inglese) e indica due mosse legali.
class MoveInputAmbiguous extends MoveInputResult {
  const MoveInputAmbiguous();
}

class MoveInputInvalid extends MoveInputResult {
  const MoveInputInvalid();
}

const _italianPieces = {'R': 'K', 'D': 'Q', 'T': 'R', 'A': 'B', 'C': 'N'};
final _ignored = RegExp(r'[\s+#!?]');
final _uci = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');
final _castling = RegExp(r'^[oO0](-[oO0]){1,2}$');
final _promotion = RegExp(r'^(.*[a-h][18])=?([A-Z])$');

/// Legge una mossa in SAN inglese o italiana (`Nf3`, `Cf3`) oppure in UCI
/// (`g1f3`); ignora spazi, simboli di scacco e annotazioni.
MoveInputResult parseMoveInput(Position pos, String text) {
  var t = text.replaceAll(_ignored, '');
  if (t.length < 2) return const MoveInputInvalid();

  final lower = t.toLowerCase();
  if (_uci.hasMatch(lower)) {
    // dartchess accetta anche e1g1, ma l'arrocco si registra re-su-torre (e1h1)
    // come nelle mosse generate dalla scacchiera.
    final parsed = Move.parse(lower)!;
    final move = parsed is NormalMove ? pos.normalizeMove(parsed) : parsed;
    return isPlayableMove(pos, move)
        ? MoveInputOk(move)
        : const MoveInputInvalid();
  }

  if (_castling.hasMatch(t)) {
    t = t.toUpperCase().replaceAll('0', 'O');
  } else if ('nqkrt'.contains(t[0])) {
    t = t[0].toUpperCase() + t.substring(1);
  }

  var result = _bothNotations(pos, t);
  if (result is MoveInputInvalid && 'cda'.contains(t[0])) {
    // Iniziale italiana minuscola, per esempio `cf3`.
    result = _bothNotations(pos, t[0].toUpperCase() + t.substring(1));
  }
  return result;
}

MoveInputResult _bothNotations(Position pos, String t) {
  final english = _san(pos, t, (p) => p);
  final italian = _san(pos, t, (p) => _italianPieces[p] ?? p);
  if (english != null && italian != null && english != italian) {
    return const MoveInputAmbiguous();
  }
  final move = english ?? italian;
  return move == null ? const MoveInputInvalid() : MoveInputOk(move);
}

Move? _san(Position pos, String text, String Function(String) piece) {
  var t = text;
  if (!t.startsWith('O') && RegExp('[A-Z]').hasMatch(t[0])) {
    t = piece(t[0]) + t.substring(1);
  }
  final promo = _promotion.firstMatch(t);
  if (promo != null) {
    final role = piece(promo[2]!);
    if (!'QRBN'.contains(role)) return null;
    t = '${promo[1]}=$role';
  }
  final Move? move;
  try {
    move = pos.parseSan(t);
  } on Error {
    // dartchess non valida la lunghezza di ogni testo malformato.
    return null;
  }
  return move != null && isPlayableMove(pos, move) ? move : null;
}
