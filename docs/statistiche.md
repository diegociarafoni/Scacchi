# Statistiche e rating locale

Requisiti RF-110 (rating locale contro il computer) e RF-111 (statistiche). Il codice è in `lib/stats/`. Tutto si ricalcola dall'archivio delle partite (vedi [archivio.md](archivio.md)): non c'è uno stato separato da tenere allineato.

## Dati usati

Ogni `SavedGame` può indicare, oltre a giocatori e risultato:

| Campo | Significato |
|---|---|
| `playerSide` | Colore dell'utente; assente nelle partite tra due persone, in quelle su scacchiera fisica e in quelle importate |
| `timeControl` | Cadenza in minuti più incremento (`5+0`, `15+10`); salvata anche nel PGN come `TimeControl` in secondi (`0.5+0` diventa `30+0`) |
| `opponentElo` | Elo indicativo del bot avversario |
| `accuracy` | Precisione dell'utente dalla revisione, aggiornabile con `copyWith(accuracy: () => 82.5)`; `() => null` la azzera |
| `opening` | Nome dell'apertura riconosciuta |

Le partite salvate prima di questi campi si leggono ancora: i campi mancanti valgono `null`.

## Statistiche (RF-111)

`GameStats.from(partite)` considera le partite concluse in cui l'utente ha un colore, escluse le importate:

- bilancio complessivo, con il bianco e con il nero (vittorie, patte, sconfitte e percentuale di punti);
- bilancio per cadenza, dalla più giocata, con "Senza tempo" per le partite senza orologio;
- numero di partite tra due persone (tipo `SavedGame.local`), mostrato a parte anche quando sono le sole giocate;
- aperture più giocate, a pari merito in ordine alfabetico;
- precisione media e andamento nel tempo.

## Rating locale (RF-110)

`LocalRating.from(partite)` parte da 800 e applica la formula Elo a ogni partita conclusa contro il computer (con `opponentElo`), in ordine di data (a parità, per identificativo, così il calcolo è ripetibile): punteggio atteso `1 / (1 + 10^((Elo bot − rating) / 400))`, fattore K 40 nelle prime 10 partite e 20 dopo. Con meno di 10 partite il rating è indicato come provvisorio. Le partite importate non contano.

## Schermata

`StatsPage` mostra il rating con il suo andamento, il bilancio, le cadenze, le aperture e la precisione. I grafici sono linee compatte con una descrizione per i lettori di schermo (valore iniziale, finale, minimo e massimo). Se l'archivio non si può leggere, la schermata lo dice invece di restare in attesa.
