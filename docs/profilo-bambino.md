# Profilo bambino

Requisito RP-06: interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica.

## Attivazione

Impostazioni, ultima voce del menu «Profilo bambino» (sotto un separatore), interruttore «Profilo bambino». La scelta è salvata in locale (chiave `kidMode`) e rientra nel backup come le altre impostazioni. Si applica subito, senza riavviare l'app.

Per disattivarlo serve un adulto: compare la domanda «Chiedi a un adulto» con una moltiplicazione tra 6 e 9 (per esempio 7 × 8). Con una risposta sbagliata o con Annulla il profilo resta attivo.

## Cosa cambia

| Area | Profilo bambino |
|---|---|
| Barra in basso | Home, Puzzle, Impara, Tu. Nella Home niente ricerca, avversario consigliato, statistiche e ultime partite; le Aperture sono nascoste anche in Impara (vedi [home.md](home.md)) |
| Scheda Tu | Solo Profilo e La tua settimana (stelle e frasi, senza numeri); nascosti Badge, Statistiche e Archivio. Storia, Finali, Grandi maestri e Minigiochi stanno nella Home e nella scheda Impara; Tornei (classifica ed Elo dei bot) e Scacchiera fisica restano nascosti |
| Avversari | Nella nuova partita solo «Due giocatori» e «Bot» (niente «Adattivo» con livello ed Elo). I bot sono tre dei più facili, Pino, Chiara e Rocco (`friendlyBots`), con avatar, nome e una breve descrizione al posto di Elo, stile e apertura; restano lucchetti e spunta, senza la data della vittoria. In partita il bot ha frasi brevi e incoraggianti e il titolo non mostra l'Elo. Se l'ultima scelta era il computer o un bot più forte, si ripiega su Pino. Senza motore compare «Su questo dispositivo i bot non sono disponibili.» |
| Numeri | Niente rating, XP, precisione e punteggi del motore: stelle, fiamme e parole al loro posto (dettagli sotto) |
| Testi | Frasi brevi e semplici in partita (vedi sotto) |
| Partita | Senza analisi, revisione, scambio con il QR ed editor di posizione; le nuove partite solo a scacchi classici, senza tempo o con una cadenza lenta |

## Testi in partita

- Riga di stato: «Tocca a te!» contro il computer, «Tocca al Bianco!» / «Tocca al Nero!» tra due persone (con i nomi, «Anna, tocca a te!»), «Scacco! Il tuo re è in pericolo», «Il computer ci sta pensando…».
- Fine partita con causa ed esito: «Scacco matto! Hai vinto!», «Ti sei arreso. Il computer ha vinto. Riprova!», «Ha vinto il Nero!». Quando vince il giocatore (o chiunque, tra due persone) la riga aggiunge 🎉, che il lettore di schermo non legge.
- Le patte spiegano il motivo: «Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!», «Sono rimasti troppo pochi pezzi per dare scacco matto. Pareggio!», «La stessa posizione è tornata tre volte. Pareggio!», «Pareggio deciso insieme!».
- Comandi: «Nuova partita», «Pareggio?», «Mi arrendo». Dialoghi: «Vuoi arrenderti?» con «No, continuo» / «Sì, mi arrendo»; «Nero, vuoi fare pareggio?» con «No, giochiamo» / «Sì, pareggio».
- «Allenatore» e «Aiuto» per il suggerimento, che non nomina la casa: «Sposta il cavallo sul cerchio.»
- Titolo «Rokko» al posto del nome dell'apertura (una variante mostra ancora il suo titolo); sotto, il bot senza Elo o «Il computer» senza livello.
- Il pannello «Nuova partita» non mostra le varianti e, sotto «Quanto tempo?», offre solo «Senza tempo» e «Con l'orologio, con calma» (15+10). Il limite vale per le nuove partite: una partita in corso quando si attiva il profilo, anche in variante o con una cadenza veloce, continua com'è. La variante scelta prima resta per quando il profilo si spegne. Tutti i testi del pannello e della barra dei comandi sono nei file `.arb`.
- Gli annunci per i lettori di schermo usano le stesse frasi, anche per resa e pareggio concordato.

Una partita contro un bot o il computer resta com'è iniziata: avversario e frasi seguono il profilo attivo all'inizio della partita, e il cambio vale dalla partita successiva. Elo e livello sotto il titolo restano nascosti finché il profilo è attivo, e in tutta la partita se è iniziata con il profilo.

## Niente numeri

Il criterio: spariscono i numeri che **misurano** il bambino (punteggi, XP, percentuali, valutazioni del motore, conteggi e record); restano quelli che **descrivono un compito** (titoli di sfide e traguardi come «Risolvi 3 puzzle», nomi dei temi come «Matto in 1», numeri delle mosse e coordinate della scacchiera).

Le stelle si fermano a dieci (`kidMaxStars`): una fila più lunga si conterebbe e tornerebbe a essere un numero.

| Schermata | Al posto dei numeri |
|---|---|
| Notifica dei progressi | «Bravo, continua così!» invece di «+N XP»; nuovo livello, obiettivo, sfide, traguardi e ricompense diventano frasi senza cifre; la ricompensa non ha il nome (solo italiano), così in inglese le lingue non si mescolano; record e scudo della serie (che nel profilo bambino non si vede) non si annunciano |
| Scheda Tu | Intestazione con stelle del livello e fiamma della serie, senza «Livello N» e «N giorni di fila» |
| Profilo | Livello come una stella per livello («Le tue stelle»); barra del livello senza «XP / XP»; serie come fiamma accesa o spenta, senza giorni, record e protezioni; barra dell'obiettivo senza conteggio; sfide con la barra ma senza «n/m»; sezione Record personali nascosta; tra i traguardi non si elencano quelli che citano livello, Elo dei bot battuti, punteggio o serie dei puzzle, precisione e giorni di fila (`kidHiddenAchievements`, `achievementsFor`), che si sbloccano comunque; restano quelli che descrivono un compito, anche con un conteggio («Gioca 10 partite»); nascosta anche la sezione Impostazioni (interruttore degli XP, obiettivo, giorno di riposo, promemoria), scelte da adulti |
| Foto del profilo | La sezione «Foto» della scelta dell'avatar non compare e una foto già salvata non viene mostrata (RP-09); restano avatar e cornici |
| Sblocchi | Avatar, cornici, temi e pezzi bloccati dicono «Si sblocca giocando» invece di «Livello N» o del traguardo, anche nel testo per i lettori di schermo e nell'avviso delle Impostazioni |
| Hub dei puzzle | Niente punteggio né contatori: una stella per puzzle risolto (fino a dieci); niente difficoltà del puzzle del giorno né numero di puzzle da ripassare; nascoste le modalità a tempo e la sfida a un amico, costruite su punti, errori e record; nei temi spariscono i conteggi |
| Puzzle | Nessun punteggio né variazione dopo il puzzle; sotto la scacchiera «Forza, ce la puoi fare!» e, a puzzle concluso, solo i temi |
| Revisione | Precisione da una a cinque stelle (una ogni 20 punti interi: sotto 40 una, da 80 a 99,9 quattro, 100 cinque) con un giudizio a parole («Perfetto!», «Molto bene», «Bene», «Così così», «Da migliorare»); niente Elo stimato né conteggi per categoria; le classificazioni delle mosse restano a simboli e parole; «Sto guardando la partita…» durante l'analisi; il coach dice «potevi dare scacco matto con…» e «perdi dei pezzi» invece di «matto in N» e «circa N pedoni» |
| Analisi e barra di valutazione | La barra resta, senza cifre; il lettore di schermo dice solo chi è avanti (fascia di parità tra 40 e 60% di probabilità); niente punteggi delle linee né profondità |

Stelle, fiamma, giudizi della precisione e requisito di sblocco sono in `lib/kids/kid_display.dart`. Le pagine leggono `AppSettings.of(context).kidMode` e prendono i testi `kid…` da `AppLocalizations` solo nel profilo bambino. Test: `test/kids/no_numbers_test.dart` e, per le schermate La tua settimana, Grandi maestri, Minigiochi, Profilo, mappa del Percorso, mappa della Storia e Gioca con un amico, `test/kids/screens_digits_test.dart`. Le pagine dei puzzle (hub e puzzle singolo) sono in `no_numbers_test.dart`. Nella Storia il riepilogo dice «Il tuo viaggio» con la sola barra, i capitoli non mostrano «N passi su M» e i passi sono «Lezioni» e «Puzzle del capitolo» senza conteggio; nel Percorso le stelle del riepilogo e dei capitoli sono una sola icona, senza «N/M».

Anche l'allenatore durante la partita usa le frasi senza numeri: `GamePage` passa i testi del profilo a `CoachSession.judge(kid: ...)`.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `askAdult` in `lib/settings/adult_gate.dart`: domanda per l'adulto.
- `HomeShell` ascolta solo i cambi di `kidMode` e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`; quelli della partita con prefisso `kidGame`, letti in `GamePage` solo con il profilo attivo; le descrizioni dei bot hanno prefisso `kidBot`.
- Bot amichevoli: `friendlyBots`, `friendlyBotDescriptions` e `Bot.phrases(evento, friendly: true)` in `lib/engine/bots.dart`, `GameSetup.forKids()` e `OpponentPicker(kidMode: ...)` in `lib/game/opponent_picker.dart`; `GamePage` passa `kidMode` ai pannelli e alle frasi.
- Test: `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart`, `test/kid_bot_game_test.dart`.

Contro i bot il profilo bambino gioca sempre in Allenamento (annullamento e aiuti, nessun Elo): vedi [avversario-computer.md](avversario-computer.md#allenamento-e-sfida).
