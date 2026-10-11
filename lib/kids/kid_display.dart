import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Rappresentazioni senza numeri del profilo bambino (RP-06), condivise da
/// profilo, scheda Tu, puzzle e revisione.

/// Oltre questo numero le stelle non crescono: una fila più lunga si
/// conterebbe, e tornerebbe a essere un numero.
const kidMaxStars = 10;

/// Precisione in stelle: una ogni 20 punti percentuali, da una a cinque.
int kidAccuracyStars(double accuracy) => (accuracy / 20).floor().clamp(1, 5);

/// Giudizio a parole che accompagna le stelle della precisione.
String kidAccuracyWords(AppLocalizations l, int stars) => switch (stars) {
  >= 5 => l.kidAccuracy5,
  4 => l.kidAccuracy4,
  3 => l.kidAccuracy3,
  2 => l.kidAccuracy2,
  _ => l.kidAccuracy1,
};

/// Requisito di sblocco di una ricompensa, senza «Livello N».
String kidRequirement(AppLocalizations l) => l.kidUnlockByPlaying;

/// Fila di stelle, al massimo [kidMaxStars]; [label] è il testo per i lettori
/// di schermo, che non leggono il conteggio.
class KidStars extends StatelessWidget {
  const KidStars({super.key, required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Wrap(
        children: [
          for (var i = 0; i < count.clamp(0, kidMaxStars); i++)
            Icon(Icons.star, color: color),
        ],
      ),
    );
  }
}

/// Serie di giorni come fiamma accesa o spenta, con una frase.
class KidFlame extends StatelessWidget {
  const KidFlame({super.key, required this.lit, this.style});

  final bool lit;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          color: lit ? scheme.primary : scheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(lit ? l.kidStreakOn : l.kidStreakOff, style: style),
        ),
      ],
    );
  }
}
