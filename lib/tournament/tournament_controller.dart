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

/// Gioca una partita tra due bot e restituisce i punti del bianco, o `null`
/// se non si può giocare (senza motore): la partita si simula.
typedef BotGameRunner = Future<double?> Function(
  Player white,
  Player black,
  int seed,
);

/// Torneo in corso e bacheca dei trofei, salvati a ogni partita.
class TournamentController extends ChangeNotifier {
  TournamentController(
    File file, {
    this.recordActivity,
    this.playBotGame,
    DateTime Function()? clock,
    Random? random,
  }) : _file = JsonFile(file, version: 1),
       _clock = clock ?? DateTime.now,
       _random = random ?? Random();

  static Future<TournamentController> open({
    RecordActivity? recordActivity,
    BotGameRunner? playBotGame,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final controller = TournamentController(
      File('${dir.path}/tornei.json'),
      recordActivity: recordActivity,
      playBotGame: playBotGame,
    );
    await controller.load();
    return controller;
  }

  final JsonFile _file;
  final DateTime Function() _clock;
  final Random _random;

  /// Registra XP e traguardi a torneo concluso.
  final RecordActivity? recordActivity;

  /// Gioca le partite tra bot; senza, si simulano con la formula Elo.
  final BotGameRunner? playBotGame;

  Tournament? _current;
  List<Trophy> _trophies = const [];
  bool _readOnly = false;
  bool _playingBots = false;

  Tournament? get current => _current;

  /// Vero mentre si giocano le partite tra bot.
  bool get playingBots => _playingBots;

  /// Tornei conclusi, dal più recente.
  List<Trophy> get trophies => _trophies;

  static T? _tryDecode<T>(
    Object? raw,
    T Function(Map<String, Object?> json) decode,
  ) {
    try {
      return raw == null ? null : decode((raw as Map).cast());
    } on Object {
      return null;
    }
  }

  Future<void> load() async {
    try {
      // Decodifica dentro `read`: un contenuto non valido finisce in
      // quarantena invece di bloccare la schermata.
      final data = await _file.read(
        // Il torneo in corso e ogni trofeo si leggono a parte: una voce
        // rovinata si scarta senza perdere le altre.
        (json) => (
          current: _tryDecode(json['current'], Tournament.fromJson),
          trophies: [
            for (final t in json['trophies'] as List? ?? const [])
              ?_tryDecode(t, Trophy.fromJson),
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
    await _set(
      Tournament.create(
        format: format,
        user: Player(name: userName, elo: userElo),
        bots: chooseBots(bots, userElo: userElo, count: size - 1),
        seed: _random.nextInt(1 << 31),
        createdAt: _clock(),
        simulateBots: playBotGame == null,
      ),
    );
    await resumeBots();
  }

  /// Registra la partita dell'utente, fa giocare le altre del turno e, a fine
  /// torneo, aggiunge il trofeo. Senza una partita in attesa non fa nulla.
  Future<void> recordUserGame(double points) async {
    final current = _current;
    if (current == null || current.userGame == null) return;
    await _set(
      current.recordUserGame(points, simulateBots: playBotGame == null),
    );
    await resumeBots();
  }

  /// Gioca le partite tra bot rimaste fino alla prossima dell'utente o alla
  /// fine del torneo, ad esempio dopo la chiusura dell'app a metà turno.
  Future<void> resumeBots() async {
    final runner = playBotGame;
    if (runner != null && !_playingBots) {
      _playingBots = true;
      notifyListeners();
      var available = true;
      try {
        while (true) {
          final t = _current;
          if (t == null || t.finished || t.userGame != null) break;
          final pending = t.pendingBotGames;
          if (pending.isEmpty) break;
          final game = pending.first;
          double? points;
          if (available) {
            try {
              points = await runner(
                t.players[game.white],
                t.players[game.black],
                game.seed,
              );
            } on Object catch (e) {
              if (kDebugMode) {
                debugPrint('Partita tra bot non riuscita: $e'); // l10n-ok
              }
            }
            available = points != null;
          }
          // Il torneo può essere stato chiuso o cambiato nel frattempo.
          if (!identical(_current, t)) return;
          await _set(
            points == null
                ? t.simulateBotGame(game)
                : t.withBotGame(game, points),
          );
        }
      } finally {
        _playingBots = false;
        notifyListeners();
      }
    }
    final t = _current;
    if (t != null && !t.finished && t.userGame == null) {
      await _set(t.settle());
    }
  }

  /// Imposta [next] come torneo corrente e lo salva. Se è appena finito, il
  /// trofeo entra nello stesso salvataggio: non si perde se l'app si chiude.
  Future<void> _set(Tournament next) async {
    final justFinished = next.finished && !(_current?.finished ?? false);
    _current = next;
    if (justFinished) {
      _trophies = [
        Trophy(
          date: _clock(),
          format: next.format,
          players: next.players.length,
          rank: next.userRank!,
          champion: next.players[next.champion!].name,
        ),
        ..._trophies,
      ];
    }
    await _save();
    if (justFinished) {
      await recordActivity?.call(
        TournamentFinished(rank: next.userRank!, players: next.players.length),
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
