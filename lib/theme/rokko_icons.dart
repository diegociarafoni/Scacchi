import 'package:flutter/material.dart';

/// Icone dei comandi di partita: tutte della famiglia a contorno, così
/// barra, pannello e menu hanno lo stesso tratto.
abstract final class RokkoIcons {
  static const IconData newGame = Icons.add_outlined;
  static const IconData undo = Icons.undo_outlined;
  static const IconData flip = Icons.swap_vert_outlined;
  static const IconData draw = Icons.handshake_outlined;
  static const IconData resign = Icons.flag_outlined;
  static const IconData hint = Icons.lightbulb_outlined;
  static const IconData rematch = Icons.replay_outlined;
  static const IconData review = Icons.fact_check_outlined;
  static const IconData threat = Icons.warning_amber_outlined;
  static const IconData coach = Icons.school_outlined;
  static const IconData more = Icons.more_horiz_outlined;
  static const IconData keyboard = Icons.keyboard_outlined;
  static const IconData explorer = Icons.account_tree_outlined;
  static const IconData zen = Icons.self_improvement_outlined;

  /// Pieno solo a modalità zen accesa: è il segno dello stato.
  static const IconData zenOn = Icons.self_improvement;
  static const IconData settings = Icons.settings_outlined;
}
