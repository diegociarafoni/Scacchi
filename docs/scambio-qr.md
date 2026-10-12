# Scambio di partite tra telefoni con il QR

Proposta del capitolo 7 dei requisiti: passare una partita in corso o un PGN da un telefono all'altro leggendo un codice QR, senza rete, senza account e senza server. Il codice è in `lib/exchange/`.

## Uso

| Dove | Azione | Effetto |
|---|---|---|
| Gioca › menu ⋮ › **Passa con QR** | Mostra la partita sullo schermo come QR | La partita resta sospesa (orologio fermo) finché si torna indietro |
| Gioca › menu ⋮ › **Ricevi con QR** | Apre la fotocamera | Una partita in corso continua su questo telefono, tra due persone e senza orologio; una già conclusa va ricevuta dall'archivio |
| Tu › Archivio › menu di una partita › **Passa con QR** | Mostra la partita salvata come QR | |
| Tu › Archivio › **Ricevi con QR** (icona in alto) | Apre la fotocamera | La partita ricevuta entra nell'archivio come `importata` |

Una partita fino a circa 40 mosse sta in un solo QR. Una più lunga, o un PGN con molti commenti, diventa una sequenza di QR che scorrono da soli in ciclo (0,8 secondi ciascuno): chi riceve tiene la fotocamera puntata e le parti si raccolgono in qualunque ordine, anche saltandone qualcuna al primo giro. Sotto il QR ci sono Pausa e i pulsanti per scorrere le parti a mano; chi riceve vede "3 di 6 parti lette", sente una vibrazione leggera a ogni parte nuova e il lettore di schermo annuncia l'avanzamento.

Una partita continuata con Ricevi con QR si salva nell'archivio a fine partita come le altre, ma non assegna XP (come quelle preparate con l'editor): è iniziata su un altro telefono. I nomi dei giocatori nelle impostazioni non cambiano, perché nel PGN di chi invia possono esserci "Tu" o il nome di un bot. Se la lettura fallisce o il QR non contiene una partita, la partita corrente riprende com'era, orologio compreso. Il tempo residuo dell'orologio non viene trasferito.

Passa con QR è attivo appena c'è una mossa, oppure subito per una posizione preparata con l'editor. Una partita che supererebbe le 64 parti accettate da chi riceve non viene mostrata: la schermata dice che è troppo grande.

Lo stesso trasporto serve per la **sfida a tempo tra amici** (lancio della sfida e punteggio finale, vedi [puzzle.md](puzzle.md)): `QrSendPage` e `QrReceivePage` accettano un titolo, un'istruzione e un avviso per QR estraneo propri, così le schermate parlano di sfida e non di partita.

## Formato dei fotogrammi

`lib/exchange/qr_transfer.dart`, in Dart puro e testato senza interfaccia.

```
SC1/<ID>/<i>/<n>/<DATI>
```

- `SC1`: prefisso e versione del formato; un QR che non inizia così (un indirizzo web, un biglietto) viene riconosciuto come estraneo.
- `<ID>`: CRC-32 dei dati compressi, 8 cifre esadecimali. Identifica la partita, così un QR di un'altra partita fa ricominciare la lettura invece di mescolare i pezzi, e fa da controllo d'integrità finale.
- `<i>/<n>`: numero della parte e totale.
- `<DATI>`: il PGN in UTF-8, compresso con zlib e codificato in Base32 maiuscolo (RFC 4648) senza padding, al massimo 640 caratteri per parte.

Perché Base32 e non Base64: tutti i caratteri del fotogramma (`A-Z`, `2-7`, cifre e `/`) appartengono alla modalità **alfanumerica** dei QR, che usa 5,5 bit per carattere contro gli 8 della modalità byte. Base32 porta 5 bit utili per carattere, quindi l'efficienza è del 91% contro il 75% di Base64 in modalità byte: a parità di dati il QR è più piccolo e si legge meglio da lontano. Con 640 caratteri e correzione d'errore media il QR è di versione 17 (85×85 moduli): una partita di 40 mosse con le intestazioni sta in un solo QR, e i moduli restano abbastanza grandi per una lettura da 20-30 cm. Il QR è disegnato in Dart con il pacchetto `qr`, sempre nero su bianco con il margine di 4 moduli, anche con il tema scuro.

## Ricezione e sicurezza dei dati letti

I dati letti dalla fotocamera sono input non fidato (OWASP MASVS-CODE-4). `TransferAssembler` li valida prima di usarli:

| Controllo | Esito |
|---|---|
| Fotogramma più lungo di 4096 caratteri | Rifiutato prima di analizzarlo |
| Prefisso diverso da `SC1/` | "Questo QR non contiene una partita." |
| Campi mancanti, numeri non validi, caratteri fuori dall'alfabeto Base32, parte oltre il totale | Rifiutato |
| Più di 64 parti | Rifiutato (troppo grande) |
| Stessa parte con dati diversi, totale diverso per lo stesso ID | "QR non valido: ignorato.", si tengono le parti già lette |
| CRC-32 non corrispondente, zlib o UTF-8 non validi | "Il QR è danneggiato: ricomincia la lettura." e si riparte da zero |
| Testo decompresso oltre 256 KiB | Rifiutato: la decompressione procede a blocchi e si ferma al limite, così una "bomba zip" non esaurisce la memoria |

Il testo ricomposto passa poi da `importPgn` (vedi [archivio.md](archivio.md)), che scarta mosse illegali, FEN non validi e varianti non supportate; le partite senza mosse e senza posizione di partenza vengono scartate (`receivedGames`) e solo quelle rimaste entrano nell'archivio (`GameArchive.importRecords`).

## Fotocamera: pacchetti e licenze

| Pacchetto | Uso | Licenza |
|---|---|---|
| [flutter_zxing](https://pub.dev/packages/flutter_zxing) | Lettore QR dalla fotocamera | MIT |
| [zxing-cpp](https://github.com/zxing-cpp/zxing-cpp), incluso in flutter_zxing | Decodifica, in codice nativo sul dispositivo | Apache-2.0 |
| [camera](https://pub.dev/packages/camera) (Flutter), dipendenza di flutter_zxing | Anteprima della fotocamera (CameraX su Android, AVFoundation su iOS) | BSD-3-Clause |
| [image_picker](https://pub.dev/packages/image_picker) (Flutter) | Lettura di un QR da un'immagine scelta dall'utente e foto del profilo (RP-09); dipendenza diretta | BSD-3-Clause |
| [qr](https://pub.dev/packages/qr) (Dart) | Generazione del QR | BSD-3-Clause |

Perché flutter_zxing e non `mobile_scanner`, il pacchetto più diffuso: su Android `mobile_scanner` usa Google ML Kit, una libreria proprietaria distribuita con termini propri, che non si può combinare con il codice GPL senza ambiguità e che impedirebbe la pubblicazione su F-Droid. flutter_zxing usa zxing-cpp, open source e compilato dentro l'app: nessun servizio Google, nessun modello scaricato, tutto funziona offline. MIT, Apache-2.0 e BSD sono compatibili con la GPL-3.0 e con il permesso aggiuntivo per gli store descritto in [licenza.md](licenza.md). Lo stesso decodificatore gira anche su Linux, il che permette il test end-to-end descritto sotto.

## Permessi (MASVS-PLATFORM e MASVS-PRIVACY)

- **Android** (`android/app/src/main/AndroidManifest.xml`): solo `CAMERA`, richiesto a runtime dal plugin alla prima apertura del lettore, non all'avvio dell'app. `android.hardware.camera.any` è `required="false"`, così l'app resta installabile su dispositivi senza fotocamera. Il plugin `camera` dichiara anche `RECORD_AUDIO` e `WRITE_EXTERNAL_STORAGE`, che il lettore non usa: il manifest dell'app li rimuove con `tools:node="remove"` (minimo privilegio). La scelta di un'immagine usa il selettore di foto del sistema, che non richiede permessi. La stessa fotocamera serve anche per la foto del profilo (RP-09), sempre e solo quando si tocca «Scatta una foto».
- **iOS** (`ios/Runner/Info.plist`): `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription` spiegano in italiano che fotocamera e immagini servono a leggere il QR e a scegliere la foto del profilo. Il microfono non viene mai attivato (`enableAudio: false` nel lettore), quindi non serve la sua descrizione.
- Le immagini della fotocamera restano in memoria, non vengono salvate né inviate; il lettore spegne la fotocamera quando l'app va in secondo piano e quando si esce dalla schermata.
- Se il permesso viene negato o la fotocamera manca (anche su desktop), la schermata lo spiega con "Non riesco a usare la fotocamera. Consenti l'accesso alla fotocamera per Rokko nelle impostazioni del telefono e riprova." e un pulsante Riprova, senza bloccare il resto dell'app.

## Test

| Livello | File | Cosa verifica |
|---|---|---|
| Unitari | `test/exchange/qr_transfer_test.dart` | CRC-32 e Base32 sui vettori standard; andata e ritorno di partite brevi, lunghe, vuote e con accenti; ordine casuale e duplicati; alfabeto alfanumerico; QR estranei, malformati, alterati, troppo grandi; bomba zip; cambio di partita |
| Widget | `test/exchange/qr_pages_test.dart` | QR singolo e a fotogrammi, scorrimento, pausa e passi a mano, bianco e nero col tema scuro, partita oltre il limite di parti; ricezione in qualunque ordine, avanzamento, azzeramento dopo un errore finale, annuncio al lettore di schermo, QR estraneo, danneggiato, fotocamera negata |
| Widget | `test/archive/archive_page_test.dart` | Passa con QR dall'archivio, ricezione e import, testo che non è una partita |
| Widget | `test/game/game_qr_test.dart` | Passa la partita in corso; continua una partita ricevuta fino al matto; partita già conclusa rimandata all'archivio; testo non valido che lascia la partita com'era |
| E2E | `integration_test/qr_exchange_test.dart` | Sull'app reale: il QR della partita in corso, catturato dallo schermo, viene letto da zxing-cpp (lo stesso decodificatore del telefono); ogni parte di una partita lunga si legge alla densità reale; senza fotocamera la schermata spiega cosa fare; il QR di lancio di una sfida tra amici si legge e porta il seme giusto |

Nei test di widget il lettore è sostituito da uno finto tramite il parametro `scanner` (`qrScanner` in `GamePage`): la fotocamera non esiste in `flutter test`.

## Limiti noti

- L'orologio non passa all'altro telefono: la partita continua senza orologio. I tempi residui già registrati a ogni mossa (`[%clk]`) viaggiano invece nel PGN.
- Su desktop il lettore non ha una fotocamera (il pacchetto `camera` non la supporta); si può comunque mostrare il QR.
- Una partita contro il computer ricevuta prosegue tra due persone.
