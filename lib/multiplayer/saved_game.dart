import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../storage/json_file.dart';
import 'game_invite.dart';

/// Quanto serve per riprendere una partita a due dopo un riavvio: l'invito,
/// la chiave privata di questo telefono, il registro e i messaggi sigillati
/// da rimandare nel recupero.
class SavedGame {
  SavedGame({
    required this.inviteLink,
    required this.isHost,
    required this.seed,
    required this.moves,
    required this.sealed,
    this.peerKey,
  });

  final String inviteLink;
  final bool isHost;

  /// Seme privato Ed25519: chi legge il file può firmare al nostro posto.
  final Uint8List seed;
  final List<String> moves;
  final Map<int, Uint8List> sealed;

  /// Chiave dell'avversario, nota a chi ospita solo dopo il suo ingresso.
  final Uint8List? peerKey;

  GameInvite get invite => GameInvite.parse(inviteLink)!;

  Map<String, Object?> toJson() => {
    'inviteLink': inviteLink,
    'isHost': isHost,
    'seed': base64.encode(seed),
    'moves': moves,
    'peerKey': ?peerKey == null ? null : base64.encode(peerKey!),
    'sealed': {
      for (final e in sealed.entries) '${e.key}': base64.encode(e.value),
    },
  };

  /// `null` se il contenuto non è una partita valida.
  static SavedGame? fromJson(Map<String, Object?> json) {
    try {
      final link = json['inviteLink']! as String;
      if (GameInvite.parse(link) == null) return null;
      final seed = base64.decode(json['seed']! as String);
      if (seed.length != 32) return null;
      final peer = json['peerKey'] as String?;
      final peerKey = peer == null ? null : base64.decode(peer);
      if (peerKey != null && peerKey.length != 32) return null;
      return SavedGame(
        inviteLink: link,
        isHost: json['isHost']! as bool,
        seed: seed,
        moves: [for (final m in json['moves']! as List) m as String],
        peerKey: peerKey,
        sealed: {
          for (final e in (json['sealed'] as Map? ?? {}).entries)
            int.parse(e.key as String): base64.decode(e.value as String),
        },
      );
    } on Object {
      return null;
    }
  }
}

/// Partita a due in corso, in un file nella cartella privata dell'app.
class SavedGameStore {
  SavedGameStore(File file) : _file = JsonFile(file, version: 1);

  static Future<SavedGameStore>? _shared;

  /// File `multiplayer.json` nella cartella dati dell'app, una sola istanza.
  static Future<SavedGameStore> open() =>
      _shared ??= getApplicationSupportDirectory().then(
        (dir) => SavedGameStore(File('${dir.path}/multiplayer.json')),
        onError: (Object e, StackTrace st) {
          _shared = null;
          Error.throwWithStackTrace(e, st);
        },
      );

  final JsonFile _file;

  /// La partita salvata; un file non valido viene messo da parte.
  Future<SavedGame?> load() => _file.read<SavedGame?>(
    (json) => SavedGame.fromJson(json) ?? (throw const FormatException()),
  );

  Future<void> save(SavedGame game) async {
    try {
      await _file.write(game.toJson());
    } on FileSystemException catch (e) {
      // Senza spazio la partita continua, solo non si potrà riprendere.
      if (kDebugMode) debugPrint('Salvataggio della partita non riuscito: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _file.delete();
    } on FileSystemException catch (e) {
      if (kDebugMode) debugPrint('Cancellazione non riuscita: $e');
    }
  }
}
