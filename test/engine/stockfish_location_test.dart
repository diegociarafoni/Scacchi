import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/engine/process_transport.dart';

void main() {
  test('STOCKFISH_PATH ha la precedenza', () {
    expect(
      findStockfish(
        environment: {'STOCKFISH_PATH': '/x/sf', 'PATH': '/usr/bin'},
        exists: (p) => p == '/x/sf' || p == '/usr/bin/stockfish',
        windows: false,
      ),
      '/x/sf',
    );
  });

  test('cerca nelle cartelle di PATH', () {
    expect(
      findStockfish(
        environment: {'PATH': '/a:/b'},
        exists: (p) => p == '/b/stockfish',
        windows: false,
      ),
      '/b/stockfish',
    );
  });

  test('su Windows cerca stockfish.exe con il separatore ;', () {
    expect(
      findStockfish(
        environment: {'PATH': r'C:\a;C:\b'},
        exists: (p) => p == r'C:\b\stockfish.exe',
        windows: true,
      ),
      r'C:\b\stockfish.exe',
    );
  });

  test('prova i percorsi abituali di Linux e macOS', () {
    expect(
      findStockfish(
        environment: const {},
        exists: (p) => p == '/opt/homebrew/bin/stockfish',
        windows: false,
      ),
      '/opt/homebrew/bin/stockfish',
    );
  });

  test('senza Stockfish restituisce null', () {
    expect(
      findStockfish(
        environment: {'PATH': '/a'},
        exists: (_) => false,
        windows: false,
      ),
      isNull,
    );
  });
}
