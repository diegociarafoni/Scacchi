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
    for (final entry in (environment['PATH'] ?? '').split(windows ? ';' : ':'))
      if (_cleanDir(entry, separator) case final dir when dir.isNotEmpty)
        '$dir$separator$name',
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

String _cleanDir(String entry, String separator) {
  var dir = entry.trim();
  if (dir.length >= 2 && dir.startsWith('"') && dir.endsWith('"')) {
    dir = dir.substring(1, dir.length - 1);
  }
  while (dir.length > 1 && dir.endsWith(separator)) {
    dir = dir.substring(0, dir.length - 1);
  }
  return dir;
}

/// Stockfish come processo esterno, per i computer.
class ProcessTransport implements UciTransport {
  ProcessTransport._(this._process)
    : lines = _process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .asBroadcastStream() {
    // Un processo terminato non deve far fallire le scritture fuori controllo.
    _process.stdin.done.ignore();
    _process.stderr.drain<void>().ignore();
  }

  final Process _process;

  @override
  final Stream<String> lines;

  /// Cercato una volta, all'avvio.
  static final String? binary = findStockfish(
    environment: Platform.environment,
    exists: (path) => File(path).existsSync(),
    windows: Platform.isWindows,
  );

  static Future<UciTransport> start() async {
    final path = binary;
    if (path == null) {
      throw const FileSystemException('Stockfish non trovato');
    }
    return ProcessTransport._(await Process.start(path, const []));
  }

  @override
  void send(String command) {
    try {
      _process.stdin.writeln(command);
    } on StateError {
      // Processo già chiuso: la richiesta scadrà e il motore verrà riavviato.
    }
  }

  @override
  Future<void> dispose() async {
    send('quit');
    await _process.stdin.close().catchError((_) {});
    await _process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _process.kill();
        return -1;
      },
    );
  }
}
