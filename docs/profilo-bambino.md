# Profilo bambino

Requisito RP-06, sul modello di ChessKid: interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica.

## Attivazione

Impostazioni, sezione «Profilo», interruttore «Profilo bambino». La scelta è salvata in locale (chiave `kidMode`) e rientra nel backup come le altre impostazioni. Si applica subito, senza riavviare l'app.

Per disattivarlo serve un adulto, come nel controllo genitori di ChessKid: compare la domanda «Chiedi a un adulto» con una moltiplicazione tra 6 e 9 (per esempio 7 × 8). Con una risposta sbagliata o con Annulla il profilo resta attivo.

## Cosa cambia

| Area | Profilo bambino | Stato |
|---|---|---|
| Barra in basso | Tre schede: Gioca, Puzzle, Tu (le Aperture sono nascoste) | Disponibile |
| Scheda Tu | Solo Profilo, Percorso e Minigiochi; nascoste Statistiche, La tua settimana, Scacchiera fisica e Archivio | Disponibile |
| Avversari | Nella nuova partita solo «Due giocatori» e «Bot» (niente «Computer» con livello ed Elo). I bot sono i tre più facili della scala, Pino, Chiara e Rocco, con avatar, nome e una breve descrizione al posto di Elo, stile e apertura; restano lucchetti e spunta, senza la data della vittoria. In partita il bot ha frasi brevi e incoraggianti e il titolo non mostra l'Elo. Se l'ultima scelta era il computer o un bot più forte, si ripiega su Pino. Senza motore compare «Su questo dispositivo i bot non sono disponibili.» | Disponibile |
| Numeri | Niente rating, precisione e punteggi del motore | In sviluppo |
| Testi | Frasi brevi e semplici in partita (vedi sotto) | Disponibile |
| Partita | Senza analisi, revisione ed editor di posizione; le nuove partite solo a scacchi classici, senza tempo o con una cadenza lenta | Disponibile |

Se il profilo si attiva mentre è aperta la scheda Aperture, si torna alla scheda Gioca.

## Testi in partita

- Riga di stato: «Tocca a te!» contro il computer, «Tocca al Bianco!» / «Tocca al Nero!» tra due persone (con i nomi, «Anna, tocca a te!»), «Scacco! Il tuo re è in pericolo», «Il computer ci sta pensando…».
- Fine partita con causa ed esito: «Scacco matto! Hai vinto!», «Ti sei arreso. Il computer ha vinto. Riprova!», «Ha vinto il Nero!». Quando vince il giocatore (o chiunque, tra due persone) la riga aggiunge 🎉, che il lettore di schermo non legge.
- Le patte spiegano il motivo: «Stallo: il re non può muoversi ma non è sotto scacco. Pareggio!», «Sono rimasti troppo pochi pezzi per dare scacco matto. Pareggio!», «La stessa posizione è tornata tre volte. Pareggio!», «Pareggio deciso insieme!».
- Comandi: «Nuova partita», «Pareggio?», «Mi arrendo». Dialoghi: «Vuoi arrenderti?» con «No, continuo» / «Sì, mi arrendo»; «Nero, vuoi fare pareggio?» con «No, giochiamo» / «Sì, pareggio».
- Titolo «Scacchi» al posto del nome dell'apertura (una variante mostra ancora il suo titolo); sotto, il bot senza Elo o «Il computer» senza livello.
- Il pannello «Nuova partita» non mostra le varianti e, sotto «Quanto tempo?», offre solo «Senza tempo» e «Con l'orologio, con calma» (15+10). Il limite vale per le nuove partite: una partita in corso quando si attiva il profilo, anche in variante o con una cadenza veloce, continua com'è. La variante scelta prima resta per quando il profilo si spegne. Tutti i testi del pannello e della barra dei comandi sono nei file `.arb`.
- Gli annunci per i lettori di schermo usano le stesse frasi, anche per resa e pareggio concordato.

Una partita contro un bot o il computer resta com'è iniziata: avversario e frasi seguono il profilo attivo all'inizio della partita, e il cambio vale dalla partita successiva. Elo e livello sotto il titolo restano nascosti finché il profilo è attivo, e in tutta la partita se è iniziata con il profilo.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `askAdult` in `lib/settings/adult_gate.dart`: domanda per l'adulto.
- `HomeShell` ascolta solo i cambi di `kidMode` e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`; quelli della partita con prefisso `kidGame`, letti in `GamePage` solo con il profilo attivo.
- I testi del profilo sono nei file `.arb` con prefisso `kid`; le descrizioni dei bot hanno prefisso `kidBot`.
- Bot amichevoli: `friendlyBots`, `friendlyBotDescriptions` e `Bot.phrases(evento, friendly: true)` in `lib/engine/bots.dart`, `GameSetup.forKids()` e `OpponentPicker(kidMode: ...)` in `lib/game/opponent_picker.dart`; `GamePage` passa `kidMode` ai pannelli e alle frasi.
- Test: `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart`, `test/kid_bot_game_test.dart`.
