# Profilo bambino

Requisito RP-06: interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica.

## Attivazione

Impostazioni, sezione «Profilo», interruttore «Profilo bambino». La scelta è salvata in locale (chiave `kidMode`) e rientra nel backup come le altre impostazioni. Si applica subito, senza riavviare l'app.

Per disattivarlo serve un adulto: compare la domanda «Chiedi a un adulto» con una moltiplicazione tra 6 e 9 (per esempio 7 × 8). Con una risposta sbagliata o con Annulla il profilo resta attivo.

## Cosa cambia

| Area | Profilo bambino | Stato |
|---|---|---|
| Barra in basso | Tre schede: Gioca, Puzzle, Tu (le Aperture sono nascoste) | Disponibile |
| Scheda Tu | Solo Profilo, Storia, Finali (senza conteggio delle mosse), Grandi maestri (senza percentuali), Minigiochi e La tua settimana (stelle e frasi, senza numeri); nascoste Statistiche, La tua settimana, Scacchiera fisica, Archivio e Tornei (classifica ed Elo dei bot) | Disponibile |
| Avversari | Nella nuova partita solo «Due giocatori» e «Bot» (niente «Computer» con livello ed Elo). I bot sono i tre più facili della scala, Pino, Chiara e Rocco, con avatar, nome e una breve descrizione al posto di Elo, stile e apertura; restano lucchetti e spunta, senza la data della vittoria. In partita il bot ha frasi brevi e incoraggianti e il titolo non mostra l'Elo. Se l'ultima scelta era il computer o un bot più forte, si ripiega su Pino. Senza motore compare «Su questo dispositivo i bot non sono disponibili.» | Disponibile |
| Numeri | Niente rating, XP, precisione e punteggi del motore: stelle, fiamme e parole al loro posto (dettagli sotto) | Disponibile |
| Testi | Frasi brevi e semplici in partita (vedi sotto) | Disponibile |
| Partita | Senza analisi, revisione, scambio con il QR ed editor di posizione; le nuove partite solo a scacchi classici, senza tempo o con una cadenza lenta | Disponibile |

Se il profilo si attiva mentre è aperta la scheda Aperture, si torna alla scheda Gioca.

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
| Profilo | Livello come una stella per livello («Le tue stelle»); barra del livello senza «XP / XP»; serie come fiamma accesa o spenta, senza giorni, record e protezioni; barra dell'obiettivo senza conteggio; sfide con la barra ma senza «n/m»; sezione Record personali nascosta; nascosta anche la sezione Impostazioni (interruttore degli XP, obiettivo, giorno di riposo, promemoria), scelte da adulti |
| Sblocchi | Avatar, cornici, temi e pezzi bloccati dicono «Si sblocca giocando» invece di «Livello N» o del traguardo, anche nel testo per i lettori di schermo e nell'avviso delle Impostazioni |
| Hub dei puzzle | Niente punteggio né contatori: una stella per puzzle risolto (fino a dieci); niente difficoltà del puzzle del giorno né numero di puzzle da ripassare; nascoste le modalità a tempo (Storm, Sopravvivenza, Serie), costruite su punti, errori e record; nei temi spariscono i conteggi |
| Puzzle | Nessun punteggio né variazione dopo il puzzle; sotto la scacchiera «Forza, ce la puoi fare!» e, a puzzle concluso, solo i temi |
| Revisione | Precisione da una a cinque stelle (una ogni 20 punti interi: sotto 40 una, da 80 a 99,9 quattro, 100 cinque) con un giudizio a parole («Perfetto!», «Molto bene», «Bene», «Così così», «Da migliorare»); niente Elo stimato né conteggi per categoria; le classificazioni delle mosse restano a simboli e parole; «Sto guardando la partita…» durante l'analisi; il coach dice «potevi dare scacco matto con…» e «perdi dei pezzi» invece di «matto in N» e «circa N pedoni» |
| Analisi e barra di valutazione | La barra resta, senza cifre; il lettore di schermo dice solo chi è avanti (fascia di parità tra 40 e 60% di probabilità); niente punteggi delle linee né profondità |

Stelle, fiamma, giudizi della precisione e requisito di sblocco sono in `lib/kids/kid_display.dart`. Le pagine leggono `AppSettings.of(context).kidMode` e prendono i testi `kid…` da `AppLocalizations` solo nel profilo bambino. Test: `test/kids/no_numbers_test.dart`.

Anche l'allenatore durante la partita usa le frasi senza numeri: `GamePage` passa i testi del profilo a `CoachSession.judge(kid: ...)`.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `askAdult` in `lib/settings/adult_gate.dart`: domanda per l'adulto.
- `HomeShell` ascolta solo i cambi di `kidMode` e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`; quelli della partita con prefisso `kidGame`, letti in `GamePage` solo con il profilo attivo; le descrizioni dei bot hanno prefisso `kidBot`.
- Bot amichevoli: `friendlyBots`, `friendlyBotDescriptions` e `Bot.phrases(evento, friendly: true)` in `lib/engine/bots.dart`, `GameSetup.forKids()` e `OpponentPicker(kidMode: ...)` in `lib/game/opponent_picker.dart`; `GamePage` passa `kidMode` ai pannelli e alle frasi.
- Test: `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart`, `test/kid_bot_game_test.dart`.
