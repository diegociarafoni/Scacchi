# Pezzi e scacchiere

Oltre ai set di chessground, Rokko ha cinque set di pezzi e tredici scacchiere con texture propri, scelti tra le proposte dell'Officina di Rokko. Si scelgono nella schermata Stile (vedi [stile.md](stile.md)) o in Impostazioni, alle voci «Tema della scacchiera» e «Pezzi» (vedi [interfaccia.md](interfaccia.md)).

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
| Marmo | Marmo bianco venato di grigio e marmo verde scuro, con un riflesso diagonale | |
| Metallo | Acciaio satinato con striature orizzontali e bordi smussati tra le case | |
| Vetro | Lastre di vetro azzurro con bordi luminosi e riflessi | |

Alle tredici con texture si aggiungono le tinte unite di sempre (Verde, Legno, Blu, Grigio, Sabbia, Oceano, Corallo, Notte, Oro) e tre nuove: Menta, Cipria e Ardesia. Le case di Ardesia sono abbastanza vicine nella luminosità da dare ai punti delle mosse possibili il contrasto 3:1 su entrambe, come controlla `test/settings/board_marks_test.dart`. Le texture sono in `assets/boards/`, in WebP da 1024 px. Per ogni tema con texture l'ultima mossa e la casa selezionata prendono, tra alcuni colori candidati, il più discreto che abbia contrasto almeno 1,25 sia sulle case chiare sia sulle scure (per esempio sul tema Retrò il verde lime si perderebbe); gli altri temi tengono i colori di sempre se raggiungono quella soglia, altrimenti prendono il candidato più discreto che la raggiunge (sul Verde l'ultima mossa diventa ambra). I punti delle mosse possibili devono avere contrasto 3:1 (WCAG 1.4.11) su entrambe le case: i temi di chessground tengono il colore originale se ci arriva, gli altri usano nero o bianco semitrasparente con la trasparenza minima che basta. Su Notte, Castello e Retrò le case chiare e scure hanno luminosità troppo vicina perché un solo colore arrivi a 3:1 su tutte e due: lì si prende il punto che stacca di più (circa 2,3 su Notte, 2,7 su Castello, 2,8 su Retrò). L'ultima mossa e la casa selezionata restano invece a 1,25: sono riempimenti di tutta la casa, e a 3:1 coprirebbero i pezzi che ci stanno sopra togliendo loro contrasto; la stessa informazione è comunque nella lista delle mosse e negli annunci per i lettori di schermo. Le immagini delle scacchiere di chessground hanno licenza AGPL e non si usano. I colori delle case chiare e scure di ogni tema restano in `lib/settings/settings.dart`: servono alle coordinate, ai colori per daltonici e ai chip delle Impostazioni.

## Frecce e cerchi

Suggerimenti, mossa migliore, risposta attesa nel ripasso e minaccia sono frecce e cerchi con un contorno: `BoardMarks` (`lib/settings/board_marks.dart`) disegna sotto il colore un bordo nero, o bianco su Spazio, che ha contrasto almeno 3:1 (WCAG 1.4.11) con entrambe le case. Su Notte, Castello e Retrò né il nero né il bianco arrivano a 3:1 su tutte e due le case, quindi il contorno è doppio, nero e bianco: su ogni casa uno dei due stacca. Il colore all'interno (verde per il suggerimento, rosso per la minaccia e per la mossa sbagliata nei problemi; blu e arancione o vermiglio con i colori per daltonici) è chiaro dentro un bordo nero e scuro dentro un bordo bianco, sempre con contrasto almeno 3:1 rispetto al bordo. I cerchi hanno il contorno su entrambi i lati, così staccano sia dalla casa sia dalle vicine. Anche analisi, revisione, percorso, finali e minigiochi usano il tema scelto (`AppSettings.exerciseBoard`) e quindi i suoi segni. `test/settings/board_marks_test.dart` controlla contrasti e famiglia di colore su tutti i temi, normali e per daltonici.

## Alone sui temi scuri

Sui temi scuri (Notte, Crepuscolo, Castello, Spazio) i pezzi neri hanno un contorno crema, altrimenti si confonderebbero con le case. L'alone vale per tutti i set, anche quelli di chessground: le versioni con alone dei soli pezzi neri sono in `assets/pieces/halo/<set>/`. `PieceStyle.assetsOn` sceglie quali usare in base al tema. Fuori dalla scacchiera, nei pezzi catturati e nella tavolozza dell'editor, l'alone non si usa.

## Coordinate fuori dalla scacchiera

Con «Coordinate fuori dalla scacchiera» le lettere stanno sotto e i numeri a sinistra, su una cornice del colore delle case scure, come nei libri. La scacchiera si rimpicciolisce del 10% per farle posto e le coordinate non coprono mai i pezzi. La cornice è `BoardFrame` in `lib/settings/board_frame.dart` e vale per partita, esercizi e anteprima delle Impostazioni; l'editor di posizione non ha cornice e mostra le coordinate sulle case. Le coordinate si girano con la scacchiera e non vengono lette dai lettori di schermo, che annunciano già le case.

## Rigenerare le immagini

Pezzi, aloni e texture si disegnano in SVG in `tool/board_art/art.mjs` e si convertono con Chromium:

```sh
npm install --no-save playwright
node tool/board_art/render.mjs
BOARDS=marmo,metallo,vetro node tool/board_art/render.mjs   # solo alcune scacchiere
```

Il sorgente di Papercut è in `tool/board_art/papercut/`. Il carattere Noto si scarica da Google Fonts durante la generazione, quindi serve la rete. Gli aloni dei set di chessground partono dalle sue immagini da 512 px, lette dalla cache dei pacchetti dopo `flutter pub get`. Una nuova cartella di immagini va aggiunta anche alla sezione `assets` di `pubspec.yaml`.

I test in `test/settings/board_art_test.dart` controllano che ogni set abbia i dodici pezzi e gli aloni, entrambe le risoluzioni, e che le texture siano solo nostre.
