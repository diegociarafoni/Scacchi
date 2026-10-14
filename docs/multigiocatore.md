# Multigiocatore tra due telefoni

Partita tra due persone su due telefoni, pensata per funzionare in ogni situazione: sulla stessa Wi-Fi o hotspot, vicini senza Wi-Fi (Bluetooth LE), a distanza tramite relay Nostr, tra Android e iOS. Una partita iniziata in presenza continua a distanza e torna in presenza senza azioni dell'utente. Il gioco da soli resta interamente offline: il multigiocatore è un modulo opzionale in `lib/multiplayer/`.

## Come si accede

| Canale o funzione | Dove |
|---|---|
| Wi-Fi locale (TCP), ricollegamento automatico, ricerca mDNS dopo un cambio di indirizzo | Home › Gioca con un amico, «Come collegarvi» › Wi-Fi |
| Bluetooth LE | Home › Gioca con un amico, «Come collegarvi» › Bluetooth |
| Relay Nostr, link d'invito, avvisi in background (solo Android) | Home › Gioca con un amico, «Come collegarvi» › A distanza |
| Orologio con cadenza scelta alla creazione; a distanza anche il tempo per mossa in giorni | stessa schermata, sezioni «Tempo di gioco» e «Tempo per mossa» |
| Salvataggio e ripresa della partita | «Riprendi la partita» nella stessa schermata |
| Stessi comandi dal foglio Nuova partita | Nuova partita › Sfida un amico › Ognuno sul suo telefono |

Il nucleo del protocollo (invito, identità, cifratura, registro delle mosse, canali multipli) è in Dart puro, senza interfaccia.

## Requisiti

| ID | Requisito |
|---|---|
| RMP-01 | Una partita nasce da un invito (QR all'abbinamento o link condiviso) con UUID v4, segreto di 256 bit, chiave pubblica dell'ospite, colore dell'ospite e, facoltativo, indirizzo in rete locale (solo IPv4 di reti private: 10/8, 172.16/12, 192.168/16). Un invito non valido viene scartato. |
| RMP-02 | Le mosse sono numerate (semimossa da 1) e accompagnate dall'impronta della posizione risultante; i due telefoni tengono lo stesso registro. Si rifiutano mosse illegali, fuori turno, in contrasto con il registro o con posizione diversa; i doppioni si ignorano. |
| RMP-03 | Ogni messaggio è firmato dal suo autore (Ed25519). L'ospite fissa la chiave dell'avversario al primo ingresso; i messaggi di altre chiavi vengono scartati. |
| RMP-04 | Ogni messaggio è cifrato end-to-end (AES-256-GCM); canali e relay vedono solo byte casuali. Messaggi alterati, di altre partite o con un altro segreto vengono scartati. |
| RMP-05 | I canali disponibili si usano insieme: si invia su tutti, basta che uno consegni; si riceve da tutti in un solo flusso. |
| RMP-07 | In rete locale (stessa Wi-Fi o hotspot) l'ospite ascolta su TCP e l'invitato si collega all'indirizzo dell'invito; l'invitato si ricollega da solo, anche se l'ospite apre la partita dopo di lui, e a ogni collegamento nuovo si ripete l'ultima mossa. Pacchetti oltre 4096 byte chiudono il collegamento; l'ospite tiene al massimo 4 collegamenti e oltre chiude il più vecchio. |
| RMP-08 | Da Home › Gioca con un amico un telefono sceglie il colore e crea la partita: mostra il QR dell'invito con l'indirizzo in rete locale; l'altro lo inquadra e si collega; se l'ospite non risponde il canale riprova da solo. Poi si gioca a turno sulla scacchiera, con lo stato (attesa, turno, esito) annunciato al lettore di schermo insieme alle mosse dell'avversario. Senza Wi-Fi o hotspot compare un avviso; un QR estraneo viene rifiutato; uscire chiede conferma. |
| RMP-09 | La partita a due si salva a ogni mossa in `multiplayer.json` (invito, seme privato, registro, chiave dell'avversario, messaggi sigillati) e a partita finita il salvataggio sparisce. Chi ospita salva solo dopo l'ingresso dell'avversario. Uscire lascia la partita salvata; da Home › Gioca con un amico compare «Riprendi la partita» (anche «Elimina»). Chi ospita riapre l'ascolto sulla porta di prima, se libera; l'invitato si ricollega all'indirizzo dell'invito e i registri si riallineano. Una partita nuova sostituisce quella salvata solo dopo conferma; un file non valido viene messo da parte. Chi ospita e esce mentre attende l'avversario non lascia nulla da riprendere. Se la porta di prima è occupata, l'ospite usa un'altra porta e aggiorna l'invito salvato. |
| RMP-10 | Chi ospita annuncia la partita in rete locale (mDNS, servizio `_rokko-chess._tcp`, nome = impronta dell'id della partita, non l'id). Se l'invitato non raggiunge più l'indirizzo dell'invito, dopo ogni tentativo fallito cerca l'annuncio con il nome della sua partita (al massimo 6 secondi) e si ricollega al nuovo indirizzo. L'annuncio è facoltativo: se non funziona la partita non si ferma; finisce con la chiusura della partita. |
| RMP-11 | Oltre al Wi-Fi, i canali registrati in `extraChannelFactories` (`channel_registry.dart`) si aprono a ogni partita nuova, unita o ripresa e si aggiungono al `MultiTransport` appena pronti; un canale assente o che fallisce non ferma la partita. |
| RMP-20 | Vicini senza Wi-Fi si gioca via Bluetooth LE. Da «Gioca con un amico» chi crea sceglie «Come collegarvi» (Wi-Fi, Bluetooth o A distanza); l'invito Bluetooth porta `ble=1`, non ha indirizzo di rete e il QR si inquadra come sempre; il canale si apre solo se l'invito lo prevede, quindi una partita in Wi-Fi non chiede permessi Bluetooth. L'ospite annuncia, senza nome, un servizio GATT il cui UUID deriva dall'id della partita; l'invitato lo cerca con quel filtro, si collega e si ricollega da solo se cade. I messaggi sigillati si spezzano nei pacchetti dell'MTU e si ricompongono con memoria limitata. Bluetooth spento, permesso negato o telefono senza BLE danno un avviso chiaro. La partita si salva e riprende anche via Bluetooth. |
| RMP-30 | Per ogni partita a distanza la chiave Nostr (secp256k1) e le etichette degli slot si derivano dal segreto dell'invito con HKDF-SHA256, uguali sui due telefoni senza scambiarsi altro. Partite o segreti diversi danno chiavi e slot diversi: il relay vede solo una chiave pubblica casuale per partita. |
| RMP-31 | Il canale `NostrTransport` pubblica ogni messaggio sigillato come evento sostituibile (tipo 30078, firma Schnorr BIP-340) con il messaggio in base64; ogni lato ha 4 slot a rotazione, quindi il relay conserva solo gli ultimi messaggi e mai lo storico. Si ascoltano solo gli slot dell'altro lato; eventi con id o firma sbagliati, altra chiave, slot estraneo, contenuto non base64 o oltre 1024 byte si scartano, e una copia già vista non si ripete. Si usano solo relay `wss`, tutti insieme: un invio riesce se un relay risponde `OK` entro 8 secondi. Un relay caduto si ricontatta con attese da 2 a 60 secondi (l'attesa riparte da 2 solo dopo un messaggio valido del relay, per esempio EOSE) e al ritorno si ripubblicano gli eventi in corso. |
| RMP-32 | L'invito a distanza porta `r=1` (altri valori lo rendono non valido). Solo con `r=1` la partita apre il canale Nostr, a ogni partita nuova, unita o ripresa; senza, nessun relay viene contattato. Senza Wi-Fi né hotspot l'ospite può creare la partita a distanza e l'invitato entrare con un invito senza `lan`; senza `r=1` e senza `lan` l'invito non è utilizzabile. Se l'ospite ha la Wi-Fi, l'invito porta entrambi e la partita passa da un canale all'altro da sola. |
| RMP-33 | Chi rientra in una partita a distanza (ripresa dopo la chiusura dell'app) trova sul relay l'ultima mossa dell'amico e si riallinea; l'ospite può riprendere anche senza Wi-Fi, e l'amico può arrivare ore dopo. |
| RMP-34 | In Home › Gioca con un amico la scelta «A distanza» tra i modi di collegarsi (Wi-Fi, Bluetooth, A distanza) apre il canale internet. Chi ospita a distanza condivide il link con le app di messaggi o mostra il QR; l'altro lo incolla da «Unisciti con il link» (anche dentro un messaggio con altro testo) o lo inquadra; un testo che non è un invito si rifiuta. L'ospite a distanza salva la partita subito, anche senza avversario, e uscire in attesa la lascia riprendibile. L'app non registra alcun link profondo (MASVS-PLATFORM). |
| RMP-40 | Con una partita a distanza salvata, il controllo in background si collega una volta ai relay, guarda se l'amico ha giocato oltre il registro locale e, se sì, mostra una notifica locale con la sua mossa (o «La partita è finita») nella lingua del telefono. Per ogni mossa si avvisa una sola volta; il controllo non salva nulla, alla riapertura la partita si riallinea da sola. Senza partita salvata, o in rete locale, non fa nulla. |
| RMP-41 | Su Android un lavoro periodico di WorkManager (ogni 15 minuti, con rete) esegue il controllo: si accende quando parte una partita a distanza, si spegne a partita finita o quando non c'è più una partita da seguire. Il permesso per le notifiche si chiede in quel momento. Su iOS il sistema non garantisce l'esecuzione in background, quindi non si programma nulla. |
| RMP-50, A-26 | Chi crea la partita sceglie la cadenza (le stesse dell'orologio contro il computer, oppure «Senza orologio») e la scelta viaggia nell'invito (`tc=minuti+incremento`, al massimo 180+60; una cadenza non valida rende nullo l'invito). Ogni mossa porta il tempo che resta a chi l'ha giocata, incremento compreso: i due orologi si riallineano a ogni mossa senza dipendere dalla latenza. Il tempo parte con la prima mossa e il primo tratto del Bianco non costa nulla. Chi resta senza tempo dichiara la scadenza (`FlagMessage`, firmato e cifrato): l'avversario vince, o patta se non ha materiale per il matto. Se un avversario a tempo scaduto non si fa vivo entro 15 secondi, la vittoria si assegna dal proprio telefono. I tempi e l'inizio del turno si salvano con la partita e il tempo scorre anche ad app chiusa. A distanza (A-26) chi crea sceglie tra due modi che si escludono: **lampo** con la stessa cadenza e l'orologio dal vivo, per chi gioca con l'app aperta (tolleranza sulla scadenza dell'avversario 60 secondi invece di 15, perché i relay ritardano), oppure **lenta** con un tempo per mossa di 1, 3 o 7 giorni (`dm=1\|3\|7`, valido solo con `r=1` e senza `tc`). Nella lenta non c'è orologio: il tempo parte con la prima mossa e riparte a ogni mossa; la schermata mostra la scadenza di chi è di turno. Passata la scadenza, chi attende può reclamare la vittoria («Reclama la vittoria»): parte un `ClaimMessage` firmato e cifrato con il numero di semimosse; chi lo riceve lo accetta solo se per il proprio orologio il tempo è scaduto, con 2 ore di tolleranza (`claimTolerance`), altrimenti lo ignora. Il reclamo è provvisorio per chi lo manda: se l'avversario lo ha ignorato perché per lui il tempo non era scaduto (la sua scadenza parte alla ricezione della mossa, quindi può essere in ritardo rispetto alla nostra) e poi muove, la partita si riapre anche su chi aveva reclamato. Reclamo e scadenza non sopravvivono alla chiusura dell'app: alla ripresa la partita torna in corso su entrambi i telefoni e si può reclamare di nuovo. La scadenza si salva con la partita (`turnStartedAt`) e un controllo al minuto mostra il comando appena serve. |
| RMP-06 | Cambiare canale non cambia la partita. Chi è rimasto indietro chiede le mosse mancanti e si rimette in pari; una mossa non partita si ripete quando un canale torna disponibile e, finché resta in attesa, ogni 15 secondi. La triplice ripetizione e la regola delle 50 mosse chiudono la partita in patta in automatico, uguale sui due telefoni (come `ChessGame.endReason`). |

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
       └─ relay Nostr       NostrTransport
```

| File | Ruolo |
|---|---|
| `game_invite.dart` | `GameInvite`: link `rokko://partita?v=1&g=<uuid>&s=<segreto>&k=<chiave>&c=w|b[&lan=host:porta][&tc=minuti+incremento][&r=1][&ble=1]`, campi binari in Base64 URL senza padding; i link col vecchio schema `scacchi://` si leggono ancora, si scrive sempre `rokko://`. `newGameId`, `newSecret` usano `Random.secure`. |
| `player_identity.dart` | `PlayerIdentity`: coppia di chiavi Ed25519; il seme di 32 byte è salvato con la partita (`saved_game.dart`). |
| `game_message.dart` | Messaggi: `JoinMessage` (l'invitato si presenta), `MoveMessage` (semimossa, UCI, impronta, tempo residuo facoltativo `c` in millisecondi), `FlagMessage` (tempo scaduto dopo N semimosse), `SyncRequest` (rimandare da una semimossa). |
| `message_codec.dart` | `MessageCodec`: sigillo dei messaggi. |
| `game_sync.dart` | `GameSync`: registro e validazione. `positionHash`: SHA-256 del FEN, primi 128 bit in esadecimale. |
| `transport.dart` | `MessageTransport`, `MultiTransport`, `LoopbackTransport` (in memoria, per i test), `ConnectionAware` per i canali che segnalano un collegamento nuovo. |
| `lan_discovery.dart` | `LanDiscovery` e `BonsoirLanDiscovery` (pacchetto `bonsoir`, MIT): annuncio e ricerca mDNS; `lanServiceName`. |
| `channel_registry.dart` | `ChannelFactory` e `extraChannelFactories`: dove si registra un canale in più (Bluetooth LE, relay). |
| `lan_transport.dart` | `LanTransport`: canale Wi-Fi su TCP (vedi sotto). |
| `match_clock.dart` | `MatchClock`: il `ChessClock` delle partite contro il computer guidato dal registro; ricostruito dai tempi delle mosse e dall'inizio del turno. |
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
- **Pacchetti.** Ogni scrittura o notifica porta al più `MTU - 3` byte (20 finché la MTU non è nota). Intestazione di 4 byte: id del messaggio (2), indice (1), numero di frammenti (1). `BleReassembler` ricompone in qualunque ordine (l'id parte da un numero casuale), ignora i doppioni e tiene al massimo 4 messaggi incompleti e 2048 byte per messaggio; frammenti incoerenti si scartano in silenzio.
- **Collegamenti.** L'ospite accetta scritture solo da telefoni iscritti alle sue risposte e tiene al massimo 3 telefoni iscritti e, oltre, scollega il più vecchio. Il Bluetooth non autentica nessuno: come per il Wi-Fi, chi non ha il segreto dell'invito non produce messaggi validi.
- **Permessi.** Android 12 e successivi: `BLUETOOTH_SCAN` (`neverForLocation`), `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`, richiesti a runtime solo quando si sceglie il Bluetooth. Android 11 e precedenti: `BLUETOOTH`, `BLUETOOTH_ADMIN` e `ACCESS_FINE_LOCATION` con `maxSdkVersion="30"`; la posizione non viene letta né salvata (il sistema la pretende per cercare dispositivi BLE e il GPS deve essere acceso). iOS: `NSBluetoothAlwaysUsageDescription`. Tutti i motivi sono in `tool/policy.json`.
- **Limiti noti.** Si gioca in primo piano: in background iOS limita annunci e ricerche; il controllo in background delle mosse passa solo dal relay, non dal Bluetooth. La portata è quella del BLE (qualche metro). Un invio riuscito vuol dire consegnato al sistema operativo, come nel Wi-Fi; la mossa si ripete al ricollegamento. Se il Bluetooth si spegne o un permesso viene tolto dopo il controllo iniziale, il canale non parte e l'errore resta nel registro di debug: la schermata continua a mostrare l'attesa. Come ogni radio aperta, il BLE si può disturbare: chi è vicino e ha l'id del servizio può occupare uno dei 3 posti dell'ospite o interferire con i frammenti in arrivo, ma non può falsificare né leggere le mosse; i messaggi persi si richiedono con la sincronizzazione del registro. Verificato in automatico con una radio finta in memoria (`ble_link_test.dart`); la prova su due telefoni veri è manuale.

### Grafica della schermata

I componenti sono in `lib/multiplayer/multiplayer_widgets.dart`. `ConnectionIndicator` mostra una voce per canale (`LinkChannel`: Wi-Fi, Bluetooth, a distanza) con icona, nome e stato (`LinkLevel`: collegato, in collegamento, non raggiungibile); lo stato si legge dalla forma dell'icona e dal testo, non solo dal colore, ed è annunciato dal lettore di schermo. Un canale nuovo si aggiunge come voce di `_channels` in `MultiplayerGamePage` e di `LinkChannel`. `InviteCard` mostra il QR, sempre nero su bianco con margine fisso anche nel tema scuro, con la didascalia «Mostra questo codice al tuo amico». I testi nuovi sono in `lib/l10n/<lingua>/multiplayer_ui.arb`; i golden fedeli (tema Rokko, font reali) in `test/golden/multiplayer_golden_test.dart`.

### Dal foglio Nuova partita

Il foglio **Nuova partita** (vedi [interfaccia.md](interfaccia.md)) è un menu: «Inizia partita» in testa e le voci grandi sotto. **Sfida un amico** è una scelta a gradini: prima dove si gioca, **Sullo stesso telefono** (la partita a due di sempre, con nomi, variante, handicap e tempo) oppure **Ognuno sul suo telefono**; poi, per i due telefoni, come ci si raggiunge. La pagina dei due telefoni è `FriendGamePanel`: colore, «Come collegarvi» con tre scelte (**Wi-Fi** o hotspot, **Bluetooth**, **A distanza**) e una riga che spiega quella scelta, la sezione **Cadenza** e i comandi «Crea la partita», «Unisciti con il QR» e «Unisciti con il link». La distanza è un canale come gli altri. La cadenza compare solo per Wi-Fi e Bluetooth; a distanza al suo posto una riga dice che l'orologio non c'è. Toccare una cadenza la sceglie senza avviare nulla: la partita parte dai comandi. «Sfida un amico» non c'è nel profilo bambino, che ha la scelta semplice di sempre.

`FriendGamePanel` (in `lib/multiplayer/multiplayer_page.dart`) tiene lo stato della preparazione e la logica di avvio e ripresa; la pagina Home › Gioca con un amico lo riusa dentro una scheda. La partita salvata si riprende da entrambi i punti d'ingresso.

### Schermata

`MultiplayerPage` (voce Home › Gioca con un amico) mostra i tre passi (crea, inquadra, gioca) e sotto lo stesso `FriendGamePanel`: scelta del colore, «Come collegarvi» (Wi-Fi, Bluetooth o A distanza), la cadenza (tranne a distanza), «Crea la partita», «Unisciti con il QR» e «Unisciti con il link». `MultiplayerController` tiene lo stato per l'interfaccia: crea identità e invito per partita, apre il canale con `openLanHost` (indirizzo IPv4 privato scelto da `pickLanAddress` preferendo Wi-Fi e hotspot ed escludendo dati mobili e VPN, porta scelta dal sistema) o `openLanGuest`, e avvisa a ogni mossa. L'invito si mostra una sola volta come QR del link `rokko://`, non a ogni mossa; la fotocamera riusa il lettore dello scambio QR. `MultiplayerGamePage` mostra il QR finché l'avversario non arriva, poi la scacchiera orientata dal proprio lato, con le mosse permesse solo al proprio turno.

Su Android il permesso `INTERNET` è dichiarato con il motivo in `tool/policy.json`; su iOS `NSLocalNetworkUsageDescription` spiega l'uso della rete locale. Nessun socket si apre finché non si crea o si inquadra un invito. `NSBonjourServices` dichiara solo `_rokko-chess._tcp`; su Android `bonsoir` aggiunge `CHANGE_WIFI_MULTICAST_STATE` (in `tool/policy.json` tra i permessi aggiunti dalle librerie).

### Regole del registro

- Le semimosse dispari sono del Bianco, le pari del Nero. Una semimossa del proprio colore viene accettata solo se porta la propria firma: succede nel recupero, quando l'avversario rimanda i messaggi originali. L'avversario non può quindi muovere al posto dell'altro, nemmeno fingendo un buco nel registro.
- Semimossa già nota con stesso contenuto: doppione, ignorato (i canali paralleli consegnano più copie). Con contenuto diverso: rifiutata.
- Semimossa oltre la successiva attesa: buco nel registro (`Gap`); la sessione invia `SyncRequest` e l'avversario rimanda, identici, i messaggi sigillati di ogni semimossa, ciascuno con la firma del suo autore. Numeri oltre 2000 semimosse sono scartati.
- L'invitato si presenta con `JoinMessage`, ma anche la sua prima mossa vale come presentazione: se la mossa arriva prima (i canali non garantiscono l'ordine), la partita non si blocca.
- Se l'avversario ripete una mossa più vecchia della nostra ultima, oppure rientra con un nuovo `JoinMessage`, significa che forse non ha ricevuto la nostra: la sessione la rimanda.
- I messaggi in arrivo si elaborano uno alla volta, nell'ordine di arrivo.
- A partita finita non si accettano altre mosse.

### Gioco a distanza (relay Nostr)

| File | Ruolo |
|---|---|
| `nostr_event.dart` | `NostrEvent` (id e firma NIP-01, forma validata) e `RelayKeys` (chiave e slot derivati dal segreto). |
| `nostr_transport.dart` | `NostrTransport`, relay predefiniti (`defaultRelays`) e `openNostrChannel`, registrato in `channel_registry.dart`. |
| `remote_turn_check.dart` | `checkRemoteGame`: collegamento unico al relay con la partita salvata e avviso una volta per mossa. |
| `remote_watch.dart`, `remote_watch_task.dart` | `RemoteWatch` / `BackgroundRemoteWatch` (WorkManager), lavoro in background, notifica locale e registro degli avvisi. |

Come funziona: ogni telefono scrive nei propri 4 slot (eventi sostituibili con `d` casuale per partita e lato) e ascolta quelli dell'altro. Poiché i turni si alternano, un telefono può perdere al massimo l'ultima mossa dell'altro, e quella resta sul relay finché non ne arriva una nuova: per questo basta conservare pochi eventi. I 4 slot a rotazione evitano che un messaggio di servizio (richiesta di recupero, presentazione) cancelli l'ultima mossa ancora da consegnare. Il contenuto è sempre il messaggio sigillato di `MessageCodec`: il relay non può leggerlo né falsificarlo, e chi ha la chiave Nostr (derivata dal segreto) non può comunque firmare mosse a nome dell'avversario.

L'invito a distanza ha `r=1`. Il canale si apre dal registro dei canali solo con `r=1`; gli eventi si firmano con la chiave della partita, quindi qualunque relay li accetta senza account. I relay predefiniti sono quattro pubblici (`relay.damus.io`, `nos.lol`, `relay.primal.net`, `offchain.pub`); ne basta uno. Cambiare l'elenco è una riga in `defaultRelays`; un relay proprio sarebbe un altro valore dello stesso elenco.

Controllo in background: `BackgroundRemoteWatch` registra un lavoro periodico di WorkManager (Android) che chiama `checkRemoteGame` in un isolate a parte: legge `multiplayer.json`, apre il canale, aspetta fino a 15 secondi e, se il registro cresce, mostra la notifica. Il registro degli avvisi (`PrefsNotifiedLog`) tiene in `shared_preferences` fino a quale mossa si è già avvisato. Il ritardo tipico è di 15 minuti, adeguato alla corrispondenza. Android 13 e successivi chiedono il permesso delle notifiche quando parte la prima partita a distanza.

Limiti noti: i relay pubblici possono rifiutare o perdere eventi (per questo se ne usano più d'uno e si ripubblica a ogni ricollegamento); vedono l'indirizzo IP dei telefoni e l'ora delle mosse. I test usano un relay finto e canali in memoria: la prova su relay e telefoni veri è manuale, come quella del lavoro in background, che su iOS non esiste. Una partita a distanza è per corrispondenza e non ha orologio.

### Orologio

`MultiplayerController.clock` esiste solo se l'invito porta una cadenza; i testi sono in `lib/l10n/<lingua>/multiplayer_clock.arb`.

- Ogni telefono è autorevole sul proprio tempo: dopo la propria mossa legge il residuo dal `MatchClock` e lo spedisce con la mossa; chi riceve lo adotta e fa partire l'orologio dell'avversario. Non si compensa la latenza: chi riceve parte con un ritardo di pochi millisecondi, a suo vantaggio, e un tempo dichiarato non può superare quello della mossa precedente più l'incremento (alla prima mossa, il tempo iniziale più l'incremento).
- Un timer da 100 ms (`tick`) controlla il proprio orologio con l'ora di parete: a tempo scaduto il telefono dichiara la sconfitta, non accetta altre mosse e avvisa l'avversario; il messaggio si ripete a ogni nuovo collegamento.
- Il telefono non dichiara mai la scadenza dell'altro: la stima locale è in anticipo della latenza. Solo se l'avversario resta a zero oltre `peerFlagGrace` (15 s) la vittoria si assegna senza suo messaggio, ad esempio perché ha chiuso l'app; una sua mossa valida arrivata prima vince sul tavolino e l'orologio riparte.
- Una partita a distanza (`r=1`) può avere l'orologio dal vivo (lampo, `tc`) oppure un tempo per mossa in giorni (lenta, `dm`), mai entrambi; senza scelta resta senza orologio. Scegliere uno dei due azzera l'altro. La prova su telefoni veri con un `integration_test` resta manuale.

## Sicurezza (OWASP MASVS)

| Area | Misura |
|---|---|
| MASVS-CRYPTO | Ed25519, AES-256-GCM, HKDF-SHA256 dal pacchetto `cryptography`; nonce casuale per ogni messaggio; segreti da `Random.secure`. |
| MASVS-NETWORK | Cifratura end-to-end su ogni canale, anche locale; il relay non legge né falsifica le mosse. |
| MASVS-CODE | Invito e messaggi sono input non fidato: limiti di lunghezza, validazione di ogni campo, scarto silenzioso. |
| MASVS-AUTH | Nessun account: l'identità è la chiave Ed25519; la chiave dell'avversario si fissa al primo ingresso. |
| MASVS-PRIVACY | Nessun dato personale; il relay vede solo byte cifrati, una chiave casuale per partita e l'indirizzo IP di chi si collega; il canale a distanza si apre solo se l'invito lo prevede (`r=1`). |
| MASVS-PLATFORM | Nessun link profondo né schema URL registrato: il link d'invito si incolla da dentro l'app. Il lavoro in background non è esportato e WorkManager non usa servizi in primo piano. |

Limiti noti: l'invito contiene il segreto, quindi chi lo intercetta prima dell'avversario può occupare la partita (l'ospite vedrà una chiave diversa da quella attesa). Il salvataggio contiene il seme privato della partita: sta nella cartella privata dell'app, escluso dai backup di Android (`allowBackup="false"`), ma incluso nel file di backup che l'utente crea da sé (vedi [backup.md](backup.md)); su iOS segue il backup del dispositivo, cifrato. Chi legge il file può firmare al posto del giocatore, ma solo in quella partita: l'identità è generata per ogni partita. Se l'indirizzo dell'ospite cambia dopo il riavvio, l'invitato lo ritrova con la ricerca mDNS (RMP-10), purché i due telefoni siano ancora nella stessa rete.

## Test

`flutter test test/multiplayer`: `remote_clock_test.dart` (invito con `dm`, `ClaimMessage`, lampo a distanza, partita lenta: scadenza, reclamo, reclamo anticipato ignorato, tolleranza, salvataggio), `multiplayer_clock_test.dart` (cadenza nell'invito, tempo nelle mosse, tempo scaduto, patta per materiale insufficiente, ripresa col tempo trascorso, schermata a tempo); Bluetooth (`ble_fragmenter_test.dart`: frammenti in disordine, doppi, incoerenti, memoria limitata; `ble_transport_test.dart`: canale su un collegamento in memoria; `ble_link_test.dart`: ospite e invitato su una radio finta, permessi, Bluetooth spento, ricollegamento, limite di collegamenti; `multiplayer_bluetooth_test.dart` e `multiplayer_bluetooth_page_test.dart`: partita intera, ripresa e schermata), eventi Nostr e chiavi (`nostr_event_test.dart`), canale su un relay finto in memoria (`nostr_transport_test.dart`, `fake_relay.dart`: slot, relay spento o che non risponde, caduta e ritorno, eventi falsi), controller e schermata a distanza (`remote_controller_test.dart`, `remote_page_test.dart`), controllo e testi degli avvisi (`remote_turn_check_test.dart`, `remote_watch_test.dart`); salvataggio e ripresa (`saved_game_test.dart`), invito, sigillo, registro, canali e sessione completa con canali in memoria, compreso il passaggio Wi-Fi → relay → Wi-Fi e il recupero dopo un ripristino. `lan_transport_test.dart` usa socket TCP veri su 127.0.0.1: pacchetti spezzati, pacchetti troppo grandi, limite di collegamenti, ricollegamento senza invii, chiusura durante il collegamento, una partita completa e una mossa consegnata dopo la caduta del collegamento. `multiplayer_controller_test.dart` e `multiplayer_page_test.dart` provano stato e schermata con canali in memoria e un lettore QR finto: attesa, turni, matto, nuovi tentativi dell'invitato, assenza di Wi-Fi, QR estraneo e conferma d'uscita. `test/game/new_game_friend_test.dart` prova le scelte «Sfida un amico» e «Ognuno sul suo» nel foglio Nuova partita (sezioni mostrate e nascoste, cadenza solo in presenza, scelte conservate, profilo bambino) e i golden `nuova-partita-amico-*` la mostrano su tre telefoni.
