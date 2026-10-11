#!/usr/bin/env python3
"""Builds assets/openings/openings.tsv from the Lichess chess-openings data set (CC0).

Converts each line from SAN to UCI so the app does not need to parse SAN at startup.

Usage: python3 tool/datasets/build_openings.py > assets/openings/openings.tsv
"""

import csv
import io
import sys
import urllib.request

import chess

SOURCE = "https://raw.githubusercontent.com/lichess-org/chess-openings/master/{}.tsv"


def main():
    out = csv.writer(sys.stdout, delimiter="\t", lineterminator="\n")
    out.writerow(["eco", "name", "uci"])
    for volume in "abcde":
        with urllib.request.urlopen(SOURCE.format(volume)) as response:
            text = response.read().decode()
        for row in csv.DictReader(io.StringIO(text), delimiter="\t"):
            board = chess.Board()
            moves = []
            for token in row["pgn"].split():
                if token.endswith("."):
                    continue
                move = board.parse_san(token)
                moves.append(move.uci())
                board.push(move)
            out.writerow([row["eco"], row["name"], " ".join(moves)])


if __name__ == "__main__":
    main()
