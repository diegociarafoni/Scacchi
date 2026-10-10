# Interfaccia

L'app è progettata prima di tutto per il telefono in verticale.

## Telefono in verticale

Dall'alto verso il basso:

1. **Barra del titolo** con il menu delle opzioni.
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
| Nuova | Inizia una nuova partita dalla posizione iniziale |
| Annulla | Annulla l'ultima mossa; disattivato se non ci sono mosse |
| Gira | Capovolge la scacchiera |
| Patta | Chiede all'avversario se accetta la patta; disattivato a partita conclusa |
| Abbandona | Chiede conferma e fa abbandonare il lato al tratto; disattivato a partita conclusa |
| Menu, "Ruota a ogni turno" | Orienta automaticamente la scacchiera dal lato di chi deve muovere |

## Tema

L'app segue il tema chiaro o scuro del sistema. Tutti i testi sono in italiano.
