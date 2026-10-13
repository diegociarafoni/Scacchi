/// Nomi delle aperture in italiano.
///
/// Il dataset pubblico è in inglese: qui le famiglie più comuni hanno la loro
/// traduzione e le varianti si compongono da un piccolo glossario (sostantivi,
/// aggettivi, nazionalità). I nomi propri restano invariati; ciò che non si sa
/// tradurre resta com'è, così non si perde mai l'informazione.
library;

const _families = <String, String>{
  'Sicilian Defense': 'Difesa siciliana',
  'Ruy Lopez': 'Partita spagnola',
  'French Defense': 'Difesa francese',
  "Queen's Gambit": 'Gambetto di donna',
  'Italian Game': 'Partita italiana',
  'English Opening': 'Apertura inglese',
  "King's Gambit": 'Gambetto di re',
  "King's Indian Defense": 'Difesa indiana di re',
  'Caro-Kann Defense': 'Difesa Caro-Kann',
  'Nimzo-Indian Defense': 'Difesa nimzo-indiana',
  "Queen's Pawn Game": 'Partita di pedone di donna',
  'Semi-Slav Defense': 'Difesa semislava',
  'Dutch Defense': 'Difesa olandese',
  'Benoni Defense': 'Difesa Benoni',
  'Grünfeld Defense': 'Difesa Grünfeld',
  "Queen's Indian Defense": 'Difesa indiana di donna',
  'Alekhine Defense': 'Difesa Alekhine',
  'Indian Defense': 'Difesa indiana',
  'Scotch Game': 'Partita scozzese',
  'Slav Defense': 'Difesa slava',
  "Petrov's Defense": 'Difesa Petrov',
  'Four Knights Game': 'Partita dei quattro cavalli',
  'Zukertort Opening': 'Apertura Zukertort',
  'Scandinavian Defense': 'Difesa scandinava',
  'Philidor Defense': 'Difesa Philidor',
  'Réti Opening': 'Apertura Réti',
  'Nimzowitsch Defense': 'Difesa Nimzowitsch',
  "Bishop's Opening": "Apertura dell'alfiere",
  'Vienna Game': 'Partita viennese',
  'Modern Defense': 'Difesa moderna',
  "King's Pawn Game": 'Partita di pedone di re',
  'Van Geet Opening': 'Apertura Van Geet',
  'Pterodactyl Defense': 'Difesa Pterodattilo',
  'Catalan Opening': 'Apertura catalana',
  'Bird Opening': 'Apertura Bird',
  'Pirc Defense': 'Difesa Pirc',
  'Tarrasch Defense': 'Difesa Tarrasch',
  'Polish Opening': 'Apertura polacca',
  'Neo-Grünfeld Defense': 'Difesa neo-Grünfeld',
  'Blackmar-Diemer Gambit': 'Gambetto Blackmar-Diemer',
  'Bogo-Indian Defense': 'Difesa bogo-indiana',
  'Grob Opening': 'Apertura Grob',
  'Hungarian Opening': 'Apertura ungherese',
  "King's Indian Attack": 'Attacco indiano di re',
  'Nimzo-Larsen Attack': 'Attacco Nimzo-Larsen',
  'Center Game': 'Partita del centro',
  'Latvian Gambit': 'Gambetto lettone',
  'Ponziani Opening': 'Apertura Ponziani',
  'Vienna Gambit': 'Gambetto viennese',
  'Old Indian Defense': 'Difesa vecchio-indiana',
  'Rat Defense': 'Difesa del ratto',
  'Trompowsky Attack': 'Attacco Trompowsky',
  'Benko Gambit': 'Gambetto Benko',
  'Kádas Opening': 'Apertura Kádas',
  'Englund Gambit': 'Gambetto Englund',
  'Owen Defense': 'Difesa Owen',
  'Richter-Veresov Attack': 'Attacco Richter-Veresov',
  'Ware Opening': 'Apertura Ware',
  'English Defense': 'Difesa inglese',
  'Barnes Opening': 'Apertura Barnes',
  'Torre Attack': 'Attacco Torre',
  'Lion Defense': 'Difesa del leone',
  'Danish Gambit': 'Gambetto danese',
  'Three Knights Opening': 'Apertura dei tre cavalli',
  'Rubinstein Opening': 'Apertura Rubinstein',
  "Van't Kruijs Opening": "Apertura Van't Kruijs",
  'Borg Defense': 'Difesa Borg',
  'Mieses Opening': 'Apertura Mieses',
  'Sodium Attack': 'Attacco Sodium',
  'Mikenas Defense': 'Difesa Mikenas',
  'London System': 'Sistema di Londra',
  'St. George Defense': 'Difesa San Giorgio',
  'Elephant Gambit': "Gambetto dell'elefante",
  'Amar Opening': 'Apertura Amar',
  'Colle System': 'Sistema Colle',
  "King's Pawn Opening": 'Apertura di pedone di re',
  'Portuguese Opening': 'Apertura portoghese',
  "King's Knight Opening": 'Apertura del cavallo di re',
  'Rapport-Jobava System': 'Sistema Rapport-Jobava',
  'Blumenfeld Countergambit': 'Controgambetto Blumenfeld',
  "Anderssen's Opening": 'Apertura Anderssen',
  'Clemenz Opening': 'Apertura Clemenz',
  'Formation': 'Formazione',
  'Zukertort Defense': 'Difesa Zukertort',
  'English Orangutan': 'Orango inglese',
  'Horwitz Defense': 'Difesa Horwitz',
  'Kangaroo Defense': 'Difesa del canguro',
  'Polish Defense': 'Difesa polacca',
  'Slav Indian': 'Slava-indiana',
  'Amazon Attack': 'Attacco Amazzone',
  'Marienbad System': 'Sistema Marienbad',
  "Pseudo Queen's Indian Defense": 'Pseudo difesa indiana di donna',
  'Mexican Defense': 'Difesa messicana',
  'Carr Defense': 'Difesa Carr',
  'Goldsmith Defense': 'Difesa Goldsmith',
  'Hippopotamus Defense': "Difesa dell'ippopotamo",
  'Ware Defense': 'Difesa Ware',
  'Amsterdam Attack': 'Attacco Amsterdam',
  'Creepy Crawly Formation': 'Formazione Creepy Crawly',
  'Global Opening': 'Apertura Global',
  'Lasker Simul Special': 'Speciale simultanea Lasker',
  'Saragossa Opening': 'Apertura Saragozza',
  'Valencia Opening': 'Apertura Valencia',
  'Australian Defense': 'Difesa australiana',
  'Montevideo Defense': 'Difesa Montevideo',
  'Zaire Defense': 'Difesa Zaire',
  'Robatsch Defense': 'Difesa Robatsch',
  'Wade Defense': 'Difesa Wade',
  'Basque Opening': 'Apertura basca',
  'Canard Opening': 'Apertura Canard',
  'Paleface Attack': 'Attacco Paleface',
  'Döry Defense': 'Difesa Döry',
  'Yusupov-Rubinstein System': 'Sistema Yusupov-Rubinstein',
  'East Indian Defense': 'Difesa est-indiana',
  "Queen's Indian Accelerated": 'Indiana di donna accelerata',
  'Vulture Defense': "Difesa dell'avvoltoio",
  'Barnes Defense': 'Difesa Barnes',
  'Fried Fox Defense': 'Difesa Fried Fox',
  'Lemming Defense': 'Difesa del lemming',
  'Czech Defense': 'Difesa ceca',
  'Bongcloud Attack': 'Attacco Bongcloud',
  'Gunderam Defense': 'Difesa Gunderam',
  'Dresden Opening': 'Apertura Dresda',
  'Irish Gambit': 'Gambetto irlandese',
  'Duras Gambit': 'Gambetto Duras',
  "Queen's Pawn": 'Pedone di donna',
};

/// Sostantivi che reggono la frase: forma italiana e genere (vero se femminile).
const _nouns = <String, (String, bool)>{
  'Variation': ('variante', true),
  'Variations': ('varianti', true),
  'Attack': ('attacco', false),
  'Gambit': ('gambetto', false),
  'Countergambit': ('controgambetto', false),
  'Defense': ('difesa', true),
  'System': ('sistema', false),
  'Line': ('linea', true),
  'Opening': ('apertura', true),
  'Game': ('partita', true),
  'Formation': ('formazione', true),
  'Trap': ('trappola', true),
  'Sacrifice': ('sacrificio', false),
  'Endgame': ('finale', false),
  'Counterattack': ('contrattacco', false),
  'Retreat': ('ritirata', true),
};

/// Aggettivi: forma maschile e femminile (la stessa se invariabile).
const _adjectives = <String, (String, String)>{
  'Classical': ('classico', 'classica'),
  'Modern': ('moderno', 'moderna'),
  'Closed': ('chiuso', 'chiusa'),
  'Open': ('aperto', 'aperta'),
  'Main': ('principale', 'principale'),
  'Normal': ('normale', 'normale'),
  'Orthodox': ('ortodosso', 'ortodossa'),
  'Accepted': ('accettato', 'accettata'),
  'Declined': ('rifiutato', 'rifiutata'),
  'Advance': ("d'avanzamento", "d'avanzamento"),
  'Exchange': ('dei cambi', 'dei cambi'),
  'Symmetrical': ('simmetrico', 'simmetrica'),
  'Symmetric': ('simmetrico', 'simmetrica'),
  'Reversed': ('rovesciato', 'rovesciata'),
  'Accelerated': ('accelerato', 'accelerata'),
  'Hyperaccelerated': ('iperaccelerato', 'iperaccelerata'),
  'Delayed': ('ritardato', 'ritardata'),
  'Deferred': ('differito', 'differita'),
  'Quiet': ('tranquillo', 'tranquilla'),
  'Traditional': ('tradizionale', 'tradizionale'),
  'Positional': ('posizionale', 'posizionale'),
  'Double': ('doppio', 'doppia'),
  'Central': ('centrale', 'centrale'),
  'Old': ('vecchio', 'vecchia'),
  'Early': ('anticipato', 'anticipata'),
  'Long': ('lungo', 'lunga'),
  'Short': ('corto', 'corta'),
  'Improved': ('migliorato', 'migliorata'),
  'Original': ('originale', 'originale'),
  'Hybrid': ('ibrido', 'ibrida'),
  'Poisoned': ('avvelenato', 'avvelenata'),
  'Austrian': ('austriaco', 'austriaca'),
  'Russian': ('russo', 'russa'),
  'Italian': ('italiano', 'italiana'),
  'Spanish': ('spagnolo', 'spagnola'),
  'English': ('inglese', 'inglese'),
  'Dutch': ('olandese', 'olandese'),
  'French': ('francese', 'francese'),
  'Polish': ('polacco', 'polacca'),
  'Hungarian': ('ungherese', 'ungherese'),
  'Czech': ('ceco', 'ceca'),
  'Portuguese': ('portoghese', 'portoghese'),
  'Norwegian': ('norvegese', 'norvegese'),
  'Swiss': ('svizzero', 'svizzera'),
  'Swedish': ('svedese', 'svedese'),
  'Siberian': ('siberiano', 'siberiana'),
  'Eastern': ('orientale', 'orientale'),
  'Western': ('occidentale', 'occidentale'),
  'Chinese': ('cinese', 'cinese'),
  'Yugoslav': ('jugoslavo', 'jugoslava'),
  'Scandinavian': ('scandinavo', 'scandinava'),
  'German': ('tedesco', 'tedesca'),
  'Ukrainian': ('ucraino', 'ucraina'),
  'Mexican': ('messicano', 'messicana'),
  'American': ('americano', 'americana'),
  'Argentine': ('argentino', 'argentina'),
  'Baltic': ('baltico', 'baltica'),
  'Sicilian': ('siciliano', 'siciliana'),
  'Slav': ('slavo', 'slava'),
  'Indian': ('indiano', 'indiana'),
  'Wing': ("d'ala", "d'ala"),
  'Center': ('del centro', 'del centro'),
  'Kingside': ("dell'ala di re", "dell'ala di re"),
  'Queenside': ("dell'ala di donna", "dell'ala di donna"),
  'Black': ('del Nero', 'del Nero'),
  'White': ('del Bianco', 'del Bianco'),
  'Check': ('di scacco', 'di scacco'),
  'Knight': ('del cavallo', 'del cavallo'),
  'Bishop': ("dell'alfiere", "dell'alfiere"),
};

/// Gruppi di parole che si traducono insieme, provati prima delle singole.
const _phrases = <String, String>{
  'Two Knights': 'dei due cavalli',
  'Three Knights': 'dei tre cavalli',
  'Four Knights': 'dei quattro cavalli',
  'Two Pawns': 'dei due pedoni',
  'Three Pawns': 'dei tre pedoni',
  'Four Pawns': 'dei quattro pedoni',
  "King's": 'di re',
  "Queen's": 'di donna',
  "Bishop's": "dell'alfiere",
  "Knight's": 'del cavallo',
  "Queen's Knight": 'del cavallo di donna',
  "King's Knight": 'del cavallo di re',
  'Early Deviations': 'deviazioni anticipate',
  'Move Order': 'ordine delle mosse',
  'Kingside Move Order': "ordine delle mosse dell'ala di re",
  'Queenside Move Order': "ordine delle mosse dell'ala di donna",
  'Pawn Push': 'spinta di pedone',
  'Double-Dutch': 'doppio olandese',
  "King's English": 'inglese di re',
};

/// Nome italiano di [name], o [name] stesso dove manca la traduzione.
String openingNameIt(String name) => _cache.putIfAbsent(name, () {
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

final _cache = <String, String>{};

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

/// Vero se il nome italiano dell'apertura è femminile: gli aggettivi senza
/// sostantivo ("Open", "Closed") si accordano con lui.
bool _isFeminine(String it) => _feminineStart.hasMatch(it);

final _feminineStart = RegExp(
  r'^(Difesa|Apertura|Partita|Formazione|Pseudo difesa|Indiana|Slava)',
);
final _acceptedDeclined = RegExp(r'^(.*) (Accepted|Declined)$');

String _familyHead(String text) {
  final known = _families[text];
  if (known != null) return known;
  final m = _acceptedDeclined.firstMatch(text);
  if (m != null) {
    final base = _families[m[1]];
    if (base != null) {
      final adj = _adjectives[m[2]]!;
      return '$base ${_isFeminine(base) ? adj.$2 : adj.$1}';
    }
  }
  return _part(text, feminine: false);
}

/// Un pezzo di nome: "sostantivo + aggettivi" se c'è un sostantivo noto,
/// altrimenti parola per parola.
String _part(String text, {required bool feminine}) {
  if (text.startsWith('with ')) {
    return 'con ${_part(text.substring(5), feminine: feminine)}';
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

const _prefixes = {
  'Neo': 'neo',
  'Anti': 'anti',
  'Semi': 'semi',
  'Pseudo': 'pseudo',
};

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
