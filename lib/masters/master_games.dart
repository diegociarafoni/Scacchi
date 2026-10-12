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
    id: 'capablanca-burn-1911',
    white: 'Capablanca',
    black: 'Burn',
    event: 'Torneo di San Sebastián',
    year: 1911,
    result: '1-0',
    intro:
        'Una partita del libro «Chess Fundamentals» (1921), dove Capablanca '
        'la commenta per gli allievi. Il Nero perde tempo nello sviluppo, '
        'Capablanca vince un pedone e poi lo porta alla vittoria con calma, '
        'senza dare al Nero nessuna occasione di attaccare. I commenti '
        'riprendono a parole nostre le sue idee.',
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
    notes: {
      9:
          'Uno sviluppo semplice e solido. Capablanca racconta che allora '
          'lo giocava spesso perché non conosceva molte varianti di '
          'apertura.',
      22:
          'L\'alfiere fa posto alla donna, ma secondo Capablanca era meglio '
          'Ae6: sviluppa un pezzo e minaccia Ac4.',
      28:
          'Un errore: prima il Nero doveva cambiare l\'alfiere con il '
          'cavallo che sta per arrivare in d5.',
      29:
          'Il cavallo salta in d5 e attacca la donna. Il cavallo nero in '
          'f6 è inchiodato dall\'alfiere in g5.',
      33:
          'Il Bianco attacca il pedone b5. Il Nero non può più evitare di '
          'perdere un pedone.',
      41:
          'Il Bianco ha un pedone in più e tutti i pezzi pronti, mentre il '
          'Nero è ancora indietro nello sviluppo.',
      43:
          'Il cavallo va verso f5 e minaccia Dh8+ e Cf5+. Il Nero deve '
          'offrire il cambio delle donne, e così sparisce ogni pericolo '
          'per il re bianco.',
      61:
          'Il pedone caccia il cavallo da f4. Il Nero ha pedoni isolati da '
          'difendere con i pezzi.',
      88:
          'Il Nero dà la torre per il cavallo, ma i pedoni bianchi sul lato '
          'di re sono troppo forti.',
      91:
          'Il pedone arriva in g6 e non si può più fermare: il Nero '
          'abbandona.',
    },
  ),
  MasterGame(
    id: 'capablanca-teichmann-1913',
    white: 'Capablanca',
    black: 'Teichmann',
    event: 'Berlino',
    year: 1913,
    result: '1-0',
    intro:
        'Dal libro «Chess Fundamentals» (1921). Fin dall\'apertura '
        'Capablanca punta a lasciare al Nero un pedone isolato in d5. Poi '
        'guadagna un pedone e vince il finale con mosse precise, anche con '
        'gli alfieri di colore diverso. I commenti riprendono a parole '
        'nostre le sue idee.',
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
    notes: {
      17:
          'Una mossa inventata da Capablanca in partita: è un normale '
          'sviluppo e non va contro nessun principio, quindi non può '
          'essere cattiva.',
      26:
          'Il Nero riprende con il cavallo, ma il suo pedone in d5 resta '
          'isolato: sarà il bersaglio di tutta la partita.',
      34:
          'Il Nero vuole cambiare le donne per restare con i due alfieri. '
          'È un errore: l\'alfiere in b7 è chiuso dietro al pedone d5.',
      37:
          'I cavalli si muovono a catena: uno è sempre in d4 o pronto ad '
          'andarci.',
      39:
          'Il cavallo attacca l\'alfiere in e7. Capablanca scrive di non '
          'vedere una buona difesa per il Nero.',
      45:
          'Il cavallo nero in f6 è inchiodato. Il Bianco minaccia di '
          'portare il re al centro e il Nero può solo aspettare.',
      47:
          'Il Bianco prende il pedone h6: il Nero lo ha dato per liberare '
          'il cavallo.',
      57: 'La torre prende la colonna c, l\'unica aperta.',
      62:
          'Quasi forzata: altrimenti il re bianco arriva in d4 e poi in c5 '
          'e mangia i pedoni del lato di donna.',
      75:
          'L\'alfiere in g7 difende il pedone d4. Ora il re bianco può '
          'entrare da f4 e il Nero abbandona.',
    },
  ),
  MasterGame(
    id: 'marshall-capablanca-1918',
    white: 'Marshall',
    black: 'Capablanca',
    event: 'Torneo di New York',
    year: 1918,
    result: '0-1',
    intro:
        'Dal libro «Chess Fundamentals» (1921). Marshall vince un pedone, '
        'ma la torre nera sulla settima traversa e l\'alfiere sulla grande '
        'diagonale valgono di più. Capablanca la chiama un finale da '
        'studiare con molta cura. I commenti riprendono a parole nostre le '
        'sue idee.',
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
    notes: {
      14:
          'Una delle difese più antiche contro il gambetto di donna: il '
          'Nero cambia qualche pezzo per avere spazio.',
      24:
          'La chiave di questa difesa: l\'alfiere andrà sulla grande '
          'diagonale senza creare debolezze. Svilupparlo è il problema più '
          'difficile del Nero.',
      30:
          'Il cavallo attacca e4 e prepara la presa in d5: la posizione '
          'si apre.',
      35:
          'La sorpresa di Marshall: se la donna nera prende in a2, la '
          'torre va in a1 e la donna è presa.',
      36:
          'Forse l\'unica mossa buona: la donna si offre al cambio e il '
          'Nero è almeno pari.',
      40:
          'La torre sulla settima traversa vale più del pedone che il Nero '
          'ha perso.',
      41:
          'Un errore di giudizio: il Bianco crede di stare meglio perché '
          'ha un pedone in più. Con Ce7+ poteva ottenere la patta.',
      44:
          'Il pedone impedisce f4. Il cavallo bianco è quasi inchiodato: '
          'se si muove, la torre nera prende in e5.',
      48:
          'Meglio che prendere pedoni: la torre minaccia di andare in g6 '
          'e obbliga il Bianco a difendere il cavallo.',
      56:
          'Guarda i pezzi bianchi: non possono muoversi senza perdere '
          'qualcosa.',
      60:
          'Ancora una mossa di attesa: il Bianco deve muovere e così '
          'peggiora la sua posizione.',
      62:
          'Ora il cavallo non può muoversi: dopo h2+ il re prende il '
          'pedone, poi Th6+, Rg1 e Th1 matto.',
      78:
          'Il pedone nero in h2 sta per diventare donna: il Bianco '
          'abbandona.',
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
