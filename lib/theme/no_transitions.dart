import 'package:flutter/material.dart';

/// Pagine che compaiono senza transizione, per chi riduce le animazioni.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Tema delle transizioni senza movimento su ogni piattaforma.
const PageTransitionsTheme stillTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: NoTransitionsBuilder(),
    TargetPlatform.iOS: NoTransitionsBuilder(),
    TargetPlatform.linux: NoTransitionsBuilder(),
    TargetPlatform.macOS: NoTransitionsBuilder(),
    TargetPlatform.windows: NoTransitionsBuilder(),
    TargetPlatform.fuchsia: NoTransitionsBuilder(),
  },
);
