import io
import unittest

import build_opening_stats as b

HEADER = '[Event "Rated Blitz game"]\n[Result "{r}"]\n[WhiteElo "{w}"]\n[BlackElo "{k}"]\n[Termination "Normal"]\n\n'


def game(moves, result="1-0", white=2000, black=2000, event="Rated Blitz game"):
    head = HEADER.replace("Rated Blitz game", event).format(r=result, w=white, k=black)
    return head + moves + " " + result + "\n\n"


class Stats(unittest.TestCase):
    def rows(self, pgn, **kw):
        games = b.read_games(io.StringIO(pgn), kw.pop("min_elo", 1800), 0)
        nodes = b.count_paths(games, kw.pop("plies", 16))
        return b.build_rows(nodes, kw.pop("min_games", 1), kw.pop("top", 8))

    def test_initial_key_matches_the_app(self):
        # Same value as the Dart test in test/openings/opening_stats_test.dart.
        self.assertEqual(b.position_key(b.chess.Board()), "7bd6409c02270343")

    def test_counts_moves_and_results(self):
        pgn = (
            game("1. e4 { [%clk 0:03:00] } e5 2. Nf3", "1-0")
            + game("1. e4 c5", "0-1")
            + game("1. d4 d5", "1/2-1/2")
        )
        first = {m[0]: m[1] for m in self.rows(pgn)[b.position_key(b.chess.Board())]}
        self.assertEqual(first["e4"], [2, 1, 1])
        self.assertEqual(first["d4"], [1, 0, 0])

    def test_most_played_move_comes_first(self):
        pgn = game("1. d4") + game("1. e4") + game("1. e4")
        moves = self.rows(pgn)[b.position_key(b.chess.Board())]
        self.assertEqual([m[0] for m in moves], ["e4", "d4"])

    def test_transpositions_merge(self):
        pgn = game("1. Nf3 Nf6 2. d4 d5") + game("1. d4 Nf6 2. Nf3 d5", "0-1")
        rows = self.rows(pgn)
        moves = rows[b.position_key(self.after("Nf3 Nf6 d4"))]
        self.assertEqual(moves, [("d5", [2, 1, 1])])

    def after(self, line):
        board = b.chess.Board()
        for san in line.split():
            board.push_san(san)
        return board

    def test_filters(self):
        pgn = (
            game("1. e4", white=1500)
            + game("1. e4", event="Rated Bullet game")
            + game("1. e4", result="*")
            + game("1. d4")
        )
        moves = self.rows(pgn)[b.position_key(b.chess.Board())]
        self.assertEqual([m[0] for m in moves], ["d4"])

    def test_min_games_and_top(self):
        pgn = game("1. e4") * 3 + game("1. d4") * 2 + game("1. c4")
        moves = self.rows(pgn, min_games=2, top=1)[b.position_key(b.chess.Board())]
        self.assertEqual([m[0] for m in moves], ["e4"])

    def test_output_format(self):
        out = io.StringIO()
        b.write(self.rows(game("1. e4 e5")), out)
        lines = out.getvalue().splitlines()
        self.assertEqual(lines[0], "chiave\tmosse")
        self.assertIn("\te4:1:1:0", "\n".join(lines))


if __name__ == "__main__":
    unittest.main()
