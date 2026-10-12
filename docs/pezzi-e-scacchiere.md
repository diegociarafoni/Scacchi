# Pezzi e scacchiere

Oltre ai set di chessground, Rokko ha cinque set di pezzi e dieci scacchiere con texture propri, scelti tra le proposte dell'Officina di Rokko. Si scelgono in Impostazioni, alle voci «Tema della scacchiera» e «Pezzi» (vedi [interfaccia.md](interfaccia.md)).

## Set di pezzi

| Set | Aspetto | Autore e licenza |
|---|---|---|
| Rokko | Pezzi classici, morbidi e arrotondati, crema e marrone come l'icona; la torre sorride | Progetto, GPL-3.0+ |
| Pixel | Sprite 12×12 in stile 8 bit | Progetto, GPL-3.0+ |
| Arcano | Mondo di maghi: pedoni apprendisti, alfiere stregone, donna maga, re con corona stellata, cavallo unicorno | Progetto, GPL-3.0+ |
| Papercut | Carta ritagliata con ombre morbide | Nikolay Anzarov, CC BY 4.0 |
| Noto | Simboli Unicode del carattere Noto Sans Symbols 2 | Google, OFL-1.1 |

I set del progetto non richiamano personaggi, nomi o simboli di opere esistenti, che gli store non accetterebbero. I file sono in `assets/pieces/<set>/`, in WebP da 128 px con la variante `3.0x/` da 384 px per gli schermi densi.

## Scacchiere

| Tema | Aspetto | Scuro |
|---|---|---|
| Arancia | Crema e arancio dell'icona, puntini sulle case scure | |
| Crepuscolo | Lavanda e viola con piccole stelle | Sì |
| Pergamena | Carta antica macchiata d'inchiostro, bordi bruniti | |
| Castello | Pietra con rune luminose e luce di candela | Sì |
| Bosco elfico | Betulla e muschio con foglie e rami, luce di luna | |
| Noce | Legno di noce con venature | |
| Spazio | Blu notte con nebulosa e stelle | Sì |
| Retrò | Quattro verdi e retinatura a pixel, da console portatile | |
| Giardino | Prato con fili d'erba | |
| Terracotta | Piastrelle con decoro a stella | |

Le texture sono in `assets/boards/`, in WebP da 1024 px. Per ogni tema con texture l'ultima mossa e la casa selezionata prendono, tra alcuni colori candidati, il più discreto che abbia contrasto almeno 1,25 sia sulle case chiare sia sulle scure (per esempio sul tema Retrò il verde lime si perderebbe); i temi a tinta unita tengono i colori di sempre. Le immagini delle scacchiere di chessground hanno licenza AGPL e non si usano. I colori delle case chiare e scure di ogni tema restano in `lib/settings/settings.dart`: servono alle coordinate, ai colori per daltonici e ai chip delle Impostazioni.

## Alone sui temi scuri

Sui temi scuri (Notte, Crepuscolo, Castello, Spazio) i pezzi neri hanno un contorno crema, altrimenti si confonderebbero con le case. L'alone vale per tutti i set, anche quelli di chessground: le versioni con alone dei soli pezzi neri sono in `assets/pieces/halo/<set>/`. `PieceStyle.assetsOn` sceglie quali usare in base al tema. Fuori dalla scacchiera, nei pezzi catturati e nella tavolozza dell'editor, l'alone non si usa.

## Coordinate fuori dalla scacchiera

Con «Coordinate fuori dalla scacchiera» le lettere stanno sotto e i numeri a sinistra, su una cornice del colore delle case scure, come nei libri. La scacchiera si rimpicciolisce del 10% per farle posto e le coordinate non coprono mai i pezzi. La cornice è `BoardFrame` in `lib/settings/board_frame.dart` e vale per partita, esercizi e anteprima delle Impostazioni; l'editor di posizione non ha cornice e mostra le coordinate sulle case. Le coordinate si girano con la scacchiera e non vengono lette dai lettori di schermo, che annunciano già le case.

## Rigenerare le immagini

Pezzi, aloni e texture si disegnano in SVG in `tool/board_art/art.mjs` e si convertono con Chromium:

```sh
npm install --no-save playwright
node tool/board_art/render.mjs
```

Il sorgente di Papercut è in `tool/board_art/papercut/`. Il carattere Noto si scarica da Google Fonts durante la generazione, quindi serve la rete. Gli aloni dei set di chessground partono dalle sue immagini da 512 px, lette dalla cache dei pacchetti dopo `flutter pub get`. Una nuova cartella di immagini va aggiunta anche alla sezione `assets` di `pubspec.yaml`.

I test in `test/settings/board_art_test.dart` controllano che ogni set abbia i dodici pezzi e gli aloni, entrambe le risoluzioni, e che le texture siano solo nostre.
