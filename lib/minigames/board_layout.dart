import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scacchiera e pannello: affiancati in orizzontale, impilati in verticale.
class BoardLayout extends StatelessWidget {
  const BoardLayout({super.key, required this.board, required this.panel});

  /// Costruisce la scacchiera del lato indicato.
  final Widget Function(double size) board;
  final Widget panel;

  /// Spazio minimo sotto la scacchiera in verticale per testo e comandi.
  static const double _portraitReserve = 240;

  /// Larghezza minima del pannello accanto alla scacchiera in orizzontale.
  static const double _landscapePanel = 280;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape =
              constraints.maxWidth - constraints.maxHeight >= _landscapePanel;
          final size = math.max(
            0.0,
            landscape
                ? constraints.maxHeight
                : math.min(
                    constraints.maxWidth,
                    constraints.maxHeight - _portraitReserve,
                  ),
          );
          final scrollable = SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: panel,
          );
          if (landscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                board(size),
                Expanded(child: scrollable),
              ],
            );
          }
          return Column(
            children: [
              Center(child: board(size)),
              Expanded(child: scrollable),
            ],
          );
        },
      ),
    );
  }
}
