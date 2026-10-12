# Multigiocatore tra due telefoni

Partita tra due persone su due telefoni, pensata per funzionare in ogni situazione: sulla stessa Wi-Fi o hotspot, vicini senza Wi-Fi (Bluetooth LE), a distanza tramite relay Nostr, tra Android e iOS. Una partita iniziata in presenza continua a distanza e torna in presenza senza azioni dell'utente. Il gioco da soli resta interamente offline: il multigiocatore è un modulo opzionale in `lib/multiplayer/`.

## Stato

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | Nucleo del protocollo: invito, identità, cifratura, registro delle mosse, canali multipli | Disponibile (senza interfaccia) |
| 2a | Canale Wi-Fi locale su TCP con ricollegamento automatico | Disponibile (senza interfaccia) |
| 2b | Abbinamento via QR, permessi di rete e schermata di gioco in rete locale | Disponibile da Tu › Gioca con un amico |
| 2c-1 | Salvataggio e ripresa della partita in rete locale | Disponibile da Tu › Gioca con un amico › Riprendi la partita |
| 2c-2 | Ricerca mDNS dopo un cambio di indirizzo | Da fare |
| 3 | Canale Bluetooth LE, scelta Wi-Fi o Bluetooth nella schermata | Disponibile da Tu › Gioca con un amico › Come collegarvi |
| 4 | Relay Nostr, link d'invito, notifiche in background, schermate | Da fare |

## Requisiti

| ID | Requisito |
|---|---|
| RMP-01 | Una partita nasce da un invito (QR all'abbinamento o link condiviso) con UUID v4, segreto di 256 bit, chiave pubblica dell'ospite, colore dell'ospite e, facoltativo, indirizzo in rete locale. Un invito non valido viene scartato. |
| RMP-02 | Le mosse sono numerate (semimossa da 1) e accompagnate dall'impronta della posizione risultante; i due telefoni tengono lo stesso registro. Si rifiutano mosse illegali, fuori turno, in contrasto con il registro o con posizione diversa; i doppioni si ignorano. |
| RMP-03 | Ogni messaggio è firmato dal suo autore (Ed25519). L'ospite fissa la chiave dell'avversario al primo ingresso; i messaggi di altre chiavi vengono scartati. |
| RMP-04 | Ogni messaggio è cifrato end-to-end (AES-256-GCM); canali e relay vedono solo byte casuali. Messaggi alterati, di altre partite o con un altro segreto vengono scartati. |
| RMP-05 | I canali disponibili si usano insieme: si invia su tutti, basta che uno consegni; si riceve da tutti in un solo flusso. |
| RMP-07 | In rete locale (stessa Wi-Fi o hotspot) l'ospite ascolta su TCP e l'invitato si collega all'indirizzo dell'invito; l'invitato si ricollega da solo, anche se l'ospite apre la partita dopo di lui, e a ogni collegamento nuovo si ripete l'ultima mossa. Pacchetti oltre 4096 byte chiudono il collegamento; l'ospite tiene al massimo 4 collegamenti e oltre chiude il più vecchio. |
| RMP-08 | Da Tu › Gioca con un amico un telefono sceglie il colore e crea la partita: mostra il QR dell'invito con l'indirizzo in rete locale; l'altro lo inquadra e si collega; se l'ospite non risponde il canale riprova da solo. Poi si gioca a turno sulla scacchiera, con lo stato (attesa, turno, esito) annunciato al lettore di schermo insieme alle mosse dell'avversario. Senza Wi-Fi o hotspot compare un avviso; un QR estraneo viene rifiutato; uscire chiede conferma. |
| RMP-09 | La partita a due si salva a ogni mossa in `multiplayer.json` (invito, seme privato, registro, chiave dell'avversario, messaggi sigillati) e a partita finita il salvataggio sparisce. Chi ospita salva solo dopo l'ingresso dell'avversario. Uscire lascia la partita salvata; da Tu › Gioca con un amico compare «Riprendi la partita» (anche «Elimina»). Chi ospita riapre l'ascolto sulla porta di prima, se libera; l'invitato si ricollega all'indirizzo dell'invito e i registri si riallineano. Una partita nuova sostituisce quella salvata solo dopo conferma; un file non valido viene messo da parte. Chi ospita e esce mentre attende l'avversario non lascia nulla da riprendere. Se la porta di prima è occupata, l'ospite usa un'altra porta e aggiorna l'invito salvato. |
| RMP-11 | Oltre al Wi-Fi, i canali registrati in `extraChannelFactories` (`channel_registry.dart`) si aprono a ogni partita nuova, unita o ripresa e si aggiungono al `MultiTransport` appena pronti; un canale assente o che fallisce non ferma la partita. |
| RMP-20 | Vicini senza Wi-Fi si gioca via Bluetooth LE. Da «Gioca con un amico» chi crea sceglie «Come collegarvi» (Wi-Fi o Bluetooth); l'invito Bluetooth porta `ble=1`, non ha indirizzo di rete e il QR si inquadra come sempre; il canale si apre solo se l'invito lo prevede, quindi una partita in Wi-Fi non chiede permessi Bluetooth. L'ospite annuncia, senza nome, un servizio GATT il cui UUID deriva dall'id della partita; l'invitato lo cerca con quel filtro, si collega e si ricollega da solo se cade. I messaggi sigillati si spezzano nei pacchetti dell'MTU e si ricompongono con memoria limitata. Bluetooth spento, permesso negato o telefono senza BLE danno un avviso chiaro. La partita si salva e riprende anche via Bluetooth. |
| RMP-06 | Cambiare canale non cambia la partita. Chi è rimasto indietro chiede le mosse mancanti e si rimette in pari; una mossa non partita si ripete quando un canale torna disponibile. |

Questi requisiti sostituiscono, per il solo modulo multigiocatore, l'esclusione delle partite tra persone su più dispositivi e il vincolo "nessun permesso di rete" di RNF-01, che resta valido per il gioco da soli.

## Architettura

La partita non appartiene a un canale: è un registro di mosse identico sui due telefoni. I canali sono "postini" intercambiabili che portano byte opachi.

```
MultiplayerSession          lib/multiplayer/multiplayer_session.dart
  ├─ GameSync               registro, regole, chiavi (Dart puro, sincrono)
  ├─ MessageCodec           firma + cifratura dei messaggi
  └─ MultiTransport         tutti i canali insieme
       ├─ Wi-Fi locale      LanTransport
       ├─ Bluetooth LE      BleTransport
       └─ relay Nostr       (fase 4)
```

| File | Ruolo |
|---|---|
| `game_invite.dart` | `GameInvite`: link `scacchi://partita?v=1&g=<uuid>&s=<segreto>&k=<chiave>&c=w|b[&lan=host:porta]`, campi binari in Base64 URL senza padding. `newGameId`, `newSecret` usano `Random.secure`. |
| `player_identity.dart` | `PlayerIdentity`: coppia di chiavi Ed25519; il seme di 32 byte è salvato con la partita (`saved_game.dart`). |
| `game_message.dart` | Messaggi: `JoinMessage` (l'invitato si presenta), `MoveMessage` (semimossa, UCI, impronta), `SyncRequest` (rimandare da una semimossa). |
| `message_codec.dart` | `MessageCodec`: sigillo dei messaggi. |
| `game_sync.dart` | `GameSync`: registro e validazione. `positionHash`: SHA-256 del FEN, primi 128 bit in esadecimale. |
| `transport.dart` | `MessageTransport`, `MultiTransport`, `LoopbackTransport` (in memoria, per i test), `ConnectionAware` per i canali che segnalano un collegamento nuovo. |
| `channel_registry.dart` | `ChannelFactory` e `extraChannelFactories`: dove si registra un canale in più (Bluetooth LE, relay). |
| `lan_transport.dart` | `LanTransport`: canale Wi-Fi su TCP (vedi sotto). |
| `ble_fragmenter.dart` | `BleFragmenter` e `BleReassembler`: messaggio ↔ pacchetti con intestazione di 4 byte. |
| `ble_transport.dart` | `BleLink` (estremo del collegamento), `BleTransport` (canale `MessageTransport`), `bleServiceUuid`. |
| `ble_link.dart` | Adattatore su `bluetooth_low_energy`: `BlePeripheralLink` (ospite), `BleCentralLink` (invitato), `ensureBluetoothReady`, `checkBluetooth`, `BluetoothUnavailable` e `openBleChannel`, la riga registrata in `extraChannelFactories`. |
| `saved_game.dart` | `SavedGame` e `SavedGameStore`: la partita in corso in `multiplayer.json`, nella cartella privata dell'app (`JsonFile`, scrittura atomica). |
| `multiplayer_session.dart` | `MultiplayerSession`: collega registro, sigillo e canali e reagisce ai messaggi. |

### Formato del messaggio sigillato

```
nonce (12 byte) | AES-256-GCM( {"a": chiave autore, "b": corpo JSON, "s": firma} ) | MAC (16 byte)
```

- Chiave AES derivata con HKDF-SHA256 dal segreto dell'invito, con l'UUID come sale e `scacchi-messaggi-v1` come contesto; l'UUID è anche dato autenticato aggiuntivo, quindi un messaggio non si sposta da una partita all'altra.
- La firma Ed25519 copre `scacchi-mossa-v1|<uuid>|`, la chiave dell'autore e il corpo: chi conosce il segreto (l'avversario) può cifrare, ma non può firmare a nome dell'altro.
- Oltre 1024 byte un messaggio non viene neppure decifrato; ogni errore di formato porta allo scarto silenzioso (dati del canale non fidati, MASVS-CODE-4).

### Canale Wi-Fi locale

`LanTransport.host()` apre un `ServerSocket` su tutte le interfacce IPv4 (porta scelta dal sistema, da mettere nell'invito come `lan=host:porta`); `LanTransport.connect(host, porta)` è il lato dell'invitato, che si collega al primo invio e si ricollega da solo quando il primo tentativo fallisce o il collegamento cade, anche senza nulla da inviare, con attese crescenti da 1 a 15 secondi; al rientro annuncia la sua chiave e ripete l'ultima mossa, mentre l'ospite ripete la sua. Ogni messaggio sigillato viaggia preceduto dalla sua lunghezza su 4 byte big-endian; il decodificatore ricompone i pacchetti spezzati in qualunque punto. Un pacchetto annunciato oltre 4096 byte chiude il collegamento senza leggere oltre, e oltre il quarto collegamento l'ospite chiude il più vecchio: il canale è aperto in rete locale, quindi non deve poter consumare memoria, e un telefono uscito dalla Wi-Fi senza salutare non deve bloccare il proprio rientro. Un invio che non si svuota entro 5 secondi chiude il collegamento. Limite noto: un invio riuscito vuol dire consegnato al sistema operativo, non letto dall'altro telefono; se il collegamento era già morto la mossa riparte al ricollegamento. L'autenticità non dipende dal canale: chi si collega senza il segreto dell'invito non produce messaggi validi.

A ogni collegamento nuovo `MultiTransport.connected` avvisa la sessione, che fa ripresentare l'invitato e ripete la propria ultima mossa: dopo un'uscita dalla Wi-Fi la partita riprende senza azioni dell'utente.

### Canale Bluetooth LE

Per giocare vicini senza Wi-Fi né rete (RMP-20). `GameInvite.ble` (`ble=1` nel link) dice a entrambi di aprire il Bluetooth; un invito può avere `lan`, `ble` o tutti e due, e `MultiTransport` usa quelli disponibili insieme. `openBleChannel` è registrato in `extraChannelFactories` (RMP-11): restituisce `null` se l'invito non è Bluetooth. `MultiplayerController.host(bluetooth: true)` non apre la rete locale e crea un invito senza `lan`; l'invitato e la ripresa saltano la rete locale quando l'invito non ha indirizzo ma ha `ble`. La schermata controlla prima permessi e Bluetooth acceso (`checkBluetooth`) e mostra l'avviso; il canale poi si apre in sottofondo e `connected` avvisa la sessione.

- **Servizio.** UUID del servizio GATT = primi 128 bit di SHA-256(`scacchi-ble-v1|<id partita>`): l'invitato filtra la ricerca su quello, e dall'annuncio non si risale all'id. Due caratteristiche fisse: `…4c01` (l'invitato scrive, con risposta) e `…4c02` (l'ospite notifica).
- **Ruoli.** L'ospite è periferica (`BlePeripheralLink`): pubblica il servizio, si annuncia senza nome e risponde con notifiche a chi si iscrive; si ripubblica se il Bluetooth viene spento e riacceso e si riannuncia dopo ogni uscita. L'invitato è centrale (`BleCentralLink`): cerca, si collega, scopre il servizio, si iscrive alle notifiche e, se il collegamento cade o la ricerca non trova nulla, ricomincia con attese da 1 a 8 secondi.
- **Pacchetti.** Ogni scrittura o notifica porta al più `MTU - 3` byte (20 finché la MTU non è nota). Intestazione di 4 byte: id del messaggio (2), indice (1), numero di frammenti (1). `BleReassembler` ricompone in qualunque ordine, ignora i doppioni e tiene al massimo 4 messaggi incompleti e 2048 byte per messaggio; frammenti incoerenti si scartano in silenzio.
- **Collegamenti.** L'ospite tiene al massimo 3 telefoni iscritti e, oltre, scollega il più vecchio. Il Bluetooth non autentica nessuno: come per il Wi-Fi, chi non ha il segreto dell'invito non produce messaggi validi.
- **Permessi.** Android 12 e successivi: `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`, richiesti a runtime solo quando si sceglie il Bluetooth. Android 11 e precedenti: `BLUETOOTH`, `BLUETOOTH_ADMIN` e `ACCESS_FINE_LOCATION` con `maxSdkVersion="30"`; la posizione non viene letta né salvata (il sistema la pretende per cercare dispositivi BLE e il GPS deve essere acceso). iOS: `NSBluetoothAlwaysUsageDescription`. Tutti i motivi sono in `tool/policy.json`.
- **Limiti noti.** Si gioca in primo piano: in background iOS limita annunci e ricerche e non c'è ancora il recupero in background (fase 4). La portata è quella del BLE (qualche metro). Un invio riuscito vuol dire consegnato al sistema operativo, come nel Wi-Fi; la mossa si ripete al ricollegamento. Verificato con una radio finta in memoria (`ble_link_test.dart`); la prova su due telefoni veri va fatta a mano prima di annunciarlo.

### Schermata

`MultiplayerPage` (voce Tu › Gioca con un amico) offre la scelta del colore, «Come collegarvi» (Wi-Fi o Bluetooth), «Crea la partita» e «Unisciti con il QR». `MultiplayerController` tiene lo stato per l'interfaccia: crea identità e invito per partita, apre il canale con `openLanHost` (indirizzo IPv4 privato scelto da `pickLanAddress` preferendo Wi-Fi e hotspot ed escludendo dati mobili e VPN, porta scelta dal sistema) o `openLanGuest`, e avvisa a ogni mossa. L'invito si mostra una sola volta come QR del link `scacchi://`, non a ogni mossa; la fotocamera riusa il lettore dello scambio QR. `MultiplayerGamePage` mostra il QR finché l'avversario non arriva, poi la scacchiera orientata dal proprio lato, con le mosse permesse solo al proprio turno.

Su Android il permesso `INTERNET` è dichiarato con il motivo in `tool/policy.json`; su iOS `NSLocalNetworkUsageDescription` spiega l'uso della rete locale. Nessun socket si apre finché non si crea o si inquadra un invito. `NSBonjourServices` arriverà con la ricerca mDNS (fase 2c).

### Regole del registro

- Le semimosse dispari sono del Bianco, le pari del Nero. Una semimossa del proprio colore viene accettata solo se porta la propria firma: succede nel recupero, quando l'avversario rimanda i messaggi originali. L'avversario non può quindi muovere al posto dell'altro, nemmeno fingendo un buco nel registro.
- Semimossa già nota con stesso contenuto: doppione, ignorato (i canali paralleli consegnano più copie). Con contenuto diverso: rifiutata.
- Semimossa oltre la successiva attesa: buco nel registro (`Gap`); la sessione invia `SyncRequest` e l'avversario rimanda, identici, i messaggi sigillati di ogni semimossa, ciascuno con la firma del suo autore. Numeri oltre 2000 semimosse sono scartati.
- L'invitato si presenta con `JoinMessage`, ma anche la sua prima mossa vale come presentazione: se la mossa arriva prima (i canali non garantiscono l'ordine), la partita non si blocca.
- Se l'avversario ripete una mossa più vecchia della nostra ultima, oppure rientra con un nuovo `JoinMessage`, significa che forse non ha ricevuto la nostra: la sessione la rimanda.
- I messaggi in arrivo si elaborano uno alla volta, nell'ordine di arrivo.
- A partita finita non si accettano altre mosse.

### Cadenza (fasi successive)

In presenza si gioca con l'orologio; quando la partita passa a distanza l'orologio va in pausa e la cadenza diventa per corrispondenza, con la ripresa dell'orologio dal vivo concordata al ritorno in presenza.

## Sicurezza (OWASP MASVS)

| Area | Misura |
|---|---|
| MASVS-CRYPTO | Ed25519, AES-256-GCM, HKDF-SHA256 dal pacchetto `cryptography`; nonce casuale per ogni messaggio; segreti da `Random.secure`. |
| MASVS-NETWORK | Cifratura end-to-end su ogni canale, anche locale; il relay non legge né falsifica le mosse. |
| MASVS-CODE | Invito e messaggi sono input non fidato: limiti di lunghezza, validazione di ogni campo, scarto silenzioso. |
| MASVS-AUTH | Nessun account: l'identità è la chiave Ed25519; la chiave dell'avversario si fissa al primo ingresso. |
| MASVS-PRIVACY | Nessun dato personale; il relay vedrà solo byte cifrati e chiavi casuali per partita. |

Limiti noti: l'invito contiene il segreto, quindi chi lo intercetta prima dell'avversario può occupare la partita (l'ospite vedrà una chiave diversa da quella attesa). Il salvataggio contiene il seme privato della partita: sta nella cartella privata dell'app, escluso dai backup di Android (`backup_rules.xml`, `data_extraction_rules.xml`); su iOS segue il backup del dispositivo, cifrato. Chi legge il file può firmare al posto del giocatore, ma solo in quella partita: l'identità è generata per ogni partita. Se l'indirizzo dell'ospite cambia dopo il riavvio, l'invitato non lo ritrova finché non arriva la ricerca mDNS (fase 2c-2).

## Test

`flutter test test/multiplayer`: Bluetooth (`ble_fragmenter_test.dart`: frammenti in disordine, doppi, incoerenti, memoria limitata; `ble_transport_test.dart`: canale su un collegamento in memoria; `ble_link_test.dart`: ospite e invitato su una radio finta, permessi, Bluetooth spento, ricollegamento, limite di collegamenti; `multiplayer_bluetooth_test.dart` e `multiplayer_bluetooth_page_test.dart`: partita intera, ripresa e schermata), salvataggio e ripresa (`saved_game_test.dart`), invito, sigillo, registro, canali e sessione completa con canali in memoria, compreso il passaggio Wi-Fi → relay → Wi-Fi e il recupero dopo un ripristino. `lan_transport_test.dart` usa socket TCP veri su 127.0.0.1: pacchetti spezzati, pacchetti troppo grandi, limite di collegamenti, ricollegamento senza invii, chiusura durante il collegamento, una partita completa e una mossa consegnata dopo la caduta del collegamento. `multiplayer_controller_test.dart` e `multiplayer_page_test.dart` provano stato e schermata con canali in memoria e un lettore QR finto: attesa, turni, matto, nuovi tentativi dell'invitato, assenza di Wi-Fi, QR estraneo e conferma d'uscita.
