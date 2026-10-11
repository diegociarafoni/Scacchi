# Minigiochi

Requisito RG-10. Il codice è in `lib/minigames/`: la logica è in file senza interfaccia, testati a parte, e le schermate la usano.

## I quattro minigiochi

| Minigioco | Identificativo | Come si gioca | Punteggio |
|---|---|---|---|
| Coordinate a tempo | `coordinate` | Si tocca la casa indicata su una scacchiera senza lettere né numeri, dal lato del bianco o del nero. Una casa sbagliata conta come errore e la richiesta resta | Case giuste in 30 secondi |
| Cattura tutto | `cattura` | Un pezzo bianco cattura tutti i pedoni neri. I pezzi lunghi non scavalcano i pedoni: il primo sulla linea si cattura. Cinque scacchiere di fila (torre, alfiere, cavallo, donna, cavallo), con i pedoni che crescono da 3 a 6 | Somma delle stelle, massimo 15 |
| Alla cieca | `cieca` | Si leggono 6 mosse giocate dalla posizione iniziale, senza scacchiera, e si indica cosa c'è su una casa toccata da quelle mosse. Dopo la risposta compare la posizione con la casa evidenziata | Risposte giuste su 10 |
| Conta del materiale | `materiale` | Su una posizione nata da una partita casuale si indica chi è in vantaggio e di quanto (pedone 1, cavallo e alfiere 3, torre 5, donna 9) | Risposte giuste su 10 |

Solo le coordinate hanno un limite di tempo, perché è il senso dell'esercizio; le altre domande non hanno orologio, nel rispetto di RG-12.

## Generazione

- Tutto si genera in locale con un `Random`; i test passano un seme fisso e ottengono sempre le stesse domande.
- **Cattura tutto**: il minimo di mosse si calcola con una ricerca in ampiezza sugli stati (casa del pezzo, pedoni rimasti), tenendo conto dei pedoni come ostacoli. Le stelle seguono la stessa regola delle tappe del percorso: tre al minimo, due con al massimo due mosse in più, una altrimenti. L'alfiere riceve solo pedoni sulle case del proprio colore, così ogni scacchiera è risolvibile; i test lo verificano su 200 scacchiere giocando la soluzione trovata.
- **Alla cieca**: mosse legali scelte a caso con `dartchess` (l'arrocco compare una volta sola, anche se la scacchiera lo accetta pure come re sulla torre); le scelte sono il pezzo giusto più tre alternative tra i dodici pezzi e la casa vuota.
- **Conta del materiale**: partita casuale da 20 a 49 semimosse, con le catture favorite per creare squilibri (comprese quelle en passant); la posizione non è mai finita. Le alternative sono vicine alla risposta (±1, ±2, ±3, ±5 o il segno opposto).

## Progressi

A fine sessione la schermata registra `MinigameFinished(game: 'coordinate', score: n, duration: d)`:

- 5 XP, come un puzzle, se il punteggio è almeno 1: una sessione a vuoto non vale XP;
- la durata, che conta per l'obiettivo giornaliero a minuti;
- il record del minigioco in `PersonalRecords.minigames`, mostrato nell'elenco dei minigiochi e nel Profilo;
- due traguardi: *Occhio di lince* (20 coordinate in una sessione) e *Giocoliere* (tutti i minigiochi provati).

Una sessione chiusa prima della fine (tasto indietro) è abbandonata e non si registra.

I minigiochi non contano come puzzle né come sessioni a tempo dei puzzle, così non falsano quei record e quelle sfide.

## Schermate

| File | Contenuto |
|---|---|
| `minigames_page.dart` | Elenco con descrizione e record; registra i punteggi se riceve un `ProgressController` |
| `coordinates_page.dart` | Scacchiera statica senza coordinate, conto alla rovescia, scelta del lato |
| `capture_all_page.dart` | Scacchiera interattiva, contatore di mosse e minimo, Ricomincia |
| `quiz_page.dart` | Dieci domande a scelta multipla, usata da Alla cieca e Conta del materiale |
| `board_layout.dart` | Scacchiera e pannello affiancati in orizzontale, impilati in verticale |

I minigiochi si aprono dalla scheda Tu e registrano punteggi e XP nei progressi.
