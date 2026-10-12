import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carica Roboto e le icone Material dell'SDK: i golden mostrano testo leggibile
/// invece dei rettangoli del font di test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) {
    throw StateError('FLUTTER_ROOT non è impostata: servono i font dell\'SDK');
  }
  final fonts = '$root/bin/cache/artifacts/material_fonts';
  await _load('Roboto', [
    '$fonts/Roboto-Regular.ttf',
    '$fonts/Roboto-Medium.ttf',
    '$fonts/Roboto-Bold.ttf',
  ]);
  await _load('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
  await testMain();
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
  }
  await loader.load();
}
