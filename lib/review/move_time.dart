import 'package:dartchess/dartchess.dart';

import '../game/clock.dart';

/// Tempo speso su ogni mossa (RF-67), ricavato dai tempi residui [clocks]
/// registrati dopo ciascuna mossa: il residuo precedente dello stesso lato,
/// più l'incremento, meno il residuo attuale. La prima mossa di ogni lato parte
/// dal tempo iniziale della [control] e non prende incremento; la mossa che
/// completa la fase aggiunta riceve anche i suoi minuti; senza cadenza resta
/// ignota. [startTimes] dà un tempo iniziale diverso per lato, nelle
/// partite a handicap (RF-27). `null` dove manca un tempo.
List<Duration?> timeSpent(
  List<Duration?> clocks, {
  required Side first,
  TimeControl? control,
  Map<Side, Duration>? startTimes,
}) {
  final initial = control == null ? null : Duration(minutes: control.minutes);
  final increment = Duration(seconds: control?.increment ?? 0);
  final previous = <Side, Duration?>{
    for (final side in Side.values)
      side: control == null ? null : startTimes?[side] ?? initial,
  };
  final made = <Side, int>{for (final side in Side.values) side: 0};
  final spent = <Duration?>[];
  for (var i = 0; i < clocks.length; i++) {
    final side = i.isEven ? first : first.opposite;
    final before = previous[side];
    final after = clocks[i];
    if (before == null || after == null) {
      spent.add(null);
    } else {
      // Il tempo della fase aggiunta arriva con la mossa che la completa.
      final bonus =
          (made[side]! > 0 ? increment : Duration.zero) +
          (control?.phaseBonus(made[side]! + 1) ?? Duration.zero);
      final d = before + bonus - after;
      spent.add(d.isNegative ? Duration.zero : d);
    }
    previous[side] = after;
    made[side] = made[side]! + 1;
  }
  return spent;
}

/// Mosse sbagliate ([isError]) giocate molto più in fretta del solito: meno
/// del 40% del tempo medio di quel lato, che deve avere almeno quattro mosse
/// cronometrate e una media di almeno 3 secondi, altrimenti la partita è
/// troppo veloce per dire cosa è fretta. [sides] dà il lato di ogni mossa.
List<int> hastyPlies(
  List<Duration?> spent, {
  required List<Side> sides,
  required bool Function(int ply) isError,
}) {
  final total = <Side, int>{Side.white: 0, Side.black: 0};
  final count = <Side, int>{Side.white: 0, Side.black: 0};
  for (var i = 0; i < spent.length; i++) {
    final d = spent[i];
    if (d == null) continue;
    total[sides[i]] = total[sides[i]]! + d.inMilliseconds;
    count[sides[i]] = count[sides[i]]! + 1;
  }
  return [
    for (var i = 0; i < spent.length; i++)
      if (spent[i] != null &&
          isError(i) &&
          count[sides[i]]! >= 4 &&
          total[sides[i]]! / count[sides[i]]! >= 3000 &&
          spent[i]!.inMilliseconds < 0.4 * total[sides[i]]! / count[sides[i]]!)
        i,
  ];
}
