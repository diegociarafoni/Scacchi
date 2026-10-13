import '../l10n/content.dart';

/// Nomi delle aperture nella lingua attiva.
///
/// Il libro è in inglese, quindi in inglese il nome resta quello del
/// libro. Per le altre lingue le famiglie più comuni hanno la loro traduzione
/// e le varianti si compongono da un piccolo glossario (sostantivi, aggettivi,
/// nazionalità), tutto in `assets/content/<lingua>/opening_names.json`. I nomi
/// propri restano invariati; ciò che non si sa tradurre resta com'è, così non
/// si perde mai l'informazione.
///
/// Gli id del file sono: `family.<nome inglese>`, `phrase.<gruppo di parole>`,
/// `noun.<parola>` (forma e genere, `f` o `m`), `adjective.<parola>` (forma
/// maschile e femminile), `prefix.<prefisso>`, `grammar.with` ("con") e
/// `grammar.feminine` (inizi dei nomi di genere femminile, a cui gli aggettivi
/// senza sostantivo come "Open" si accordano).
String localOpeningName(String name) {
  final texts = Content.of('opening_names');
  if (!identical(texts, _namerFor)) {
    _namerFor = texts;
    _namer = texts.hasLanguage ? _OpeningNamer(texts) : null;
  }
  return _namer?.name(name) ?? name;
}

ContentText? _namerFor;
_OpeningNamer? _namer;

class _OpeningNamer {
  _OpeningNamer(ContentText texts)
    : _families = _strings(texts, 'family.'),
      _phrases = _strings(texts, 'phrase.'),
      _prefixes = _strings(texts, 'prefix.'),
      _nouns = {
        for (final id in texts.ownIds)
          if (id.startsWith('noun.'))
            id.substring(5): (
              texts.ownList(id)![0],
              texts.ownList(id)![1] == 'f',
            ),
      },
      _adjectives = {
        for (final id in texts.ownIds)
          if (id.startsWith('adjective.'))
            id.substring(10): (texts.ownList(id)![0], texts.ownList(id)![1]),
      },
      _with = texts.ownText('grammar.with'),
      _feminineStarts = texts.ownList('grammar.feminine') ?? const [];

  static Map<String, String> _strings(ContentText texts, String prefix) => {
    for (final id in texts.ownIds)
      if (id.startsWith(prefix))
        id.substring(prefix.length): texts.ownText(id)!,
  };

  /// Famiglie complete tradotte.
  final Map<String, String> _families;

  /// Gruppi di parole che si traducono insieme, provati prima delle singole.
  final Map<String, String> _phrases;
  final Map<String, String> _prefixes;

  /// Sostantivi che reggono la frase: forma e genere (vero se femminile).
  final Map<String, (String, bool)> _nouns;

  /// Aggettivi: forma maschile e femminile (la stessa se invariabile).
  final Map<String, (String, String)> _adjectives;
  final String? _with;
  final List<String> _feminineStarts;
  final _cache = <String, String>{};

  static final _acceptedDeclined = RegExp(r'^(.*) (Accepted|Declined)$');

  String name(String name) => _cache.putIfAbsent(name, () {
    final i = name.indexOf(': ');
    final family = _family(i < 0 ? name : name.substring(0, i));
    if (i < 0) return family;
    final fem = _isFeminine(family);
    final rest = name
        .substring(i + 2)
        .split(', ')
        .map((p) => _part(p, feminine: fem))
        .join(', ');
    return '$family: $rest';
  });

  /// Famiglia, anche con coda ("Accepted", "Declined", ", with e3").
  String _family(String text) {
    final comma = text.split(', ');
    final head = _familyHead(comma.first);
    if (comma.length == 1) return head;
    final fem = _isFeminine(head);
    return [
      head,
      ...comma.skip(1).map((p) => _part(p, feminine: fem)),
    ].join(', ');
  }

  /// Vero se il nome tradotto dell'apertura è femminile: gli aggettivi senza
  /// sostantivo ("Open", "Closed") si accordano con lui.
  bool _isFeminine(String translated) =>
      _feminineStarts.any(translated.startsWith);

  String _familyHead(String text) {
    final known = _families[text];
    if (known != null) return known;
    final m = _acceptedDeclined.firstMatch(text);
    if (m != null) {
      final base = _families[m[1]];
      final adj = _adjectives[m[2]];
      if (base != null && adj != null) {
        return '$base ${_isFeminine(base) ? adj.$2 : adj.$1}';
      }
    }
    return _part(text, feminine: false);
  }

  /// Un pezzo di nome: "sostantivo + aggettivi" se c'è un sostantivo noto,
  /// altrimenti parola per parola.
  String _part(String text, {required bool feminine}) {
    final withWord = _with;
    if (withWord != null && text.startsWith('with ')) {
      return '$withWord ${_part(text.substring(5), feminine: feminine)}';
    }
    final words = text.split(' ');
    final k = words.lastIndexWhere(_nouns.containsKey);
    if (k < 0) return _words(words, feminine: feminine);
    final (noun, nounFeminine) = _nouns[words[k]]!;
    // Due sostantivi ("Paulsen Attack Variation"): il primo diventa il
    // complemento ("variante attacco Paulsen").
    final before = words.sublist(0, k);
    final inner = before.any(_nouns.containsKey)
        ? _part(before.join(' '), feminine: nounFeminine)
        : _words(before, feminine: nounFeminine);
    final tail = _words(words.sublist(k + 1), feminine: nounFeminine);
    return [noun, inner, tail].where((p) => p.isNotEmpty).join(' ');
  }

  String _word(String w, {required bool feminine}) {
    final phrase = _phrases[w];
    if (phrase != null) return phrase;
    final adj = _adjectives[w];
    if (adj != null) return feminine ? adj.$2 : adj.$1;
    final noun = _nouns[w];
    if (noun != null) return noun.$1;
    // "Neo-Modern", "Anti-Classical": prefisso più aggettivo o nome proprio.
    final dash = w.indexOf('-');
    final prefix = dash < 0 ? null : _prefixes[w.substring(0, dash)];
    if (prefix != null) {
      return '$prefix-${_word(w.substring(dash + 1), feminine: feminine)}';
    }
    // "Benoni-Indian", "Nimzo-Dutch": l'ultimo pezzo è un aggettivo.
    final last = w.lastIndexOf('-');
    if (last > 0 && _adjectives.containsKey(w.substring(last + 1))) {
      return '${w.substring(0, last)}-'
          '${_word(w.substring(last + 1), feminine: feminine)}';
    }
    return w;
  }

  String _words(List<String> words, {required bool feminine}) {
    final out = <String>[];
    var i = 0;
    while (i < words.length) {
      if (i + 1 < words.length) {
        final two = _phrases['${words[i]} ${words[i + 1]}'];
        if (two != null) {
          out.add(two);
          i += 2;
          continue;
        }
      }
      out.add(_word(words[i], feminine: feminine));
      i++;
    }
    return out.join(' ');
  }
}
