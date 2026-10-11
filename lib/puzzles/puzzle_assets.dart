import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../storage/key_value_store.dart';
import 'puzzle.dart';
import 'puzzle_library.dart';
import 'puzzle_trainer.dart';

const puzzleAsset = 'assets/puzzles/puzzles.csv';

Future<PuzzleLibrary> loadPuzzleLibrary([AssetBundle? bundle]) async {
  final csv = await (bundle ?? rootBundle).loadString(puzzleAsset);
  return PuzzleLibrary(await compute(Puzzle.parseCsvFile, csv));
}

Future<PuzzleTrainer> loadPuzzleTrainer() async =>
    PuzzleTrainer.load(await loadPuzzleLibrary(), await JsonFileStore.open());
