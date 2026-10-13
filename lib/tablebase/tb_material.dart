/// Ruoli dei pezzi come numeri, nell'ordine di valore crescente.
abstract final class TbRole {
  static const pawn = 0;
  static const knight = 1;
  static const bishop = 2;
  static const rook = 3;
  static const queen = 4;
  static const king = 5;

  static const letters = 'PNBRQK';
  static const _values = [1, 3, 3, 5, 9];

  static int value(int role) => _values[role];
}

/// Pezzi presenti in un finale, oltre ai due re. I Bianchi sono sempre il
/// lato più forte (vedi [canonical]), così un solo archivio vale per i due
/// colori. I pezzi sono in ordine di ruolo decrescente.
class TbMaterial {
  TbMaterial(List<int> white, List<int> black)
    : white = List.unmodifiable(<int>[...white]..sort((a, b) => b - a)),
      black = List.unmodifiable(<int>[...black]..sort((a, b) => b - a));

  /// Nome come «KQvKR»: re e pezzi dei Bianchi, poi quelli dei Neri.
  factory TbMaterial.parse(String name) {
    final parts = name.split('v');
    if (parts.length != 2 ||
        !parts[0].startsWith('K') ||
        !parts[1].startsWith('K')) {
      throw FormatException('Materiale non valido: $name'); // l10n-ok
    }
    List<int> roles(String s) {
      final result = <int>[];
      for (final c in s.substring(1).split('')) {
        final role = TbRole.letters.indexOf(c);
        if (role < 0 || role > TbRole.queen) {
          throw FormatException('Pezzo non valido: $c'); // l10n-ok
        }
        result.add(role);
      }
      return result;
    }

    return TbMaterial(roles(parts[0]), roles(parts[1]));
  }

  final List<int> white;
  final List<int> black;

  /// Re compresi.
  int get pieces => 2 + white.length + black.length;

  bool get hasPawns =>
      white.contains(TbRole.pawn) || black.contains(TbRole.pawn);

  /// Si trattano i finali fino a quattro pezzi. I pedoni di entrambi i lati
  /// sono esclusi perché la presa en passant cambierebbe il risultato; con
  /// quattro pezzi i pedoni sono esclusi anche per il tempo di calcolo
  /// sul telefono (restano re e pedone contro re).
  bool get supported =>
      pieces <= 4 &&
      !(white.contains(TbRole.pawn) && black.contains(TbRole.pawn)) &&
      (pieces <= 3 || !hasPawns);

  /// Colore (0 Bianco, 1 Nero) di ogni casella dell'elenco: re bianco, re
  /// nero, pezzi bianchi, pezzi neri.
  List<int> get slotColors => [
    0,
    1,
    for (final _ in white) 0,
    for (final _ in black) 1,
  ];

  List<int> get slotRoles => [TbRole.king, TbRole.king, ...white, ...black];

  String get name =>
      'K${white.map((r) => TbRole.letters[r]).join()}'
      'vK${black.map((r) => TbRole.letters[r]).join()}';

  /// Codice numerico per cercare l'archivio senza costruire stringhe.
  int get code => codeOf(white, black);

  static int codeOf(Iterable<int> white, Iterable<int> black) {
    var code = 0;
    for (final r in white) {
      code += 1 << (2 * r);
    }
    for (final r in black) {
      code += 1 << (2 * (5 + r));
    }
    return code;
  }

  int _strength(List<int> side) =>
      side.fold(0, (sum, r) => sum + TbRole.value(r));

  /// Vero se i Neri sono più forti: l'archivio si tiene con i colori
  /// scambiati.
  bool get needsSwap {
    final w = _strength(white);
    final b = _strength(black);
    if (b != w) return b > w;
    for (var i = 0; i < white.length && i < black.length; i++) {
      if (black[i] != white[i]) return black[i] > white[i];
    }
    return false;
  }

  TbMaterial get swapped => TbMaterial(black, white);

  TbMaterial get canonical => needsSwap ? swapped : this;

  @override
  bool operator ==(Object other) => other is TbMaterial && other.code == code;

  @override
  int get hashCode => code;

  @override
  String toString() => name;
}
