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

  /// Riprova se il motore precedente non ha ancora liberato il posto.
  static Future<UciTransport> start() async {
    for (var attempt = 1; ; attempt++) {
      try {
        return StockfishTransport._(await Stockfish.create());
      } on StateError {
        // Il rilascio del motore precedente può richiedere alcuni secondi.
        if (attempt == 20) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  Stream<String> get lines => _engine.stdout;

  @override
  void send(String command) => _engine.stdin = command;

  @override
  Future<void> dispose() => _engine.dispose();
}
