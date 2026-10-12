import '../l10n/app_localizations.dart';

/// Saluto di un bot nel fumetto, nella lingua dell'app; vuoto se il bot non
/// esiste.
String botGreeting(AppLocalizations l, String botId) => switch (botId) {
  'lia' => l.botGreetingLia,
  'pino' => l.botGreetingPino,
  'nico' => l.botGreetingNico,
  'chiara' => l.botGreetingChiara,
  'viola' => l.botGreetingViola,
  'rocco' => l.botGreetingRocco,
  'ettore' => l.botGreetingEttore,
  'marta' => l.botGreetingMarta,
  'bruna' => l.botGreetingBruna,
  'duilio' => l.botGreetingDuilio,
  'carlo' => l.botGreetingCarlo,
  'elena' => l.botGreetingElena,
  'ada' => l.botGreetingAda,
  'luna' => l.botGreetingLuna,
  'cosmo' => l.botGreetingCosmo,
  'massimo' => l.botGreetingMassimo,
  'stella' => l.botGreetingStella,
  'tino' => l.botGreetingTino,
  _ => '',
};

/// Battuta di un bot già battuto, per invitare alla rivincita.
String botRematchLine(AppLocalizations l, String botId) => switch (botId) {
  'lia' => l.botRematchLia,
  'pino' => l.botRematchPino,
  'nico' => l.botRematchNico,
  'chiara' => l.botRematchChiara,
  'viola' => l.botRematchViola,
  'rocco' => l.botRematchRocco,
  'ettore' => l.botRematchEttore,
  'marta' => l.botRematchMarta,
  'bruna' => l.botRematchBruna,
  'duilio' => l.botRematchDuilio,
  'carlo' => l.botRematchCarlo,
  'elena' => l.botRematchElena,
  'ada' => l.botRematchAda,
  'luna' => l.botRematchLuna,
  'cosmo' => l.botRematchCosmo,
  'massimo' => l.botRematchMassimo,
  'stella' => l.botRematchStella,
  'tino' => l.botRematchTino,
  _ => '',
};
