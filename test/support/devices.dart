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

  void apply(WidgetTester tester) {
    tester.view
      ..physicalSize = logicalSize * pixelRatio
      ..devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
  }
}
