export type PieceCode = 'K' | 'Q' | 'R' | 'B' | 'N' | 'P' | 'k' | 'q' | 'r' | 'b' | 'n' | 'p';
export type Square = PieceCode | null;
export type Board = Square[][];

export const START_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

const PIECE_CODES = new Set<string>(['K', 'Q', 'R', 'B', 'N', 'P', 'k', 'q', 'r', 'b', 'n', 'p']);

const GLYPHS: Record<PieceCode, string> = {
  K: '♔',
  Q: '♕',
  R: '♖',
  B: '♗',
  N: '♘',
  P: '♙',
  k: '♚',
  q: '♛',
  r: '♜',
  b: '♝',
  n: '♞',
  p: '♟',
};

/** Converte la parte di posizionamento di una stringa FEN in una matrice 8x8 (riga 0 = traversa 8). */
export function parseFenPlacement(fen: string): Board {
  const placement = fen.trim().split(/\s+/)[0] ?? '';
  const ranks = placement.split('/');
  if (ranks.length !== 8) {
    throw new Error(`FEN non valida: attese 8 traverse, trovate ${ranks.length}`);
  }
  return ranks.map((rank, index) => {
    const row: Square[] = [];
    for (const char of rank) {
      if (/[1-8]/.test(char)) {
        row.push(...Array<Square>(Number(char)).fill(null));
      } else if (PIECE_CODES.has(char)) {
        row.push(char as PieceCode);
      } else {
        throw new Error(`FEN non valida: carattere "${char}" nella traversa ${8 - index}`);
      }
    }
    if (row.length !== 8) {
      throw new Error(`FEN non valida: la traversa ${8 - index} ha ${row.length} case`);
    }
    return row;
  });
}

export function pieceGlyph(piece: PieceCode): string {
  return GLYPHS[piece];
}

export function squareName(row: number, col: number): string {
  return `${'abcdefgh'[col]}${8 - row}`;
}
