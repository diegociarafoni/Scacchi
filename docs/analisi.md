# Analisi della posizione

Analisi libera con Stockfish locale (requisiti RF-50, RF-51, RF-52 in parte, RF-54). Il codice è in `lib/analysis/analysis_page.dart`.

## Come si apre

- Dal menu della partita: **Analisi della posizione** apre la posizione corrente. Mentre è aperta, l'eventuale mossa del computer viene sospesa e riprende alla chiusura, perché il motore è uno solo.
- Dalla revisione della partita: il pulsante **Analizza la posizione** nella barra del titolo apre la posizione mostrata.

Entrambe le voci compaiono solo dove c'è il motore (Android e iOS).

## Schermata

| Elemento | Requisito | Comportamento |
|---|---|---|
| Barra di valutazione | RF-50 | Verticale, dal punto di vista del Bianco, con valore numerico (`+0.3`, `M3`) e descrizione per i lettori di schermo |
| Linee del motore | RF-51 | Da 1 a 3 linee (selettore "1 linea / 2 linee / 3 linee"), ognuna con valutazione e prime otto semimosse in SAN; toccare una linea ne gioca la prima mossa |
| Profondità | RF-51 | "Profondità N" aggiornata durante la ricerca |
| Pausa | RF-51 | Il pulsante centrale ferma e riprende l'analisi; chiudendo la pagina il motore si ferma |
| Esplorazione | RF-52 | Si muovono i pezzi di entrambi i colori; **Indietro** e **Avanti** scorrono le mosse; una mossa nuova da una posizione precedente sostituisce il seguito |
| Freccia | RF-54 | Freccia verde della mossa migliore, attivabile dalla barra del titolo; l'arrocco punta alla casa del re |

## Motore

`ComputerPlayer.analyseLive(fen, multiPv:, maxDepth: 40)` restituisce un flusso di varianti ordinate. La ricerca usa la forza piena e si ferma alla profondità massima oppure quando chi ascolta annulla l'iscrizione: in quel caso il motore riceve `stop` e la coda delle richieste si libera. Se l'iscrizione viene annullata prima che la ricerca parta, la ricerca non viene inviata.

Per la batteria (RNF-05) la schermata ridisegna le linee al massimo ogni 250 ms, anche se il motore ne invia molte di più.

## Limiti attuali

- Le varianti non formano ancora un albero (RF-52): c'è una sola linea di esplorazione, senza promozione né eliminazione di varianti.
- L'editor di posizione (RF-53) non è ancora disponibile.
