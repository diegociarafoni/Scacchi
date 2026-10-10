import 'package:dartchess/dartchess.dart';

import 'game_review.dart';
import 'move_classification.dart';
import 'sacrifice.dart';

/// Tema della spiegazione, utile anche per raggruppare gli errori ricorrenti.
enum CoachTheme {
  allowedMate,
  missedMate,
  hangingPiece,
  allowedFork,
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
/// (RF-70, RF-71). `null` se mancano i dati per spiegarla.
CoachComment? explainMove(MoveReview m) {
  final c = m.classification;
  if (!c.isError) return CoachComment(CoachTheme.praise, _praise[c]!);

  final before = Chess.fromSetup(Setup.parseFen(m.fenBefore));
  final me = before.turn;
  final after = before.play(m.move);

  return _allowedMate(m, after) ??
      _missedMate(m) ??
      _hanging(after, m.replyLine, me) ??
      _allowedFork(after, m.replyLine, me) ??
      _missedTactic(before, m) ??
      _materialLoss(after, m.replyLine, me) ??
      (m.bestSan == null
          ? null
          : CoachComment(
              CoachTheme.generic,
              'Meglio ${m.bestSan}: la tua posizione peggiora.',
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

CoachComment? _allowedMate(MoveReview m, Position after) {
  final mate = m.replyScore?.mate;
  final reply = _move(after, m.replyLine.firstOrNull);
  if (mate == null || mate <= 0 || reply == null) return null;
  return CoachComment(
    CoachTheme.allowedMate,
    'Dopo ${m.san} il ${_sideName(after.turn)} dà matto in $mate con '
    '${after.makeSan(reply).$2}.',
  );
}

CoachComment? _missedMate(MoveReview m) {
  final mate = m.bestScore?.mate;
  if (mate == null || mate <= 0 || m.bestSan == null) return null;
  // Ha ancora il matto, solo più lungo: non è un matto mancato.
  final replyMate = m.replyScore?.mate;
  if (replyMate != null && replyMate < 0) return null;
  return CoachComment(
    CoachTheme.missedMate,
    'Avevi il matto in $mate con ${m.bestSan}.',
  );
}

/// L'avversario cattura un pezzo e non lo si riprende con un guadagno pari.
CoachComment? _hanging(Position after, List<String> reply, Side me) {
  final first = _move(after, reply.firstOrNull);
  if (first is! NormalMove) return null;
  final victim = after.board.pieceAt(first.to);
  final attacker = after.board.pieceAt(first.from);
  if (victim == null || attacker == null || victim.color != me) return null;
  if (victim.role == Role.pawn) return null;
  final start = materialBalance(after, me);
  final taken = after.play(first);
  final retake = _bestRecapture(taken, first.to, me);
  if (start - materialBalance(taken, me) - retake < 2) return null;
  return CoachComment(
    CoachTheme.hangingPiece,
    'Hai lasciato ${_the(victim.role)} in presa in ${first.to.name}: '
    '${_the(attacker.role)} ${_colorAdj(attacker)} '
    '${_pronoun(victim.role)} cattura.',
  );
}

CoachComment? _allowedFork(Position after, List<String> reply, Side me) {
  final first = _move(after, reply.firstOrNull);
  if (first is! NormalMove) return null;
  final mover = after.board.pieceAt(first.from);
  if (mover == null) return null;
  final next = after.play(first);
  final targets = _valuableTargets(next, first.to, me);
  if (targets.length < 2) return null;
  return CoachComment(
    CoachTheme.allowedFork,
    'Dopo ${after.makeSan(first).$2} ${_the(mover.role)} ${_colorAdj(mover)} '
    'attacca insieme ${_list(targets)}: è una forchetta.',
  );
}

/// Tattica nella prima mossa della variante migliore: cattura netta, doppio
/// attacco o attacco di scoperta.
CoachComment? _missedTactic(Position before, MoveReview m) {
  final best = m.bestMove;
  final san = m.bestSan;
  if (best is! NormalMove || san == null || m.playedBest) return null;
  final me = before.turn;
  final mover = before.board.pieceAt(best.from)!;
  final captured = before.board.pieceAt(best.to);
  final next = before.play(best);

  if (captured != null && captured.color != me) {
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

  final targets = _valuableTargets(next, best.to, me.opposite);
  if (targets.length >= 2) {
    return CoachComment(
      CoachTheme.missedFork,
      'Potevi fare un doppio attacco con $san: ${_the(mover.role)} attacca '
      '${_list(targets)}.',
    );
  }

  for (final from in next.board.bySide(me).squares) {
    if (from == best.to) continue;
    final piece = next.board.pieceAt(from)!;
    final now = _valuableTargets(next, from, me.opposite);
    final was = _valuableTargets(before, from, me.opposite);
    final revealed = now.where((r) => !was.contains(r) && r != Role.king);
    if (revealed.isNotEmpty) {
      return CoachComment(
        CoachTheme.missedDiscovery,
        'Potevi fare un attacco di scoperta con $san: ${_the(piece.role)} '
        'attacca ${_the(revealed.first)}.',
      );
    }
  }
  return null;
}

CoachComment? _materialLoss(Position after, List<String> reply, Side me) {
  final start = materialBalance(after, me);
  var pos = after;
  for (final uci in reply.take(4)) {
    final move = _move(pos, uci);
    if (move == null) break;
    pos = pos.play(move);
  }
  final lost = start - materialBalance(pos, me);
  if (lost < 2) return null;
  return CoachComment(
    CoachTheme.materialLoss,
    'Questa mossa perde materiale: circa $lost '
    '${lost == 1 ? 'pedone' : 'pedoni'} nella variante prevista.',
  );
}

/// Valore della miglior ripresa di [side] su [square], 0 se non può.
int _bestRecapture(Position pos, Square square, Side side) {
  if (pos.turn != side) return 0;
  final piece = pos.board.pieceAt(square);
  if (piece == null) return 0;
  final canRetake = pos.board
      .attacksTo(square, side)
      .squares
      .any((from) => pos.isLegal(NormalMove(from: from, to: square)));
  return canRetake ? pieceValue(piece.role) : 0;
}

/// Pezzi di [victim] (re o almeno un cavallo) attaccati dal pezzo in [from].
List<Role> _valuableTargets(Position pos, Square from, Side victim) {
  final piece = pos.board.pieceAt(from);
  if (piece == null || piece.color == victim) return const [];
  final attacked = <Role>[];
  for (final sq in pos.board.bySide(victim).squares) {
    final target = pos.board.pieceAt(sq)!;
    if (target.role != Role.king && pieceValue(target.role) < 3) continue;
    if (pos.board.attacksTo(sq, piece.color).has(from)) {
      attacked.add(target.role);
    }
  }
  // Il re per primo, poi dal più prezioso.
  attacked.sort((a, b) {
    if (a == Role.king) return -1;
    if (b == Role.king) return 1;
    return pieceValue(b).compareTo(pieceValue(a));
  });
  return attacked;
}

Move? _move(Position pos, String? uci) {
  final m = uci == null ? null : Move.parse(uci);
  if (m == null) return null;
  final move = m is NormalMove ? pos.normalizeMove(m) : m;
  return pos.isLegal(move) ? move : null;
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
