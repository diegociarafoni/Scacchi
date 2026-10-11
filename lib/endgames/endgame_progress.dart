import 'dart:math';

import 'drill.dart';

/// Stelle migliori e posizioni da ripetere dell'allenatore dei finali.
class EndgameProgress {
  const EndgameProgress({this.stars = const {}, this.toRepeat = const {}});

  factory EndgameProgress.fromJson(
    Map<String, dynamic> json,
  ) => EndgameProgress(
    stars: {
      for (final e in (json['stars'] as Map<String, dynamic>? ?? {}).entries)
        e.key: e.value as int,
    },
    toRepeat: {...(json['toRepeat'] as List<dynamic>? ?? []).cast<String>()},
  );

  final Map<String, int> stars;

  /// Posizioni fallite e non ancora riuscite, riproposte per prime.
  final Set<String> toRepeat;

  int starsFor(String id) => stars[id] ?? 0;

  EndgameProgress complete(String id, int stars) => EndgameProgress(
    stars: {...this.stars, id: max(starsFor(id), stars.clamp(1, 3))},
    toRepeat: {...toRepeat}..remove(id),
  );

  /// Una posizione già riuscita non torna da ripetere.
  EndgameProgress fail(String id) => starsFor(id) > 0
      ? this
      : EndgameProgress(stars: stars, toRepeat: {...toRepeat, id});

  /// Le posizioni da ripetere prima, poi le altre nell'ordine del catalogo.
  List<EndgameDrill> ordered(List<EndgameDrill> drills) => [
    ...drills.where((d) => toRepeat.contains(d.id)),
    ...drills.where((d) => !toRepeat.contains(d.id)),
  ];

  Map<String, dynamic> toJson() => {
    'stars': stars,
    'toRepeat': toRepeat.toList(),
  };
}
