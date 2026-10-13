import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Testi lunghi o in lista, letti da `assets/content/<lingua>/<nome>.json`.
///
/// Ogni file è piatto: `{"id": "testo"}` oppure `{"id": ["frase", ...]}` per le
/// liste (per esempio le frasi dei bot). Se un id manca nella lingua scelta si
/// ripiega sull'inglese e poi sull'italiano; un id che non esiste da nessuna
/// parte restituisce l'id stesso, così l'errore si vede e non blocca l'app.
/// I segnaposto sono `{nome}`.
class ContentText {
  ContentText._(this.language, this._own, this._chain);

  /// Versione sincrona, per i test e per i contenuti già in memoria.
  /// [tables] associa a ogni lingua i suoi testi.
  factory ContentText.fromMaps(
    Map<String, Map<String, Object>> tables, {
    required String language,
  }) => ContentText._(language, tables[language], [
    for (final code in fallbackChain(language))
      if (tables[code] != null) tables[code]!,
  ]);

  /// Carica `assets/content/<lingua>/<nome>.json` per la lingua scelta e per
  /// quelle di ripiego. I file mancanti si saltano; se non ce n'è nessuno è
  /// un errore, perché il nome è sbagliato.
  static Future<ContentText> load(
    String name,
    String language, {
    AssetBundle? bundle,
  }) async {
    final source = bundle ?? rootBundle;
    final tables = <String, Map<String, Object>>{};
    for (final code in fallbackChain(language)) {
      final path = 'assets/content/$code/$name.json';
      try {
        tables[code] = parse(await source.loadString(path), path);
      } on FlutterError {
        continue;
      }
    }
    if (tables.isEmpty) {
      throw StateError('Nessun contenuto "$name" per $language');
    }
    return ContentText.fromMaps(tables, language: language);
  }

  /// Legge un file JSON di contenuti; [origin] serve ai messaggi d'errore.
  static Map<String, Object> parse(String source, String origin) {
    final json = jsonDecode(source);
    if (json is! Map<String, Object?>) {
      throw FormatException('$origin: serve un oggetto JSON');
    }
    return {
      for (final e in json.entries)
        e.key: switch (e.value) {
          final String s => s,
          final List<Object?> l when l.every((x) => x is String) =>
            List<String>.from(l),
          _ => throw FormatException(
            '$origin: "${e.key}" deve essere un testo o una lista di testi',
          ),
        },
    };
  }

  /// Lingua scelta, poi inglese, poi italiano, senza ripetizioni.
  static List<String> fallbackChain(String language) => [
    ...{language, 'en', 'it'},
  ];

  final String language;
  final Map<String, Object>? _own;
  final List<Map<String, Object>> _chain;

  /// Vero se esiste un file per la lingua scelta (non solo per il ripiego).
  bool get hasLanguage => _own != null;

  /// Id della sola lingua scelta.
  Set<String> get ownIds => _own?.keys.toSet() ?? const {};

  /// Testo di [id] nella sola lingua scelta, senza ripiego: serve a chi
  /// compone testi (i nomi delle aperture) e deve sapere cosa manca.
  String? ownText(String id) => switch (_own?[id]) {
    final String s => s,
    _ => null,
  };

  /// Come [ownText], per le liste.
  List<String>? ownList(String id) => switch (_own?[id]) {
    final List<String> l => l,
    _ => null,
  };

  /// Tutti gli id noti in almeno una lingua della catena.
  Set<String> get ids => {for (final t in _chain) ...t.keys};

  bool has(String id) => _chain.any((t) => t.containsKey(id));

  /// Testo di [id] con i segnaposto di [args] sostituiti.
  String text(String id, [Map<String, Object> args = const {}]) {
    for (final table in _chain) {
      final value = table[id];
      if (value is String) return _fill(value, args);
    }
    return id;
  }

  /// Frasi di [id]; vuota se l'id non è una lista in nessuna lingua.
  List<String> list(String id, [Map<String, Object> args = const {}]) {
    for (final table in _chain) {
      final value = table[id];
      if (value is List<String>) return [for (final s in value) _fill(s, args)];
    }
    return const [];
  }

  static final _placeholder = RegExp(r'\{(\w+)\}');

  static String _fill(String text, Map<String, Object> args) => args.isEmpty
      ? text
      : text.replaceAllMapped(
          _placeholder,
          (m) => args[m.group(1)]?.toString() ?? m.group(0)!,
        );
}

/// Contenuti della lingua attiva, caricati una volta all'avvio.
///
/// L'app li carica prima di mostrare le schermate (`ScacchiApp`), i test dal
/// disco (`test/flutter_test_config.dart`).
abstract final class Content {
  static final Map<String, ContentText> _byName = {};
  static String _language = 'it';

  static bool get isLoaded => _byName.isNotEmpty;

  /// Lingua dei contenuti caricati.
  static String get language => _language;

  static ContentText of(String name) =>
      _byName[name] ?? (throw StateError('Contenuto "$name" non caricato'));

  /// Registra contenuti già pronti (test).
  static void use(Map<String, ContentText> content) {
    _byName
      ..clear()
      ..addAll(content);
    if (content.isNotEmpty) _language = content.values.first.language;
  }

  static void reset() {
    _byName.clear();
    _language = 'it';
  }

  /// Carica tutti i contenuti di [language]. Non fa nulla se già caricati
  /// nella stessa lingua. Senza [names] li cerca nell'elenco degli asset.
  static Future<void> ensureLoaded({
    String language = 'it',
    AssetBundle? bundle,
    List<String>? names,
  }) async {
    if (isLoaded && _language == language) return;
    final source = bundle ?? rootBundle;
    final found = names ?? await _names(source);
    final loaded = {
      for (final name in found)
        name: await ContentText.load(name, language, bundle: source),
    };
    use(loaded);
    _language = language;
  }

  static Future<List<String>> _names(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return [
      for (final path in manifest.listAssets())
        if (path.startsWith('assets/content/it/') && path.endsWith('.json'))
          path.substring('assets/content/it/'.length, path.length - 5),
    ];
  }
}

/// Lingua dei contenuti per il dispositivo: la sua se l'app la supporta,
/// altrimenti l'italiano.
String contentLanguage(Locale device, Iterable<Locale> supported) =>
    supported.any((l) => l.languageCode == device.languageCode)
    ? device.languageCode
    : 'it';
