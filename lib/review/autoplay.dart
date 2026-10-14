import 'move_classification.dart';

/// Pausa tra una mossa e la successiva durante la riproduzione.
const playbackStep = Duration(milliseconds: 900);

/// Posizione (come l'indice della revisione: k è quella dopo la mossa k-1)
/// della prossima mossa che ha un commento dopo [from], o `null` se [from] è
/// già la fine. Senza altri commenti restituisce l'ultima posizione.
///
/// Un commento c'è per errori, mosse brillanti od ottime, note personali e
/// per l'ingresso nel libro; le mosse Libro successive non fanno fermare.
int? nextCommentedIndex({
  required List<MoveClass> classes,
  List<bool> hasNote = const [],
  required int from,
}) {
  for (var ply = from; ply < classes.length; ply++) {
    if (_commented(classes, hasNote, ply)) return ply + 1;
  }
  return from < classes.length ? classes.length : null;
}

bool _commented(List<MoveClass> classes, List<bool> hasNote, int ply) {
  if (ply < hasNote.length && hasNote[ply]) return true;
  final c = classes[ply];
  if (c == MoveClass.book) return ply == 0 || classes[ply - 1] != c;
  return c.isError || c == MoveClass.brilliant || c == MoveClass.great;
}
