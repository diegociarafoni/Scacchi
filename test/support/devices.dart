import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Schermi di riferimento per i test di layout, golden e accessibilità.
enum Device {
  phoneSmall('telefono-piccolo', Size(360, 640), 2),
  phoneMedium('telefono-medio', Size(393, 852), 3),
  phoneLarge('telefono-grande', Size(430, 932), 3),
  phoneLandscape('telefono-orizzontale', Size(852, 393), 3),
  tablet('tablet', Size(820, 1180), 2);

  const Device(this.name, this.logicalSize, this.pixelRatio);

  final String name;
  final Size logicalSize;
  final double pixelRatio;

  static const phones = [phoneSmall, phoneMedium, phoneLarge];

  /// Altezza logica della barra a tre tasti di Android.
  static const double threeButtonBar = 48;

  /// Con [navBar] la parte bassa dello schermo è occupata dalla barra di
  /// navigazione di sistema, come con i tre tasti.
  void apply(WidgetTester tester, {double navBar = 0}) {
    final inset = FakeViewPadding(bottom: navBar * pixelRatio);
    tester.view
      ..physicalSize = logicalSize * pixelRatio
      ..devicePixelRatio = pixelRatio
      ..padding = inset
      ..viewPadding = inset;
    addTearDown(tester.view.reset);
  }
}
