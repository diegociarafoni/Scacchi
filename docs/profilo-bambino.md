# Profilo bambino

Requisito RP-06, sul modello di ChessKid: interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica.

## Attivazione

Impostazioni, sezione «Profilo», interruttore «Profilo bambino». La scelta è salvata in locale (chiave `kidMode`) e rientra nel backup come le altre impostazioni. Si applica subito, senza riavviare l'app.

## Cosa cambia

| Area | Profilo bambino | Stato |
|---|---|---|
| Barra in basso | Tre schede: Gioca, Puzzle, Tu (le Aperture sono nascoste) | Disponibile |
| Scheda Tu | Solo Profilo, Percorso e Minigiochi; nascoste Statistiche, La tua settimana, Scacchiera fisica e Archivio | Disponibile |
| Avversari | Nella nuova partita solo «Due giocatori» e «Bot» (niente «Computer» con livello ed Elo). I bot sono i tre più facili della scala, Pino, Chiara e Rocco, con avatar, nome e una breve descrizione al posto di Elo, stile e apertura; restano lucchetti e spunta, senza la data della vittoria. In partita il bot ha frasi brevi e incoraggianti e il titolo non mostra l'Elo. Se l'ultima scelta era il computer o un bot più forte, si ripiega su Pino | Disponibile |
| Numeri | Niente rating, precisione e punteggi del motore | In sviluppo |
| Testi | Frasi brevi e semplici in partita | In sviluppo |

Se il profilo si attiva mentre è aperta la scheda Aperture, si torna alla scheda Gioca.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `HomeShell` ascolta le impostazioni e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`; le descrizioni dei bot hanno prefisso `kidBot`.
- Bot amichevoli: `friendlyBots` e `Bot.phrases(evento, friendly: true)` in `lib/engine/bots.dart`, `GameSetup.forKids()` e `OpponentPicker(kidMode: ...)` in `lib/game/opponent_picker.dart`; `GamePage` passa `kidMode` ai pannelli e alle frasi.
- Test: `test/engine/kid_bots_test.dart`, `test/game/kid_opponent_picker_test.dart`, `test/kid_bot_game_test.dart`.
