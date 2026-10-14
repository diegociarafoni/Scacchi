/// Indirizzo del codice sorgente, richiesto dalla GPL.
const sourceCodeUrl = 'https://github.com/diegociarafoni/rokko';

/// Un componente di terze parti con la sua licenza.
class Credit {
  const Credit(this.name, this.license);

  final String name;
  final String license;
}

/// Crediti di motore, pezzi e caratteri (nomi propri, non tradotti); l'elenco
/// completo è in `CREDITS.md` e nella pagina delle licenze del sistema.
const credits = <Credit>[
  Credit('Rokko', 'GPL-3.0 / CC0'),
  Credit('Stockfish 19', 'GPL-3.0'),
  Credit('dartchess (Lichess)', 'GPL-3.0'),
  Credit('chessground (Lichess)', 'GPL-3.0'),
  Credit('cburnett, Colin M.L. Burnett', 'GPL-2.0+ / CC BY-SA 3.0'),
  Credit('merida, Armando Hernández Marroquín', 'GPL-2.0+'),
  Credit('chessnut, Alexis Luengas', 'Apache-2.0'),
  Credit('fantasy, spatial, celtic, Maurizio Monge', 'MIT'),
  Credit('shapes, flugsio', 'CC BY-SA 4.0'),
  Credit('firi, James Faure', 'CC BY 4.0'),
  Credit('mpchess, Maxime Chupin', 'GPL-3.0+'),
  Credit('kiwen-suwi, neverRare', 'CC BY 4.0'),
  Credit('totoy, Kosal Sen', 'CC BY 4.0'),
  Credit('rhosgfx, RhosGFX', 'CC0'),
  Credit('papercut, Nikolay Anzarov (Lichess)', 'CC BY 4.0'),
  Credit('pirouetti, pirouetti (Lichess)', 'AGPL-3.0+'),
  Credit('letter, usolando (Lichess)', 'AGPL-3.0+'),
  Credit('Noto Sans Symbols 2, Google', 'OFL-1.1'),
  Credit('Flutter', 'BSD-3-Clause'),
];
