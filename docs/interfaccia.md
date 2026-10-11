# Interfaccia

L'app è progettata prima di tutto per il telefono in verticale.

## Navigazione

La barra in basso ha quattro schede: Gioca, Puzzle, Aperture e Tu. La scheda Tu mostra avatar, livello e serie, e porta a Profilo, Percorso, Minigiochi, Statistiche e Archivio. Se i dati salvati di una sezione non si possono leggere, un messaggio lo dice e si può riprovare. Nel profilo bambino le Aperture sono nascoste e la scheda Tu mostra solo Profilo, Percorso e Minigiochi (vedi [profilo-bambino.md](profilo-bambino.md)). 

## Telefono in verticale

Dall'alto verso il basso:

1. **Barra del titolo** con il pulsante delle impostazioni.
2. **Striscia delle mosse**: scorre in orizzontale e mostra sempre l'ultima mossa a destra.
3. **Riga di stato**: chi muove, scacco, oppure risultato e motivo della fine partita.
4. **Materiale del giocatore in alto**: pezzi che ha catturato e vantaggio.
5. **Scacchiera** a tutta larghezza.
6. **Materiale del giocatore in basso**.
7. **Barra dei comandi** in basso, alla portata del pollice: Nuova, Annulla, Gira, Patta, Abbandona.

Striscia, stato, righe del materiale e scacchiera sono centrati insieme nello spazio disponibile. La scacchiera ha come lato il minimo tra la larghezza dello schermo e l'altezza rimasta dopo striscia, stato, righe del materiale e comandi.

## Tablet e orizzontale

Quando la larghezza supera di oltre il 20% l'altezza, la scacchiera sta a sinistra e un pannello a destra contiene, dall'alto: materiale del giocatore in alto, stato, lista delle mosse, materiale del giocatore in basso e comandi.

## Materiale catturato

Per ciascun giocatore una riga mostra le icone dei pezzi avversari catturati, dal più prezioso al pedone, seguite dal vantaggio di materiale (per esempio "+3") solo per chi è in vantaggio. Valori: pedone 1, cavallo 3, alfiere 3, torre 5, donna 9. I pezzi catturati si ricavano dalle mosse della partita: un pezzo promosso e poi catturato compare come pezzo promosso, e una promozione senza cattura non compare. Il vantaggio è invece calcolato sul materiale presente sulla scacchiera, quindi include le promozioni. Le righe seguono l'orientamento della scacchiera; se i pezzi catturati non entrano nella larghezza disponibile, la riga si riduce in scala. Per i lettori di schermo ogni riga è annunciata come frase, per esempio «Bianco: ha catturato pedone, vantaggio di 1».

## Interazione con la scacchiera

- Mossa per trascinamento oppure con due tocchi (pezzo, poi casa di arrivo).
- Puntini sulle case raggiungibili dal pezzo selezionato.
- Evidenziazione dell'ultima mossa e del re sotto scacco.
- Alla promozione compare un selettore con i quattro pezzi possibili.
- Schema colori verde, set di pezzi "cburnett".

## Comandi

| Comando | Effetto |
|---|---|
| Nuova | Apre la scelta dell'avversario (due giocatori o computer, con colore e livello), della variante (Classica, Chess960, Re della collina, Tre scacchi; contro il computer solo Classica) e della cadenza; toccando la cadenza inizia la nuova partita |
| Annulla | Annulla l'ultima mossa; disattivato se non ci sono mosse |
| Gira | Capovolge la scacchiera |
| Patta | Chiede all'avversario se accetta la patta; disattivato a partita conclusa |
| Abbandona | Chiede conferma e fa abbandonare il lato al tratto; disattivato a partita conclusa |
| Menu ⋮, "Analisi della posizione" | Apre l'analisi libera della posizione corrente con orologio e computer fermi (vedi [analisi.md](analisi.md)) |
| Menu ⋮, "Revisione della partita" | Apre la revisione con classificazione delle mosse e precisione (vedi [revisione-partita.md](revisione-partita.md)); il menu c'è solo dove c'è il motore e negli scacchi classici, non nelle varianti |

## Orologio

"Nuova" apre un pannello in cui si sceglie l'avversario (vedi [avversario-computer.md](avversario-computer.md)) e, toccandola, la cadenza: "Senza tempo" oppure le cadenze di chess.com, cioè Bullet (1+0, 1+1, 2+1), Blitz (3+0, 3+2, 5+0) e Rapid (10+0, 15+10, 30+0), dove il primo numero sono i minuti per giocatore e il secondo i secondi aggiunti dopo ogni mossa.

- Ogni orologio sta a destra della riga del materiale del rispettivo giocatore.
- Il tempo inizia a scorrere dopo la prima mossa del Bianco, per il Nero.
- L'orologio di chi ha il tratto è evidenziato; sotto i 10 secondi diventa rosso.
- Sotto i 20 secondi mostra anche i decimi.
- Si ferma mentre è aperto un dialogo (abbandono, patta, nuova partita) e quando l'app va in secondo piano, e riparte al ritorno.
- Una mossa fatta a tempo già scaduto non viene accettata.

## Nomi dei giocatori

Nella partita tra due persone il pannello "Nuova" ha due campi facoltativi, "Nome del Bianco" e "Nome del Nero" (al massimo 24 caratteri, spazi iniziali e finali ignorati), per il gioco a due sullo stesso telefono (RF-30). I nomi vengono ricordati per le partite successive. Se indicati:

- compaiono a sinistra della riga del materiale di ciascun giocatore;
- riga di stato e dialoghi di abbandono e patta li affiancano al colore, per esempio «Muove Anna (Bianco).», «Scacco. Muove Bruno (Nero).», «Scacco matto. Vince Anna (Bianco).» o «Bruno (Nero) accetta la patta?»;
- il lettore di schermo usa il nome per materiale, orologio e annuncio delle mosse («Bruno: pedone e5»).

Lasciando un campo vuoto torna il colore.

## Rivedere le mosse

Toccando una mossa nella striscia (o nella lista, in orizzontale) la scacchiera mostra la posizione dopo quella mossa, con la mossa evidenziata. La riga di stato diventa una barra con mossa precedente, mossa successiva, il testo "Posizione dopo 12... Nf6" (o "Posizione iniziale") e il pulsante "Torna alla partita".

- Durante la revisione la scacchiera non accetta mosse, le righe del materiale seguono la posizione mostrata e l'orologio continua a scorrere.
- Con una mossa in attesa di conferma la navigazione è disattivata finché non viene confermata o scartata.
- Sulla scacchiera, scorrendo il dito in orizzontale (almeno una casa e mezza, in direzione prevalentemente orizzontale) si cambia posizione: a sinistra si va avanti, a destra indietro, e oltre l'ultima mossa si torna alla partita. Il gesto vale se parte da una casa vuota o da un pezzo dell'avversario; se parte da un pezzo che si può muovere resta il trascinamento del pezzo, e con più dita insieme non scorre.
- Con una tastiera: frecce sinistra e destra per scorrere, Home per la posizione iniziale, Fine per tornare alla partita.
- Andare oltre l'ultima mossa, una nuova partita o "Annulla" riportano alla posizione corrente; durante la revisione "Annulla" non toglie mosse.
- I numeri delle mosse partono dalla posizione iniziale della partita, anche quando è importata da un FEN.

## Mossa da tastiera e lettori di schermo

L'icona della tastiera nella barra del titolo apre un campo in cui scrivere la mossa (requisito RNF-07), utile con TalkBack e VoiceOver o con una tastiera fisica. Sono accettate:

- notazione algebrica inglese (`Nf3`, `exd5`, `Qxf7#`) e italiana (`Cf3`, `Dxf7`), con R per il re in italiano e T per la torre; l'iniziale del pezzo può essere minuscola (`cf3`);
- arrocco come `O-O`, `0-0-0` o `o-o`;
- promozione con o senza `=` (`e8=Q`, `e8D`), sempre indicando il pezzo;
- coordinate UCI, anche maiuscole (`g1f3`, `e7e8q`).

Spazi, segni di scacco e annotazioni vengono ignorati. Se `R` indica sia una mossa di re (italiano) sia una di torre (inglese), il campo chiede di usare K o T. Una mossa non valida mostra un errore e lascia la tastiera aperta. La mossa passa per lo stesso percorso di quelle sulla scacchiera, quindi rispetta orologio e conferma della mossa. Il comando è disattivato a partita conclusa, durante la revisione e con una mossa in attesa di conferma.

Dopo ogni mossa il lettore di schermo annuncia una frase in italiano, per esempio «Bianco: cavallo prende f7, scacco», «Nero: pedone della colonna e prende d5» o «Nero: arrocco corto». Una mossa in attesa di conferma è annunciata come «Da confermare», e la fine della partita, anche per tempo scaduto, è annunciata con il risultato.

## Impostazioni

In cima alla pagina, sempre visibile mentre si scorre, c'è un'anteprima della scacchiera: mostra una posizione di prova con tema, pezzi, coordinate, mosse legali, colori per daltonici e velocità delle animazioni correnti, e si aggiorna a ogni scelta. Toccandola si gioca la mossa di prova (l'alfiere prende in c6), con l'animazione scelta; un secondo tocco la ripristina. I chip dei temi mostrano i colori delle case chiare e scure, quelli dei pezzi il cavallo del set, così si riconoscono a colpo d'occhio. L'anteprima ha un'etichetta per i lettori di schermo.

Si aprono dall'icona a forma di ingranaggio nella barra del titolo. Ogni modifica si applica subito e viene salvata sul dispositivo.

| Impostazione | Effetto | Predefinito |
|---|---|---|
| Mostra le mosse legali | Puntini sulle case raggiungibili dal pezzo selezionato | Attiva |
| Coordinate | Lettere e numeri sui bordi della scacchiera | Attiva |
| Promuovi sempre a donna | Salta il selettore di promozione | Disattiva |
| Frecce e cerchi | Disegno di frecce e cerchi con due dita sulla scacchiera | Attiva |
| Conferma la mossa | Dopo ogni mossa mostra la posizione risultante con i pulsanti Conferma e Scarta al posto della riga di stato; la mossa conta solo dopo Conferma, e l'orologio continua a scorrere. Durante l'attesa "Annulla" equivale a Scarta, mentre Patta e Abbandona sono disattivati | Disattiva |
| Ruota a ogni turno | Orienta la scacchiera dal lato di chi deve muovere | Disattiva |
| Modalità tavolo | Capovolge i pezzi del giocatore in alto, per giocare uno di fronte all'altro con il telefono sul tavolo | Disattiva |
| Colori per daltonici | Sostituisce le evidenziazioni (ultima mossa, casa selezionata, mosse legali, premosse) con colori della palette Okabe-Ito, leggibili con deuteranopia, protanopia e tritanopia; i colori delle case restano quelli del tema. Indizi dei problemi e frecce del ripasso passano dal verde al blu, gli esiti delle coordinate da verde e rosso a blu e arancio (requisito RNF-07) | Disattiva |
| Suoni | Suoni per mossa, cattura, arrocco, scacco, promozione, fine partita e tempo sotto i 10 secondi | Attivi |
| Volume | Volume dei suoni, da 0 a 100% | 100% |
| Vibrazione | Vibrazione breve a ogni mossa, più marcata per catture e fine partita | Attiva |
| Tema della scacchiera | Verde, Legno, Blu, Grigio; sbloccabili Sabbia, Oceano, Corallo, Notte, Oro | Verde |
| Pezzi | Classico, Merida, Chessnut, Fantasy, Spatial; sbloccabili Celtic, Shapes, Firi, Mpchess, Kiwen-suwi, Totoy, RhosGFX | Classico |
| Sblocca tutto | Rende disponibili le ricompense estetiche senza sbloccarle (vedi [gamification.md](gamification.md)) | Disattiva |
| Animazioni | Nessuna, Veloce, Normale, Lenta | Normale |

Tema, pezzi, coordinate, mosse legali, frecce e animazioni valgono anche per le scacchiere dei problemi, delle aperture e del repertorio, che si aggiornano subito quando cambiano. La modalità tavolo vale solo per la partita, perché negli esercizi si gioca sempre da un solo lato; anche la promozione automatica a donna vale solo per la partita, perché alcuni puzzle si risolvono promuovendo a un altro pezzo.

I set di pezzi disponibili sono solo quelli con licenza compatibile con la GPL e con la distribuzione commerciale, elencati in `CREDITS.md`: i set CC BY-NC-SA di chessground (California, Cardinal, Maestro e altri) sono esclusi, e chi li aveva scelti torna al set Classico. I temi usano solo colori, senza le immagini di chessground (licenza AGPL). Anche le icone dei pezzi catturati usano il set scelto.

## Suoni

A ogni mossa suona un solo effetto, scelto in quest'ordine di priorità: fine partita, scacco, promozione, arrocco, cattura (anche en passant), mossa semplice. Con l'orologio, un breve segnale avvisa quando il tempo di un giocatore scende sotto i 10 secondi, una volta per partita. I suoni sono generati dallo script `tool/generate_sounds.py`.

## Tema

L'app segue il tema chiaro o scuro del sistema. Tutti i testi sono in italiano.

### Colori per daltonici

Per ogni tema `lib/settings/color_blind.dart` sceglie, tra blu, azzurro, giallo, arancio, vermiglio e viola della palette Okabe-Ito, la coppia di colori distinti per ultima mossa e casa selezionata. Le regole, in ordine:

1. sono esclusi i colori con tinta e saturazione troppo vicine a quelle delle case (differenza di tinta sotto 15° e di saturazione sotto 0,3), per esempio l'azzurro sul tema Oceano;
2. ogni evidenziazione deve avere, sia sulle case chiare sia sulle scure, un rapporto di contrasto WCAG almeno pari a quello dell'evidenziazione originale del tema e mai sotto 1,25, con trasparenza massima del 90%;
3. tra le coppie valide vince quella con la trasparenza più bassa, così i pezzi restano ben visibili.

I puntini delle mosse legali sono neri o bianchi, con contrasto almeno 1,6; le premosse usano il primo colore della palette non preso dalle altre evidenziazioni. Lo schema è calcolato una volta per tema e riusato, così la scacchiera non ridisegna lo sfondo.

L'opzione vale per partita, problemi, aperture, repertorio, percorso e minigiochi. Restano invariati il bagliore rosso del re sotto scacco, disegnato da chessground con un colore fisso e riconoscibile anche dalla posizione sul re, e la casa gialla del quiz sul materiale, che non usa la coppia rosso-verde.
