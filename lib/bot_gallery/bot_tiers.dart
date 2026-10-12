import '../engine/bots.dart';

/// Fasce della galleria dei bot, per Elo (RG-18).
enum BotTier {
  novice(0),
  beginner(800),
  intermediate(1300),
  advanced(1700),
  master(2100);

  const BotTier(this.minElo);

  /// Elo da cui comincia la fascia.
  final int minElo;
}

BotTier tierOfElo(int elo) => BotTier.values.lastWhere((t) => elo >= t.minElo);

BotTier tierOf(Bot bot) => tierOfElo(bot.elo);

/// Bot della scala in [tier], nell'ordine della scala.
List<Bot> botsInTier(BotTier tier) => [
  for (final bot in bots)
    if (tierOf(bot) == tier) bot,
];
