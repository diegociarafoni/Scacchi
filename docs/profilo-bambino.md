# Profilo bambino

Requisito RP-06, sul modello di ChessKid: interfaccia semplificata, testi più semplici, bot amichevoli, nessuna statistica numerica.

## Attivazione

Impostazioni, sezione «Profilo», interruttore «Profilo bambino». La scelta è salvata in locale (chiave `kidMode`) e rientra nel backup come le altre impostazioni. Si applica subito, senza riavviare l'app.

## Cosa cambia

| Area | Profilo bambino | Stato |
|---|---|---|
| Barra in basso | Tre schede: Gioca, Puzzle, Tu (le Aperture sono nascoste) | Disponibile |
| Scheda Tu | Solo Profilo, Percorso e Minigiochi; nascoste Statistiche, La tua settimana, Scacchiera fisica e Archivio | Disponibile |
| Avversari | Solo bot amichevoli, senza Elo né livelli numerici | In sviluppo |
| Numeri | Niente rating, precisione e punteggi del motore | In sviluppo |
| Testi | Frasi brevi e semplici in partita | In sviluppo |

Se il profilo si attiva mentre è aperta la scheda Aperture, si torna alla scheda Gioca.

## Codice

- `AppSettings.kidMode` in `lib/settings/settings.dart`.
- `HomeShell` ascolta le impostazioni e passa `simple` a `YouPage`.
- I testi del profilo sono nei file `.arb` con prefisso `kid`.
