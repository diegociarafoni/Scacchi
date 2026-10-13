import '../l10n/app_localizations.dart';
import 'game_phase.dart';
import 'move_classification.dart';

/// Nome breve della categoria di una mossa, dai file `review.arb`.
String moveClassLabel(AppLocalizations l, MoveClass c) => switch (c) {
  MoveClass.brilliant => l.reviewClassBrilliant,
  MoveClass.great => l.reviewClassGreat,
  MoveClass.best => l.reviewClassBest,
  MoveClass.excellent => l.reviewClassExcellent,
  MoveClass.good => l.reviewClassGood,
  MoveClass.book => l.reviewClassBook,
  MoveClass.inaccuracy => l.reviewClassInaccuracy,
  MoveClass.mistake => l.reviewClassMistake,
  MoveClass.miss => l.reviewClassMiss,
  MoveClass.blunder => l.reviewClassBlunder,
};

String phaseLabel(AppLocalizations l, GamePhase p) => switch (p) {
  GamePhase.opening => l.reviewPhaseOpening,
  GamePhase.middlegame => l.reviewPhaseMiddlegame,
  GamePhase.endgame => l.reviewPhaseEndgame,
};
