import 'package:flutter/foundation.dart';

import '../game/clock.dart';
import '../game/handicap.dart';
import '../game/variant.dart';

/// Opzioni della partita scelte nella galleria dei bot, dopo l'avversario:
/// cadenza, variante, handicap, allenatore acceso dall'inizio e modalità
/// Allenamento o Sfida.
@immutable
class GameOptions {
  const GameOptions({
    this.control,
    this.variant = Variant.standard,
    this.handicap,
    this.coach = false,
    this.training = false,
  });

  /// Cadenza; `null` per nessun orologio.
  final TimeControl? control;
  final Variant variant;
  final Handicap? handicap;
  final bool coach;

  /// Allenamento al posto della Sfida: aiuti accesi, niente Elo né vittorie.
  final bool training;
}
