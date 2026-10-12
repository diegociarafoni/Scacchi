import 'package:dartchess/dartchess.dart' show Side;

import '../archive/saved_game.dart';
import '../engine/bot_collection.dart';
import '../engine/bots.dart';
import '../path/curriculum.dart';

/// Quanti Elo sopra il proprio livello può stare il bot consigliato: una
/// sfida alla portata, non una scalata.
const recommendedBotMargin = 100;

/// Partita non conclusa più recente, quella da riprendere. Le importate e
/// quelle su scacchiera fisica non si riprendono nell'app.
SavedGame? unfinishedGame(Iterable<SavedGame> games) {
  SavedGame? best;
  for (final g in games) {
    if (g.finished ||
        g.mode == SavedGame.imported ||
        g.mode == SavedGame.physical) {
      continue;
    }
    if (best == null || g.updatedAt.isAfter(best.updatedAt)) best = g;
  }
  return best;
}

/// Ultime partite concluse, dalla più recente.
List<SavedGame> recentGames(Iterable<SavedGame> games, {int count = 3}) {
  final done = [
    for (final g in games)
      if (g.finished && g.mode != SavedGame.imported) g,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return done.take(count).toList();
}

enum NextStepKind { resumeGame, story, dailyPuzzle }

/// Il passo proposto in cima alla Home.
class NextStep {
  const NextStep(this.kind, {this.game, this.stage});

  final NextStepKind kind;
  final SavedGame? game;
  final Stage? stage;
}

/// Una sola proposta, in ordine: la partita lasciata a metà, poi la lezione
/// della Storia, poi il puzzle del giorno.
NextStep chooseNextStep({SavedGame? openGame, Stage? storyStage}) {
  if (openGame != null) {
    return NextStep(NextStepKind.resumeGame, game: openGame);
  }
  if (storyStage != null) {
    return NextStep(NextStepKind.story, stage: storyStage);
  }
  return const NextStep(NextStepKind.dailyPuzzle);
}

/// Bot da proporre: il più forte, tra quelli già sbloccati, che non supera il
/// proprio livello di più di [recommendedBotMargin] Elo; se nessuno è così
/// debole, il primo sbloccato.
Bot recommendedBot(int rating, BotCollection collection) {
  final unlocked = [
    for (final b in bots)
      if (collection.isUnlocked(b)) b,
  ];
  Bot pick = unlocked.first;
  for (final b in unlocked) {
    if (b.elo <= rating + recommendedBotMargin && b.elo >= pick.elo) pick = b;
  }
  return pick;
}

/// Funzione dell'app raggiungibile dalla Home.
class HomeFeature {
  const HomeFeature({
    required this.id,
    required this.label,
    this.keywords = const [],
  });

  final String id;
  final String label;

  /// Altre parole con cui cercare la funzione.
  final List<String> keywords;
}

/// Le funzioni che corrispondono a [query], senza badare a maiuscole e accenti.
List<HomeFeature> searchFeatures(List<HomeFeature> all, String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return all;
  return [
    for (final f in all)
      if ([f.label, ...f.keywords].any((t) => _fold(t).contains(q))) f,
  ];
}

String _fold(String text) {
  const from = 'àáâèéêìíîòóôùúû';
  const to = 'aaaeeeiiiooouuu';
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final r in lower.runes) {
    final c = String.fromCharCode(r);
    final i = from.indexOf(c);
    out.write(i < 0 ? c : to[i]);
  }
  return out.toString();
}

/// Nome dell'avversario di una partita, per le righe dell'elenco.
String opponentOf(SavedGame game) => switch (game.playerSide) {
  Side.white => game.black,
  Side.black => game.white,
  null => game.title,
};
