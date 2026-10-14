import 'package:flutter/material.dart';

import '../settings/settings.dart';

/// Stile per dialoghi e fogli: senza animazione quando si chiede di ridurle,
/// altrimenti quello di sistema.
AnimationStyle? motionStyle(BuildContext context) {
  if (!context.mounted) return null;
  final still =
      AppSettings.of(context).reduceMotion ||
      MediaQuery.disableAnimationsOf(context);
  return still ? AnimationStyle.noAnimation : null;
}
