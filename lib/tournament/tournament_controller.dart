import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../progress/activity.dart';
import '../storage/json_file.dart';
import 'tournament.dart';

/// Risultato di un torneo concluso, per la bacheca dei trofei.
class Trophy {
  const Trophy({
    required this.date,
    required this.format,
    required this.players,
    required this.rank,
    required this.champion,
  });

  final DateTime date;
  final TournamentFormat format;
  final int players;
  final int rank;

  /// Nome del vincitore.
  final String champion;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'format': format.name,
    'players': players,
    'rank': rank,
    'champion': champion,
  };

  static Trophy fromJson(Map<String, Object?> json) => Trophy(
    date: DateTime.parse(json['date']! as String),
    format: TournamentFormat.values.byName(json['format']! as String),
    players: json['players']! as int,
    rank: json['rank']! as int,
    champion: json['champion']! as String,
  );
}

/// Torneo in corso e bacheca dei trofei, salvati a ogni partita.
class TournamentController extends ChangeNotifier {
  TournamentController(
    File file, {
    this.recordActivity,
    DateTime Function()? clock,
    Random? random,
  }) : _file = JsonFile(file, version: 1),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random();

  static Future<TournamentController> open({
    RecordActivity? recordActivity,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final controller = TournamentController(
      File('${dir.path}/tornei.json'),
      recordActivity: recordActivity,
    );
    await controller.load();
    return controller;
  }

  final JsonFile _file;
  final DateTime Function() _clock;
  final Random _random;

  /// Registra XP e traguardi a torneo concluso.
  final RecordActivity? recordActivity;

  Tournament? _current;
  List<Trophy> _trophies = const [];
  bool _readOnly = false;

  Tournament? get current => _current;

  /// Tornei conclusi, dal più recente.
  List<Trophy> get trophies => _trophies;

  Future<void> load() async {
    try {
      // Decodifica dentro `read`: un contenuto non valido finisce in
      // quarantena invece di bloccare la schermata.
      final data = await _file.read(
        (json) => (
          current: json['current'] == null
              ? null
              : Tournament.fromJson((json['current']! as Map).cast()),
          trophies: [
            for (final t in json['trophies'] as List? ?? const [])
              Trophy.fromJson((t as Map).cast()),
          ],
        ),
      );
      _current = data?.current;
      _trophies = data?.trophies ?? const [];
    } on FileSystemException catch (e) {
      debugPrint('Lettura dei tornei non riuscita: $e'); // l10n-ok
      _readOnly = true;
    }
    notifyListeners();
  }

  Future<void> start({
    required TournamentFormat format,
    required int size,
    required String userName,
    required int userElo,
    required List<Player> bots,
  }) async {
    _current = Tournament.create(
      format: format,
      user: Player(name: userName, elo: userElo),
      bots: chooseBots(bots, userElo: userElo, count: size - 1),
      seed: _random.nextInt(1 << 31),
      createdAt: _clock(),
    );
    await _save();
  }

  /// Registra la partita dell'utente; a fine torneo aggiunge il trofeo.
  /// Senza una partita in attesa non fa nulla.
  Future<void> recordUserGame(double points) async {
    final current = _current;
    if (current == null || current.userGame == null) return;
    final t = current.recordUserGame(points);
    _current = t;
    if (t.finished) {
      _trophies = [
        Trophy(
          date: _clock(),
          format: t.format,
          players: t.players.length,
          rank: t.userRank!,
          champion: t.players[t.champion!].name,
        ),
        ..._trophies,
      ];
    }
    await _save();
    if (t.finished) {
      await recordActivity?.call(
        TournamentFinished(rank: t.userRank!, players: t.players.length),
      );
    }
  }

  /// Chiude il torneo: abbandonato se in corso, archiviato se finito.
  Future<void> dismiss() async {
    _current = null;
    await _save();
  }

  Future<void> _save() async {
    notifyListeners();
    if (_readOnly) return;
    try {
      await _file.write({
        'current': _current?.toJson(),
        'trophies': [for (final t in _trophies) t.toJson()],
      });
    } on FileSystemException catch (e) {
      debugPrint('Salvataggio dei tornei non riuscito: $e'); // l10n-ok
    }
  }
}
