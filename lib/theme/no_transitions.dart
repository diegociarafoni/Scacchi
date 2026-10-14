import 'package:flutter/cupertino.dart';
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

/// Tema delle transizioni senza movimento. Su iOS e macOS resta quella di
/// sistema, perché porta anche il gesto per tornare indietro dal bordo.
const PageTransitionsTheme stillTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: NoTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: NoTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: NoTransitionsBuilder(),
    TargetPlatform.fuchsia: NoTransitionsBuilder(),
  },
);
