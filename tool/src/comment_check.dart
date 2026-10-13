/// Controlli sui commenti del codice: niente app concorrenti, riferimenti a
/// PR o issue, né promemoria senza motivo. Lavora su testi già letti.
library;

final _competitor = RegExp(
  'lichess|chess\\.com|chesscom|chessable|chess24',
  caseSensitive: false,
);
final _reference = RegExp(
  r'\b(PR|pull request|issue)\s*#?\d+|\(#\d+\)',
  caseSensitive: false,
);
final _reminder = RegExp(r'\b(TODO|FIXME|XXX|HACK)\b(?!: .{15,})');

/// Problemi nei commenti a riga intera di [sources] (percorso → testo).
/// Un commento con un indirizzo web è una fonte e non si controlla.
List<String> checkComments(Map<String, String> sources) {
  final problems = <String>[];
  for (final MapEntry(key: path, value: text) in sources.entries) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimLeft();
      if (!line.startsWith('//') || line.contains('http')) continue;
      final where = '$path:${i + 1}';
      if (_competitor.hasMatch(line)) {
        problems.add('$where: il commento nomina un\'app concorrente');
      }
      if (_reference.hasMatch(line)) {
        problems.add('$where: il commento rimanda a una PR o a un\'issue');
      }
      if (_reminder.hasMatch(line)) {
        problems.add(
          '$where: promemoria senza motivo, scrivi "TODO: " e almeno una '
          'frase che dica cosa manca',
        );
      }
    }
  }
  return problems;
}
