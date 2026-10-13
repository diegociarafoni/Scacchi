import 'master_game.dart';

/// Partite celebri della raccolta (RF-87), in ordine cronologico.
///
/// Le mosse sono fatti storici e le intestazioni sono dati di pubblico
/// dominio; i commenti sono scritti per il progetto (vedi
/// `docs/grandi-maestri.md`).
const List<MasterGame> masterGames = [
  MasterGame(
    id: 'legal-1750',
    year: 1750,
    result: '1-0',
    moves: [
      'e4', 'e5', 'Nf3', 'd6', 'Bc4', 'Bg4', 'Nc3', 'g6', 'Nxe5', 'Bxd1', //
      'Bxf7+', 'Ke7', 'Nd5#',
    ],
  ),
  MasterGame(
    id: 'immortal-1851',
    year: 1851,
    result: '1-0',
    moves: [
      'e4', 'e5', 'f4', 'exf4', 'Bc4', 'Qh4+', 'Kf1', 'b5', 'Bxb5', 'Nf6', //
      'Nf3', 'Qh6', 'd3', 'Nh5', 'Nh4', 'Qg5', 'Nf5', 'c6', 'g4', 'Nf6', //
      'Rg1', 'cxb5', 'h4', 'Qg6', 'h5', 'Qg5', 'Qf3', 'Ng8', 'Bxf4', 'Qf6', //
      'Nc3', 'Bc5', 'Nd5', 'Qxb2', 'Bd6', 'Bxg1', 'e5', 'Qxa1+', 'Ke2', //
      'Na6', 'Nxg7+', 'Kd8', 'Qf6+', 'Nxf6', 'Be7#',
    ],
  ),
  MasterGame(
    id: 'evergreen-1852',
    year: 1852,
    result: '1-0',
    moves: [
      'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5', 'b4', 'Bxb4', 'c3', 'Ba5', //
      'd4', 'exd4', 'O-O', 'd3', 'Qb3', 'Qf6', 'e5', 'Qg6', 'Re1', 'Nge7', //
      'Ba3', 'b5', 'Qxb5', 'Rb8', 'Qa4', 'Bb6', 'Nbd2', 'Bb7', 'Ne4', 'Qf5', //
      'Bxd3', 'Qh5', 'Nf6+', 'gxf6', 'exf6', 'Rg8', 'Rad1', 'Qxf3', 'Rxe7+', //
      'Nxe7', 'Qxd7+', 'Kxd7', 'Bf5+', 'Ke8', 'Bd7+', 'Kf8', 'Bxe7#',
    ],
  ),
  MasterGame(
    id: 'opera-1858',
    year: 1858,
    result: '1-0',
    moves: [
      'e4', 'e5', 'Nf3', 'd6', 'd4', 'Bg4', 'dxe5', 'Bxf3', 'Qxf3', 'dxe5', //
      'Bc4', 'Nf6', 'Qb3', 'Qe7', 'Nc3', 'c6', 'Bg5', 'b5', 'Nxb5', 'cxb5', //
      'Bxb5+', 'Nbd7', 'O-O-O', 'Rd8', 'Rxd7', 'Rxd7', 'Rd1', 'Qe6', //
      'Bxd7+', 'Nxd7', 'Qb8+', 'Nxb8', 'Rd8#',
    ],
  ),
  MasterGame(
    id: 'reti-tartakower-1910',
    year: 1910,
    result: '1-0',
    moves: [
      'e4', 'c6', 'd4', 'd5', 'Nc3', 'dxe4', 'Nxe4', 'Nf6', 'Qd3', 'e5', //
      'dxe5', 'Qa5+', 'Bd2', 'Qxe5', 'O-O-O', 'Nxe4', 'Qd8+', 'Kxd8', //
      'Bg5+', 'Kc7', 'Bd8#',
    ],
  ),
  MasterGame(
    id: 'capablanca-burn-1911',
    year: 1911,
    result: '1-0',
    moves: [
      'e4', 'e5', 'Nf3', 'Nc6', 'Bb5', 'a6', 'Ba4', 'Nf6', 'd3', 'd6', //
      'c3', 'Be7', 'Nbd2', 'O-O', 'Nf1', 'b5', 'Bc2', 'd5', 'Qe2', 'dxe4', //
      'dxe4', 'Bc5', 'Bg5', 'Be6', 'Ne3', 'Re8', 'O-O', 'Qe7', 'Nd5', //
      'Bxd5', 'exd5', 'Nb8', 'a4', 'b4', 'cxb4', 'Bxb4', 'Bxf6', 'Qxf6', //
      'Qe4', 'Bd6', 'Qxh7+', 'Kf8', 'Nh4', 'Qh6', 'Qxh6', 'gxh6', 'Nf5', //
      'h5', 'Bd1', 'Nd7', 'Bxh5', 'Nf6', 'Be2', 'Nxd5', 'Rfd1', 'Nf4', //
      'Bc4', 'Red8', 'h4', 'a5', 'g3', 'Ne6', 'Bxe6', 'fxe6', 'Ne3', 'Rdb8', //
      'Nc4', 'Ke7', 'Rac1', 'Ra7', 'Re1', 'Kf6', 'Re4', 'Rb4', 'g4', 'Ra6', //
      'Rc3', 'Bc5', 'Rf3+', 'Kg7', 'b3', 'Bd4', 'Kg2', 'Ra8', 'g5', 'Ra6', //
      'h5', 'Rxc4', 'bxc4', 'Rc6', 'g6',
    ],
  ),
  MasterGame(
    id: 'capablanca-teichmann-1913',
    year: 1913,
    result: '1-0',
    moves: [
      'd4', 'd5', 'Nf3', 'Nf6', 'c4', 'e6', 'Bg5', 'Be7', 'Nc3', 'Nbd7', //
      'e3', 'O-O', 'Rc1', 'b6', 'cxd5', 'exd5', 'Bb5', 'Bb7', 'O-O', 'a6', //
      'Ba4', 'Rc8', 'Qe2', 'c5', 'dxc5', 'Nxc5', 'Rfd1', 'Nxa4', 'Nxa4', //
      'b5', 'Rxc8', 'Qxc8', 'Nc3', 'Qc4', 'Nd4', 'Qxe2', 'Ncxe2', 'Rc8', //
      'Nf5', 'Kf8', 'Nxe7', 'Kxe7', 'Nd4', 'g6', 'f3', 'h6', 'Bxh6', 'Nd7', //
      'h4', 'Nc5', 'Bf4', 'Ne6', 'Nxe6', 'Kxe6', 'Rd2', 'Rh8', 'Rc2', 'Rc8', //
      'Rxc8', 'Bxc8', 'Kf2', 'd4', 'exd4', 'Kd5', 'Ke3', 'Be6', 'Kd3', //
      'Kc6', 'a3', 'Bc4+', 'Ke3', 'Be6', 'Bh6', 'Kd5', 'Bg7',
    ],
  ),
  MasterGame(
    id: 'marshall-capablanca-1918',
    year: 1918,
    result: '0-1',
    moves: [
      'd4', 'd5', 'Nf3', 'Nf6', 'c4', 'e6', 'Nc3', 'Nbd7', 'Bg5', 'Be7', //
      'e3', 'O-O', 'Rc1', 'c6', 'Qc2', 'dxc4', 'Bxc4', 'Nd5', 'Bxe7', //
      'Qxe7', 'O-O', 'Nxc3', 'Qxc3', 'b6', 'e4', 'Bb7', 'Rfe1', 'Rfd8', //
      'd5', 'Nc5', 'dxe6', 'Nxe6', 'Bxe6', 'Qxe6', 'Nd4', 'Qe5', 'Nxc6', //
      'Qxc3', 'Rxc3', 'Rd2', 'Rb1', 'Re8', 'e5', 'g5', 'h4', 'gxh4', 'Re1', //
      'Re6', 'Rec1', 'Kg7', 'b4', 'b5', 'a3', 'Rg6', 'Kf1', 'Ra2', 'Kg1', //
      'h3', 'g3', 'a6', 'e6', 'Rxe6', 'g4', 'Rh6', 'f3', 'Rd6', 'Ne7', //
      'Rdd2', 'Nf5+', 'Kf6', 'Nh4', 'Kg5', 'Nf5', 'Rg2+', 'Kf1', 'h2', //
      'f4+', 'Kxf4',
    ],
  ),
  MasterGame(
    id: 'byrne-fischer-1956',
    year: 1956,
    result: '0-1',
    moves: [
      'Nf3', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'd4', 'O-O', 'Bf4', 'd5', //
      'Qb3', 'dxc4', 'Qxc4', 'c6', 'e4', 'Nbd7', 'Rd1', 'Nb6', 'Qc5', 'Bg4', //
      'Bg5', 'Na4', 'Qa3', 'Nxc3', 'bxc3', 'Nxe4', 'Bxe7', 'Qb6', 'Bc4', //
      'Nxc3', 'Bc5', 'Rfe8+', 'Kf1', 'Be6', 'Bxb6', 'Bxc4+', 'Kg1', 'Ne2+', //
      'Kf1', 'Nxd4+', 'Kg1', 'Ne2+', 'Kf1', 'Nc3+', 'Kg1', 'axb6', 'Qb4', //
      'Ra4', 'Qxb6', 'Nxd1', 'h3', 'Rxa2', 'Kh2', 'Nxf2', 'Re1', 'Rxe1', //
      'Qd8+', 'Bf8', 'Nxe1', 'Bd5', 'Nf3', 'Ne4', 'Qb8', 'b5', 'h4', 'h5', //
      'Ne5', 'Kg7', 'Kg1', 'Bc5+', 'Kf1', 'Ng3+', 'Ke1', 'Bb4+', 'Kd1', //
      'Bb3+', 'Kc1', 'Ne2+', 'Kb1', 'Nc3+', 'Kc1', 'Rc2#',
    ],
  ),
  MasterGame(
    id: 'kasparov-topalov-1999',
    year: 1999,
    result: '1-0',
    moves: [
      'e4', 'd6', 'd4', 'Nf6', 'Nc3', 'g6', 'Be3', 'Bg7', 'Qd2', 'c6', //
      'f3', 'b5', 'Nge2', 'Nbd7', 'Bh6', 'Bxh6', 'Qxh6', 'Bb7', 'a3', 'e5', //
      'O-O-O', 'Qe7', 'Kb1', 'a6', 'Nc1', 'O-O-O', 'Nb3', 'exd4', 'Rxd4', //
      'c5', 'Rd1', 'Nb6', 'g3', 'Kb8', 'Na5', 'Ba8', 'Bh3', 'd5', 'Qf4+', //
      'Ka7', 'Rhe1', 'd4', 'Nd5', 'Nbxd5', 'exd5', 'Qd6', 'Rxd4', 'cxd4', //
      'Re7+', 'Kb6', 'Qxd4+', 'Kxa5', 'b4+', 'Ka4', 'Qc3', 'Qxd5', 'Ra7', //
      'Bb7', 'Rxb7', 'Qc4', 'Qxf6', 'Kxa3', 'Qxa6+', 'Kxb4', 'c3+', 'Kxc3', //
      'Qa1+', 'Kd2', 'Qb2+', 'Kd1', 'Bf1', 'Rd2', 'Rd7', 'Rxd7', 'Bxc4', //
      'bxc4', 'Qxh8', 'Rd3', 'Qa8', 'c3', 'Qa4+', 'Ke1', 'f4', 'f5', 'Kc1', //
      'Rd2', 'Qa7',
    ],
  ),
];
