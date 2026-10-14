import 'package:flutter/material.dart';

import 'motion.dart';

/// Scheda a comparsa dal basso che resta sopra i tasti di sistema: con la
/// barra a tre tasti il contenuto non va sotto la navigazione di Android.
Future<T?> showRokkoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool showDragHandle = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: motionStyle(context),
  showDragHandle: showDragHandle,
  builder: (context) => SafeArea(top: false, child: builder(context)),
);

/// Riempimento di una lista o di un pannello scorrevole: aggiunge in basso
/// l'ingombro della navigazione di sistema, che un riempimento esplicito
/// altrimenti sostituisce invece di sommare. Dentro un `SafeArea` o sopra una
/// barra inferiore l'ingombro è già stato tolto e non si somma due volte.
extension SystemInsets on BuildContext {
  EdgeInsets withSystemBottom(EdgeInsets base) =>
      base.copyWith(bottom: base.bottom + MediaQuery.paddingOf(this).bottom);
}
