import 'dart:convert';

import '../exchange/qr_transfer.dart';
import 'puzzle_library.dart';
import 'puzzle_run.dart';

/// Prove che si possono lanciare a un amico: solo quelle a tempo, dove tutti
/// partono e finiscono insieme.
const friendChallengeModes = [
  PuzzleRunMode.storm,
  PuzzleRunMode.rush3,
  PuzzleRunMode.rush5,
];

/// Un messaggio di sfida è più corto di così: oltre non viene analizzato.
const _maxMessageLength = 512;
const _maxScore = 9999;
const _version = 1;

/// Impronta della raccolta di puzzle: due telefoni giocano la stessa sfida
/// solo se hanno gli stessi puzzle, altrimenti il seme darebbe serie diverse.
String libraryFingerprint(PuzzleLibrary library) {
  final ids = utf8.encode(library.puzzles.map((p) => p.id).join(','));
  return crc32(ids).toRadixString(16).toUpperCase().padLeft(8, '0');
}

/// Prova, seme dei puzzle e raccolta: tutto ciò che serve per giocare gli
/// stessi puzzle sui due telefoni.
class FriendChallenge {
  const FriendChallenge({
    required this.mode,
    required this.seed,
    required this.library,
  });

  final PuzzleRunMode mode;
  final int seed;
  final String library;

  @override
  bool operator ==(Object other) =>
      other is FriendChallenge &&
      other.mode == mode &&
      other.seed == seed &&
      other.library == library;

  @override
  int get hashCode => Object.hash(mode, seed, library);
}

sealed class ChallengeMessage {
  const ChallengeMessage(this.challenge);

  final FriendChallenge challenge;
}

/// Primo QR: lancia la sfida.
class ChallengeInvite extends ChallengeMessage {
  const ChallengeInvite(super.challenge);
}

/// Secondo QR: il punteggio ottenuto in una sfida.
class ChallengeResult extends ChallengeMessage {
  const ChallengeResult(super.challenge, this.score);

  final int score;

  /// Se questo risultato appartiene a [other].
  bool answers(FriendChallenge other) => challenge == other;
}

enum ChallengeOutcome { won, lost, draw }

ChallengeOutcome compareScores({required int mine, required int theirs}) =>
    mine == theirs
    ? ChallengeOutcome.draw
    : mine > theirs
    ? ChallengeOutcome.won
    : ChallengeOutcome.lost;

/// Fotogrammi QR del messaggio, nello stesso formato dello scambio di partite.
List<String> encodeChallenge(ChallengeMessage message) {
  final c = message.challenge;
  final map = <String, Object>{
    'k': message is ChallengeResult ? 'risultato' : 'sfida',
    'v': _version,
    'm': c.mode.name,
    's': c.seed,
    'l': c.library,
    if (message is ChallengeResult) 'p': message.score,
  };
  return encodeTransfer(jsonEncode(map));
}

final _fingerprint = RegExp(r'^[0-9A-F]{8}$');

/// Legge un testo ricomposto dai QR; `null` se non è una sfida valida. Il
/// testo viene da una fotocamera, quindi ogni campo è controllato.
ChallengeMessage? parseChallenge(String text) {
  if (text.length > _maxMessageLength) return null;
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (json is! Map<String, Object?> || json['v'] != _version) return null;
  final name = json['m'];
  final mode = friendChallengeModes.where((m) => m.name == name).firstOrNull;
  final seed = json['s'];
  final library = json['l'];
  if (mode == null ||
      seed is! int ||
      seed < 0 ||
      seed > 0xFFFFFFFF ||
      library is! String ||
      !_fingerprint.hasMatch(library)) {
    return null;
  }
  final challenge = FriendChallenge(mode: mode, seed: seed, library: library);
  switch (json['k']) {
    case 'sfida':
      return ChallengeInvite(challenge);
    case 'risultato':
      final score = json['p'];
      if (score is! int || score < 0 || score > _maxScore) return null;
      return ChallengeResult(challenge, score);
  }
  return null;
}
