import 'package:dartchess/dartchess.dart';

import '../progress/activity.dart';

/// Partita già impostata contro il computer, lanciata da un'altra schermata
/// (guardiano del percorso, partita di un torneo): parte subito, senza scelte
/// e senza poter ricominciare o annullare.
class GameChallenge {
  const GameChallenge({
    required this.title,
    required this.levelId,
    required this.side,
  });

  /// Titolo della schermata, per esempio "Il guardiano".
  final String title;

  /// Livello del motore (vedi `engineLevels`).
  final int levelId;

  /// Colore dell'utente.
  final Side side;
}

/// Stelle di una sfida vinta, in base alla lunghezza della partita: tre fino a
/// 40 mosse, due fino a 60, poi una. `null` se non si è vinto.
int? challengeStars(GameResult result, {required int moves}) {
  if (result != GameResult.win) return null;
  if (moves <= 40) return 3;
  if (moves <= 60) return 2;
  return 1;
}
