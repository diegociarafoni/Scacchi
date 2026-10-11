/// Righe eseguibili e righe coperte di un file.
class FileCoverage {
  FileCoverage(this.found, this.hit);

  final int found;
  final int hit;
}

/// Legge un file lcov in una mappa percorso → copertura.
Map<String, FileCoverage> parseLcov(String lcov) {
  final result = <String, FileCoverage>{};
  String? file;
  var found = 0;
  var hit = 0;
  for (final line in lcov.split('\n')) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).replaceAll(r'\', '/');
      found = 0;
      hit = 0;
    } else if (line.startsWith('LF:')) {
      found = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit = int.parse(line.substring(3));
    } else if (line == 'end_of_record' && file != null) {
      result[file] = FileCoverage(found, hit);
      file = null;
    }
  }
  return result;
}

double coveragePercent(Iterable<FileCoverage> files) {
  var found = 0;
  var hit = 0;
  for (final f in files) {
    found += f.found;
    hit += f.hit;
  }
  return found == 0 ? 100 : hit * 100 / found;
}

final _uiImport = RegExp(
  r'''^\s*import\s+['"](package:flutter/|dart:ui)''',
  multiLine: true,
);

/// La logica di gioco è il codice scritto a mano che non dipende da Flutter.
bool isGameLogic(String source) =>
    !source.contains('GENERATED CODE') && !_uiImport.hasMatch(source);
