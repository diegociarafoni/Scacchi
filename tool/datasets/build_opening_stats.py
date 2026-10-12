#!/usr/bin/env python3
"""Builds assets/openings/opening_stats.tsv from the Lichess games database (CC0).

Reads a PGN stream on stdin (a monthly dump decompressed with zstd) and, for every
position reached in the first PLIES half-moves, counts how many games played each
move and how they ended. Only the head of the stream is needed: the dump is
chronological, so --max-games stops reading early and the download can be cut.

Positions are keyed by the 64-bit FNV-1a hash of "pieces turn castling" (see
OpeningStats.keyOf in lib/openings/opening_stats.dart), so transpositions merge.
Output rows: key TAB san:games:white-wins:black-wins,... from the most played move.

Usage:
  curl -sSfL https://database.lichess.org/standard/lichess_db_standard_rated_2025-01.pgn.zst \
    | zstd -dc | python3 tool/datasets/build_opening_stats.py > assets/openings/opening_stats.tsv
"""

import argparse
import re
import sys

import chess

RESULTS = {"1-0": 0, "0-1": 1, "1/2-1/2": 2}
NOISE = re.compile(r"\{[^}]*\}|\$\d+|\d+\.+")
WANTED = ("[Event ", "[Result ", "[WhiteElo ", "[BlackElo ", "[Termination ")
TAG = re.compile(r'\[(\w+) "(.*)"\]')


def fnv1a64(text):
    h = 0xCBF29CE484222325
    for b in text.encode():
        h = ((h ^ b) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return "%016x" % h


def position_key(board):
    return fnv1a64(" ".join(board.fen().split()[:3]))


def read_games(stream, min_elo, max_games):
    """Yields (moves, result) for the games that pass the filters."""
    tags = {}
    seen = 0
    for line in stream:
        if line.startswith("["):
            # Most of a dump is tags nobody reads: match only the needed ones.
            if line.startswith(WANTED):
                m = TAG.match(line)
                if m:
                    tags[m.group(1)] = m.group(2)
            continue
        if not line.strip():
            continue
        # Movetext is a single line in the Lichess dumps.
        seen += 1
        if accepted(tags, min_elo):
            moves = NOISE.sub(" ", line).split()
            if moves and moves[-1] in RESULTS:
                moves.pop()
            yield moves, RESULTS[tags["Result"]]
        tags = {}
        if max_games and seen >= max_games:
            return


def accepted(tags, min_elo):
    if tags.get("Result") not in RESULTS:
        return False
    event = tags.get("Event", "")
    if "Bullet" in event or "Correspondence" in event:
        return False
    if tags.get("Termination") in ("Abandoned", "Rules infraction"):
        return False
    try:
        return min(int(tags["WhiteElo"]), int(tags["BlackElo"])) >= min_elo
    except (KeyError, ValueError):
        return False


def count_paths(games, plies):
    """Counts games, white wins and black wins for every move sequence."""
    nodes = {}
    for moves, result in games:
        path = ""
        for san in moves[:plies]:
            path = path + " " + san if path else san
            node = nodes.get(path)
            if node is None:
                node = nodes[path] = [0, 0, 0]
            node[0] += 1
            if result == 0:
                node[1] += 1
            elif result == 1:
                node[2] += 1
    return nodes


def build_rows(nodes, min_games, top):
    """Merges move sequences into positions: {key: {san: [games, white, black]}}."""
    kept = sorted(
        (p for p, n in nodes.items() if n[0] >= min_games),
        key=lambda p: (p.count(" "), p),
    )
    boards = {"": chess.Board()}
    rows = {}
    for path in kept:
        parent, _, san = path.rpartition(" ")
        board = boards.get(parent)
        if board is None:
            continue
        try:
            move = board.parse_san(san)
        except ValueError:
            continue
        normal = board.san(move)
        edge = rows.setdefault(position_key(board), {}).setdefault(normal, [0, 0, 0])
        for i, v in enumerate(nodes[path]):
            edge[i] += v
        child = board.copy(stack=False)
        child.push(move)
        boards[path] = child
    out = {}
    for key, edges in rows.items():
        best = sorted(edges.items(), key=lambda kv: (-kv[1][0], kv[0]))[:top]
        out[key] = best
    return out


def write(rows, out):
    out.write("chiave\tmosse\n")
    for key in sorted(rows):
        moves = ",".join("%s:%d:%d:%d" % (san, g, w, b) for san, (g, w, b) in rows[key])
        out.write("%s\t%s\n" % (key, moves))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plies", type=int, default=16)
    ap.add_argument("--min-games", type=int, default=300)
    ap.add_argument("--top", type=int, default=8)
    ap.add_argument("--min-elo", type=int, default=1800)
    ap.add_argument("--max-games", type=int, default=0, help="games read, 0 = all")
    args = ap.parse_args()
    nodes = count_paths(read_games(sys.stdin, args.min_elo, args.max_games), args.plies)
    rows = build_rows(nodes, args.min_games, args.top)
    write(rows, sys.stdout)
    print("%d move sequences, %d positions" % (len(nodes), len(rows)), file=sys.stderr)


if __name__ == "__main__":
    main()
