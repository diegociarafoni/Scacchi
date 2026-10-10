import 'dart:io' show Platform;

import 'package:multistockfish/multistockfish.dart';

/// Canale di testo verso un motore UCI.
abstract interface class UciTransport {
  Stream<String> get lines;
  void send(String command);
  Future<void> dispose();
}

/// Stockfish 19 nativo tramite il plugin multistockfish.
class StockfishTransport implements UciTransport {
  StockfishTransport._(this._engine);

  final Stockfish _engine;

  /// multistockfish supporta solo Android e iOS.
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  static Future<UciTransport> start() async =>
      StockfishTransport._(await Stockfish.create());

  @override
  Stream<String> get lines => _engine.stdout;

  @override
  void send(String command) => _engine.stdin = command;

  @override
  Future<void> dispose() => _engine.dispose();
}
