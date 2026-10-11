# Allenatore dei finali

Requisito RF-86: posizioni teoriche da vincere o pattare contro il motore a forza piena, con obiettivo dichiarato, da 1 a 3 stelle in base alle mosse e ripetizione delle posizioni fallite. Il codice è in `lib/endgames/`. Questa parte contiene la logica; le schermate arrivano con la PR successiva.

## Posizioni

| Posizione | Colore | Obiettivo | Par |
|---|---|---|---|
| Donna e re contro re | Bianco | Matto | 10 |
| Torre e re contro re | Bianco | Matto | 18 |
| Re e pedone contro re | Bianco | Promozione | 10 |
| La posizione di Lucena | Bianco | Promozione | 10 |
| La difesa di Philidor | Nero | Resistere 15 mosse | 15 |
| Alfiere e cavallo | Bianco | Matto | 35 |

Le posizioni sono costruite per il progetto e sono di dominio pubblico come schemi teorici. Durante la stesura sono state controllate con Stockfish: le posizioni da vincere sono vinte (matto forzato o vantaggio decisivo), la Philidor con il Nero al tratto è patta. L'utente gioca il colore che ha la mossa nella FEN (`EndgameDrill.fen`); il motore risponde al livello più forte (`engineLevels.last`).

## Regole della prova

`DrillRun` conta le mosse dell'utente e decide l'esito dopo ogni mossa:

- **Matto**: riesce con lo scacco matto. Fallisce con lo stallo, la patta per materiale insufficiente, la regola delle 50 mosse o la triplice ripetizione, oppure oltre il triplo del par.
- **Promozione**: riesce quando l'utente ha una donna che l'avversario non può catturare subito, quando la donna resta in piedi dopo la risposta del motore, o quando resta con la torre contro il re solo (nella Lucena il motore può dare la torre per la donna: basta riprenderla). Fallisce se l'utente resta senza pedoni né donna (con una torre ha ancora una mossa per riprendere il pezzo), con una patta o oltre il triplo del par.
- **Resistere**: riesce raggiungendo il par senza perdere, oppure con una patta. Fallisce con il matto subito o se l'avversario promuove.

Stelle (`drillStars`): 3 entro il par, 2 fino a metà del par in più (arrotondata per eccesso), 1 oltre. Per «Resistere» il par è il numero di mosse da tenere, quindi riuscire vale sempre 3 stelle.

## Progressi e ripetizione

`EndgameProgress` tiene le stelle migliori per posizione e l'insieme delle posizioni fallite e non ancora riuscite; `ordered` mette queste per prime. `EndgameController` salva in `endgames.json` (`JsonFile`, versione 1) e registra un `LessonCompleted` (XP e obiettivo giornaliero) solo la prima volta che una posizione riesce.
