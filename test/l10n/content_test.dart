import 'dart:convert';

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scacchi/l10n/content.dart';

/// Contenitore di file in memoria, per provare il caricamento senza asset.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('asset assente: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  final tables = {
    'it': <String, Object>{
      'a.title': 'La torre',
      'a.intro': 'Muovi la {pezzo} {n} volte.',
      'solo.it': 'Solo italiano',
      'bot.check': ['Scacco!', 'Occhio al re'],
    },
    'en': <String, Object>{
      'a.title': 'The rook',
      'a.intro': 'Move the {pezzo} {n} times.',
      'solo.en': 'English only',
      'bot.check': ['Check!'],
    },
  };

  group('ContentText', () {
    test('legge il testo nella lingua scelta', () {
      final c = ContentText.fromMaps(tables, language: 'en');
      expect(c.text('a.title'), 'The rook');
      expect(
        ContentText.fromMaps(tables, language: 'it').text('a.title'),
        'La torre',
      );
    });

    test('ripiega sull\'inglese e poi sull\'italiano', () {
      final c = ContentText.fromMaps({
        ...tables,
        'es': {'a.title': 'La torre (es)'},
      }, language: 'es');
      expect(c.text('a.title'), 'La torre (es)');
      expect(c.text('solo.en'), 'English only');
      expect(c.text('solo.it'), 'Solo italiano');
    });

    test('un id sconosciuto restituisce l\'id e has è falso', () {
      final c = ContentText.fromMaps(tables, language: 'en');
      expect(c.text('non.esiste'), 'non.esiste');
      expect(c.has('non.esiste'), isFalse);
      expect(c.has('solo.it'), isTrue);
    });

    test('sostituisce i segnaposto, anche ripetuti, e lascia gli ignoti', () {
      final c = ContentText.fromMaps({
        'it': {'x': '{n} e {n}, {altro}'},
      }, language: 'it');
      expect(c.text('x', {'n': 3}), '3 e 3, {altro}');
      expect(c.text('x'), '{n} e {n}, {altro}');
    });

    test('le liste di frasi hanno i segnaposto sostituiti', () {
      final c = ContentText.fromMaps({
        'it': {
          'bot.x': ['Ciao {nome}', 'Eccomi {nome}'],
        },
      }, language: 'it');
      expect(c.list('bot.x', {'nome': 'Tino'}), ['Ciao Tino', 'Eccomi Tino']);
    });

    test('la lista della lingua scelta ha la precedenza, anche più corta', () {
      final c = ContentText.fromMaps(tables, language: 'en');
      expect(c.list('bot.check'), ['Check!']);
      expect(c.list('assente'), isEmpty);
    });

    test('una lista non è un testo e viceversa', () {
      final c = ContentText.fromMaps(tables, language: 'it');
      expect(c.text('bot.check'), 'bot.check');
      expect(c.list('a.title'), isEmpty);
    });

    test('ids elenca gli id di tutte le lingue del ripiego', () {
      final c = ContentText.fromMaps(tables, language: 'en');
      expect(
        c.ids,
        containsAll(['a.title', 'a.intro', 'solo.it', 'solo.en', 'bot.check']),
      );
    });

    test('own* legge solo la lingua scelta, senza ripiego', () {
      final es = ContentText.fromMaps({
        ...tables,
        'es': {
          'a.title': 'La torre (es)',
          'lista': ['uno', 'dos'],
        },
      }, language: 'es');
      expect(es.hasLanguage, isTrue);
      expect(es.ownText('a.title'), 'La torre (es)');
      expect(es.ownText('solo.en'), isNull);
      expect(es.ownList('lista'), ['uno', 'dos']);
      expect(es.ownList('a.title'), isNull);
      expect(es.ownIds, {'a.title', 'lista'});
    });

    test('hasLanguage è falso se la lingua non ha un file', () {
      final fr = ContentText.fromMaps(tables, language: 'fr');
      expect(fr.hasLanguage, isFalse);
      expect(fr.ownIds, isEmpty);
      expect(fr.ownText('a.title'), isNull);
      expect(fr.text('a.title'), 'The rook');
    });

    test('parse rifiuta valori che non sono testi o liste di testi', () {
      expect(
        () => ContentText.parse('{"a": 3}', 'x.json'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ContentText.parse('{"a": ["ok", 2]}', 'x.json'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ContentText.parse('[1]', 'x.json'),
        throwsA(isA<FormatException>()),
      );
      expect(ContentText.parse('{"a": "b", "c": ["d"]}', 'x.json'), {
        'a': 'b',
        'c': ['d'],
      });
    });

    test('load legge assets/content/<lingua>/<nome>.json', () async {
      final bundle = _Bundle({
        'assets/content/it/demo.json': '{"a.title": "La torre"}',
        'assets/content/en/demo.json': '{"a.title": "The rook"}',
      });
      final en = await ContentText.load('demo', 'en', bundle: bundle);
      expect(en.text('a.title'), 'The rook');
    });

    test('load tollera le lingue senza file', () async {
      final bundle = _Bundle({
        'assets/content/it/demo.json': '{"a.title": "La torre"}',
      });
      final fr = await ContentText.load('demo', 'fr', bundle: bundle);
      expect(fr.text('a.title'), 'La torre');
    });
  });

  group('Content', () {
    tearDown(Content.reset);

    test('of restituisce il contenuto registrato', () {
      Content.use({'demo': ContentText.fromMaps(tables, language: 'it')});
      expect(Content.of('demo').text('a.title'), 'La torre');
    });

    test('of senza contenuto caricato segnala l\'errore', () {
      expect(() => Content.of('demo'), throwsStateError);
    });

    test('ensureLoaded carica ogni file della lingua e non ripete', () async {
      final bundle = _Bundle({
        'assets/content/it/uno.json': '{"a": "A"}',
        'assets/content/it/due.json': '{"b": "B"}',
        'assets/content/en/uno.json': '{"a": "AA"}',
      });
      await Content.ensureLoaded(
        language: 'en',
        bundle: bundle,
        names: ['uno', 'due'],
      );
      expect(Content.of('uno').text('a'), 'AA');
      expect(Content.of('due').text('b'), 'B');
      expect(Content.isLoaded, isTrue);
    });
  });

  group('contentLanguage', () {
    const supported = [Locale('it'), Locale('en')];

    test('segue la lingua del dispositivo se è supportata', () {
      expect(contentLanguage(const Locale('en', 'US'), supported), 'en');
      expect(contentLanguage(const Locale('it'), supported), 'it');
    });

    test('una lingua non supportata ripiega sull\'italiano', () {
      expect(contentLanguage(const Locale('ja'), supported), 'it');
    });
  });
}
