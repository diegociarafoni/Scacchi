import 'package:dartchess/dartchess.dart';

import '../openings/opening_names_it.dart';
import '../progress/progress_state.dart';

/// Un libro della collezione: si sblocca giocando una partita che segue
/// un'apertura della sua famiglia (nomi del dataset, in inglese).
class OpeningVolume {
  const OpeningVolume(this.id, this.name, this.cover, {Set<String>? families})
    : _families = families ?? const {};

  /// Identificativo stabile, salvato nei contatori: non cambiarlo.
  final String id;

  /// Nome dell'apertura, come nel dataset («Sicilian Defense»).
  final String name;

  /// Mosse UCI che portano alla posizione in copertina.
  final List<String> cover;

  /// Famiglie del dataset che sbloccano il libro; vuoto se è solo [name].
  final Set<String> _families;

  Set<String> get families => _families.isEmpty ? {name} : _families;

  /// Nome in italiano; l'originale se la famiglia non ha traduzione.
  String get localName => openingNameIt(name);

  /// Posizioni dalla iniziale a quella della copertina.
  List<Position> get coverPositions {
    var pos = Chess.initial as Position;
    final all = [pos];
    for (final uci in cover) {
      pos = pos.play(Move.parse(uci)!);
      all.add(pos);
    }
    return all;
  }

  Position get coverPosition => coverPositions.last;

  /// FEN della copertina, calcolata una volta sola per libro.
  String get coverFen => _fens[id] ??= coverPosition.fen;
}

final _fens = <String, String>{};

const openingVolumes = <OpeningVolume>[
  OpeningVolume('italian', 'Italian Game', [
    'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1c4', //
  ]),
  OpeningVolume('ruy_lopez', 'Ruy Lopez', [
    'e2e4', 'e7e5', 'g1f3', 'b8c6', 'f1b5', //
  ]),
  OpeningVolume('sicilian', 'Sicilian Defense', ['e2e4', 'c7c5']),
  OpeningVolume('french', 'French Defense', [
    'e2e4', 'e7e6', 'd2d4', 'd7d5', //
  ]),
  OpeningVolume('caro_kann', 'Caro-Kann Defense', [
    'e2e4', 'c7c6', 'd2d4', 'd7d5', //
  ]),
  OpeningVolume('scandinavian', 'Scandinavian Defense', ['e2e4', 'd7d5']),
  OpeningVolume('alekhine', 'Alekhine Defense', ['e2e4', 'g8f6']),
  OpeningVolume('pirc', 'Pirc Defense', [
    'e2e4', 'd7d6', 'd2d4', 'g8f6', 'b1c3', 'g7g6', //
  ]),
  OpeningVolume('modern', 'Modern Defense', ['e2e4', 'g7g6']),
  OpeningVolume('nimzowitsch', 'Nimzowitsch Defense', ['e2e4', 'b8c6']),
  OpeningVolume('philidor', 'Philidor Defense', [
    'e2e4', 'e7e5', 'g1f3', 'd7d6', //
  ]),
  OpeningVolume('petrov', "Petrov's Defense", [
    'e2e4', 'e7e5', 'g1f3', 'g8f6', //
  ]),
  OpeningVolume('scotch', 'Scotch Game', [
    'e2e4', 'e7e5', 'g1f3', 'b8c6', 'd2d4', //
  ]),
  OpeningVolume('vienna', 'Vienna Game', ['e2e4', 'e7e5', 'b1c3']),
  OpeningVolume('bishops', "Bishop's Opening", ['e2e4', 'e7e5', 'f1c4']),
  OpeningVolume(
    'kings_gambit',
    "King's Gambit",
    ['e2e4', 'e7e5', 'f2f4', 'e5f4'],
    families: {"King's Gambit Accepted", "King's Gambit Declined"},
  ),
  OpeningVolume('four_knights', 'Four Knights Game', [
    'e2e4', 'e7e5', 'g1f3', 'b8c6', 'b1c3', 'g8f6', //
  ]),
  OpeningVolume('ponziani', 'Ponziani Opening', [
    'e2e4', 'e7e5', 'g1f3', 'b8c6', 'c2c3', //
  ]),
  OpeningVolume(
    'center_game',
    'Center Game',
    ['e2e4', 'e7e5', 'd2d4', 'e5d4'],
    families: {'Center Game', 'Center Game Accepted'},
  ),
  OpeningVolume('latvian', 'Latvian Gambit', [
    'e2e4', 'e7e5', 'g1f3', 'f7f5', //
  ]),
  OpeningVolume(
    'queens_gambit',
    "Queen's Gambit",
    ['d2d4', 'd7d5', 'c2c4', 'e7e6'],
    families: {"Queen's Gambit Declined", "Queen's Gambit Accepted"},
  ),
  OpeningVolume('slav', 'Slav Defense', [
    'd2d4', 'd7d5', 'c2c4', 'c7c6', //
  ]),
  OpeningVolume('semi_slav', 'Semi-Slav Defense', [
    'd2d4', 'd7d5', 'c2c4', 'c7c6', 'b1c3', 'g8f6', 'g1f3', 'e7e6', //
  ]),
  OpeningVolume('tarrasch', 'Tarrasch Defense', [
    'd2d4', 'd7d5', 'c2c4', 'e7e6', 'b1c3', 'c7c5', //
  ]),
  OpeningVolume('blackmar_diemer', 'Blackmar-Diemer Gambit', [
    'd2d4', 'd7d5', 'e2e4', 'd5e4', 'b1c3', 'g8f6', 'f2f3', //
  ]),
  OpeningVolume('kings_indian', 'King\'s Indian Defense', [
    'd2d4', 'g8f6', 'c2c4', 'g7g6', 'b1c3', 'f8g7', //
  ]),
  OpeningVolume('nimzo_indian', 'Nimzo-Indian Defense', [
    'd2d4', 'g8f6', 'c2c4', 'e7e6', 'b1c3', 'f8b4', //
  ]),
  OpeningVolume('queens_indian', "Queen's Indian Defense", [
    'd2d4', 'g8f6', 'c2c4', 'e7e6', 'g1f3', 'b7b6', //
  ]),
  OpeningVolume('gruenfeld', 'Grünfeld Defense', [
    'd2d4', 'g8f6', 'c2c4', 'g7g6', 'b1c3', 'd7d5', //
  ]),
  OpeningVolume('benoni', 'Benoni Defense', [
    'd2d4', 'g8f6', 'c2c4', 'c7c5', 'd4d5', //
  ]),
  OpeningVolume('dutch', 'Dutch Defense', ['d2d4', 'f7f5']),
  OpeningVolume('catalan', 'Catalan Opening', [
    'd2d4', 'g8f6', 'c2c4', 'e7e6', 'g2g3', //
  ]),
  OpeningVolume('english', 'English Opening', ['c2c4']),
  OpeningVolume('reti', 'Réti Opening', ['g1f3', 'd7d5', 'c2c4']),
  OpeningVolume('bird', 'Bird Opening', ['f2f4']),
  OpeningVolume('polish', 'Polish Opening', ['b2b4']),
  OpeningVolume('grob', 'Grob Opening', ['g2g4']),
];

/// Il libro a cui porta una famiglia di aperture del dataset, se c'è.
OpeningVolume? volumeForFamily(String family) {
  for (final v in openingVolumes) {
    if (v.families.contains(family)) return v;
  }
  return null;
}

/// Chiave del contatore con le partite giocate in quell'apertura.
String volumeKey(String id) => 'book:$id';

/// Libri sbloccati, nell'ordine della collezione.
List<OpeningVolume> unlockedVolumes(ProgressState s) => [
  for (final v in openingVolumes)
    if ((s.tally[volumeKey(v.id)] ?? 0) > 0) v,
];
