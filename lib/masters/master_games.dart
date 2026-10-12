import 'master_game.dart';

/// Partite celebri della raccolta (RF-87), in ordine cronologico.
///
/// Le mosse sono fatti storici e le intestazioni sono dati di pubblico
/// dominio; i commenti sono scritti per il progetto (vedi
/// `docs/grandi-maestri.md`).
const List<MasterGame> masterGames = [
  MasterGame(
    id: 'legal-1750',
    white: 'Légal',
    black: 'Saint-Brie',
    event: 'Parigi',
    year: 1750,
    result: '1-0',
    nickname: 'Il matto di Légal',
    intro:
        'Una delle trappole più antiche, attribuita a Parigi nel 1750: il '
        'Bianco sacrifica la donna per dare matto con tre pezzi leggeri. '
        'Il Nero perde perché pensa solo a inchiodare il cavallo.',
    moves: [
      'e4', 'e5', 'Nf3', 'd6', 'Bc4', 'Bg4', 'Nc3', 'g6', 'Nxe5', 'Bxd1', //
      'Bxf7+', 'Ke7', 'Nd5#',
    ],
    notes: {
      5: 'L\'alfiere guarda f7, il punto più debole del campo nero.',
      6: 'Inchioda il cavallo f3 alla donna: sembra una mossa naturale.',
      8:
          'Un errore: il Nero non si accorge che il cavallo inchiodato può '
          'comunque prendere in e5.',
      9:
          'Il sacrificio: il cavallo prende il pedone e lascia la donna in '
          'presa. Se il Nero la cattura, il re resta senza difese.',
      11: 'Lo scacco costringe il re a muoversi e libera la casa d5.',
      13:
          'Matto: re chiuso dai propri pezzi, alfiere e cavalli lo '
          'circondano.',
    },
  ),
  MasterGame(
    id: 'immortal-1851',
    white: 'Anderssen',
    black: 'Kieseritzky',
    event: 'Londra, partita amichevole',
    year: 1851,
    result: '1-0',
    nickname: 'La partita immortale',
    intro:
        'Anderssen rinuncia a un alfiere, due torri e la donna pur di '
        'attaccare il re nero, e vince con i soli pezzi leggeri rimasti.',
    moves: [
      'e4', 'e5', 'f4', 'exf4', 'Bc4', 'Qh4+', 'Kf1', 'b5', 'Bxb5', 'Nf6', //
      'Nf3', 'Qh6', 'd3', 'Nh5', 'Nh4', 'Qg5', 'Nf5', 'c6', 'g4', 'Nf6', //
      'Rg1', 'cxb5', 'h4', 'Qg6', 'h5', 'Qg5', 'Qf3', 'Ng8', 'Bxf4', 'Qf6', //
      'Nc3', 'Bc5', 'Nd5', 'Qxb2', 'Bd6', 'Bxg1', 'e5', 'Qxa1+', 'Ke2', //
      'Na6', 'Nxg7+', 'Kd8', 'Qf6+', 'Nxf6', 'Be7#',
    ],
    notes: {
      3:
          'Il gambetto di re: un pedone in cambio di sviluppo e di un '
          'centro libero.',
      5: 'Il gambetto di alfiere: il Bianco punta subito a f7.',
      6: 'Lo scacco toglie al Bianco il diritto di arroccare.',
      21:
          'La torre su g1 sembra fuori gioco ma sarà una delle vittime '
          'dell\'attacco.',
      33: 'Anderssen non difende la torre in a1: continua l\'attacco al re.',
      35:
          'Il Nero può prendere due torri, ma intanto la rete attorno al '
          'suo re si stringe.',
      37:
          'Una mossa di pedone senza catturare nulla: il Bianco preferisce '
          'l\'attacco al materiale.',
      43:
          'Il sacrificio della donna: il cavallo nero è costretto a '
          'prenderla.',
      45:
          'Matto: alfiere e cavalli coordinati bastano, nonostante il '
          'Nero abbia molto più materiale.',
    },
  ),
  MasterGame(
    id: 'evergreen-1852',
    white: 'Anderssen',
    black: 'Dufresne',
    event: 'Berlino',
    year: 1852,
    result: '1-0',
    nickname: 'La sempreverde',
    intro:
        'Un classico del gambetto Evans: Anderssen apre il centro, sacrifica '
        'una torre e la donna con due scacchi in fila e chiude con un matto '
        'di alfiere.',
    moves: [
      'e4', 'e5', 'Nf3', 'Nc6', 'Bc4', 'Bc5', 'b4', 'Bxb4', 'c3', 'Ba5', //
      'd4', 'exd4', 'O-O', 'd3', 'Qb3', 'Qf6', 'e5', 'Qg6', 'Re1', 'Nge7', //
      'Ba3', 'b5', 'Qxb5', 'Rb8', 'Qa4', 'Bb6', 'Nbd2', 'Bb7', 'Ne4', 'Qf5', //
      'Bxd3', 'Qh5', 'Nf6+', 'gxf6', 'exf6', 'Rg8', 'Rad1', 'Qxf3', 'Rxe7+', //
      'Nxe7', 'Qxd7+', 'Kxd7', 'Bf5+', 'Ke8', 'Bd7+', 'Kf8', 'Bxe7#',
    ],
    notes: {
      7:
          'Il gambetto Evans: un pedone offerto per guadagnare tempi e '
          'costruire un grande centro.',
      21: 'L\'alfiere su a3 impedisce al Nero di arroccare corto.',
      33: 'Il cavallo scatta con scacco: il Nero deve aprire la colonna g.',
      39:
          'Il sacrificio di torre: il cavallo nero è costretto a prendere '
          'e abbandona la difesa di d7.',
      41: 'Il sacrificio di donna: il re nero è costretto a prenderla.',
      43:
          'Gli scacchi dell\'alfiere spingono il re nero verso f8, dove '
          'lo aspetta il matto.',
      47: 'Matto: l\'alfiere in e7 è protetto dal pedone f6.',
    },
  ),
  MasterGame(
    id: 'opera-1858',
    white: 'Morphy',
    black: 'Duca di Brunswick e conte Isouard',
    event: 'Parigi, all\'opera',
    year: 1858,
    result: '1-0',
    nickname: 'La partita all\'opera',
    intro:
        'Morphy gioca in un palco del teatro contro due nobili in consulto. '
        'Sviluppa i pezzi più in fretta e poi sacrifica la donna per un '
        'matto di torre.',
    moves: [
      'e4', 'e5', 'Nf3', 'd6', 'd4', 'Bg4', 'dxe5', 'Bxf3', 'Qxf3', 'dxe5', //
      'Bc4', 'Nf6', 'Qb3', 'Qe7', 'Nc3', 'c6', 'Bg5', 'b5', 'Nxb5', 'cxb5', //
      'Bxb5+', 'Nbd7', 'O-O-O', 'Rd8', 'Rxd7', 'Rxd7', 'Rd1', 'Qe6', //
      'Bxd7+', 'Nxd7', 'Qb8+', 'Nxb8', 'Rd8#',
    ],
    notes: {
      7:
          'Morphy apre il centro: il Nero prende il cavallo ma resta '
          'indietro nello sviluppo.',
      13: 'Doppia minaccia: la donna attacca b7 e f7.',
      17:
          'L\'alfiere inchioda il cavallo f6: ogni suo movimento sarebbe '
          'pericoloso per la donna.',
      19:
          'Un cavallo sacrificato apre la colonna b e l\'alfiere con '
          'scacco.',
      23: 'L\'arrocco lungo mette la torre in gioco sulla colonna d.',
      25: 'La torre prende il cavallo inchiodato: il Nero deve riprendere.',
      31:
          'Il sacrificio della donna: il cavallo deve prenderla e poi il '
          'matto è inevitabile.',
      33: 'Matto: la torre in d8 è protetta da quella in d1.',
    },
  ),
  MasterGame(
    id: 'reti-tartakower-1910',
    white: 'Réti',
    black: 'Tartakower',
    event: 'Vienna',
    year: 1910,
    result: '1-0',
    nickname: 'La miniatura di Réti',
    intro:
        'Una partita da undici mosse: il Bianco sacrifica la donna per '
        'scoprire un doppio scacco e dare matto con l\'alfiere.',
    moves: [
      'e4', 'c6', 'd4', 'd5', 'Nc3', 'dxe4', 'Nxe4', 'Nf6', 'Qd3', 'e5', //
      'dxe5', 'Qa5+', 'Bd2', 'Qxe5', 'O-O-O', 'Nxe4', 'Qd8+', 'Kxd8', //
      'Bg5+', 'Kc7', 'Bd8#',
    ],
    notes: {
      9:
          'La donna in d3 prepara la colonna d: sembra solo un modo di '
          'proteggere il cavallo.',
      15: 'Il Bianco arrocca lungo e mette la torre dietro alla donna.',
      16: 'Il Nero prende il cavallo e non vede la minaccia.',
      17:
          'Il sacrificio: la donna va in d8 con scacco e il re è costretto '
          'a prenderla.',
      19:
          'Doppio scacco: lo danno l\'alfiere e la torre insieme, quindi il '
          're deve muoversi.',
      21: 'Matto: l\'alfiere in d8 è protetto dalla torre in d1.',
    },
  ),
  MasterGame(
    id: 'byrne-fischer-1956',
    white: 'Donald Byrne',
    black: 'Fischer',
    event: 'Torneo Rosenwald, New York',
    year: 1956,
    result: '0-1',
    nickname: 'La partita del secolo',
    intro:
        'Fischer ha tredici anni. Dopo un sacrificio di donna in cambio di '
        'torre, alfiere e pedone, i suoi pezzi dominano la scacchiera e '
        'Byrne non riesce a evitare il matto.',
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
    notes: {
      22: 'Il cavallo attacca la donna e il cavallo in c3.',
      32:
          'Lo scacco di torre costringe il re a muoversi: da qui il Nero '
          'ha l\'iniziativa.',
      34:
          'La mossa che ha reso famosa la partita: l\'alfiere in e6 '
          'offre la donna in cambio di un attacco irresistibile.',
      36: 'Il Nero prende l\'alfiere con scacco.',
      38:
          'Seguono scacchi di cavallo ripetuti: il re bianco va avanti e '
          'indietro mentre il Nero raccoglie materiale.',
      82:
          'Matto: la torre in c2 è protetta dall\'alfiere e il cavallo '
          'copre b1 e d1, quindi il re non ha vie di fuga.',
    },
  ),
  MasterGame(
    id: 'kasparov-topalov-1999',
    white: 'Kasparov',
    black: 'Topalov',
    event: 'Torneo Hoogovens, Wijk aan Zee',
    year: 1999,
    result: '1-0',
    nickname: 'Il sacrificio di torre di Kasparov',
    intro:
        'Kasparov sacrifica una torre e trascina il re nero dalla sua '
        'casa fino ad a4, in un attacco che dura una ventina di mosse.',
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
    notes: {
      47:
          'Il sacrificio di torre: il Bianco dà una torre per spezzare il '
          'riparo del re nero.',
      49:
          'La seconda torre entra con scacco: il re nero non può più '
          'tornare indietro.',
      52: 'Il re nero è costretto a prendere il cavallo e finisce in a5.',
      53: 'Il pedone dà scacco e spinge il re verso a4.',
      59:
          'La torre prende l\'alfiere: il Bianco sta guadagnando '
          'materiale con l\'attacco ancora in corso.',
      71:
          'Una mossa silenziosa: l\'alfiere in f1 prepara la minaccia '
          'decisiva Td7.',
    },
  ),
];
