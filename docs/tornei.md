# Tornei offline contro bot

Requisito RG-09: tornei contro 4-8 bot al posto delle leghe online, con partite vere. Il codice è in `lib/tournament/`.

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

Senza `play` la partita non parte e la schermata lo dice. Il collegamento al motore, ai livelli dei bot e alla schermata principale arriva dopo la partita contro il computer (PR #2).
