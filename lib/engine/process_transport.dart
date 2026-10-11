import 'dart:convert';
import 'dart:io';

import 'uci_transport.dart';

/// Percorso di Stockfish sul computer: `STOCKFISH_PATH`, poi le cartelle di
/// `PATH`, poi i percorsi abituali di Linux e macOS.
String? findStockfish({
  required Map<String, String> environment,
  required bool Function(String path) exists,
  required bool windows,
}) {
  final separator = windows ? r'\' : '/';
  final name = windows ? 'stockfish.exe' : 'stockfish';
  final candidates = [
    ?environment['STOCKFISH_PATH'],
    for (final dir in (environment['PATH'] ?? '').split(windows ? ';' : ':'))
      if (dir.isNotEmpty) '$dir$separator$name',
    if (!windows) ...[
      '/usr/games/stockfish',
      '/usr/bin/stockfish',
      '/usr/local/bin/stockfish',
      '/opt/homebrew/bin/stockfish',
    ],
  ];
  for (final path in candidates) {
    if (exists(path)) return path;
  }
  return null;
}

/// Stockfish come processo esterno, per i computer.
class ProcessTransport implements UciTransport {
  ProcessTransport._(this._process)
    : lines = _process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream();

  final Process _process;

  @override
  final Stream<String> lines;

  static String? findBinary() => findStockfish(
    environment: Platform.environment,
    exists: (path) => File(path).existsSync(),
    windows: Platform.isWindows,
  );

  static Future<UciTransport> start() async {
    final binary = findBinary();
    if (binary == null) throw StateError('Stockfish non trovato');
    return ProcessTransport._(await Process.start(binary, const []));
  }

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
