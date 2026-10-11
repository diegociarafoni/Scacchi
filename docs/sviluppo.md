# Sviluppo

## Requisiti

- [Flutter](https://docs.flutter.dev/get-started/install), canale stable, versione 3.47 o successiva (la CI usa 3.47.7).
- Per Android: Android Studio o Android SDK, Java 17.
- Per iOS e macOS: un Mac con Xcode, oppure un servizio di build in cloud.
- Per Linux desktop: le librerie di sviluppo GTK 3 e GStreamer (`libgtk-3-dev`, `libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`) e, per riprodurre i suoni, i plugin `gstreamer1.0-plugins-base` e `gstreamer1.0-plugins-good`: senza questi ultimi l'app si chiude al primo suono.
- Per gli hook locali: [lefthook](https://lefthook.dev) e [Gitleaks](https://github.com/gitleaks/gitleaks), vedi [convenzioni-git.md](convenzioni-git.md).

Dopo il clone, una volta: `lefthook install`.

## Comandi

```sh
flutter pub get                       # dipendenze
flutter run                           # avvio sul dispositivo o emulatore collegato
flutter test                          # test unitari e di widget
flutter test integration_test -d linux  # test e2e (su Linux senza schermo: xvfb-run -a ...)
flutter analyze --fatal-infos --fatal-warnings  # analisi statica, come in CI
dart format lib test integration_test tool      # formattazione, come in CI
dart tool/check_docs.dart             # link, percorsi, indice e mappa del codice
flutter build apk                     # APK Android
flutter build ios                     # app iOS (su Mac)
```

## Suoni

I file in `assets/sounds/` si rigenerano con `python3 tool/generate_sounds.py`.

## Icone e schermata di avvio

Si rigenerano con `tool/generate_icons.py` e i due generatori Flutter, come descritto in [identita-visiva.md](identita-visiva.md).

## Test

### Metodo: prima i test

Ogni funzione nasce dai requisiti del progetto, nel documento dei requisiti, con questo ordine:

1. Si scrivono i test che descrivono il comportamento richiesto, citando nel nome l'identificativo del requisito (per esempio `RF-32 patta concordata`).
2. Si eseguono e si verifica che falliscano per la ragione attesa.
3. Si implementa il minimo necessario per farli passare.
4. Si aggiorna la documentazione in `docs/`.

### Livelli

| Livello | Cartella | Cosa verifica | Comando |
|---|---|---|---|
| Unitari | `test/chess_game_test.dart`, `test/material_test.dart`, `test/settings_test.dart`, `test/clock_test.dart`, `test/sound_test.dart`, `test/move_label_test.dart`, `test/move_input_test.dart`, `test/move_speech_test.dart` | Regole e fine partita su `ChessGame`; pezzi catturati e vantaggio su `MaterialBalance`; impostazioni e salvataggio; orologio; scelta dei suoni; numerazione, lettura e annuncio delle mosse; senza interfaccia | `flutter test` |
| Unitari | `test/engine/` | Protocollo UCI, scelta delle mosse, `ComputerPlayer` con motore finto e con Stockfish reale (se installato) | `flutter test` |
| Widget | `test/analysis/` | Schermata di analisi con motore finto: linee, MultiPV, esplorazione, pausa, freccia | `flutter test` |
| Unitari e widget | `test/review/` | Probabilità di vittoria, classificazione, sacrifici, precisione, revisione con motore finto, schermata di revisione e accesso dal menu | `flutter test` |
| Widget | `test/widget_test.dart`, `test/l10n_test.dart` | Avvio dell'app e stato iniziale; lingua italiana predefinita | `flutter test` |
| Unitari | `test/branding_test.dart` | Nome Rokko su Android e iOS, identificativo invariato, icona monocromatica | `flutter test` |
| Widget | `test/computer_game_test.dart` | Partita contro il computer con un motore finto | `flutter test` |
| Gamification | `test/progress/` | Regole di XP, serie (anche la sua spiegazione in parole) e traguardi; salvataggio; schermata Profilo | `flutter test test/progress` |
| Percorso | `test/path/` | Esercizi, contenuti, sblocco, mappa e tappe sulla scacchiera | `flutter test test/path` |
| Statistiche | `test/stats/` | Bilancio, rating locale, schermata | `flutter test test/stats` |
| Minigiochi | `test/minigames/` | Generazione risolvibile, risposte, schermate, registrazione dei punteggi | `flutter test test/minigames` |
| Scheda Tu | `test/home/` | Voci della scheda Tu: guardiani del percorso, tornei contro il motore finto, apertura di una partita dell'archivio nella revisione | `flutter test test/home` |
| Tornei | `test/tournament/` | Abbinamenti, simulazione, spareggi, salvataggio, schermata | `flutter test test/tournament` |
| Scacchiera per esercizi | `test/training/` | Tema, pezzi e coordinate presi dalle impostazioni, senza capovolgere i pezzi | `flutter test test/training` |
| Archivio | `test/archive/` | PGN, salvataggio su file, schermata Partite | `flutter test test/archive` |
| Scambio QR | `test/exchange/`, `test/game/game_qr_test.dart` | Fotogrammi QR, validazione dei dati letti, schermate Passa e Ricevi, partita continuata (vedi scambio-qr.md) | `flutter test test/exchange` |
| Allenatore | `test/coach/` | Avvisi, Riprova e Continua, suggerimento a livelli, frasi in parole semplici | `flutter test test/coach` |
| Puzzle | `test/puzzles/` | Dataset, Glicko-2, sessioni, Storm, Rush e Serie, ripasso, spiegazione delle modalità | `flutter test test/puzzles` |
| Aperture | `test/openings/` | Libro, nomi italiani, Esplora aperture, repertorio | `flutter test test/openings` |
| Regole | `test/regole/` | Partite di riferimento e perft | `flutter test test/regole` |
| Editor, backup, scacchiera fisica, promemoria | `test/editor/`, `test/backup/`, `test/physical/`, `test/reminders/` | FEN e validazione, backup e ripristino, orologio e registro, promemoria | `flutter test test/editor test/backup test/physical test/reminders` |
| Profilo bambino | `test/kids/` | Niente numeri, scheda Tu semplificata | `flutter test test/kids` |
| Strumenti | `test/tool/` | Controlli di rami, commit, documentazione e licenze | `flutter test test/tool` |
| End-to-end | `integration_test/qr_exchange_test.dart` | QR disegnato dall'app letto da zxing-cpp, fotocamera assente | `flutter test integration_test/qr_exchange_test.dart -d linux` |
| Golden | `test/settings/goldens/` | Schermata Impostazioni su telefono piccolo, medio e grande, con e senza colori per daltonici, e chip di temi e pezzi | `flutter test test/settings/board_preview_test.dart` |
| End-to-end | `integration_test/*_test.dart` | L'app reale avviata su un dispositivo o desktop, con tocchi e trascinamenti sulla scacchiera | `flutter test integration_test -d <dispositivo>` |
| End-to-end | `integration_test/computer_test.dart` | Partite contro un vero Stockfish (processo esterno, richiede `stockfish` installato) | `flutter test integration_test/computer_test.dart -d linux` |

Su desktop i file e2e vanno eseguiti uno alla volta: avviandone più di uno nello stesso comando, l'app del secondo file non parte. La CI li esegue in sequenza.

I test e2e simulano uno schermo da telefono in verticale (1170×2532 pixel fisici, rapporto 3) e muovono i pezzi calcolando la posizione delle case sulla scacchiera.

I golden si rigenerano con `flutter test test/settings --update-goldens` dopo una modifica voluta dell'aspetto; il testo dei test è disegnato con il font Ahem, quindi le immagini non dipendono dai font del sistema. Vanno generati con la stessa versione di Flutter della CI (3.47.7) e riletti prima del commit.

### Copertura attuale dei requisiti

| Requisito | Unitari | E2E |
|---|---|---|
| RF-01 mossa con due tocchi e trascinamento, mosse illegali ignorate | ✓ | ✓ |
| RF-04 promozione | ✓ | |
| RF-06 capovolgimento della scacchiera | | ✓ |
| RF-10 lista delle mosse in SAN, navigazione tra le posizioni e scorrimento sulla scacchiera | ✓ | ✓ |
| RF-11 pezzi catturati e vantaggio di materiale | ✓ | ✓ |
| RF-02, RF-04, RF-07, RF-12, RP-01, RP-04 impostazioni salvate | ✓ | ✓ |
| RF-20 colore e livello contro il computer | ✓ | ✓ |
| RF-21 motore separato, scacchiera bloccata mentre pensa, ritardo artificiale | ✓ | ✓ |
| Annullamento contro il computer (mossa e risposta) | | ✓ |
| RP-05 italiano predefinito, struttura per altre lingue; testi di backup, minigiochi, statistiche e aiuto FEN già tradotti (chiavi e segnaposto uguali in it/en, pagine in inglese) | ✓ | ✓ |
| RF-40, RF-41 cadenze, incremento, avvisi, tempo scaduto | ✓ | ✓ |
| RF-40 orologio contro il computer, annullamento con orologio | | ✓ |
| RP-03 suoni e vibrazione, RF-31 modalità tavolo | ✓ | ✓ |
| RNF-07 mossa da tastiera, annuncio delle mosse | ✓ | ✓ |
| RNF-07 colori per daltonici | ✓ | ✓ |
| RP-04 anteprima delle impostazioni (widget test e golden su tre telefoni) | ✓ | |
| RP-06 profilo bambino: impostazione, schede e sezioni semplificate | ✓ | |
| RP-06 profilo bambino: niente statistiche numeriche in profilo, puzzle, revisione e analisi (widget test) | ✓ | |
| RP-02 tema chiaro, scuro o di sistema scelto in Impostazioni (unitari, widget test e golden) | ✓ | ✓ |
| RF-30 nomi dei giocatori | ✓ | ✓ |
| RF-09 conferma della mossa | ✓ | ✓ |
| RF-25 matto, stallo, materiale insufficiente, ripetizione, 50 mosse, abbandono | ✓ | matto, abbandono |
| RF-25 patta accettata dal computer in base alla valutazione | ✓ | ✓ |
| RF-51 analisi a forza piena con più varianti, analisi continua interrompibile | ✓ | |
| RF-52 esplorazione lineare con avanti e indietro | ✓ | |
| RF-60 revisione completa con avanzamento e interruzione | ✓ | |
| RF-61, RF-62 classificazione delle mosse, Brillante e Ottima | ✓ | |
| RF-55 annotazioni (simbolo e commento) sulle mosse, conservate in import ed export PGN (modifica nell'interfaccia: da fare) | ✓ | |
| RF-56 minaccia dell'avversario nell'analisi e nella partita con l'allenatore | ✓ | ✓ |
| RF-63 precisione, conteggi e stima della forza | ✓ | |
| RF-67 tempo residuo a ogni mossa nel PGN (`[%clk]`, import ed export), registrato in partita, tempo per mossa ed errori in fretta nella revisione | ✓ | |
| RF-68 precisione per fase (apertura, mediogioco, finale) nella revisione | ✓ | ✓ |
| RF-50 barra di valutazione con valore numerico | ✓ | |
| RF-54 freccia della mossa migliore | ✓ | |
| RF-64 grafico della valutazione cliccabile con momenti chiave | ✓ | |
| RF-65 Riprova sugli errori | ✓ | |
| RF-66 cache della revisione (in memoria) | ✓ | |
| RF-70 spiegazioni: matto concesso o mancato, pezzo in presa, forchetta, inchiodatura, re scoperto, perdita di materiale | ✓ | |
| RF-72 giudizio con simbolo sulla casa della mossa (con l'allenatore acceso) | ✓ | ✓ |
| RF-73 allenatore: avviso in tempo reale, Riprova e Continua | ✓ | |
| RF-74 suggerimento a livelli, in parole semplici, con cerchio e freccia | ✓ | |
| RF-71 cattura netta, doppio attacco, scoperta dalla variante del motore | ✓ | |
| Cap. 7, errori trasformati in puzzle personali | ✓ | |
| Cap. 7, puzzle personali salvati e nel ripasso | ✓ | ✓ |
| RG-01 la revisione vale XP, una volta per partita | | ✓ |
| Cap. 7, scambio tra telefoni con il QR | ✓ | ✓ |
| RF-31 rotazione automatica a ogni turno | | ✓ |
| RF-32 patta concordata e annullamento | ✓ | ✓ |
| RF-100 salvataggio e partita da riprendere | ✓ | |
| RF-101 storico con ricerca | ✓ | |
| RF-102 import ed export PGN, condivisione, copia | ✓ | |
| Annullamento di abbandono e patta senza perdita di mosse | ✓ | |
| RF-04 chiusura del selettore di promozione con Annulla | | ✓ |
| RF-110 rating locale contro il computer | ✓ | |
| RF-111 statistiche per colore, cadenza, aperture, precisione | ✓ | |
| RG-01 XP e livelli | ✓ | |
| RG-02 obiettivo giornaliero, serie, riposo, protezioni | ✓ | |
| RG-03 percorso a tappe, stelle, sblocco, contenuti verificati | ✓ | |
| RG-05 37 traguardi e notifica in-app | ✓ | |
| RG-07 sfide giornaliere e settimanali | ✓ | |
| RG-08 record personali | ✓ | |
| RG-10 minigiochi | ✓ | |
| RG-09 tornei offline contro bot | ✓ | |
| RG-12 gamification disattivabile | ✓ | |
| RF-80 raccolta di puzzle inclusa e valida | ✓ | ✓ |
| RF-81 risoluzione e punteggio Glicko-2 | ✓ | ✓ |
| RF-83 suggerimento, soluzione, filtro per tema | ✓ | ✓ |
| RF-84 puzzle del giorno | ✓ | ✓ |
| RG-01 XP per i puzzle risolti | ✓ | |
| RF-82 Combo a tempo, corsa, sopravvivenza, serie | ✓ | ✓ |
| RF-85 ripasso dei puzzle sbagliati | ✓ | |
| RF-86 allenatore dei finali: esito, stelle, ripetizione | ✓ | |
| RG-08 record personali delle serie | ✓ | ✓ |
| RF-90 nome dell'apertura in partita | ✓ | ✓ |
| RF-91 mosse di libro | ✓ | |
| RF-92 Esplora aperture | ✓ | ✓ |
| RF-93 repertorio e ripasso dilazionato | ✓ | ✓ |

## Integrazione continua

Il workflow `.github/workflows/ci.yml` gira su ogni pull request e su ogni push su `main`, tranne quando cambiano solo `docs/`, file Markdown o `LICENSE`:

1. **test**, sempre: installa Stockfish (per i test d'integrazione del motore), verifica di localizzazione e formattazione, `flutter analyze`, `flutter test`, licenze delle dipendenze. È il controllo bloccante di ogni PR.
2. **e2e**, se i test passano: installa Stockfish ed esegue i test end-to-end sull'app Linux desktop con uno schermo virtuale (`xvfb`), un file alla volta perché avvii ravvicinati dell'app Linux nello stesso comando falliscono.
3. **android**, se i test passano: libera spazio sul runner (la compilazione nativa di Stockfish con l'NDK lo esaurisce), compila un APK di debug solo arm64 e lo pubblica come artefatto `scacchi-debug-apk` per 7 giorni.

e2e e android girano sempre su `main`; su una PR solo se la PR tocca i file che li riguardano (`integration_test/` o `linux/` per e2e, `android/` per android, `pubspec.*`, `ci.yml` e `ci-completa.yml` per entrambi) oppure se ha l'etichetta **`ci-completa`**: aggiungerla avvia subito tutta la CI con il workflow `ci-completa.yml`, senza bisogno di un nuovo push, e da lì in poi ogni push sulla PR la esegue per intero. L'etichetta si crea una volta in **Issues → Labels → New label**. I job avviati dall'etichetta compaiono come `ci / test`, `ci / e2e` e `ci / android` e devono essere verdi prima del merge. Conviene metterla sulle PR che cambiano molto l'interfaccia: senza, e2e gira solo dopo il merge su `main`.

### Consumo di minuti

Il repository è privato: ogni job si paga in minuti di Actions, arrotondati per eccesso al minuto, sul piano gratuito 2000 al mese. Per spenderne pochi:

- un nuovo push sulla stessa PR annulla il giro precedente ancora in corso (`concurrency`), su `main` invece ogni commit ha il suo giro completo;
- e2e e build Android, i job lunghi, girano sulle PR solo quando servono (vedi sopra);
- le modifiche alla sola documentazione non avviano la CI;
- cache di Flutter e pub (`subosito/flutter-action`) e di Gradle (`setup-java`);
- APK di debug solo per arm64, come quello di rilascio;
- solo runner Linux, che costano un decimo di quelli macOS;
- ogni job ha un `timeout-minutes`, così un job bloccato non consuma le 6 ore predefinite.

Durate misurate sulle esecuzioni dell'11 ottobre 2026, in minuti fatturati:

| Evento | Prima | Dopo |
|---|---|---|
| Push su una PR che tocca solo `lib/` o `test/` | 23 (convenzioni 1, test 4, e2e 5, android 13) | 5 (convenzioni 1, test 4) |
| Push su una PR che tocca `android/` o `pubspec.*` | 23 | circa 12 (android arm64 con cache di Gradle, stima) |
| PR di sola documentazione | 23 | 1 (convenzioni) |
| Merge su `main` | 22 | circa 16 |
| PR tipica: 4 push e merge | 114 | circa 36 (−68%) |

Con 2000 minuti al mese si passa da circa 17 a circa 55 PR tipiche. Per controllare il consumo: **Settings → Billing and plans → Usage** del proprio account GitHub.

Con le regole di protezione di `main` attive (vedi [convenzioni-git.md](convenzioni-git.md)) un job saltato conta come superato, ma una PR di sola documentazione non avvia la CI e resterebbe in attesa dei controlli obbligatori: in quel caso va tolto `paths-ignore` dall'evento `pull_request`.

Altri workflow:

- **Convenzioni** (`conventions.yml`, su ogni PR, meno di un minuto): nome del ramo, titolo della PR, messaggi dei commit, Gitleaks sui commit della PR e controllo della documentazione (anche sulle PR di sola documentazione), vedi [convenzioni-git.md](convenzioni-git.md) e [mappa-del-codice.md](mappa-del-codice.md).
- **Sicurezza** (`security.yml`): Trivy, OSV-Scanner, Gitleaks su tutta la cronologia, zizmor e SBOM, su `main`, ogni lunedì, a mano e sulle PR che cambiano dipendenze, `.github/`, `android/`, `tool/policy.json` o `.gitleaks.toml`, vedi [sicurezza.md](sicurezza.md).
- **Dataset** (`datasets.yml`, a mano o sulle PR che cambiano `tool/datasets/`): rigenera puzzle e aperture dai dati Lichess, vedi [puzzle.md](puzzle.md).

Il workflow `.github/workflows/apk-release.yml` produce l'APK release installabile sul telefono e lo pubblica come GitHub Release: vedi [rilascio-android.md](rilascio-android.md).

## Convenzioni

- Nel codice solo commenti funzionali e brevi: cosa fa un elemento, non la sua storia o le motivazioni di progetto.
- La documentazione completa sta in `docs/`, da aggiornare insieme al codice che descrive.
- Testi dell'interfaccia in italiano.
- Logica di gioco separata dall'interfaccia (`ChessGame` non importa Flutter), così da poterla testare in isolamento.
- Analisi statica rigorosa (`analysis_options.yaml`): tipi stretti, `Future` sempre attesi o marcati con `unawaited`, nessun avviso ammesso.
- Prima del push: `tool/verifica.sh --test` (rami, commit, documentazione, formattazione, analisi, test), vedi [convenzioni-git.md](convenzioni-git.md#senza-hook-toolverificash).
- Rami, commit Angular, hook e merge: [convenzioni-git.md](convenzioni-git.md).
