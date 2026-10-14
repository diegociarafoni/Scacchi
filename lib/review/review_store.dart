import 'dart:io';

import 'package:dartchess/dartchess.dart' hide File;
import 'package:path_provider/path_provider.dart';

import '../storage/json_file.dart';
import 'engine_evaluator.dart';
import 'game_review.dart';

/// Revisioni su disco (RF-66): la revisione di una partita già analizzata si
/// riapre all'istante anche dopo il riavvio. Tiene le più recenti.
class ReviewStore {
  ReviewStore(File file, {this.capacity = 50})
    : _file = JsonFile(file, version: 1);

  /// Archivio nel file predefinito della cartella dati dell'app.
  static Future<ReviewStore> openDefault() async {
    final dir = await getApplicationSupportDirectory();
    return ReviewStore(File('${dir.path}/reviews.json'));
  }

  /// Versione della classificazione: si cambia quando le regole cambiano e
  /// le revisioni salvate non valgono più.
  static const schema = 1;

  /// Chiave di una revisione: posizione e mosse, motore, profondità e uso del
  /// libro delle aperture, perché ognuno cambia il risultato.
  static String key(
    Position initial,
    List<Move> moves, {
    String engine = reviewEngine,
    int depth = reviewDepth,
    bool book = false,
  }) =>
      'r$schema|$engine|d$depth|${book ? 'libro' : 'senza'}|${initial.fen}|'
      '${moves.map((m) => m.uci).join(' ')}';

  final int capacity;
  final JsonFile _file;
  Future<Map<String, GameReview>>? _loaded;

  Future<Map<String, GameReview>> _load() => _loaded ??= _read();

  Future<Map<String, GameReview>> _read() async {
    try {
      return await _file.read((json) {
            final map = <String, GameReview>{};
            for (final e in (json['reviews']! as Map).entries) {
              // Una voce non valida si salta senza perdere le altre.
              try {
                map[e.key as String] = GameReview.fromJson(
                  (e.value as Map).cast(),
                );
              } on Object {
                continue;
              }
            }
            return map;
          }) ??
          <String, GameReview>{};
    } on FileSystemException {
      return <String, GameReview>{};
    }
  }

  /// La revisione salvata; leggerla la rende la più recente.
  Future<GameReview?> get(String key) async {
    final reviews = await _load();
    final review = reviews.remove(key);
    if (review != null) reviews[key] = review;
    return review;
  }

  Future<void> put(String key, GameReview review) async {
    final reviews = await _load();
    reviews
      ..remove(key)
      ..[key] = review;
    while (reviews.length > capacity) {
      reviews.remove(reviews.keys.first);
    }
    await _file.write({
      'reviews': {for (final e in reviews.entries) e.key: e.value.toJson()},
    });
  }
}
