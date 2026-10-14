import 'package:dartchess/dartchess.dart';

import '../l10n/content.dart';

/// Cosa serve per completare una posizione dell'allenatore dei finali.
enum DrillGoal {
  /// Dare scacco matto.
  mate,

  /// Promuovere e restare con una donna, o con la torre contro il re solo,
  /// che l'avversario non riesce a vincere nelle due mosse seguenti.
  promote,

  /// Non perdere: arrivare alla patta o resistere per [EndgameDrill.par]
  /// mosse senza restare con il re solo o lasciare una donna all'avversario.
  hold,
}

/// Posizione teorica da giocare contro il motore a forza piena (RF-86).
class EndgameDrill {
  const EndgameDrill({
    required this.id,
    required this.fen,
    required this.goal,
    required this.par,
  });

  final String id;

  String get title => Content.of('endgames').text('$id.title');

  /// Spiegazione breve mostrata prima di iniziare, con l'obiettivo dichiarato.
  String get intro => Content.of('endgames').text('$id.intro', {'par': par});

  /// Posizione iniziale; l'utente gioca il colore che ha la mossa.
  final String fen;

  final DrillGoal goal;

  /// Mosse dell'utente per le tre stelle; per [DrillGoal.hold] sono le
  /// mosse da resistere.
  final int par;
}

/// Stelle in base alle mosse impiegate: tre entro il par, due con uno scarto
/// fino a metà del par, altrimenti una.
int drillStars(int moves, int par) {
  if (moves <= par) return 3;
  if (moves <= par + (par / 2).ceil()) return 2;
  return 1;
}

enum DrillState { playing, success, failure }

/// Una prova in corso: l'utente muove, il motore risponde con [reply].
class DrillRun {
  DrillRun(this.drill)
    : _position = Chess.fromSetup(Setup.parseFen(drill.fen)) {
    side = _position.turn;
    _seen[_key(_position)] = 1;
  }

  final EndgameDrill drill;

  /// Colore dell'utente.
  late final Side side;

  Position _position;
  Position get position => _position;

  int _moves = 0;

  /// Mosse giocate dall'utente.
  int get moves => _moves;

  DrillState _state = DrillState.playing;
  DrillState get state => _state;

  final Map<String, int> _seen = {};

  final List<Move> _history = [];

  /// Mosse di entrambi dalla posizione iniziale, per dare al motore la
  /// storia (e quindi le ripetizioni).
  List<Move> get history => List.unmodifiable(_history);

  bool get userToMove => _state == DrillState.playing && _position.turn == side;

  /// Stelle ottenute, zero se la prova non è (ancora) riuscita.
  int get stars =>
      _state == DrillState.success ? drillStars(_moves, drill.par) : 0;

  /// Gioca la mossa dell'utente; `false` se non è il suo turno o è illegale.
  bool play(Move move) {
    if (!userToMove || !_position.isLegal(move)) return false;
    _apply(move);
    _moves++;
    if (_ended()) return true;
    switch (drill.goal) {
      case DrillGoal.hold:
        if (_opponentQueened() ||
            _bareKing(side) && !_bareKing(side.opposite)) {
          _state = DrillState.failure;
        }
      case DrillGoal.promote:
        if (_winIsSafe(_position)) {
          _state = DrillState.success;
        } else if (_outOfMaterial()) {
          _state = DrillState.failure;
        }
      case DrillGoal.mate:
        break;
    }
    if (_state == DrillState.playing &&
        drill.goal != DrillGoal.hold &&
        _moves >= drill.par * 3) {
      _state = DrillState.failure;
    }
    return true;
  }

  /// Applica la risposta del motore; `false` se non è il suo turno o la
  /// mossa è illegale.
  bool reply(Move move) {
    if (_state != DrillState.playing ||
        _position.turn == side ||
        !_position.isLegal(move)) {
      return false;
    }
    _apply(move);
    if (_ended()) return true;
    switch (drill.goal) {
      case DrillGoal.hold:
        if (_bareKing(side) && !_bareKing(side.opposite)) {
          _state = DrillState.failure;
        } else if (_moves >= drill.par && !_opponentQueened()) {
          // Una donna appena promossa non vale la patta: l'utente deve
          // ancora poterla catturare.
          _state = DrillState.success;
        }
      case DrillGoal.promote:
        if (_outOfMaterial()) _state = DrillState.failure;
      case DrillGoal.mate:
        break;
    }
    return true;
  }

  void _apply(Move move) {
    _position = _position.play(move);
    _history.add(move);
    final key = _key(_position);
    _seen[key] = (_seen[key] ?? 0) + 1;
  }

  /// Chiude la prova su matto o patta; `true` se è finita.
  bool _ended() {
    if (_position.isCheckmate) {
      _state = _position.turn == side ? DrillState.failure : DrillState.success;
      return true;
    }
    final draw =
        _position.isGameOver ||
        _position.halfmoves >= 100 ||
        (_seen[_key(_position)] ?? 0) >= 3;
    if (draw) {
      _state = drill.goal == DrillGoal.hold
          ? DrillState.success
          : DrillState.failure;
      return true;
    }
    return false;
  }

  bool _material(Side owner, Role role) =>
      _position.board.piecesOf(owner, role).isNotEmpty;

  /// L'avversario ha una donna e l'utente no.
  bool _opponentQueened() =>
      _material(side.opposite, Role.queen) && !_material(side, Role.queen);

  bool _bareKing(Side owner) => _position.board.bySide(owner).size == 1;

  /// L'utente non ha più pedoni, donne né torri: la promozione è sfumata.
  bool _outOfMaterial() =>
      !_material(side, Role.pawn) &&
      !_material(side, Role.queen) &&
      !_material(side, Role.rook);

  /// Con l'avversario al tratto: qualunque cosa risponda, l'utente ha una
  /// mossa che lo lascia vincente in [_winning]. Guardare due mosse avanti
  /// scopre la donna che si fa catturare, infilare o prendere con una
  /// forchetta di scacco, e la torre lasciata indifesa vicino al re nemico.
  bool _winIsSafe(Position position) {
    if (!_winning(position, safe: false)) return false;
    for (final reply in _legalMoves(position)) {
      final after = position.play(reply);
      if (after.isGameOver) return false;
      if (!_legalMoves(after).any((m) => _winning(after.play(m), safe: true))) {
        return false;
      }
    }
    return true;
  }

  /// L'utente ha la donna, o la torre contro il re solo; con [safe] nessuna
  /// mossa dell'avversario può catturarle.
  bool _winning(Position position, {required bool safe}) {
    if (position.isCheckmate) return true;
    if (position.isGameOver) return false;
    final board = position.board;
    final strong = board.piecesOf(side, Role.queen).isNotEmpty
        ? board.piecesOf(side, Role.queen)
        : board.bySide(side.opposite).size == 1
        ? board.piecesOf(side, Role.rook)
        : SquareSet.empty;
    if (strong.isEmpty) return false;
    if (!safe) return true;
    return !position.legalMoves.values.any(
      (targets) => targets.isIntersected(strong),
    );
  }

  static Iterable<Move> _legalMoves(Position position) sync* {
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries) {
      for (final to in targets.squares) {
        final move = NormalMove(from: from, to: to);
        final isPromotion =
            position.board.roleAt(from) == Role.pawn &&
            (to.rank == Rank.first || to.rank == Rank.eighth);
        if (isPromotion) {
          for (final role in [
            Role.queen,
            Role.rook,
            Role.bishop,
            Role.knight,
          ]) {
            yield NormalMove(from: from, to: to, promotion: role);
          }
        } else {
          yield move;
        }
      }
    }
  }

  static String _key(Position p) => p.fen.split(' ').take(4).join(' ');
}
