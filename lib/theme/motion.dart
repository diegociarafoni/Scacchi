import 'package:flutter/material.dart';

import '../settings/settings.dart';

/// Stile per dialoghi e fogli: senza animazione quando si chiede di ridurle,
/// altrimenti quello di sistema.
AnimationStyle? motionStyle(BuildContext context) {
  if (!context.mounted) return null;
  return reduceMotionOf(context) ? AnimationStyle.noAnimation : null;
}

/// Vero se l'utente chiede meno movimento, dall'impostazione dell'app o da
/// quella del telefono.
bool reduceMotionOf(BuildContext context) =>
    AppSettings.of(context).reduceMotion ||
    MediaQuery.disableAnimationsOf(context);
