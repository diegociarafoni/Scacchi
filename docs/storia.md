# Percorso a storia

Requisito RG-13: una trama a capitoli sopra il [percorso a tappe](percorso.md). Il codice è in `lib/story/`. Si apre dalla scheda Tu, voce **Storia**, ed è l'unico percorso di apprendimento dell'interfaccia: «Continua da dove eri» della scheda Tu porta qui (prossima tappa: `nextStoryStage`), e le stelle già ottenute nel [percorso](percorso.md) contano subito.

## Come funziona

La storia accompagna il giocatore dal villaggio ai piedi della Rocca fino alla corona e oltre, verso la pianura dei piani e l'accademia del maestro. Ogni capitolo ha un racconto breve, un elenco di passi da fare nell'ordine e un epilogo che compare a capitolo concluso. Il capitolo successivo si apre quando il precedente è concluso. Non ci sono vite, penalità né tempo: una sfida persa si riprova quando si vuole.

| Capitolo | Lezioni e guardiano (percorso) | Puzzle | Sfida finale |
|---|---|---|---|
| Il sentiero dei primi passi («Capitolo 0») | Come si muovono i pezzi | 3 matti in una, scelti tra i più facili | Tino (400 Elo) |
| Il villaggio dei pezzi | Catturare e difendere | 3 pezzi in presa | Pino |
| Le porte della città | Le regole | 3 promozioni | Chiara |
| La torre del re | Matti elementari, guardiano | 3 matti sulla traversa | Rocco |
| Il bosco delle trappole | Tattiche, guardiano | 4 forchette | Marta |
| Il castello dei finali | Finali, guardiano | 3 finali di pedoni | Duilio |
| La corona | Aperture, guardiano | 3 aperture | Elena |
| La pianura dei piani | La strategia, guardiano | 3 pedoni avanzati | Massimo |
| L'accademia del maestro | La scuola di Capablanca, guardiano | 3 finali di torri | Stella |

I bot sono quelli della scala (vedi [bot.md](bot.md)) in ordine di forza crescente; Tino, il custode del Capitolo 0, gioca solo nella Storia, al livello 0 (400 Elo, fuori dai livelli scelti dall'utente): la sfida usa il loro livello del motore, senza orologio e con **Annulla** (come il guardiano). Lo stile e il libro d'aperture del bot non sono applicati alla sfida.

## Passi

Dentro un capitolo ogni passo si apre quando quelli prima sono fatti:

1. **Lezioni**: tutte le lezioni del capitolo corrispondente del percorso (il guardiano è escluso). Si apre la prima non ancora completata.
2. **Puzzle**: risolvere al primo tentativo il numero indicato di puzzle del tema. `StoryPuzzleFeed` propone puzzle del tema finché l'obiettivo non è raggiunto; i puzzle si registrano come gli altri (punteggio e XP). Chi esce prima conserva quelli già risolti.
3. **Guardiano** (dove il capitolo del percorso ce l'ha): è la stessa partita del percorso, con le stesse stelle; battuto lì, conta anche qui.
4. **Sfida finale**: battere il bot del capitolo. Uscire a partita in corso vale una sconfitta.

Un passo già fatto non si riapre (lezioni, puzzle e partite restano raggiungibili dal resto dell'app). I passi che richiedono il motore (guardiano e sfida) mostrano un avviso dove Stockfish non c'è, come nel percorso. **Continua** apre il primo passo da fare del capitolo corrente.

## Aspetto

In cima una scheda mostra i capitoli conclusi con una barra. I capitoli sono lungo un binario verticale: ogni capitolo ha un badge con un anello di avanzamento (passi fatti su passi totali), il numero, la spunta a capitolo concluso o il lucchetto se è chiuso. Il capitolo corrente ha il bordo nel colore d'azione e la scritta «In corso»; quelli chiusi hanno il contorno tratteggiato e il testo che dice come aprirli. Lezioni e puzzle mostrano una barra con il conteggio, i passi fatti hanno la spunta e quelli bloccati il lucchetto, oltre al testo letto dai lettori di schermo. Contenuti e logica della storia non cambiano; i testi nuovi sono in `story.arb` (italiano e inglese).

## Foglio di passaggio

Quando un passo si conclude (lezioni, puzzle, guardiano o sfida), la schermata mostra un foglio dal basso che celebra il risultato e dice cosa viene dopo: dalle lezioni ai puzzle, dai puzzle alla sfida con il custode del capitolo (o al guardiano, dove c'è), e a capitolo concluso l'epilogo con l'apertura del capitolo successivo (o la fine della storia). L'icona compare con un breve rimbalzo, fermo se le animazioni sono disattivate. Il pulsante principale apre subito il passo successivo, «Più tardi» chiude il foglio. Una sfida persa resta un avviso, perché non c'è nulla da celebrare. La logica di avanzamento non cambia: il foglio legge lo stato dopo il passo, comparando con quello di prima. I testi sono `storyPassage*` in `story.arb`; in test `StoryPage.playLesson` sostituisce la schermata della lezione.

## Stato e salvataggio

Chi ha già battuto un bot o risolto dei puzzle in un capitolo successivo trova concluso anche il Capitolo 0 (`StoryProgress.isChapterDone`), così l'aggiunta del capitolo non toglie nulla a chi era più avanti. Lo stato deriva dal percorso: le lezioni e i guardiani completati contano così come sono, comprese le lezioni aggiunte con un aggiornamento dei contenuti (per questo la storia non elenca le singole lezioni, ma il capitolo del percorso). Salva da sé, in `story.json` (`StoryController`, con `JsonFile`), solo i puzzle risolti per capitolo e i capitoli con il bot battuto. Capitoli sconosciuti o valori illeggibili sono ignorati alla lettura.

## Testi e accessibilità

I testi (racconto, passi, avvisi) sono nei file `.arb` in italiano e in inglese; `story_l10n.dart` li associa ai capitoli. Il nome dei bot resta quello della scala. Ogni capitolo e ogni passo è un nodo per i lettori di schermo, con titolo e stato («da fare», «fatto», «bloccato»); l'avatar del bot è escluso dalla lettura.

## Come aggiungere un capitolo

I puzzle di un capitolo possono avere un tetto di difficoltà (`StoryChapter.puzzleRating`): il Capitolo 0 pesca puzzle fino a 500 punti anche se il punteggio dell'utente è più alto. Aggiungere un `StoryChapter` in `storyChapters` (capitolo del percorso, bot, tema e numero di puzzle) e le quattro stringhe `story<Id>Title`, `Intro`, `Boss` (con `{name}`), `Outro` nei due `.arb`, poi il caso in `story_l10n.dart`. I test controllano che il capitolo punti a un capitolo del percorso e a un bot esistenti, che i bot siano in ordine di forza, che il tema abbia puzzle a sufficienza e che ogni testo esista nelle due lingue.

## Componenti

| File | Ruolo |
|---|---|
| `story.dart` | Capitoli, stato salvato e avanzamento |
| `story_controller.dart` | Caricamento e salvataggio |
| `story_feed.dart` | Puzzle del tema fino all'obiettivo |
| `story_l10n.dart` | Testi dei capitoli |
| `story_page.dart` | Schermata della storia: riepilogo, binario dei capitoli, passi |
