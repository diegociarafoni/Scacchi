# Multigiocatore tra due telefoni

Partita tra due persone su due telefoni, pensata per funzionare in ogni situazione: sulla stessa Wi-Fi o hotspot, vicini senza Wi-Fi (Bluetooth LE), a distanza tramite relay Nostr, tra Android e iOS. Una partita iniziata in presenza continua a distanza e torna in presenza senza azioni dell'utente. Il gioco da soli resta interamente offline: il multigiocatore è un modulo opzionale in `lib/multiplayer/`.

## Stato

| Fase | Contenuto | Stato |
|---|---|---|
| 1 | Nucleo del protocollo: invito, identità, cifratura, registro delle mosse, canali multipli | Disponibile (senza interfaccia) |
| 2 | Canale Wi-Fi locale con ricerca mDNS e abbinamento via QR | Da fare |
| 3 | Canale Bluetooth LE | Da fare |
| 4 | Relay Nostr, link d'invito, notifiche in background, schermate | Da fare |

## Requisiti

| ID | Requisito |
|---|---|
| RMP-01 | Una partita nasce da un invito (QR all'abbinamento o link condiviso) con UUID v4, segreto di 256 bit, chiave pubblica dell'ospite, colore dell'ospite e, facoltativo, indirizzo in rete locale. Un invito non valido viene scartato. |
| RMP-02 | Le mosse sono numerate (semimossa da 1) e accompagnate dall'impronta della posizione risultante; i due telefoni tengono lo stesso registro. Si rifiutano mosse illegali, fuori turno, in contrasto con il registro o con posizione diversa; i doppioni si ignorano. |
| RMP-03 | Ogni messaggio è firmato dal suo autore (Ed25519). L'ospite fissa la chiave dell'avversario al primo ingresso; i messaggi di altre chiavi vengono scartati. |
| RMP-04 | Ogni messaggio è cifrato end-to-end (AES-256-GCM); canali e relay vedono solo byte casuali. Messaggi alterati, di altre partite o con un altro segreto vengono scartati. |
| RMP-05 | I canali disponibili si usano insieme: si invia su tutti, basta che uno consegni; si riceve da tutti in un solo flusso. |
| RMP-06 | Cambiare canale non cambia la partita. Chi è rimasto indietro chiede le mosse mancanti e si rimette in pari; una mossa non partita si ripete quando un canale torna disponibile. |

Questi requisiti sostituiscono, per il solo modulo multigiocatore, l'esclusione delle partite tra persone su più dispositivi e il vincolo "nessun permesso di rete" di RNF-01, che resta valido per il gioco da soli.

## Architettura

La partita non appartiene a un canale: è un registro di mosse identico sui due telefoni. I canali sono "postini" intercambiabili che portano byte opachi.

```
MultiplayerSession          lib/multiplayer/multiplayer_session.dart
  ├─ GameSync               registro, regole, chiavi (Dart puro, sincrono)
  ├─ MessageCodec           firma + cifratura dei messaggi
  └─ MultiTransport         tutti i canali insieme
       ├─ Wi-Fi locale      (fase 2)
       ├─ Bluetooth LE      (fase 3)
       └─ relay Nostr       (fase 4)
```

| File | Ruolo |
|---|---|
| `game_invite.dart` | `GameInvite`: link `scacchi://partita?v=1&g=<uuid>&s=<segreto>&k=<chiave>&c=w|b[&lan=host:porta]`, campi binari in Base64 URL senza padding. `newGameId`, `newSecret` usano `Random.secure`. |
| `player_identity.dart` | `PlayerIdentity`: coppia di chiavi Ed25519; il seme di 32 byte andrà nel portachiavi di sistema (fase 2). |
| `game_message.dart` | Messaggi: `JoinMessage` (l'invitato si presenta), `MoveMessage` (semimossa, UCI, impronta), `SyncRequest` (rimandare da una semimossa). |
| `message_codec.dart` | `MessageCodec`: sigillo dei messaggi. |
| `game_sync.dart` | `GameSync`: registro e validazione. `positionHash`: SHA-256 del FEN, primi 128 bit in esadecimale. |
| `transport.dart` | `MessageTransport`, `MultiTransport`, `LoopbackTransport` (in memoria, per i test). |
| `multiplayer_session.dart` | `MultiplayerSession`: collega registro, sigillo e canali e reagisce ai messaggi. |

### Formato del messaggio sigillato

```
nonce (12 byte) | AES-256-GCM( {"a": chiave autore, "b": corpo JSON, "s": firma} ) | MAC (16 byte)
```

- Chiave AES derivata con HKDF-SHA256 dal segreto dell'invito, con l'UUID come sale e `scacchi-messaggi-v1` come contesto; l'UUID è anche dato autenticato aggiuntivo, quindi un messaggio non si sposta da una partita all'altra.
- La firma Ed25519 copre `scacchi-mossa-v1|<uuid>|`, la chiave dell'autore e il corpo: chi conosce il segreto (l'avversario) può cifrare, ma non può firmare a nome dell'altro.
- Oltre 1024 byte un messaggio non viene neppure decifrato; ogni errore di formato porta allo scarto silenzioso (dati del canale non fidati, MASVS-CODE-4).

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

Limiti noti: l'invito contiene il segreto, quindi chi lo intercetta prima dell'avversario può occupare la partita (l'ospite vedrà una chiave diversa da quella attesa). I messaggi sigillati restano per ora in memoria: il salvataggio insieme alla partita, necessario per il recupero dopo un riavvio, arriva con la fase 2.

## Test

`flutter test test/multiplayer`: invito, sigillo, registro, canali e sessione completa con canali in memoria, compreso il passaggio Wi-Fi → relay → Wi-Fi e il recupero dopo un ripristino.
