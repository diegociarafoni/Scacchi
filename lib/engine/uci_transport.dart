import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:multistockfish/multistockfish.dart';

import 'process_transport.dart';

/// Canale di testo verso un motore UCI.
abstract interface class UciTransport {
  Stream<String> get lines;
  void send(String command);
  Future<void> dispose();
}

/// Stockfish 19 nativo tramite il plugin multistockfish su Android e iOS;
/// sui computer lo Stockfish installato, come processo esterno.
class StockfishTransport implements UciTransport {
  StockfishTransport._(this._engine);

  final Stockfish _engine;

  static bool get _mobile => Platform.isAndroid || Platform.isIOS;

  /// Solo per i test: rende l'esito indipendente dal motore installato.
  @visibleForTesting
  static bool? debugSupported;

  /// Sui computer serve lo Stockfish installato; su macOS la sandbox dell'app
  /// non permette di avviarlo.
  static bool get isSupported =>
      debugSupported ??
      _mobile ||
          ((Platform.isLinux || Platform.isWindows) &&
              ProcessTransport.binary != null);

  /// Sul telefono riprova se il motore precedente non ha ancora liberato il posto.
  static Future<UciTransport> start() async {
    if (!_mobile) return ProcessTransport.start();
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
