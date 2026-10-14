import 'package:flutter_test/flutter_test.dart';
import 'package:rokko/review/personal_puzzles.dart';

void main() {
  test('gameIdOf è stabile e distingue le partite', () {
    expect(gameIdOf('a|e2e4'), gameIdOf('a|e2e4'));
    expect(gameIdOf('a|e2e4'), isNot(gameIdOf('a|d2d4')));
    // Valore fissato: non deve cambiare tra avvii e piattaforme.
    expect(gameIdOf('abc'), '7aigaz');
  });
}
