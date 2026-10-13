# Stile

La schermata «Stile» raccoglie in un posto solo l'aspetto della scacchiera. Si apre dalla sezione «Stile» di Impostazioni, subito dopo Profilo (`lib/style/style_page.dart`). In alto c'è l'anteprima della scacchiera dal vivo, la stessa di Impostazioni (`BoardPreview`), grande quasi quanto la larghezza dello schermo; sotto, quattro schede. Ogni scelta si applica subito e vale in partita, negli esercizi e nell'anteprima. In orizzontale l'anteprima sta a sinistra e le schede a destra.

## Schede

| Scheda | Cosa si sceglie | Dove sta |
|---|---|---|
| Scacchiera | I temi di `BoardTheme`: tinte unite e texture (legno, marmo, metallo, vetro, spazio...), ciascuno con la sua miniatura | [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md) |
| Pezzi | I set di `PieceStyle`, ciascuno mostrato con il cavallo sulla casa scura del tema scelto | [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md) |
| Sfondo | `BoardBackdrop`: ciò che sta dietro la scacchiera, o una propria foto | sotto |
| Suoni | `SoundSet`: il set dei suoni delle mosse | sotto |

Temi e pezzi ancora da sbloccare hanno il lucchetto e dicono come ottenerli, come in Impostazioni; il profilo bambino non cita il livello. Ogni tessera ha il nome per i lettori di schermo e lo stato «selezionato». Con il testo ingrandito oltre il 115% le schede si scorrono invece di stringersi, e il testo è limitato al 130% per non spingere l'anteprima fuori schermo.

## Sfondo

Lo sfondo è un margine attorno alla scacchiera: `BoardFrame` (`lib/settings/board_frame.dart`) la rimpicciolisce del 4% per lato e disegna lo sfondo nello spazio liberato. Poiché tutte le scacchiere (partita, esercizi, anteprima) passano da `BoardFrame.of`, lo sfondo vale ovunque senza toccare le singole schermate; con le coordinate esterne le due cornici si sommano. «Standard» non aggiunge nulla e lascia la scacchiera a tutto lato.

Gli sfondi sono dieci, più la foto:

- Grafite, Feltro, Perla e Cuoio sono tinte unite; Ardesia, Notte, Tramonto, Oceano e Foresta sono sfumature. Sono disegnati in codice e non pesano nell'app.
- Spazio usa la texture `assets/boards/spazio.webp`, già presente per il tema omonimo.
- «La tua foto» si sceglie dalla galleria con «Scegli una foto»: l'immagine viene ridotta a 1600 punti per lato, copiata in `<dati dell'app>/stile/` e usata da lì. Resta solo sul telefono: non viene caricata, non entra nel backup di Rokko e Android la esclude dai backup automatici e dai trasferimenti (`backup_rules.xml`, `data_extraction_rules.xml`); si cancella con i dati dell'app. Scegliere un'altra foto elimina la precedente, ma solo dopo aver salvato la scelta. Se il file manca all'avvio (dati cancellati, app ripristinata altrove) lo sfondo torna Standard; se non si legge, ripiega su un grigio scuro e la schermata resta usabile.

Il percorso della foto è in `AppSettings.backdropPhoto`; la scelta dello sfondo in `AppSettings.backdrop`.

## Suoni

Tre set, tutti generati da `tool/generate_sounds.py` e di nostra proprietà (CC0): Classico (quello di sempre, in `assets/sounds/`), Legno e Cristallo (in `assets/sounds/legno/` e `assets/sounds/cristallo/`). Ogni set ha gli stessi sette suoni di `GameSound`. Toccando un set si sente una mossa e una cattura, a meno che i suoni siano spenti, nel qual caso la scheda lo dice.

`SoundPlayer.activeSet` segue sempre la scelta: lo aggiorna `SettingsController` a ogni modifica, così la schermata di gioco usa il set scelto senza cambiare. Il lettore rilascia i suoi `AudioPlayer` dei set non più in uso.

## Peso

Le tre scacchiere nuove (Marmo, Metallo, Vetro) sono WebP da 1024 px, generate in SVG da `tool/board_art/art.mjs`; Menta, Cipria e Ardesia sono tinte unite. Sfondi e miniature non aggiungono immagini.

## Test

`test/style/` copre le impostazioni (salvataggio, valori sconosciuti, suoni e texture su disco), lo sfondo in `BoardFrame`, le quattro schede, la scelta della foto (con un selettore finto), il campione dei suoni, la voce in Impostazioni, l'inglese, l'assenza di overflow su tre telefoni e a testo grande, e i golden su più schermi in `test/style/goldens/`.
