# Backlog di Rokko

Documento unico di riferimento per le funzioni dell'app: sostituisce il vecchio elenco delle evolutive, il documento dei requisiti e l'analisi delle lacune. Aggiornato il 13 ottobre 2026 sul codice di `main` di `diegociarafoni/rokko`.

Gli identificativi (RF, RG, RP, RM, RNF, RV, RMP) sono quelli già usati nei nomi dei test e nei documenti di `docs/`: non vanno cambiati. Gli identificativi S e U sono le evolutive di storia e interfaccia.

## Come si legge

- **Stato**: *fatta* (nel codice e in `docs/`), *parziale* (c'è, ma manca una parte indicata), *da fare*.
- **Priorità**: P0 indispensabile, P1 alto valore, P2 evolutivo. Le priorità delle voci S e U sono ancora da assegnare da Diego (proposta nella colonna versione).
- **Dimensione**: piccola (giorni), media (una o due settimane), grande (più settimane o scelta di prodotto).
- **Versione**: 0.11.0 contiene solo il multilingue. Il resto è proposto dalla 0.12.0 in poi, nell'ordine della sezione «Piano di rilascio».
- Metodo: ogni funzione nasce dai test scritti dai requisiti, poi il codice minimo, poi `docs/` (vedi `docs/sviluppo.md`).

## Principi e vincoli (RV)

Rokko è open source e gratuito. Questi vincoli valgono per ogni voce.

| ID | Vincolo | Stato | Note |
|---|---|---|---|
| RV-01 | Nessun livello a pagamento, abbonamento o acquisto: revisioni, puzzle e lezioni sono libere e senza limiti giornalieri | fatta | |
| RV-02 | Nessuna pubblicità, nessun tracciamento, nessun account obbligatorio; nessun dato lascia il dispositivo senza un'azione esplicita | fatta | |
| RV-03 | Codice sotto GPL-3.0 (o successiva); licenza e sorgenti visibili nella schermata «Informazioni» | parziale | manca la schermata (vedi A-15) |
| RV-04 | Asset con licenza compatibile con la GPL, elencati con attribuzione in `CREDITS.md` e in «Informazioni» | parziale | `CREDITS.md` c'è, manca la schermata |
| RV-05 | Il permesso per gli store vale solo per il codice del progetto; verifica scritta della compatibilità con la GPL del motore prima della pubblicazione su iOS | parziale | `docs/licenza.md` e `NOTICE.md` dichiarano il permesso, manca l'esito scritto |

## Piano di rilascio

| Versione | Tema | Contenuto |
|---|---|---|
| 0.11.0 | Multilingue | Solo la traduzione dei testi (U4), già in corso |
| 0.12.0 | Giocare meglio | Premossa, frecce e cerchi, schermo acceso, tocco, cadenze libere e ritardo, annullamento con consenso, barra di valutazione in partita, comandi di partita (U1, U3, U7), icone più curate (U12) |
| 0.13.0 | Studiare meglio | Varianti salvate in PGN, note ovunque, mosse «Libro» nella revisione, cache persistente, precisione per fase nelle statistiche, scheda Tu e impostazioni in sezioni (U5, U6), funzioni scopribili (U10) |
| 0.14.0 | Pronta per gli store | Schermata «Informazioni», dichiarazioni sulla privacy, architetture del motore, iOS e F-Droid, dimensione, riduzione animazioni, schermo diviso e pieghevoli, persistenza e migrazioni, avvio rapido, identità visiva e golden (U2, U8) |
| 0.15.0 | Storia, tornei e progressi | Evolutive della storia (S1-S6), badge di multigiocatore e ripasso, percorso «dai miei errori», tornei con partite reali, orologio nelle partite a distanza, profilo bambino e multigiocatore coerenti (U9, U11) |
| Dopo | Da valutare | Bot «ombra», lettura della posizione da fotocamera, altre varianti, modalità alla cieca in partita, widget della Home, scacchiere Bluetooth e le idee in fondo al documento |

## A. Da fare o parziali

### A.1 Partita e scacchiera

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-1 / RF-08 | **Premossa**: muovere durante il turno dell'avversario, annullabile toccando una casa vuota, con opzione nelle impostazioni | da fare | P0 | media | 0.12.0 | `lib/game/game_page.dart:898-907` blocca la scacchiera mentre il computer pensa; esiste solo il colore `validPremoves` |
| A-2 / RF-05 | **Frecce e cerchi** con almeno tre colori, pressione prolungata e trascinamento su touch, rimossi al tocco successivo | parziale | P0 | piccola | 0.12.0 | `lib/settings/settings.dart:589` abilita il disegno; mancano scelta colori e test che disegni una forma |
| A-3 / RF-22 | **Allenamento e Sfida**: scelta esplicita della modalità e barra di valutazione durante la partita (oggi solo in analisi e revisione) | parziale | P0 | media | 0.12.0 | `EvalBar` usata in `lib/review/` e `lib/analysis/`; `docs/avversario-computer.md` dichiara «in parte» |
| A-4 / RF-32 | **Annullamento con consenso** dell'altro giocatore nella partita a due | parziale | P0 | piccola | 0.12.0 | la patta chiede consenso (`game_page.dart:2158`), «Annulla» no |
| A-5 / RF-40 | **Cadenza personalizzata** con minuti e incremento liberi, e **ritardo** (semplice e Bronstein); in seguito cadenze a più fasi (per esempio 40 mosse in 90 minuti più 30) anche per la scacchiera fisica | parziale | P0 | media | 0.12.0 | `lib/game/clock.dart`: `TimeControl` ha solo minuti e incremento e i preset |
| A-6 / RM-02 | **Tocco**: correzione quando il dito cade sul bordo di una casa; due tocchi come modo predefinito su telefono | parziale | P0 | piccola | 0.12.0 | `lib/game/board_swipe.dart` evita solo le mosse durante lo scorrimento |
| A-7 / RM-06 | **Schermo sempre acceso** durante la partita | da fare | P0 | piccola | 0.12.0 | nessun wakelock in `lib/`, `pubspec.yaml`, `android/`, `ios/` |
| A-8 / RM-07 | **Avvio rapido**: pronta a giocare in meno di 2 secondi su un telefono di fascia media, con misura e budget in CI | parziale | P0 | piccola | 0.14.0 | `integration_test/fluidita_perf.dart` misura la fluidità, non l'avvio |
| A-9 / RF-31 | **Modalità tavolo**: ruotare di 180° tutti i pezzi del lato superiore, non solo quelli del giocatore in alto | parziale | P0 | piccola | 0.12.0 | `tableMode` in `lib/settings/settings.dart`; da confermare se la differenza conta |

### A.2 Analisi, revisione, archivio

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-10 / RF-52 | **Varianti ad albero salvate**: salvataggio dell'analisi, esportazione e import in PGN con le varianti tra parentesi | parziale | P1 | media | 0.13.0 | `lib/analysis/variation_tree.dart` vive solo con la pagina (`docs/analisi.md`, «Limiti attuali»); `lib/archive/pgn.dart` tiene la sola linea principale |
| A-11 / RF-55 | **Annotazioni** (commento e simbolo) modificabili anche nell'analisi, sulle varianti e dall'archivio | parziale | P1 | media | 0.13.0 | `lib/game/move_note.dart` e la revisione sì; `analysis_page.dart` e `archive_page.dart` non usano `MoveNote` |
| A-12 / RF-91 | **Mosse «Libro»** nella revisione e nell'allenatore | parziale | P1 | piccola | 0.13.0 | `OpeningBook.bookPlies` (`lib/openings/opening_book.dart:131`) e `reviewGame(isBook:)` non sono collegati (`docs/revisione-partita.md:43`) |
| A-13 / RF-66 | **Cache della revisione** nel database locale, con versione del motore e profondità nella chiave | parziale | P1 | media | 0.13.0 | `ReviewCache` (`lib/review/review_page.dart:28`) è una mappa in memoria di 20 voci |
| A-14 / RF-68 | **Precisione per fase** nelle statistiche, con la media nel tempo | parziale | P1 | piccola | 0.13.0 | `GameReview.accuracyByPhase` c'è; `lib/stats/` non ha riferimenti alle fasi |

### A.3 Piattaforma, rilascio, qualità

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-15 / RV-03, RV-04 | **Schermata «Informazioni»** con licenza GPL, link ai sorgenti e crediti degli asset | da fare | P0 | piccola | 0.14.0 | nessuna schermata né `showLicensePage` in `lib/` |
| A-16 / RV-05 | **Verifica scritta** della compatibilità dell'App Store con la GPL del motore | parziale | P0 | piccola | 0.14.0 | `docs/licenza.md`, `NOTICE.md` |
| A-17 / RNF-10 | **Dichiarazioni «nessun dato raccolto»**: `PrivacyInfo.xcprivacy`, testi per le schede di sicurezza dei dati degli store, `ITSAppUsesNonExemptEncryption` | parziale | P0 | piccola | 0.14.0 | `docs/sicurezza.md`, «Da fare» |
| A-18 / RNF-03 | **Motore per tutte le architetture** (Android armv7 e x86_64 oltre ad arm64) | parziale | P0 | piccola | 0.14.0 | `docs/rilascio-android.md:71-74` |
| A-19 / RNF-02 | **iOS e F-Droid**: build iOS in CI, Fastlane per TestFlight, metadati e ricetta per F-Droid | parziale | P0 | grande | 0.14.0 | `docs/store.md`: iOS «non ancora configurato»; nessun file F-Droid |
| A-20 / RNF-04 | **Dimensione sotto i 60 MB**, con valutazione di una rete NNUE più piccola e misura dell'impatto sulla forza | parziale | P0 | media | 0.14.0 | circa 63 MiB e tetto a 80 MB in `tool/policy.json` (`docs/qualita.md:30-32`) |
| A-21 / RNF-06 | **Layout adattivo** con schermo diviso e pieghevoli, e test sulle due colonne | parziale | P0 | media | 0.14.0 | due colonne in `game_page.dart:2586` e poche altre schermate |
| A-22 / RNF-07 | **Ridurre le animazioni** anche dall'impostazione di sistema, con test | parziale | P0 | piccola | 0.14.0 | solo `lib/story/story_page.dart:833` rispetta `MediaQuery.disableAnimationsOf` |
| A-23 / RNF-08 | **Persistenza**: oggi file JSON versionati (`lib/storage/json_file.dart`). Decidere per iscritto se restare su JSON e aggiungere la catena di migrazioni (piccola), o passare a un database locale (grande). Proposta: restare su JSON | da fare | P0 | piccola | 0.14.0 | `JsonFile` rifiuta tutto ciò che non è tra 1 e la versione corrente |

### A.4 Progressi, tornei, multigiocatore

| ID | Funzione | Stato | Pri | Dim | Versione | Evidenza |
|---|---|---|---|---|---|---|
| A-24 / RG-17 | **Badge** del multigiocatore e del ripasso del repertorio | da fare | P1 | media | 0.15.0 | `docs/badge.md`, «Non ancora attivi»; nessun aggancio ai progressi in `lib/multiplayer/` |
| A-25 / RG-09 | **Tornei con partite vere** tra i bot e gironi da 4 a 8 giocatori | parziale | P2 | grande | 0.15.0 | le partite tra bot sono simulate con una formula Elo (`docs/tornei.md`); in alternativa dichiarare la scelta (piccola) |
| A-26 / RMP | **Orologio nelle partite a distanza** e prova su telefoni veri con un `integration_test` | parziale | P1 | media | 0.15.0 | `docs/multigiocatore.md` (limiti noti) |
| A-27 | **Percorso «dai miei errori»**: capitoli personali generati dai temi tattici sbagliati più spesso | da fare | P2 | media | 0.15.0 | esistono i puzzle personali (`lib/review/personal_puzzles.dart`) e la coda di ripasso, non agganciati al percorso |

### A.5 Da valutare dopo

| ID | Funzione | Stato | Pri | Dim | Note |
|---|---|---|---|---|---|
| A-28 | **Bot «ombra»** che imita lo stile personale (aperture e tempi di riflessione dall'archivio) | da fare | P2 | grande | ingredienti in `lib/openings/personal_tree.dart` e `lib/engine/style.dart` |
| A-29 | **Lettura della posizione con la fotocamera** (diagramma o scacchiera reale) | da fare | P2 | grande | richiede un modello locale; «Mossa dalla foto» è spenta nelle release dal flag `ROKKO_PHOTO_MOVE` |
| A-30 | **Altre varianti** (Crazyhouse, Atomica, Antichess, Orda, Corsa dei re) | da fare | P2 | media | le regole sono supportate da `dartchess`; per giocarle contro il computer serve il motore in Dart di RF-123 |
| A-31 | **Modalità alla cieca in partita**: pezzi nascosti, mosse a voce o da tastiera, comandi per chiedere dove sono i propri pezzi | da fare | P2 | media | oggi esiste solo il minigioco di visualizzazione (RG-10) |
| A-32 | **Widget della schermata home** con il puzzle del giorno e la serie | da fare | P2 | media | |
| A-33 | **Scacchiere elettroniche Bluetooth** | da fare | P2 | grande | permessi e protocolli diversi per marca |
| A-34 | **Test più solidi** per le funzioni già fatte: rendering di mosse legali, ultima mossa e coordinate (RF-02, RF-03, RF-07), selettore di promozione (RF-04), conferma della mossa (RF-09), velocità animazioni (RF-12), suono e grafica sotto i 10 secondi (RF-41), vibrazione (RM-03), sospensione del motore in background (RNF-05), promemoria locali (RG-11), tetto di dimensione a 60 MB (RNF-04); ID nei test di RF-68, RF-91, RF-100, RF-103, RF-112 | parziale | P1 | media | verificato per elenco dei test, non eseguendoli |

### A.6 Storia (S) e interfaccia (U)

Il dettaglio di U1-U11 è in l'analisi UX e UI del progetto; il comportamento attuale della storia è in `docs/storia.md`. La storia non è ancora stata provata su un telefono: la prova di Diego sulla 0.8.0 orienta le priorità.

| ID | Funzione | Stato | Pri | Dim | Versione |
|---|---|---|---|---|---|
| S1 | **Un antagonista per capitolo**: carattere, stile di gioco, aperture e due battute prima e dopo la partita | da fare | da assegnare | media | 0.15.0 |
| S2 | **Racconto tra un passo e l'altro**: una riga tra lezione e puzzle che richiama ciò che si è imparato | da fare | da assegnare | piccola | 0.15.0 |
| S3 | **Mappa del viaggio** con i sei luoghi, i progressi e «riprendi da dove eri» | da fare | da assegnare | media | 0.15.0 |
| S4 | **Un bivio per capitolo** (tattica o finali) con puzzle diversi | da fare | da assegnare | media | 0.15.0 |
| S5 | **Ricompense legate alla storia**: scacchiere e pezzi sbloccabili con nome a tema | da fare | da assegnare | piccola | 0.15.0 |
| S6 | **Aiuto quando ci si blocca**: dopo due errori sullo stesso puzzle, un indizio o un puzzle più facile | da fare | da assegnare | piccola | 0.15.0 |
| U1 | **Comandi di partita meno affollati**: 4 azioni in barra, Patta, Abbandona e Nuova in un pannello «Partita»; Allenatore e Minaccia come interruttori | da fare | da assegnare | media | 0.12.0 |
| U2 | **Identità visiva di Rokko**: tema proprio, carattere con personalità, torre-mascotte negli stati vuoti e a fine partita | parziale | da assegnare | media | 0.14.0 |
| U3 | **Layout della partita senza spazio morto** su schermate alte | da fare | da assegnare | media | 0.12.0 |
| U4 | **Testi tutti localizzati** nei file `.arb` | parziale | P1 | grande | 0.11.0 |
| U5 | **Scheda Tu raggruppata** (Impara, Gioca, I miei dati) con «Continua da dove eri» in testa | da fare | da assegnare | media | 0.13.0 |
| U6 | **Impostazioni in sezioni** comprimibili, con ricerca e galleria dei temi | parziale | da assegnare | media | 0.13.0 |
| U7 | **Barra del titolo della partita più semplice**: editor e tastiera nel menu ⋮; tastiera visibile con un lettore di schermo | da fare | da assegnare | piccola | 0.12.0 |
| U8 | **Golden fedeli all'app reale**: tema predefinito e font veri; aggiungere Puzzle, Percorso, Storia, Multigiocatore, Tu e profilo bambino | da fare | da assegnare | media | 0.14.0 |
| U9 | **Profilo bambino coerente** in tutte le schermate, con un test che cerca le cifre nei testi | da fare | da assegnare | media | 0.15.0 |
| U10 | **Funzioni scopribili**: suggerimenti al primo uso e invito a rivedere la prima partita conclusa | da fare | da assegnare | media | 0.13.0 |
| U11 | **Multigiocatore e Percorso più leggibili**: indicatore di connessione, QR con margine e contrasto fissi, tappe bloccate non solo in colore | da fare | da assegnare | piccola | 0.15.0 |
| U12 | **Icone più curate** dopo le traduzioni (richiesta di Diego, 13 ottobre 2026) | da fare | dopo la 0.11.0 | media | 0.12.0 |

Gli «interventi rapidi» (marchio nel titolo, arancione d'azione, gruppi nella scheda Tu, icone nel menu, anteprima comprimibile, font reale nei golden, test sui testi fissi) si possono fare prima delle voci grandi; sono elencati in l'analisi UX e UI del progetto.

### A.7 Idee oltre i requisiti, da valutare

- **Ripasso a cicli** dello stesso insieme di puzzle, sempre più veloci. Piccola, riusa i puzzle esistenti.
- **Revisione vocale a mani libere** con la sintesi vocale del sistema, per rigiocare sulla scacchiera fisica. Media.
- **Simultanea contro i bot**: 3-5 partite contemporanee con passaggio rapido tra le scacchiere. Grande.
- **Esporta GIF** della partita, oltre all'immagine della posizione (RF-104). Media.

## B. Già fatte (verificate sul codice)

Per questa parte contano i test e i documenti di `docs/`; il dettaglio è nei documenti indicati.

### B.1 Scacchiera e partita

| ID | Funzione | Stato |
|---|---|---|
| RF-01 | Mossa con trascinamento e con due tocchi | fatta |
| RF-02 | Mosse legali del pezzo selezionato, disattivabili | fatta |
| RF-03 | Evidenziazione dell'ultima mossa e del re sotto scacco | fatta |
| RF-04 | Promozione con selettore e opzione «promuovi sempre a donna» | fatta |
| RF-06 | Capovolgimento e orientamento automatico | fatta |
| RF-07 | Coordinate interne o esterne, disattivabili | fatta |
| RF-09 | Conferma della mossa opzionale | fatta |
| RF-10 | Lista delle mosse con navigazione a scorrimento e pulsanti | fatta |
| RF-11 | Materiale catturato e differenza | fatta |
| RF-12 | Animazioni con velocità regolabile | fatta |
| RF-20, RF-21 | Computer a otto livelli, in un isolate separato, con ritardo ai livelli bassi | fatta |
| RF-23 | Bot con personalità (`docs/bot.md`) | fatta |
| RF-24 | Partenza da una posizione personalizzata | fatta |
| RF-25 | Fine partita completa, patta accettata dal bot in base alla valutazione | fatta |
| RF-26 | Avversario adattivo | fatta |
| RF-27 | Partite a handicap | fatta |
| RF-30 | Partita a due sullo stesso telefono | fatta |
| RF-41 | Avviso visivo e sonoro con poco tempo | fatta |
| RF-42 | Pausa dell'orologio in background | fatta |
| RF-120, RF-121 | Chess960, Re della collina, Tre scacchi | fatta |
| RF-123 | Varianti anche contro il computer e i bot | fatta |

### B.2 Analisi, revisione, coach

| ID | Funzione | Stato |
|---|---|---|
| RF-50, RF-51, RF-53, RF-54 | Analisi con barra di valutazione, MultiPV da 1 a 3, editor di posizione, frecce della mossa migliore | fatta |
| RF-56 | Minaccia dell'avversario | fatta |
| RF-60 – RF-65 | Revisione in background, classificazione, brillanti e ottime, precisione, grafico, «Riprova» | fatta |
| RF-67 | Tempo per mossa nella revisione | fatta |
| RF-70 – RF-76 | Coach testuale, commento, allenatore, suggerimenti a livelli, notazione a scelta | fatta |
| RF-122 | Modalità «spiegami perché» | fatta |

### B.3 Puzzle, aperture, finali, archivio

| ID | Funzione | Stato |
|---|---|---|
| RF-80 – RF-85 | Raccolta di puzzle, punteggio locale, modalità a tempo, ripasso, temi, puzzle del giorno | fatta |
| RF-86, RF-97 | Allenatore dei finali e finali perfetti | fatta |
| RF-87, RF-88 | Partite dei grandi maestri e «Indovina la mossa» | fatta |
| RF-90, RF-92 – RF-94, RF-96 | Nomi delle aperture, explorer, repertorio a ripetizione, gioca un'apertura, le tue aperture | fatta |
| RF-95 | Sfida a tempo tra amici con i QR | fatta |
| RF-100 – RF-104 | Salvataggio e ripresa, storico, PGN, backup, esporta come immagine | fatta |
| RF-110, RF-111 | Rating locale e statistiche | fatta |

### B.4 Gamification

| ID | Funzione | Stato |
|---|---|---|
| RG-01, RG-02 | XP e livelli, obiettivo giornaliero e serie | fatta |
| RG-03, RG-13 | Percorso a tappe e percorso a storia | fatta |
| RG-04, RG-18 | Scala dei bot e galleria dei bot | fatta |
| RG-05, RG-06 | 37 traguardi, ricompense estetiche e «Sblocca tutto» | fatta |
| RG-07, RG-08 | Sfide giornaliere e settimanali, record personali | fatta |
| RG-10 | Minigiochi (coordinate, cattura tutto, visualizzazione, materiale) | fatta |
| RG-11 | Promemoria locali | fatta |
| RG-12 | Esclusioni etiche (nessuna vita, penalità o valuta) | fatta |
| RG-16 | Riepilogo settimanale | fatta |
| RG-17 | Badge (catalogo di 59; restano A-24) | fatta |

### B.5 Personalizzazione, mobile, non funzionali, proposte

| ID | Funzione | Stato |
|---|---|---|
| RP-01 – RP-05 | Temi di scacchiera, set di pezzi, tema chiaro e scuro, suoni, impostazioni, lingua | fatta |
| RP-06 | Profilo bambino | fatta |
| RP-07 | Modalità zen | fatta |
| RP-08, RP-09 | Avatar simpatici e foto del profilo | fatta |
| RM-01, RM-03, RM-04, RM-05 | Uso con una mano, vibrazione, sessioni brevi con «Continua», interruzioni | fatta |
| RNF-01, RNF-05, RNF-09 | Offline totale, batteria e calore, solo asset con licenza libera | fatta |
| RMP-01 – RMP-07 | Partita tra due telefoni (`docs/multigiocatore.md`; restano A-26) | fatta |
| Cap. 7 | Allenamento dagli errori, scacchiera fisica, scambio di partite con il QR, ritratto del giocatore, sfide a tempo tra amici | fatta |

## C. Esclusioni esplicite

Partite online con sconosciuti, abbinamenti, tornei online, leghe con altri utenti, chat, amici, club, forum, notizie, streaming, classifiche globali, sfide uno contro uno online, lezioni video, spiegazioni basate su intelligenza artificiale remota, statistiche di un database globale di aperture, tabelle di finali a 5 pezzi o più per dimensione.

## D. Note sul controllo

- Verifica fatta il 13 ottobre 2026 leggendo codice, test e documenti; i test non sono stati eseguiti.
- Le voci dei gruppi RF-01, RF-06, RF-10, RF-11, RF-20, RF-21, RF-23 – RF-27, RF-30, RF-42, RM-01, RM-05 e RP-01 – RP-08 sono state verificate soprattutto da elenco dei test e documenti.
- I crediti dei dati e delle librerie di terze parti restano in `CREDITS.md` e `NOTICE.md`, come richiedono le licenze.
