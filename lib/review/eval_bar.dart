import 'package:flutter/material.dart';

import '../engine/uci.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
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
    final l = AppLocalizations.of(context);
    // Profilo bambino (RP-06): la barra resta, senza cifre; a voce si dice
    // solo chi è avanti.
    final kid = AppSettings.of(context).kidMode;
    final label = s == null || kid
        ? ''
        : mated
        ? (win >= 50 ? '1-0' : '0-1')
        : formatScore(s);
    final description = s == null
        ? l.reviewScoreUnavailable
        : mated
        ? l.reviewScoreMated(win >= 50 ? 'white' : 'black')
        : kid
        ? _kidDescription(l, win)
        : describeScore(l, s);
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

  /// Fascia centrale ampia: piccoli vantaggi contano come equilibrio.
  static String _kidDescription(AppLocalizations l, double win) => win >= 60
      ? l.kidEvalWhite
      : win <= 40
      ? l.kidEvalBlack
      : l.kidEvalEven;
}
