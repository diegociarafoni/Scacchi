#!/usr/bin/env python3
"""Builds the curated puzzle subset shipped with the app.

Reads the Lichess puzzle database (CC0) as decompressed CSV on stdin and writes
assets/puzzles/puzzles.csv. The selection is deterministic: the same input
always yields the same output.

Usage:
  curl -sS https://database.lichess.org/lichess_db_puzzle.csv.zst \
    | zstd -dc | python3 tool/datasets/build_puzzles.py > assets/puzzles/puzzles.csv
"""

import csv
import hashlib
import sys

MIN_RATING = 400
MAX_RATING = 3000
BAND = 100
PER_BAND = 200
PER_THEME_IN_BAND = 6
MAX_DEVIATION = 85
MIN_POPULARITY = 85
MIN_PLAYS = 800

# Themes the app offers as filters; each band tries to cover all of them.
KEY_THEMES = [
    "mateIn1", "mateIn2", "mateIn3", "mateIn4", "mateIn5",
    "fork", "pin", "skewer", "discoveredAttack", "doubleCheck",
    "hangingPiece", "trappedPiece", "deflection", "attraction",
    "sacrifice", "backRankMate", "smotheredMate", "promotion",
    "endgame", "middlegame", "opening",
    "pawnEndgame", "rookEndgame", "queenEndgame", "knightEndgame",
    "bishopEndgame", "zugzwang", "quietMove", "defensiveMove",
    "advancedPawn", "kingsideAttack", "queensideAttack", "exposedKing",
    "intermezzo", "clearance", "interference", "xRayAttack",
    "capturingDefender", "enPassant", "castling", "underPromotion",
]


def order_key(puzzle_id):
    return hashlib.sha1(puzzle_id.encode()).hexdigest()


def main():
    bands = {}
    reader = csv.reader(sys.stdin)
    header = next(reader)
    col = {name: i for i, name in enumerate(header)}
    for row in reader:
        try:
            rating = int(row[col["Rating"]])
            deviation = int(row[col["RatingDeviation"]])
            popularity = int(row[col["Popularity"]])
            plays = int(row[col["NbPlays"]])
        except (ValueError, IndexError):
            continue
        if not MIN_RATING <= rating < MAX_RATING:
            continue
        if deviation > MAX_DEVIATION or popularity < MIN_POPULARITY:
            continue
        if plays < MIN_PLAYS:
            continue
        band = (rating - MIN_RATING) // BAND
        bands.setdefault(band, []).append((
            order_key(row[col["PuzzleId"]]),
            row[col["PuzzleId"]],
            row[col["FEN"]],
            row[col["Moves"]],
            rating,
            row[col["Themes"]],
        ))

    out = csv.writer(sys.stdout, lineterminator="\n")
    out.writerow(["id", "fen", "moves", "rating", "themes"])
    total = 0
    for band in sorted(bands):
        candidates = sorted(bands[band])
        chosen = {}
        for theme in KEY_THEMES:
            taken = 0
            for c in candidates:
                if taken >= PER_THEME_IN_BAND or len(chosen) >= PER_BAND:
                    break
                if theme in c[5].split() and c[1] not in chosen:
                    chosen[c[1]] = c
                    taken += 1
        for c in candidates:
            if len(chosen) >= PER_BAND:
                break
            chosen.setdefault(c[1], c)
        for c in sorted(chosen.values(), key=lambda c: (c[4], c[1])):
            out.writerow(c[1:])
            total += 1
    print(f"puzzles: {total}", file=sys.stderr)


if __name__ == "__main__":
    main()
