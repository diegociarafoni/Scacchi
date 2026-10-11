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
| Avversari | Solo bot amichevoli, senza Elo né livelli numerici | In sviluppo |
| Numeri | Niente rating, XP, precisione e punteggi del motore: stelle, fiamme e parole al loro posto (dettagli sotto) | Disponibile |
| Testi | Frasi brevi e semplici in partita | In sviluppo |

Se il profilo si attiva mentre è aperta la scheda Aperture, si torna alla scheda Gioca.

## Niente numeri

Il criterio: spariscono i numeri che **misurano** il bambino (punteggi, XP, percentuali, valutazioni del motore, conteggi e record); restano quelli che **descrivono un compito** (titoli di sfide e traguardi come «Risolvi 3 puzzle», nomi dei temi come «Matto in 1», obiettivo giornaliero nelle impostazioni del profilo, numeri delle mosse e coordinate della scacchiera).

| Schermata | Al posto dei numeri |
|---|---|
| Notifica dei progressi | «Bravo, continua così!» invece di «+N XP»; nuovo livello, obiettivo, sfide, traguardi e ricompense diventano frasi senza cifre; i record non si annunciano |
| Profilo | Livello come una stella per livello («Le tue stelle»); barra del livello senza «XP / XP»; serie come fiamma accesa o spenta, senza giorni, record e protezioni; barra dell'obiettivo senza conteggio; sfide con la barra ma senza «n/m»; sezione Record personali nascosta |
| Hub dei puzzle | Niente punteggio né contatori: una stella per puzzle risolto (fino a dieci); niente difficoltà del puzzle del giorno né numero di puzzle da ripassare; nascoste le modalità a tempo (Storm, Sopravvivenza, Serie), costruite su punti, errori e record; nei temi spariscono i conteggi |
| Puzzle | Nessun punteggio né variazione dopo il puzzle; sotto la scacchiera «Forza, ce la puoi fare!» e, a puzzle concluso, solo i temi |
| Revisione | Precisione da una a cinque stelle (una ogni 20 punti) con un giudizio a parole («Perfetto!», «Molto bene», «Bene», «Così così», «Da migliorare»); niente Elo stimato né conteggi per categoria; le classificazioni delle mosse restano a simboli e parole; «Sto guardando la partita…» durante l'analisi |
| Analisi e barra di valutazione | La barra resta, senza cifre; il lettore di schermo dice solo chi è avanti (fascia di parità tra 40 e 60% di probabilità); niente punteggi delle linee né profondità |

Le pagine leggono `AppSettings.of(context).kidMode` e prendono i testi `kid…` da `AppLocalizations` solo nel profilo bambino. Test: `test/kids/no_numbers_test.dart`.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `askAdult` in `lib/settings/adult_gate.dart`: domanda per l'adulto.
- `HomeShell` ascolta solo i cambi di `kidMode` e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`.
