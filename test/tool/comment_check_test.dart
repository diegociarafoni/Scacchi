import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/comment_check.dart';

void main() {
  test('un commento funzionale passa', () {
    expect(
      checkComments({'a.dart': '// Serve a evitare un doppio salvataggio'}),
      isEmpty,
    );
  });

  test('segnala le app concorrenti', () {
    final p = checkComments({'a.dart': 'int a = 1;\n  /// Formato Lichess'});
    expect(p, ['a.dart:2: il commento nomina un\'app concorrente']);
  });

  test('un indirizzo web è una fonte e passa', () {
    expect(
      checkComments({'a.dart': '// Dati da https://database.lichess.org/'}),
      isEmpty,
    );
  });

  test('segnala i rimandi a PR e issue', () {
    expect(
      checkComments({'a.dart': '// Aggiunto con la PR #12'}),
      hasLength(1),
    );
    expect(checkComments({'a.dart': '// Corretto (#240)'}), hasLength(1));
  });

  test('un promemoria vuole il motivo', () {
    expect(checkComments({'a.dart': '// TODO'}), hasLength(1));
    expect(
      checkComments({'a.dart': '// TODO: manca la gestione del timeout'}),
      isEmpty,
    );
  });

  test('il codice con le stesse parole non conta', () {
    expect(
      checkComments({'a.dart': "final s = 'lichess'; // vedi sotto"}),
      isEmpty,
    );
  });
}
