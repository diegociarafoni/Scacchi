# Allenatore dei finali

Requisito RF-86: posizioni teoriche da vincere o pattare contro il motore a forza piena, con obiettivo dichiarato, da 1 a 3 stelle in base alle mosse e ripetizione delle posizioni fallite. Il codice è in `lib/endgames/`.

## Posizioni

| Posizione | Colore | Obiettivo | Par |
|---|---|---|---|
| Donna e re contro re | Bianco | Matto | 10 |
| Torre e re contro re | Bianco | Matto | 18 |
| Re e pedone contro re | Bianco | Promozione | 10 |
| La posizione di Lucena | Bianco | Promozione | 10 |
| La difesa di Philidor | Nero | Resistere 15 mosse | 15 |
| Alfiere e cavallo | Bianco | Matto | 35 |

Le posizioni sono costruite per il progetto e sono di dominio pubblico come schemi teorici. Sono state controllate con Stockfish: le posizioni da vincere sono vinte (matto forzato o vantaggio decisivo), la Philidor con il Nero al tratto è patta. L'utente gioca il colore che ha la mossa nella FEN (`EndgameDrill.fen`); il motore risponde al livello più forte (`engineLevels.last`). Titoli e spiegazioni sono nel contenuto `endgames` (`assets/content/<lingua>/endgames.json`, id `<posizione>.title` e `<posizione>.intro`, quest'ultimo con il segnaposto `{par}`); i testi dell'interfaccia sono in `lib/l10n/<lingua>/endgames.arb`.

## Regole della prova

`DrillRun` conta le mosse dell'utente e decide l'esito dopo ogni mossa:

- **Matto**: riesce con lo scacco matto. Fallisce con lo stallo, la patta per materiale insufficiente, la regola delle 50 mosse o la triplice ripetizione, oppure oltre il triplo del par (nei matti lunghi, come alfiere e cavallo, arriva prima la regola delle 50 mosse).
- **Promozione**: riesce quando l'utente ha una donna, o una torre contro il re solo, che l'avversario non può vincere nelle due mosse seguenti: qualunque risposta del motore lascia all'utente una mossa dopo cui la donna o la torre non sono catturabili. Così una donna che si fa catturare, infilare con uno scacco o una torre indifesa vicino al re nemico non bastano, mentre nella Lucena va bene promuovere anche se il motore può dare la torre per la donna, perché dopo la ripresa resta torre contro re. Fallisce se l'utente resta senza pedoni, donne e torri, con una patta o oltre il triplo del par.
- **Resistere**: riesce quando, dopo la risposta del motore alla mossa numero par, l'utente non ha perso; anche una patta lo fa riuscire. Fallisce con il matto subito, se l'utente resta con il re solo mentre l'avversario ha ancora pezzi, o se dopo la sua mossa l'avversario ha una donna e lui no (una donna appena promossa si può ancora catturare).

Stelle (`drillStars`): 3 entro il par, 2 fino a metà del par in più (arrotondata per eccesso), 1 oltre. Per «Resistere» il par è il numero di mosse da tenere, quindi riuscire vale sempre 3 stelle.

## Progressi e ripetizione

`EndgameProgress` tiene le stelle migliori per posizione e l'insieme delle posizioni fallite e non ancora riuscite; `ordered` mette queste per prime. `EndgameController` salva in `endgames.json` (`JsonFile`, versione 1) e registra un `LessonCompleted` (XP e obiettivo giornaliero) solo la prima volta che una posizione riesce.

## Schermate

La voce **Finali** della Home compare solo dove gira il motore (Android e iOS, o Windows e Linux con Stockfish installato), come i Tornei, ma a differenza di questi c'è anche nel profilo bambino. Si apre dal gruppo Impara della Home e dalla scheda Impara. `EndgamesPage` elenca le posizioni: prima quelle da ripetere, con la scritta «Da ripetere», poi le altre con l'obiettivo; a destra le stelle migliori.

`DrillPage` mostra la spiegazione con l'obiettivo e il pulsante «Inizia»; la scacchiera è girata quando si gioca con il Nero. Dopo ogni mossa dell'utente il motore risponde a forza piena (`analysisLevel`, Skill Level 20 a 300 ms per mossa) e intanto la scacchiera è bloccata. Sotto la scacchiera c'è il conteggio delle mosse rispetto al par (nascosto nel profilo bambino, che non mostra numeri). Il motore riceve la posizione iniziale e tutte le mosse giocate, così vede le ripetizioni. A fine prova compaiono l'esito, le stelle, «Riprova» e «Fine»; l'esito si salva subito. Uscire da una prova iniziata e non finita la conta come fallita, quindi torna da ripetere. Se il motore non risponde o dà una mossa illegale, un messaggio lo dice e «Riprova» riparte dalla posizione iniziale; in quel caso uscire non conta come fallimento. Il pedone promuove sempre a donna.

## Mossa perfetta

Nelle posizioni con al massimo quattro pezzi (donna e re, torre e re, re e pedone, alfiere e cavallo) durante la prova compare la scheda «Finale perfetto» con il matto più rapido da quella posizione e il pulsante «Mostra la mossa perfetta», che disegna una freccia sulla scacchiera. Non cambia le stelle. Lucena e Philidor hanno cinque pezzi e restano senza scheda. Dettagli in [finali-perfetti.md](finali-perfetti.md).
