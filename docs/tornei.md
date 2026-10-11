# Tornei offline contro bot

Requisito RG-09: tornei da 4 a 8 giocatori (l'utente e da 3 a 7 bot) al posto delle leghe online, con partite vere. Il codice è in `lib/tournament/`.

## Formule

| Formula | Giocatori | Turni | Spareggi |
|---|---|---|---|
| Girone all'italiana | 4, 5, 6 o 8 | Tutti contro tutti una volta (con giocatori dispari ognuno riposa un turno, senza punti) | Classifica per punti, poi Sonneborn-Berger, poi vittorie |
| Eliminazione diretta | 4 o 8 | 2 o 3 (quarti, semifinali, finale) | Dopo una patta, Armageddon a colori invertiti: al nero basta la patta |

- **Abbinamenti del girone**: metodo del cerchio (tabelle di Berger). Ognuno incontra tutti una volta. Con giocatori dispari il riposo è il giocatore fisso del cerchio e tutti hanno tanti bianchi quanti neri; con giocatori pari lo scarto è di un bianco.
- **Tabellone**: teste di serie per Elo, abbinate 1-8, 4-5, 2-7, 3-6 (con 4 giocatori 1-4, 2-3). Chi vince prosegue.
- **Avversari**: i bot più vicini alla forza stimata dell'utente, dal rating locale (vedi [statistiche.md](statistiche.md)). La schermata li mostra prima di iniziare.

## Partite vere e partite simulate

L'utente è sempre il giocatore 0 e gioca partite vere contro il motore, anche l'Armageddon. Le partite tra bot si simulano con la formula Elo:

- punteggio atteso `1 / (1 + 10^((Elo nero − Elo bianco) / 400))`;
- probabilità di patta `0,3 × (1 − |2 × atteso − 1|)`, più alta tra giocatori vicini;
- estrazione con `mix32` sul seme del torneo, sul turno e sulla scacchiera: lo stesso torneo dà sempre gli stessi risultati, anche dopo un riavvio.

Se l'utente esce nell'eliminazione diretta, i turni rimanenti si simulano subito e il torneo si chiude.

## Salvataggio e bacheca

`TournamentController` salva in `tornei.json` (`JsonFile`, scrittura atomica) il torneo in corso dopo ogni partita e la bacheca dei tornei conclusi: data, formula, giocatori, posizione e vincitore. Abbandonare un torneo lo chiude senza trofeo. Un file non valido va in quarantena (`.bad-<ms>`) e si riparte da zero; un risultato che arriva quando il torneo è stato chiuso o è cambiato si ignora.

## Progressi

A torneo concluso si registra `TournamentFinished(rank: n, players: m)`: 30 XP, il traguardo *Torneista* (primo torneo concluso) e *Coppa in bacheca* (primo torneo vinto). Le singole partite valgono già XP come tutte le partite contro il computer.

## Schermata

`TournamentPage` riceve il controller, i bot disponibili, la forza dell'utente e la funzione `play` che avvia la partita contro il motore e restituisce i punti dell'utente. Mostra:

- prima di iniziare: formula, numero di giocatori, avversari e bacheca;
- durante: la prossima partita con colore e avversario, la classifica del girone o il tabellone per turni, e l'abbandono con conferma;
- alla fine: la posizione e il pulsante per un nuovo torneo.

Senza `play` la partita non parte e la schermata lo dice.

## Collegamento

La voce **Tornei** della scheda Tu compare dove gira il motore: Android e iOS, e Windows e Linux con Stockfish installato (vedi [avversario-computer.md](avversario-computer.md)), tranne nel profilo bambino. `HomeShell` tiene un solo `TournamentController` in memoria, usa come bot gli otto livelli del motore (nome e Elo del livello) e come forza dell'utente il rating locale calcolato sull'archivio.

Ogni partita è una sfida preimpostata (`GameChallenge`, titolo «Torneo · avversario», colore assegnato dal sorteggio) con il livello del bot. I punti sono 1, ½ o 0 (`tournamentPoints`); nello spareggio Armageddon la patta vale una vittoria per il nero e una sconfitta per il bianco. Uscire dalla partita, anche prima della prima mossa (a partita in corso dopo conferma), equivale a una resa: lo 0 si registra e la partita non si può rigiocare. La partita vale XP e viene archiviata come tutte le altre contro il computer.
