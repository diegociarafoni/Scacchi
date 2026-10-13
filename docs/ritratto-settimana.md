# La tua settimana

Scheda riassuntiva degli ultimi sette giorni (proposta del capitolo 7 dei requisiti, «ritratto del giocatore»), intitolata «La tua settimana». Si apre dal pulsante «Condividi la settimana» accanto alla voce La tua settimana della scheda Tu (non nel profilo bambino) e si condivide come immagine PNG: non serve alcun server. Il riepilogo dei progressi è un'altra pagina, vedi [riepilogo-settimanale.md](riepilogo-settimanale.md).

## Cosa mostra

- Partite, vinte, patte e perse.
- Fino a tre aperture, dalla più giocata.
- Precisione media delle partite già riviste.
- Matto preferito: il pezzo che ha dato più spesso il matto nelle vittorie.
- Avversario più forte battuto (Elo del computer).
- Giorno della settimana con più partite.

Le righe senza dati (per esempio nessuna partita rivista) non compaiono.

## Quali partite contano

Partite concluse, con un colore dell'utente, create negli ultimi sette giorni (estremo incluso). Restano fuori le importate, quelle in corso, quelle tra due persone e quelle su scacchiera fisica, che non hanno un lato dell'utente. Senza partite la pagina spiega come riempirla.

## Condivisione

«Condividi come immagine» disegna la scheda in un PNG e apre il menu di condivisione del sistema; il file temporaneo viene eliminato dopo l'invio.

## Codice

`lib/stats/portrait.dart` (calcolo, senza interfaccia) e `lib/stats/portrait_page.dart` (scheda e condivisione). Test in `test/stats/portrait_test.dart`, `test/stats/portrait_page_test.dart` e `integration_test/portrait_test.dart`.
