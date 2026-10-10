import 'dart:convert';
import 'dart:io';

import 'package:scacchi/engine/uci_transport.dart';

/// Stockfish nativo come processo esterno, per i test d'integrazione su
/// desktop e in CI. Cerca `STOCKFISH_PATH`, poi i percorsi abituali.
class ProcessTransport implements UciTransport {
  ProcessTransport._(this._process)
    : lines = _process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

  final Process _process;

  @override
  final Stream<String> lines;

  static String? findBinary() {
    final candidates = [
      Platform.environment['STOCKFISH_PATH'],
      '/usr/games/stockfish',
      '/usr/bin/stockfish',
      '/usr/local/bin/stockfish',
      '/opt/homebrew/bin/stockfish',
    ];
    for (final path in candidates) {
      if (path != null && File(path).existsSync()) return path;
    }
    return null;
  }

  static Future<UciTransport> start() async =>
      ProcessTransport._(await Process.start(findBinary()!, const []));

  @override
  void send(String command) => _process.stdin.writeln(command);

  @override
  Future<void> dispose() async {
    _process.stdin.writeln('quit');
    await _process.stdin.close();
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process.kill();
        return -1;
      },
    );
  }
}
