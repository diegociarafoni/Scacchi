import 'package:flutter/material.dart';

import '../engine/uci.dart';
import 'score_format.dart';

const double evalBarWidth = 20;

/// Barra verticale: la parte bianca è la probabilità di vittoria del Bianco.
class EvalBar extends StatelessWidget {
  const EvalBar({super.key, required this.height, this.score, this.whiteWin});

  final double height;
  final EngineScore? score;
  final double? whiteWin;

  @override
  Widget build(BuildContext context) {
    final win = whiteWin ?? 50;
    final s = score;
    // Il matto avvenuto non ha segno: il vincitore si ricava dalla probabilità.
    final mated = s?.mate == 0;
    final winner = win >= 50 ? 'Bianco' : 'Nero';
    final label = s == null
        ? ''
        : mated
        ? (win >= 50 ? '1-0' : '0-1')
        : formatScore(s);
    final description = s == null
        ? 'Valutazione non disponibile'
        : mated
        ? 'Scacco matto: vince il $winner'
        : describeScore(s);
    return Semantics(
      label: description,
      excludeSemantics: true,
      child: SizedBox(
        width: evalBarWidth,
        height: height,
        child: Stack(
          children: [
            Container(color: const Color(0xFF404040)),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: height * win / 100,
                color: const Color(0xFFF2F2F2),
              ),
            ),
            Align(
              alignment: win >= 50
                  ? Alignment.bottomCenter
                  : Alignment.topCenter,
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    label,
                    key: const ValueKey('eval-text'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: win >= 50
                          ? const Color(0xFF202020)
                          : const Color(0xFFF2F2F2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
