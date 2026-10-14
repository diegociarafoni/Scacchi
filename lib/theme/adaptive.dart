import 'package:flutter/widgets.dart';

/// Larghezza massima del contenuto delle schede su schermi larghi.
const double contentMaxWidth = 840;

/// Classi di larghezza della finestra (come le classi di Material): una
/// finestra stretta, per esempio con lo schermo diviso, usa il layout da
/// telefono; un tablet o un pieghevole aperto usa quello esteso.
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize forWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    return WindowSize.expanded;
  }

  static WindowSize of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}
