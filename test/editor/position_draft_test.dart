import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/editor/position_draft.dart';

const _start = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const _wk = Piece(color: Side.white, role: Role.king);
const _bk = Piece(color: Side.black, role: Role.king);
const _wq = Piece(color: Side.white, role: Role.queen);
const _wp = Piece(color: Side.white, role: Role.pawn);

Square sq(String name) => Square.parse(name)!;

PositionDraft kings() =>
    PositionDraft.empty().put(sq('e1'), _wk).put(sq('e8'), _bk);

void main() {
  test('la posizione iniziale ha il FEN standard ed è valida', () {
    final draft = PositionDraft.initial();
    expect(draft.fen, _start);
    expect(draft.problem, isNull);
    expect(draft.toPosition()!.fen, _start);
  });

  test('la scacchiera vuota segnala i re mancanti', () {
    expect(PositionDraft.empty().problem, SetupProblem.empty);
    final onlyWhite = PositionDraft.empty().put(sq('e1'), _wk);
    expect(onlyWhite.problem, SetupProblem.kings);
    expect(onlyWhite.toPosition(), isNull);
  });

  test('due re dello stesso colore non sono ammessi', () {
    expect(kings().put(sq('a1'), _wk).problem, SetupProblem.kings);
  });

  test('pedoni in prima o ottava traversa non sono ammessi', () {
    expect(kings().put(sq('a8'), _wp).problem, SetupProblem.pawnsOnBackrank);
    expect(kings().put(sq('a1'), _wp).problem, SetupProblem.pawnsOnBackrank);
  });

  test('il giocatore che non ha il tratto non può essere sotto scacco', () {
    final draft = kings().put(sq('c2'), _wq);
    expect(draft.problem, isNull);
    expect(draft.withTurn(Side.black).problem, isNull);
    final check = kings().put(sq('e7'), _wq);
    expect(check.problem, SetupProblem.oppositeCheck);
    expect(check.withTurn(Side.black).problem, isNull);
  });

  test('put sostituisce il pezzo e null lo toglie', () {
    final draft = kings().put(sq('d4'), _wq).put(sq('d4'), null);
    expect(draft.board.pieceAt(sq('d4')), isNull);
    expect(draft.fen, '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
  });

  test('l\'arrocco è possibile solo con re e torre sulle case iniziali', () {
    final draft = PositionDraft.initial();
    expect(draft.isCastlingAvailable(CastlingRight.whiteKingSide), isTrue);
    final noRook = draft.put(sq('h1'), null);
    expect(noRook.isCastlingAvailable(CastlingRight.whiteKingSide), isFalse);
    expect(noRook.castling, isNot(contains(CastlingRight.whiteKingSide)));
    expect(noRook.fen, endsWith(' w Qkq - 0 1'));
    final kingMoved = draft.put(sq('e8'), null).put(sq('d8'), _bk);
    expect(kingMoved.castling, {
      CastlingRight.whiteKingSide,
      CastlingRight.whiteQueenSide,
    });
  });

  test('i diritti di arrocco si attivano e disattivano', () {
    final draft = PositionDraft.initial().withCastling(
      CastlingRight.blackQueenSide,
      enabled: false,
    );
    expect(draft.fen, contains(' w KQk - '));
    expect(
      draft.withCastling(CastlingRight.blackQueenSide, enabled: true).fen,
      contains(' w KQkq - '),
    );
    final empty = kings().withCastling(
      CastlingRight.whiteKingSide,
      enabled: true,
    );
    expect(empty.castling, isEmpty);
  });

  test('parseFen legge tratto, arrocco ed en passant', () {
    const fen = 'rnbqkbnr/ppp1pppp/8/8/3pP3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 3';
    final draft = PositionDraft.parseFen(fen)!;
    expect(draft.turn, Side.black);
    expect(draft.castling.length, 4);
    expect(draft.fen, fen);
    expect(draft.toPosition()!.legalMoves[sq('d4')]!.has(sq('e3')), isTrue);
  });

  test('una modifica cancella la casa en passant', () {
    const fen = 'rnbqkbnr/ppp1pppp/8/8/3pP3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 3';
    final draft = PositionDraft.parseFen(fen)!.put(sq('a7'), null);
    expect(draft.fen, contains(' b KQkq - '));
  });

  test('parseFen restituisce null per un testo non valido', () {
    expect(PositionDraft.parseFen('non è un fen'), isNull);
    expect(PositionDraft.parseFen(''), isNull);
    expect(PositionDraft.parseFen('8/8/8/8/8/8/8/9 w - - 0 1'), isNull);
  });

  test('parseFen accetta il solo campo della scacchiera', () {
    final draft = PositionDraft.parseFen('4k3/8/8/8/8/8/8/4K3')!;
    expect(draft.turn, Side.white);
    expect(draft.problem, isNull);
  });

  test('flipped scambia i colori e ribalta la scacchiera', () {
    final draft = kings().put(sq('a2'), _wp).flipped();
    expect(
      draft.board.pieceAt(sq('a7')),
      const Piece(color: Side.black, role: Role.pawn),
    );
    expect(draft.board.pieceAt(sq('e8')), _bk);
    expect(draft.turn, Side.black);
  });

  test('il messaggio di ogni problema è in italiano', () {
    for (final p in SetupProblem.values) {
      expect(p.message, isNotEmpty);
    }
  });
}
