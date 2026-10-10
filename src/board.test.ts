import { describe, expect, it } from 'vitest';
import { START_FEN, parseFenPlacement, squareName } from './board';

describe('parseFenPlacement', () => {
  it('legge la posizione iniziale', () => {
    const board = parseFenPlacement(START_FEN);
    expect(board).toHaveLength(8);
    expect(board[0]?.join('')).toBe('rnbqkbnr');
    expect(board[7]?.join('')).toBe('RNBQKBNR');
    expect(board[4]?.every((square) => square === null)).toBe(true);
  });

  it('rifiuta una FEN malformata', () => {
    expect(() => parseFenPlacement('8/8/8')).toThrow(/8 traverse/);
    expect(() => parseFenPlacement('9/8/8/8/8/8/8/8')).toThrow(/carattere/);
    expect(() => parseFenPlacement('7/8/8/8/8/8/8/8')).toThrow(/case/);
  });
});

describe('squareName', () => {
  it('converte coordinate in notazione algebrica', () => {
    expect(squareName(0, 0)).toBe('a8');
    expect(squareName(7, 4)).toBe('e1');
  });
});
