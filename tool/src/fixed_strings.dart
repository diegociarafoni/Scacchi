/// Un testo italiano scritto nel codice invece che nei file `.arb`.
class FixedString {
  const FixedString(this.line, this.text);

  final int line;
  final String text;
}

/// Marcatore che esclude una riga dal controllo (nomi propri, dati dell'archivio).
const _okMarker = 'l10n-ok';

// Parole che in una frase italiana non sono quasi mai inglesi o identificatori.
const _italianWords = {
  'il',
  'lo',
  'la',
  'le',
  'gli',
  'un',
  'una',
  'di',
  'del',
  'della',
  'dei',
  'delle',
  'che',
  'per',
  'con',
  'non',
  'è',
  'sei',
  'hai',
  'ha',
  'sono',
  'ho',
  'mossa',
  'mosse',
  'partita',
  'partite',
  'pezzo',
  'pezzi',
  'scacco',
  'matto',
  'stallo',
  'bianco',
  'bianchi',
  'nero',
  'neri',
  'tuo',
  'tua',
  'tu',
  'io',
  'puoi',
  'può',
  'prova',
  'bravo',
  'bravissimo',
  'ottimo',
  'sul',
  'sulla',
  'nel',
  'nella',
  'ma',
  'se',
  'più',
  'meno',
  'anche',
  'come',
  'quando',
  'dove',
  'perché',
  'così',
  'molto',
  'apertura',
  'aperture',
  'finale',
  'finali',
  'gioca',
  'giocare',
  'dai',
  'tocca',
  'ora',
  'ancora',
  'bella',
  'bello',
  'vinto',
  'perso',
  'pari',
  'torre',
  'cavallo',
  'alfiere',
  'donna',
  're',
  'pedone',
  'pedoni',
  'scacchiera',
  'casa',
  'colonna',
  'traversa',
  'livello',
  'lezione',
  'esercizio',
  'esercizi',
  'sfida',
  'bot',
  'attento',
  'attenta',
  'guarda',
  'pensaci',
  'calma',
  'salva',
  'preso',
  'regalo',
  'ahi',
  'qui',
  'grazie',
  'ne',
  'in',
  'al',
  'dal',
  'dalla',
  'nei',
  'sui',
  'tra',
  'fra',
  'ogni',
  'tutti',
  'tutte',
  'nessuno',
  'nessuna',
  'sempre',
  'mai',
  'poi',
};

final _word = RegExp(r'[A-Za-zÀ-ÿ]+');
final _accent = RegExp('[àèéìòùÀÈÉÌÒÙ]');

bool _isItalianProse(String text) {
  final plain = text.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), ' ');
  final words = _word.allMatches(plain).map((m) => m.group(0)!).toList();
  if (words.length < 2) return false;
  if (words.any((w) => _italianWords.contains(w.toLowerCase()))) return true;
  return words.length >= 3 && _accent.hasMatch(plain);
}

/// Testi italiani tra apici nel sorgente [source]; non guarda commenti,
/// `import`/`export`/`part` e righe con il marcatore `l10n-ok`.
List<FixedString> findFixedStrings(String source) {
  final hits = <FixedString>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') ||
        trimmed.startsWith('*') ||
        trimmed.startsWith('/*') ||
        RegExp(r'^(import|export|part)\s').hasMatch(trimmed) ||
        line.contains(_okMarker)) {
      continue;
    }
    for (final text in _literals(line)) {
      if (_isItalianProse(text)) hits.add(FixedString(i + 1, text));
    }
  }
  return hits;
}

/// Letterali di una riga, fermandosi a un commento `//` fuori dagli apici.
Iterable<String> _literals(String line) sync* {
  var i = 0;
  while (i < line.length) {
    final c = line[i];
    if (c == '/' && i + 1 < line.length && line[i + 1] == '/') return;
    if (c == "'" || c == '"') {
      final buffer = StringBuffer();
      var j = i + 1;
      var closed = false;
      while (j < line.length) {
        final d = line[j];
        if (d == r'\' && j + 1 < line.length) {
          buffer.write(line[j + 1]);
          j += 2;
          continue;
        }
        if (d == c) {
          closed = true;
          break;
        }
        buffer.write(d);
        j++;
      }
      if (!closed) return;
      yield buffer.toString();
      i = j + 1;
      continue;
    }
    i++;
  }
}

/// Conteggio dei testi fissi per cartella di `lib/`, ignorando `lib/l10n/` e
/// il codice generato. [sources] ha come chiavi i percorsi relativi alla radice.
Map<String, int> countByFolder(Map<String, String> sources) {
  final counts = <String, int>{};
  for (final MapEntry(key: path, value: text) in sources.entries) {
    final parts = path.split('/');
    if (parts.length < 3 || parts[0] != 'lib') continue;
    if (parts[1] == 'l10n' || path.endsWith('.g.dart')) continue;
    final n = findFixedStrings(text).length;
    if (n > 0) counts[parts[1]] = (counts[parts[1]] ?? 0) + n;
  }
  return counts;
}

/// Cartelle in cui i testi fissi sono più di quelli registrati in [base].
Map<String, int> regressions(Map<String, int> current, Map<String, int> base) =>
    {
      for (final e in current.entries)
        if (e.value > (base[e.key] ?? 0)) e.key: e.value,
    };
