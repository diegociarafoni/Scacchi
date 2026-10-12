import 'package:flutter/foundation.dart';

import '../game/clock.dart';
import '../game/handicap.dart';
import '../game/variant.dart';

/// Opzioni della partita scelte nella galleria dei bot, dopo l'avversario:
/// cadenza, variante, handicap e allenatore acceso dall'inizio.
@immutable
class GameOptions {
  const GameOptions({
    this.control,
    this.variant = Variant.standard,
    this.handicap,
    this.coach = false,
  });

  /// Cadenza; `null` per nessun orologio.
  final TimeControl? control;
  final Variant variant;
  final Handicap? handicap;
  final bool coach;
}
