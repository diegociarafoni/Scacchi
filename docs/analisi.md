# Analisi della posizione

Analisi libera con Stockfish locale (requisiti RF-50, RF-51, RF-52 in parte, RF-54). Il codice è in `lib/analysis/analysis_page.dart`.

## Come si apre

- Dal menu della partita (⋮): **Analisi della posizione** apre la posizione mostrata sulla scacchiera, anche se si stanno scorrendo le mosse precedenti. Mentre è aperta, orologio e mossa del computer sono sospesi e riprendono alla chiusura, perché il motore è uno solo. Nella partita tra due persone il motore viene avviato solo per l'analisi e chiuso al ritorno.
- Dalla revisione della partita, ad analisi conclusa: il pulsante **Analizza la posizione** nella barra del titolo apre la posizione mostrata.

Entrambe le voci compaiono solo dove c'è il motore (Android, iOS e, con Stockfish installato, Windows e Linux), negli scacchi classici e fuori dalle partite di tornei e percorso; nel profilo bambino sono nascoste. Le varianti restano escluse perché Stockfish non analizza Chess960, Re della collina e Tre scacchi. La voce del menu è disattivata mentre il computer valuta una proposta di patta.

## Schermata

| Elemento | Requisito | Comportamento |
|---|---|---|
| Barra di valutazione | RF-50 | Verticale, dal punto di vista del Bianco, con valore numerico (`+0.3`, `M3`) e descrizione per i lettori di schermo |
| Linee del motore | RF-51 | Da 1 a 3 linee (selettore "1 linea / 2 linee / 3 linee"), ognuna con valutazione e prime otto semimosse in SAN; toccare una linea ne gioca la prima mossa |
| Profondità | RF-51 | "Profondità N" aggiornata durante la ricerca |
| Pausa | RF-51 | Il pulsante centrale ferma e riprende l'analisi; chiudendo la pagina il motore si ferma |
| Esplorazione | RF-52 | Si muovono i pezzi di entrambi i colori; **Indietro** e **Avanti** scorrono le mosse; una mossa nuova da una posizione precedente sostituisce il seguito |
| Freccia | RF-54 | Freccia verde della mossa migliore, attivabile dalla barra del titolo; l'arrocco punta alla casa del re |
| Minaccia | RF-56 | Il pulsante con il triangolo di avviso nella barra del titolo mostra con una freccia rossa la mossa migliore che l'avversario giocherebbe se toccasse a lui. Sulla posizione con il turno passato (`threatFen`, mossa nulla, senza presa en passant) il motore fa prima una ricerca a una linea fino a profondità 14, perché ha una coda sola, poi riprende l'analisi principale; la freccia resta finché non si cambia posizione. Con l'analisi in pausa o l'app in secondo piano non parte nulla. Non è disponibile quando chi muove è sotto scacco o la partita è finita |

## Motore

`ComputerPlayer.analyseLive(fen, multiPv:, maxDepth: 40)` restituisce un flusso di varianti ordinate. La ricerca usa la forza piena e si ferma alla profondità massima oppure quando chi ascolta annulla l'iscrizione: in quel caso il motore riceve `stop` e la coda delle richieste si libera. Se l'iscrizione viene annullata prima che la ricerca parta, la ricerca non viene inviata, e annullarla non ferma la ricerca di un'altra richiesta.

Il flusso emette un aggiornamento alla fine di ogni iterazione, quando tutte le varianti hanno la stessa profondità, così le linee mostrate sono confrontabili tra loro. I punteggi parziali del motore (`lowerbound`, `upperbound`) vengono scartati.

Per la batteria (RNF-05) la schermata ridisegna le linee al massimo ogni 250 ms, anche se il motore ne invia molte di più, e ferma il motore quando l'app va in secondo piano; al ritorno l'analisi riparte, a meno che non fosse in pausa.

Nel profilo bambino (RP-06) la barra di valutazione non ha cifre e le linee non mostrano punteggio né profondità: vedi [profilo-bambino.md](profilo-bambino.md#niente-numeri).

## Limiti attuali

- Le varianti non formano ancora un albero (RF-52): c'è una sola linea di esplorazione, senza promozione né eliminazione di varianti.
