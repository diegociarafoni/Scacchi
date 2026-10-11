# Interfaccia

L'app è progettata prima di tutto per il telefono in verticale.

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
| Nuova | Apre la scelta della cadenza e inizia una nuova partita dalla posizione iniziale |
| Annulla | Annulla l'ultima mossa; disattivato se non ci sono mosse |
| Gira | Capovolge la scacchiera |
| Patta | Chiede all'avversario se accetta la patta; disattivato a partita conclusa |
| Abbandona | Chiede conferma e fa abbandonare il lato al tratto; disattivato a partita conclusa |

## Orologio

"Nuova" apre un pannello con la cadenza: "Senza tempo" oppure le cadenze di chess.com raggruppate in Bullet (1+0, 1+1, 2+1), Blitz (3+0, 3+2, 5+0) e Rapid (10+0, 15+10, 30+0), dove il primo numero sono i minuti per giocatore e il secondo i secondi aggiunti dopo ogni mossa.

- Ogni orologio sta a destra della riga del materiale del rispettivo giocatore.
- Il tempo inizia a scorrere dopo la prima mossa del Bianco, per il Nero.
- L'orologio di chi ha il tratto è evidenziato; sotto i 10 secondi diventa rosso.
- Sotto i 20 secondi mostra anche i decimi.
- Si ferma mentre è aperto un dialogo (abbandono, patta, nuova partita) e quando l'app va in secondo piano, e riparte al ritorno.
- Una mossa fatta a tempo già scaduto non viene accettata.

## Impostazioni

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
| Suoni | Suoni per mossa, cattura, arrocco, scacco, promozione, fine partita e tempo sotto i 10 secondi | Attivi |
| Volume | Volume dei suoni, da 0 a 100% | 100% |
| Vibrazione | Vibrazione breve a ogni mossa, più marcata per catture e fine partita | Attiva |
| Tema della scacchiera | Verde, Legno, Blu, Grigio | Verde |
| Pezzi | Classico, Merida, Chessnut, Fantasy, Spatial | Classico |
| Animazioni | Nessuna, Veloce, Normale, Lenta | Normale |

I set di pezzi disponibili sono solo quelli con licenza compatibile con la GPL e con la distribuzione commerciale, elencati in `CREDITS.md`: i set CC BY-NC-SA di chessground (California, Cardinal, Maestro e altri) sono esclusi, e chi li aveva scelti torna al set Classico. I temi usano solo colori, senza le immagini di chessground (licenza AGPL). Anche le icone dei pezzi catturati usano il set scelto.

## Suoni

A ogni mossa suona un solo effetto, scelto in quest'ordine di priorità: fine partita, scacco, promozione, arrocco, cattura (anche en passant), mossa semplice. Con l'orologio, un breve segnale avvisa quando il tempo di un giocatore scende sotto i 10 secondi, una volta per partita. I suoni sono generati dallo script `tool/generate_sounds.py`.

## Tema

L'app segue il tema chiaro o scuro del sistema. Tutti i testi sono in italiano.
