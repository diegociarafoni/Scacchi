import 'package:dartchess/dartchess.dart';

const _pieces = {
  'K': 're',
  'Q': 'donna',
  'R': 'torre',
  'B': 'alfiere',
  'N': 'cavallo',
};

final _sanPattern = RegExp(
  r'^([KQRBN])?([a-h]?[1-8]?)(x)?([a-h][1-8])(?:=([QRBN]))?([+#])?$',
);

/// Frase in italiano per annunciare una mossa SAN con il lettore di schermo.
String describeSan(String san, Side side) {
  final who = side == Side.white ? 'Bianco' : 'Nero';
  final check = san.endsWith('#')
      ? ', scacco matto'
      : san.endsWith('+')
      ? ', scacco'
      : '';
  if (san.startsWith('O-O-O')) return '$who: arrocco lungo$check';
  if (san.startsWith('O-O')) return '$who: arrocco corto$check';
  final m = _sanPattern.firstMatch(san);
  if (m == null) return '$who: $san';
  final piece = m[1] == null ? 'pedone' : _pieces[m[1]]!;
  final origin = m[2]!;
  final from = switch (origin.length) {
    0 => '',
    2 => ' da $origin',
    _ when origin.contains(RegExp('[a-h]')) => ' della colonna $origin',
    _ => ' della traversa $origin',
  };
  final capture = m[3] == null ? '' : ' prende';
  final promotion = m[5] == null ? '' : ', promozione a ${_pieces[m[5]]}';
  final to = capture.isEmpty && from.isNotEmpty ? ' in ${m[4]}' : ' ${m[4]}';
  return '$who: $piece$from$capture$to$promotion$check';
}
