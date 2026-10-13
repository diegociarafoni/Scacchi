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
  'ancora',
  'bella',
  'bello',
  'vinto',
  'perso',
  'torre',
  'cavallo',
  'alfiere',
  'donna',
  'pedone',
  'pedoni',
  'scacchiera',
  'colonna',
  'traversa',
  'livello',
  'lezione',
  'esercizio',
  'esercizi',
  'sfida',
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
  'dal',
  'dalla',
  'nei',
  'sui',
  'ogni',
  'tutti',
  'tutte',
  'nessuno',
  'nessuna',
  'sempre',
};

final _word = RegExp(r'[A-Za-zÀ-ÿ]+');
final _accent = RegExp('[àèéìòùÀÈÉÌÒÙ]');

bool _isItalianProse(String text) {
  final words = _word.allMatches(text).map((m) => m.group(0)!).toList();
  if (words.length < 2) return false;
  if (words.any((w) => _italianWords.contains(w.toLowerCase()))) return true;
  return words.length >= 3 && _accent.hasMatch(text);
}

/// Testi italiani tra apici nel sorgente [source]; non guarda commenti,
/// `import`/`export`/`part` e righe con il marcatore `l10n-ok`.
List<FixedString> findFixedStrings(String source) {
  final lines = source.split('\n');
  final hits = <FixedString>[];
  for (final literal in _Scanner(source).literals()) {
    final line = lines[literal.line - 1];
    if (line.contains(_okMarker) ||
        RegExp(r'^\s*(import|export|part)\s').hasMatch(line)) {
      continue;
    }
    if (_isItalianProse(literal.text)) hits.add(literal);
  }
  return hits;
}

/// Legge un sorgente Dart intero: salta i commenti (anche annidati e su più
/// righe) e decodifica i letterali, con le interpolazioni sostituite da uno
/// spazio.
class _Scanner {
  _Scanner(this._s);

  final String _s;
  int _i = 0;
  int _line = 1;

  bool _isIdent(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

  Iterable<FixedString> literals() sync* {
    while (_i < _s.length) {
      final c = _s[_i];
      final next = _i + 1 < _s.length ? _s[_i + 1] : '';
      if (c == '\n') {
        _line++;
        _i++;
      } else if (c == '/' && next == '/') {
        while (_i < _s.length && _s[_i] != '\n') {
          _i++;
        }
      } else if (c == '/' && next == '*') {
        _skipBlockComment();
      } else if (c == "'" || c == '"') {
        final line = _line;
        yield FixedString(line, _readString(raw: false));
      } else if (c == 'r' &&
          (next == "'" || next == '"') &&
          (_i == 0 || !_isIdent(_s[_i - 1]))) {
        _i++;
        final line = _line;
        yield FixedString(line, _readString(raw: true));
      } else {
        _i++;
      }
    }
  }

  void _skipBlockComment() {
    var depth = 0;
    while (_i < _s.length) {
      if (_s.startsWith('/*', _i)) {
        depth++;
        _i += 2;
      } else if (_s.startsWith('*/', _i)) {
        depth--;
        _i += 2;
        if (depth == 0) return;
      } else {
        if (_s[_i] == '\n') _line++;
        _i++;
      }
    }
  }

  /// Parte dall'apice di apertura e termina dopo quello di chiusura.
  String _readString({required bool raw}) {
    final q = _s[_i];
    final triple = _s.startsWith(q * 3, _i);
    _i += triple ? 3 : 1;
    final out = StringBuffer();
    while (_i < _s.length) {
      final d = _s[_i];
      if (triple ? _s.startsWith(q * 3, _i) : d == q) {
        _i += triple ? 3 : 1;
        break;
      }
      if (d == '\n') {
        if (!triple) break; // apice mai chiuso: non inghiottire il resto
        _line++;
      }
      if (!raw && d == r'\') {
        _escape(out);
      } else if (!raw && d == r'$') {
        _interpolation(out);
      } else {
        out.write(d);
        _i++;
      }
    }
    return out.toString();
  }

  void _escape(StringBuffer out) {
    final e = _i + 1 < _s.length ? _s[_i + 1] : '';
    _i += 2;
    switch (e) {
      case 'n':
        out.write('\n');
      case 't':
        out.write('\t');
      case 'r' || 'b' || 'f' || 'v':
        out.write(' ');
      case 'u' || 'x':
        final braced = e == 'u' && _i < _s.length && _s[_i] == '{';
        final length = e == 'x' ? 2 : 4;
        final end = braced ? _s.indexOf('}', _i) : _i + length;
        final digits = braced
            ? _s.substring(_i + 1, end < 0 ? _i + 1 : end)
            : _s.substring(_i, end > _s.length ? _s.length : end);
        final code = int.tryParse(digits, radix: 16);
        if (code == null || code > 0x10FFFF) {
          out.write(e);
        } else {
          out.writeCharCode(code);
          _i = braced ? end + 1 : end;
        }
      case '\n':
        _line++;
      default:
        out.write(e);
    }
  }

  void _interpolation(StringBuffer out) {
    out.write(' ');
    _i++;
    if (_i < _s.length && _s[_i] == '{') {
      _i++;
      var depth = 1;
      while (_i < _s.length && depth > 0) {
        final c = _s[_i];
        if (c == '{') {
          depth++;
          _i++;
        } else if (c == '}') {
          depth--;
          _i++;
        } else if (c == "'" || c == '"') {
          _readString(raw: false);
        } else {
          if (c == '\n') _line++;
          _i++;
        }
      }
    } else {
      while (_i < _s.length && RegExp(r'\w').hasMatch(_s[_i])) {
        _i++;
      }
    }
  }
}

/// Nome del gruppo dei file direttamente in `lib/` (come `main.dart`).
const rootFolder = '(radice)';

/// Conteggio dei testi fissi per cartella di `lib/`, ignorando `lib/l10n/` e
/// il codice generato. [sources] ha come chiavi i percorsi relativi alla radice.
Map<String, int> countByFolder(Map<String, String> sources) {
  final counts = <String, int>{};
  for (final MapEntry(key: path, value: text) in sources.entries) {
    final parts = path.split('/');
    if (parts.length < 2 || parts[0] != 'lib') continue;
    if (parts.length > 2 && parts[1] == 'l10n') continue;
    if (path.endsWith('.g.dart')) continue;
    final folder = parts.length == 2 ? rootFolder : parts[1];
    final n = findFixedStrings(text).length;
    if (n > 0) counts[folder] = (counts[folder] ?? 0) + n;
  }
  return counts;
}

/// Cartelle in cui i testi fissi sono più di quelli registrati in [base].
Map<String, int> regressions(Map<String, int> current, Map<String, int> base) =>
    {
      for (final e in current.entries)
        if (e.value > (base[e.key] ?? 0)) e.key: e.value,
    };

/// Cartelle in cui i testi fissi sono scesi sotto la base.
Map<String, int> improvements(
  Map<String, int> current,
  Map<String, int> base,
) => {
  for (final e in base.entries)
    if ((current[e.key] ?? 0) < e.value) e.key: current[e.key] ?? 0,
};
