# Finali perfetti

Requisito RF-97: nei finali con pochi pezzi l'app conosce il risultato esatto e la mossa migliore, senza rete e senza motore. Il codice è in `lib/tablebase/`.

## Che cosa si vede

- **Analisi della posizione**: sopra le linee del motore compare la scheda «Finale perfetto» con chi vince e in quante mosse («Il Bianco vince: matto in 5 mosse»), oppure «Patta con il gioco perfetto», e la mossa perfetta, che si gioca con un tocco.
- **Allenatore dei finali**: durante la prova, quando tocca all'utente, la stessa scheda mostra il matto più rapido da quella posizione; «Mossa perfetta» disegna una freccia sulla scacchiera senza giocarla. Le stelle non cambiano e non dipendono dall'uso del suggerimento. Nel profilo bambino non ci sono numeri: la scheda dice solo chi vince.
- La scheda non compare con più di quattro pezzi, a partita finita o se la tabella non si riesce a calcolare.

La prima volta che serve un materiale l'app mostra «Calcolo il finale perfetto… succede solo la prima volta»; poi la tabella è sul telefono.

## Scelta: tabelle generate sul dispositivo

| Strada | Esito |
|---|---|
| Tabelle Syzygy fino a 5 pezzi | Scartata: le tabelle di vittoria/sconfitta per 3–5 pezzi pesano alcune centinaia di MB e quelle per la regola delle 50 mosse alcuni GB, incompatibili con i limiti di dimensione dell'app. Danno inoltre solo l'esito e la distanza al prossimo cambio, non la distanza esatta dal matto. |
| Tabelle precalcolate nel pacchetto | Scartata: file binari grandi nel repository e nell'APK (circa 13 MB per tutti i materiali a quattro pezzi). |
| **Tabelle generate sul telefono** | Scelta: nessun dato nel pacchetto, nessuna rete, distanza esatta dal matto (DTM). Le tabelle si calcolano una volta, in un isolate, e restano compresse nella cartella dati dell'app. |

Il risultato vale con le regole degli scacchi senza regola delle 50 mosse né ripetizioni: «matto in N» è il matto più rapido contro la migliore difesa.

## Materiali coperti

Fino a quattro pezzi, re compresi, senza pedoni di entrambi i lati (la presa en passant cambierebbe i risultati):

- tre pezzi: re e donna, torre, alfiere, cavallo o pedone contro re;
- quattro pezzi senza pedoni: due pezzi contro re (per esempio alfiere e cavallo) e un pezzo contro un pezzo (per esempio donna contro torre).

Con quattro pezzi i pedoni sono esclusi per il tempo di calcolo: re, donna e pedone contro re richiederebbe un minuto sul computer di sviluppo. Restano fuori anche i finali con cinque pezzi o più, come Lucena e Philidor: nell'allenatore la scheda compare solo nelle posizioni coperte (donna e re, torre e re, re e pedone, alfiere e cavallo contro re).

## Come funziona

`TbGenerator` calcola l'analisi a ritroso di un materiale:

1. ogni posizione legale riceve un valore in un byte: patta, oppure distanza dal matto in semimosse (dispari: vince chi muove; pari: perde; 0: è matto). Una posizione è «ridotta» con le simmetrie della scacchiera: otto senza pedoni, lo specchio con i pedoni;
2. i matti sono la semimossa 0; le catture e le promozioni escono dalla tabella e si leggono da quelle dei materiali più piccoli, calcolate prima (`TbSet.closure`);
3. di semimossa in semimossa, le posizioni da cui si raggiunge una sconfitta diventano vittorie e quelle in cui ogni mossa porta a una vittoria dell'avversario diventano sconfitte, con un contatore delle mosse residue. Le mosse sono generate a ritroso senza catture, per questo la distanza è esatta.

`TbSet` raccoglie le tabelle (i Bianchi sono sempre il lato più forte, quindi una tabella vale per i due colori) e le cerca per codice del materiale. `Tablebase` traduce una `Position` di dartchess in una valutazione (`TbEvaluation`: esito e semimosse) e ordina le mosse legali (`rankedMoves`): prima le vittorie più rapide, poi le patte, poi le sconfitte più lunghe.

`TablebaseService` gestisce disco e isolate: una richiesta alla volta, tabella cercata prima in memoria, poi in `tablebase/<materiale>.v<formato>.tb` nella cartella dati (zlib, scritta in modo atomico), altrimenti calcolata in un isolate. Un file danneggiato si rigenera. Se il disco non è scrivibile le tabelle restano valide in memoria. `tablebaseFormat` va alzato se cambia l'algoritmo.

## Tempi e spazio

Misure sul computer di sviluppo (esecuzione non ottimizzata); sul telefono si prevede un fattore da 2 a 4.

| Materiali | Calcolo | Spazio su disco |
|---|---|---|
| tre pezzi | meno di 0,5 s | da 2 a 35 KB |
| quattro pezzi | da 1,5 a 9 s | da 100 KB a 1,5 MB |
| tutti i 25 materiali supportati | circa 2 minuti in totale | circa 13 MB |

Le tabelle si generano solo per i materiali che l'utente incontra davvero. Le distanze massime coincidono con quelle note (matto in 10 con la donna, 16 con la torre, 33 con alfiere e cavallo, 35 donna contro torre), verificate dai test.

## Test

`test/tablebase/` verifica: le distanze massime, i matti in una mossa, lo stallo, la coerenza di ogni valore con le mosse successive su posizioni casuali (indipendente dal generatore, con le regole di dartchess), la partita giocata con le mosse migliori che arriva al matto esattamente alla distanza prevista, l'equivalenza tra colori e specchi, il servizio con cache su disco e file danneggiati, la scheda (calcolo, risultato, profilo bambino, lettori di schermo, contrasto, area tattile) e l'integrazione in analisi e allenatore.

## Limiti

- Niente pedoni con quattro pezzi, né finali con cinque o più pezzi.
- La regola delle 50 mosse non è considerata.
- Il calcolo del primo uso su un telefono lento può durare più di dieci secondi; l'interfaccia resta reattiva perché gira in un isolate.
