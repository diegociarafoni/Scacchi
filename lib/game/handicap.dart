import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import 'clock.dart';

/// Pezzo che chi dà il vantaggio toglie dalla posizione iniziale (RF-27).
enum HandicapPiece {
  /// Pedone di alfiere di re.
  fPawn('f'),

  /// Cavallo di donna.
  knight('b'),

  /// Torre di donna: con lei cade anche l'arrocco lungo.
  rook('a'),
  queen('d');

  const HandicapPiece(this.file);

  /// Colonna del pezzo tolto.
  final String file;

  /// Nome inglese, per l'intestazione PGN.
  String get pgnName => switch (this) {
    fPawn => 'f-pawn',
    knight => 'knight',
    rook => 'rook',
    queen => 'queen',
  };
}

/// Chi dà il vantaggio: chi gioca o l'avversario. Nella partita a due il
/// giocatore è il Bianco e l'avversario il Nero.
enum HandicapGiver { player, opponent }

/// Vantaggio concesso nella partita (RF-27): un pezzo in meno, meno tempo per
/// chi lo concede, o entrambi. Le partite a handicap non contano per il
/// rating locale.
@immutable
class Handicap {
  const Handicap({
    this.piece,
    this.giverMinutes,
    this.giver = HandicapGiver.player,
  }) : assert(
         piece != null || giverMinutes != null,
         'un handicap ha un pezzo o un tempo',
       );

  final HandicapPiece? piece;

  /// Minuti di chi dà il vantaggio, meno della cadenza scelta; `null` se il
  /// tempo è uguale.
  final int? giverMinutes;
  final HandicapGiver giver;

  /// Valori per l'handicap di tempo, in minuti.
  static const timeOptions = [1, 2, 3, 5];

  /// L'handicap che si può applicare davvero: il pezzo solo negli scacchi
  /// classici, il tempo solo con un orologio e se è inferiore alla cadenza.
  /// `null` se non resta nulla.
  Handicap? usable({required TimeControl? control, required bool standard}) {
    final time = giverMinutes;
    final p = standard ? piece : null;
    final t = control != null && time != null && time < control.minutes
        ? time
        : null;
    return p == null && t == null
        ? null
        : Handicap(piece: p, giverMinutes: t, giver: giver);
  }

  /// Colore di chi dà il vantaggio, dato il colore di chi gioca.
  Side giverSide(Side human) =>
      giver == HandicapGiver.player ? human : human.opposite;

  /// Posizione iniziale senza il pezzo tolto a chi dà il vantaggio.
  Position startPosition(Side human) {
    final removed = piece;
    if (removed == null) return Chess.initial;
    final white = giverSide(human) == Side.white;
    final pawns = List.filled(8, white ? 'P' : 'p');
    final back = (white ? 'RNBQKBNR' : 'rnbqkbnr').split('');
    final file = removed.file.codeUnitAt(0) - 'a'.codeUnitAt(0);
    var castling = 'KQkq';
    switch (removed) {
      case HandicapPiece.fPawn:
        pawns[file] = '';
      case HandicapPiece.rook:
        back[file] = '';
        castling = castling.replaceAll(white ? 'Q' : 'q', '');
      case HandicapPiece.knight || HandicapPiece.queen:
        back[file] = '';
    }
    String rank(List<String> cells) {
      final buffer = StringBuffer();
      var empty = 0;
      for (final c in cells) {
        if (c.isEmpty) {
          empty++;
          continue;
        }
        if (empty > 0) buffer.write(empty);
        empty = 0;
        buffer.write(c);
      }
      if (empty > 0) buffer.write(empty);
      return buffer.toString();
    }

    final fen = white
        ? 'rnbqkbnr/pppppppp/8/8/8/8/${rank(pawns)}/${rank(back)} w $castling - 0 1'
        : '${rank(back)}/${rank(pawns)}/8/8/8/8/PPPPPPPP/RNBQKBNR w $castling - 0 1';
    return Chess.fromSetup(Setup.parseFen(fen));
  }

  /// Tempo iniziale dei due lati: [control] per chi riceve, [giverMinutes]
  /// per chi dà il vantaggio.
  Map<Side, Duration> startTimes(TimeControl control, Side human) {
    final giverTime = giverMinutes;
    return {
      for (final side in Side.values)
        side: Duration(
          minutes: giverTime != null && side == giverSide(human)
              ? giverTime
              : control.minutes,
        ),
    };
  }

  /// Valore dell'intestazione PGN `Handicap`, per esempio
  /// `White gives queen; White time 3 min`.
  String pgnValue(Side human) {
    final side = giverSide(human) == Side.white ? 'White' : 'Black';
    return [
      if (piece != null) '$side gives ${piece!.pgnName}',
      if (giverMinutes != null) '$side time $giverMinutes min',
    ].join('; ');
  }

  @override
  bool operator ==(Object other) =>
      other is Handicap &&
      other.piece == piece &&
      other.giverMinutes == giverMinutes &&
      other.giver == giver;

  @override
  int get hashCode => Object.hash(piece, giverMinutes, giver);
}
