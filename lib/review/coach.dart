import 'package:dartchess/dartchess.dart';

import '../l10n/app_localizations.dart';
import '../settings/notation.dart';
import 'board_utils.dart';
import 'game_review.dart';
import 'move_classification.dart';
import 'sacrifice.dart';

/// Tema della spiegazione, utile anche per raggruppare gli errori ricorrenti.
enum CoachTheme {
  allowedMate,
  missedMate,
  hangingPiece,
  allowedFork,
  allowedPin,
  exposedKing,
  missedCapture,
  missedFork,
  missedDiscovery,
  materialLoss,
  generic,
  praise,
}

class CoachComment {
  const CoachComment(this.theme, this.text);

  final CoachTheme theme;
  final String text;
}

/// Spiegazione breve della mossa, generata localmente con regole a modello
/// (RF-70, RF-71). [previous] è la mossa precedente dell'avversario, per
/// riconoscere una ripresa mancata. `null` se mancano i dati per spiegarla.
/// Con [kid] (profilo bambino, RP-06) le frasi che citano numeri del motore
/// («matto in N», «circa N pedoni») diventano versioni senza cifre.
/// Le mosse citate nel testo seguono la [notation] scelta.
CoachComment? explainMove(
  MoveReview m, {
  MoveReview? previous,
  AppLocalizations? kid,
  MoveNotation notation = MoveNotation.english,
}) {
  String fmt(String san) => formatSan(san, notation);
  final c = m.classification;
  if (!c.isError) return CoachComment(CoachTheme.praise, _praise[c]!);

  final before = Chess.fromSetup(Setup.parseFen(m.fenBefore));
  final after = before.play(m.move);

  return _allowedMate(m, after, kid, fmt) ??
      _missedMate(m, kid, fmt) ??
      _hanging(before, after, m.replyLine) ??
      _allowedFork(after, m.replyLine, fmt) ??
      _missedTactic(before, m, previous, fmt) ??
      _materialLoss(before, after, m.replyLine, kid) ??
      // Una inchiodatura è un danno più lieve: non copre perdite concrete.
      _allowedPin(after, m.replyLine, fmt) ??
      _exposedKing(before, after, m, fmt) ??
      (m.bestSan == null
          ? null
          : CoachComment(
              CoachTheme.generic,
              'Meglio ${fmt(m.bestSan!)}: la tua posizione peggiora.',
            ));
}

const _praise = {
  MoveClass.brilliant:
      'Mossa brillante: sacrifichi materiale ma è la scelta migliore.',
  MoveClass.great: 'Ottima: era l\'unica mossa che teneva la posizione.',
  MoveClass.best: 'È la mossa migliore.',
  MoveClass.excellent: 'Mossa eccellente, quasi come la migliore.',
  MoveClass.good: 'Buona mossa.',
  MoveClass.book: 'Mossa della teoria delle aperture.',
};

CoachComment? _allowedMate(
  MoveReview m,
  Position after,
  AppLocalizations? kid,
  String Function(String) fmt,
) {
  final mate = m.replyScore?.mate;
  final reply = parseEngineMove(after, m.replyLine.firstOrNull);
  if (mate == null || mate <= 0 || reply == null) return null;
  final replySan = after.makeSan(reply).$2;
  return CoachComment(
    CoachTheme.allowedMate,
    kid?.kidCoachAllowedMate(fmt(m.san), fmt(replySan)) ??
        'Dopo ${fmt(m.san)} il ${_sideName(after.turn)} dà matto in $mate '
            'con ${fmt(replySan)}.',
  );
}

CoachComment? _missedMate(
  MoveReview m,
  AppLocalizations? kid,
  String Function(String) fmt,
) {
  final mate = m.bestScore?.mate;
  if (mate == null || mate <= 0 || m.bestSan == null) return null;
  // Ha ancora il matto, solo più lungo: non è un matto mancato.
  final replyMate = m.replyScore?.mate;
  if (replyMate != null && replyMate < 0) return null;
  return CoachComment(
    CoachTheme.missedMate,
    kid?.kidCoachMissedMate(fmt(m.bestSan!)) ??
        'Avevi il matto in $mate con ${fmt(m.bestSan!)}.',
  );
}

/// L'avversario cattura un pezzo e, contando la nostra ripresa, si resta
/// sotto di almeno due pedoni rispetto a prima della mossa: gli scambi alla
/// pari non sono pezzi in presa.
CoachComment? _hanging(Position before, Position after, List<String> reply) {
  final me = before.turn;
  final first = parseEngineMove(after, reply.firstOrNull);
  if (first is! NormalMove) return null;
  final victim = after.board.pieceAt(first.to);
  final attacker = after.board.pieceAt(first.from);
  if (victim == null || attacker == null || victim.color != me) return null;
  if (victim.role == Role.pawn) return null;
  final taken = after.play(first);
  final retake = canCapture(taken, first.to, me)
      ? pieceValue(attacker.role)
      : 0;
  final lost =
      materialBalance(before, me) - materialBalance(taken, me) - retake;
  if (lost < 2) return null;
  return CoachComment(
    CoachTheme.hangingPiece,
    'Hai lasciato ${_the(victim.role)} in presa in ${first.to.name}: '
    '${_the(attacker.role)} ${_colorAdj(attacker)} '
    '${_pronoun(victim.role)} cattura.',
  );
}

CoachComment? _allowedFork(
  Position after,
  List<String> reply,
  String Function(String) fmt,
) {
  final first = parseEngineMove(after, reply.firstOrNull);
  if (first is! NormalMove) return null;
  final mover = after.board.pieceAt(first.from);
  if (mover == null) return null;
  final next = after.play(first);
  final targets = _forkTargets(next, first.to);
  if (targets.length < 2) return null;
  return CoachComment(
    CoachTheme.allowedFork,
    'Dopo ${fmt(after.makeSan(first).$2)} ${_the(mover.role)} ${_colorAdj(mover)} '
    'attacca insieme ${_list(targets)}: è una forchetta.',
  );
}

/// La risposta dell'avversario inchioda al re un nostro pezzo con un alfiere,
/// una torre o la donna che non possiamo prendere. Se il pezzo era già
/// inchiodato dallo stesso attaccante, non è una novità della mossa.
CoachComment? _allowedPin(
  Position after,
  List<String> reply,
  String Function(String) fmt,
) {
  final first = parseEngineMove(after, reply.firstOrNull);
  if (first is! NormalMove) return null;
  final slider = after.board.pieceAt(first.from);
  if (slider == null || !_isSlider(slider.role)) return null;
  final next = after.play(first);
  final me = slider.color.opposite;
  final pinned = _pinnedPiece(next, first.to, slider, me);
  if (pinned == null) return null;
  if (_pinnedPiece(after, first.from, slider, me) == pinned) return null;
  if (next.board.attacksTo(first.to, me).isNotEmpty) return null;
  final role = next.board.pieceAt(pinned)!.role;
  return CoachComment(
    CoachTheme.allowedPin,
    'Dopo ${fmt(after.makeSan(first).$2)} ${_the(slider.role)} '
    '${_colorAdj(slider)} inchioda ${_the(role)} in ${pinned.name} contro '
    'il re.',
  );
}

/// Una mossa del re (un passo, senza arrocco) o del pedone davanti al re,
/// con il re ancora sulla traversa di partenza, a cui l'avversario risponde
/// con uno scacco che prima della mossa non aveva.
CoachComment? _exposedKing(
  Position before,
  Position after,
  MoveReview m,
  String Function(String) fmt,
) {
  final move = m.move;
  if (move is! NormalMove || before.isCheck) return null;
  final me = before.turn;
  final king = before.board.kingOf(me);
  final piece = before.board.pieceAt(move.from);
  if (king == null || piece == null) return null;
  final home = me == Side.white ? Rank.first : Rank.eighth;
  final ahead = me == Side.white ? 1 : -1;
  final shield = switch (piece.role) {
    Role.king =>
      (move.to.file - move.from.file).abs() <= 1 &&
          before.board.pieceAt(move.to) == null,
    Role.pawn =>
      (move.from.file - king.file).abs() <= 1 &&
          king.rank == home &&
          (move.from.rank - king.rank) * ahead <= 2,
    _ => false,
  };
  if (!shield) return null;
  final reply = parseEngineMove(after, m.replyLine.firstOrNull);
  if (reply == null || !after.play(reply).isCheck) return null;
  if (_couldCheckBefore(before, reply)) return null;
  return CoachComment(
    CoachTheme.exposedKing,
    'Dopo ${fmt(m.san)} il tuo re resta scoperto: '
    '${fmt(after.makeSan(reply).$2)} è scacco.',
  );
}

/// Lo stesso scacco era già possibile prima della mossa, a parti invertite:
/// allora la colpa non è della mossa.
bool _couldCheckBefore(Position before, Move reply) {
  try {
    final parts = before.fen.split(' ');
    parts[1] = before.turn == Side.white ? 'b' : 'w';
    parts[3] = '-';
    final flipped = Chess.fromSetup(Setup.parseFen(parts.join(' ')));
    return flipped.isLegal(reply) && flipped.play(reply).isCheck;
  } on Object {
    return false;
  }
}

bool _isSlider(Role role) =>
    role == Role.bishop || role == Role.rook || role == Role.queen;

/// Il solo pezzo (non pedone) di [victim] tra il pezzo in [from] e il suo
/// re, se sono sulla stessa linea di attacco del pezzo.
Square? _pinnedPiece(Position pos, Square from, Piece slider, Side victim) {
  final king = pos.board.kingOf(victim);
  if (king == null) return null;
  if (!attacks(slider, from, SquareSet.empty).has(king)) return null;
  final blockers = pos.board.occupied.intersect(between(from, king));
  if (blockers.size != 1) return null;
  final square = blockers.first!;
  final piece = pos.board.pieceAt(square)!;
  if (piece.color != victim || piece.role == Role.pawn) return null;
  return square;
}

/// Tattica nella prima mossa della variante migliore: ripresa o cattura
/// netta, doppio attacco o attacco di scoperta.
CoachComment? _missedTactic(
  Position before,
  MoveReview m,
  MoveReview? previous,
  String Function(String) fmt,
) {
  final best = m.bestMove;
  final san = m.bestSan == null ? null : fmt(m.bestSan!);
  if (best is! NormalMove || san == null || m.playedBest) return null;
  if (isCastling(before, best)) return null;
  final me = before.turn;
  final mover = before.board.pieceAt(best.from)!;
  final captured = before.board.pieceAt(best.to);
  final next = before.play(best);

  if (captured != null && captured.color != me) {
    if (_recaptures(previous, best.to)) {
      return CoachComment(
        CoachTheme.missedCapture,
        'Potevi riprendere il pezzo: $san cattura ${_the(captured.role)}.',
      );
    }
    final defended = next.board.attacksTo(best.to, me.opposite).isNotEmpty;
    final gain =
        pieceValue(captured.role) - (defended ? pieceValue(mover.role) : 0);
    if (gain >= 2) {
      return CoachComment(
        CoachTheme.missedCapture,
        'Potevi vincere materiale: $san cattura ${_the(captured.role)}.',
      );
    }
  }

  final targets = _forkTargets(next, best.to);
  if (targets.length >= 2) {
    return CoachComment(
      CoachTheme.missedFork,
      'Potevi fare un doppio attacco con $san: ${_the(mover.role)} attacca '
      '${_list(targets)}.',
    );
  }

  // Scoperta: un altro pezzo, rimasto fermo, attacca una casa nuova.
  for (final from in next.board.bySide(me).squares) {
    if (from == best.to) continue;
    final piece = next.board.pieceAt(from)!;
    if (before.board.pieceAt(from) != piece) continue;
    final was = _attackedSquares(before, from).toSet();
    final revealed = _attackedSquares(
      next,
      from,
    ).where((sq) => !was.contains(sq));
    for (final sq in revealed) {
      final role = next.board.pieceAt(sq)!.role;
      if (role == Role.king) continue;
      return CoachComment(
        CoachTheme.missedDiscovery,
        'Potevi fare un attacco di scoperta con $san: ${_the(piece.role)} '
        'attacca ${_the(role)}.',
      );
    }
  }
  return null;
}

/// La mossa precedente dell'avversario ha catturato su [square].
bool _recaptures(MoveReview? previous, Square square) {
  final move = previous?.move;
  if (previous == null || move is! NormalMove || move.to != square) {
    return false;
  }
  final pos = Chess.fromSetup(Setup.parseFen(previous.fenBefore));
  return pos.board.pieceAt(square) != null;
}

CoachComment? _materialLoss(
  Position before,
  Position after,
  List<String> reply,
  AppLocalizations? kid,
) {
  final me = before.turn;
  var pos = after;
  for (final uci in reply.take(4)) {
    final move = parseEngineMove(pos, uci);
    if (move == null) break;
    pos = pos.play(move);
  }
  final lost = materialBalance(before, me) - materialBalance(pos, me);
  if (lost < 2) return null;
  return CoachComment(
    CoachTheme.materialLoss,
    kid?.kidCoachMaterialLoss ??
        'Questa mossa perde materiale: circa $lost pedoni nella variante '
            'prevista.',
  );
}

/// Case dei pezzi avversari (re o almeno un cavallo) attaccati dal pezzo
/// in [from].
List<Square> _attackedSquares(Position pos, Square from) {
  final piece = pos.board.pieceAt(from);
  if (piece == null) return const [];
  final victim = piece.color.opposite;
  return [
    for (final sq in pos.board.bySide(victim).squares)
      if ((pos.board.pieceAt(sq)!.role == Role.king ||
              pieceValue(pos.board.pieceAt(sq)!.role) >= 3) &&
          pos.board.attacksTo(sq, piece.color).has(from))
        sq,
  ];
}

/// Pezzi colpiti da una forchetta del pezzo in [from]: il pezzo non si può
/// prendere senza perdita e ogni bersaglio è il re, vale di più o è
/// indifeso. Il re per primo, poi dal più prezioso.
List<Role> _forkTargets(Position pos, Square from) {
  final forker = pos.board.pieceAt(from);
  if (forker == null) return const [];
  final victim = forker.color.opposite;
  final value = pieceValue(forker.role);
  final defenders = pos.board.attacksTo(from, victim);
  if (defenders.isNotEmpty) return const [];
  final roles = [
    for (final sq in _attackedSquares(pos, from))
      if (pos.board.pieceAt(sq)!.role == Role.king ||
          pieceValue(pos.board.pieceAt(sq)!.role) > value ||
          pos.board.attacksTo(sq, victim).isEmpty)
        pos.board.pieceAt(sq)!.role,
  ];
  roles.sort((a, b) {
    if (a == Role.king) return -1;
    if (b == Role.king) return 1;
    return pieceValue(b).compareTo(pieceValue(a));
  });
  return roles;
}

String _sideName(Side side) => side == Side.white ? 'Bianco' : 'Nero';

const _names = {
  Role.pawn: ('il', 'pedone', 'lo', false),
  Role.knight: ('il', 'cavallo', 'lo', false),
  Role.bishop: ('l\'', 'alfiere', 'lo', false),
  Role.rook: ('la', 'torre', 'la', true),
  Role.queen: ('la', 'donna', 'la', true),
  Role.king: ('il', 're', 'lo', false),
};

String _the(Role role) {
  final (article, name, _, _) = _names[role]!;
  return article.endsWith('\'') ? '$article$name' : '$article $name';
}

String _pronoun(Role role) => _names[role]!.$3;

String _colorAdj(Piece piece) {
  final feminine = _names[piece.role]!.$4;
  final white = piece.color == Side.white;
  return white
      ? (feminine ? 'bianca' : 'bianco')
      : (feminine ? 'nera' : 'nero');
}

String _list(List<Role> roles) {
  final names = roles.map(_the).toList();
  if (names.length == 1) return names.single;
  return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
}
