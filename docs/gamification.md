# Gamification

Requisiti RG-01, RG-02, RG-05, RG-06, RG-07, RG-08, RG-11 e RG-12. Il codice è in `lib/progress/`, in Dart puro tranne la schermata e il controller.

## Principi

- Motivare senza punire: nessuna penalità per gli errori o le sconfitte, nessuna valuta, nulla di acquistabile.
- Tutto offline: lo stato è un file JSON locale.
- Tutto disattivabile: con l'interruttore generale spento non si registra nulla e il profilo mostra solo l'interruttore.

## Punti esperienza (RG-01)

| Attività | XP |
|---|---|
| Partita persa o tra due persone | 10 |
| Partita patta | 12 |
| Partita vinta | 15 |
| Puzzle risolto | 5 |
| Minigioco concluso con almeno un punto | 5 |
| Sessione di puzzle a tempo o a serie conclusa | 10 |
| Lezione completata | 20 |
| Revisione completata | 20 |
| Torneo concluso | 30 |
| Obiettivo giornaliero raggiunto | +10 |
| Sfida giornaliera completata | +20 |
| Sfida settimanale completata | +50 |

Le attività formative (lezioni, revisioni) valgono più della sola vittoria, come chiede il requisito.

### Livelli

Il livello *L* richiede `50 × L × (L − 1)` XP totali: livello 2 a 100 XP, 3 a 300, 4 a 600, 5 a 1000, 10 a 4500. Ogni livello costa 100 XP più del precedente, così i primi arrivano presto e i successivi restano raggiungibili.

## Obiettivo giornaliero e serie (RG-02)

- L'utente sceglie l'obiettivo tra 1 o 3 partite, 5 puzzle, 10 o 20 minuti. Il predefinito è una partita.
- I minuti sommano la durata di tutte le attività del giorno.
- Il giorno è quello di calendario locale: conta la data, non le 24 ore. Se l'orologio torna indietro (fuso orario, correzione dell'ora) resta valido il giorno più recente già visto, così la serie non conta due volte lo stesso giorno.
- L'obiettivo vale una volta al giorno: alzarlo dopo averlo raggiunto non allunga di nuovo la serie; abbassarlo sotto il progresso del giorno lo fa raggiungere subito.
- Ogni giorno con l'obiettivo raggiunto allunga la serie di uno. La serie resta valida per tutto il giorno successivo, finché il giorno non finisce.
- **Giorno di riposo**: un giorno della settimana a scelta che non interrompe la serie e non la allunga (se si gioca anche quel giorno, conta normalmente).
- **Protezione (congelamento)**: se ne guadagna una ogni 7 giorni di serie, al massimo 2. Copre automaticamente un giorno saltato. Non è acquistabile.
- Se i giorni saltati sono più delle protezioni disponibili, la serie torna a zero; il record personale resta.

## Sfide giornaliere e settimanali (RG-07)

- Ogni giorno tre sfide generate in locale dalla data: una di gioco (gioca 2 partite, vinci, vinci con il bianco o con il nero, dai matto in al massimo 30 mosse) e due tra puzzle (5 puzzle, 2 di forchetta, 2 di matto), revisione di una partita e lezione. La stessa data dà sempre le stesse sfide; il generatore è il finalizzatore a 32 bit di MurmurHash3 (`mix32`), con prodotti sotto 2^53: dà lo stesso risultato su Android, iOS, desktop e in JavaScript, e non dipende da `Random`.
- Una sfida settimanale (da lunedì a domenica): 10 partite, 5 vittorie, 25 puzzle, obiettivo raggiunto 5 giorni o 3 revisioni.
- Le sfide si completano una sola volta e danno XP bonus; nessuna penalità se restano incomplete.

## Record personali (RG-08)

Serie più lunga, bot più forte battuto (Elo), matto con meno mosse (solo vittorie per scacco matto, non per abbandono), precisione migliore in revisione, punteggio puzzle massimo e miglior punteggio per ciascuna modalità a tempo o a serie e per ciascun minigioco. Tutti i record sono elencati nel Profilo. La notifica in-app annuncia un record solo quando ne batte uno precedente (il primo valore si salva in silenzio) e, per il punteggio puzzle, solo quando supera un nuovo centinaio, per non ripetersi a ogni puzzle.

## Traguardi (RG-05)

37 traguardi in quattro categorie (gioco, tattica, costanza, curiosità), sbloccabili una sola volta e annunciati con una notifica in-app (`showProgressFeedback`). Alcuni esempi: prima vittoria, vittoria con il nero, miniatura (matto in meno di 20 mosse), bot da 1500 e 2000 Elo battuti, matto con il cavallo o con un pedone, vittoria con arrocco lungo, brillante trovata, 10 puzzle di forchetta o di matto, 20 punti in una modalità a tempo, giornata perfetta (tre sfide), 3, 7 e 30 giorni di fila, precisione del 90%, livello 5 e 10, 20 coordinate in una sessione, tutti i minigiochi provati, primo torneo concluso e primo torneo vinto. L'elenco completo è in `lib/progress/achievements.dart`.

## Ricompense estetiche (RG-06)

Livelli e traguardi sbloccano temi della scacchiera, set di pezzi, avatar e cornici. Le scelte di sempre (temi Verde, Legno, Blu e Grigio; pezzi Classico, Merida, Chessnut, Fantasy e Spatial; avatar Pedone e Cavallo) restano disponibili da subito: le ricompense aggiungono, non tolgono.

| Ricompensa | Si sblocca con |
|---|---|
| Tema Sabbia, avatar Alfiere | Livello 2 |
| Pezzi Celtic, cornice Bronzo | Livello 3 |
| Tema Oceano, avatar Torre | Livello 4 |
| Pezzi Firi | Livello 5 |
| Tema Corallo, cornice Argento | Livello 6 |
| Avatar Donna | Livello 7 |
| Pezzi RhosGFX | Livello 8 |
| Cornice Oro | Livello 10 |
| Tema Notte | 7 giorni di fila |
| Pezzi Shapes | 10 puzzle risolti |
| Pezzi Mpchess | Prima revisione |
| Pezzi Kiwen-suwi | Tutti i minigiochi provati |
| Pezzi Totoy | 10 vittorie |
| Cornice Fiamma | 30 giorni di fila |
| Cornice Alloro | Puzzle rating 1500 |
| Tema Oro, avatar Re | Primo torneo vinto |

La tabella completa è in `lib/progress/rewards.dart`. Una ricompensa appena meritata compare nella notifica dei progressi ("Sbloccato: tema Sabbia"). Nelle impostazioni i temi e i pezzi bloccati hanno un lucchetto e, toccati, dicono come si sbloccano; avatar e cornice si scelgono toccando l'avatar nel Profilo.

Per rispetto di RV-01, l'interruttore "Sblocca tutto" (nelle impostazioni dell'app e del Profilo) rende tutto disponibile. Con la gamification spenta non c'è nulla da sbloccare. Il tema o il set già scelto resta applicato anche se torna bloccato, per esempio spegnendo "Sblocca tutto".

## Promemoria giornaliero (RG-11)

Spento di default. Nel Profilo, "Promemoria giornaliero" chiede il permesso per le notifiche e l'orario (24 ore, proposto alle 19:00); se il permesso è negato resta spento e lo dice. Le regole sono in `lib/reminders/reminder.dart` (`nextReminder`), in Dart puro:

- al massimo una notifica al giorno, con un solo promemoria programmato alla volta;
- oggi solo se l'obiettivo manca e l'orario non è passato, altrimenti domani;
- mai nel giorno di riposo;
- il testo ricorda la serie in corso ("Serie di 4 giorni: basta 1 partita per continuarla.") o l'obiettivo, senza toni colpevolizzanti.

`ReminderController` si allinea all'avvio, al ritorno nell'app e quando cambiano obiettivo, orario o attività del giorno; con la gamification spenta cancella il promemoria. Chi non apre l'app per giorni riceve un solo promemoria, non uno al giorno: nessuna insistenza. `LocalNotificationScheduler` usa `flutter_local_notifications` con orario approssimato (`inexactAllowWhileIdle`), quindi non serve il permesso per le sveglie esatte; su Android il promemoria sopravvive al riavvio. Le notifiche programmate esistono solo su Android e iOS: altrove l'opzione non compare.

## Componenti

| File | Ruolo |
|---|---|
| `activity.dart` | Attività registrabili: partita, puzzle, sessione a tempo, lezione, revisione |
| `challenges.dart` | Tipi di sfida, generazione delle sfide del giorno e della settimana |
| `records.dart` | Record personali e loro aggiornamento |
| `game_activity.dart` | Converte una `ChessGame` conclusa in attività: risultato, pezzo che dà il matto (anche di scoperta o con l'arrocco), arrocco lungo |
| `xp.dart` | Tabella degli XP e curva dei livelli |
| `daily_goal.dart` | Obiettivo giornaliero e scelte proposte |
| `progress_state.dart` | Stato dei progressi e impostazioni, serializzabili in JSON |
| `progress_tracker.dart` | Regole: XP, obiettivo, serie, protezioni, traguardi. Funzioni pure, con l'ora passata come parametro |
| `achievements.dart` | Elenco dei traguardi e condizioni di sblocco |
| `rewards.dart` | Ricompense estetiche e condizioni di sblocco (livello o traguardo) |
| `avatar.dart` | Avatar e cornici del profilo |
| `progress_store.dart` | Salvataggio su file JSON tramite `JsonFile` |
| `progress_controller.dart` | `ChangeNotifier` per l'interfaccia: carica, registra, salva |
| `progress_feedback.dart` | Notifica in-app di XP, livello, obiettivo e traguardi |
| `profile_page.dart` | Schermata Profilo con avatar, livello, serie, obiettivo, traguardi, promemoria e impostazioni |

## Salvataggio

Il file `progress.json` sta nella cartella dati dell'app (`getApplicationSupportDirectory`). Contiene `version` (oggi 1), `settings` e `state`. Il file passa da `JsonFile` (`lib/storage/json_file.dart`), condiviso con l'archivio delle partite: scrittura atomica, salvataggi accodati, file non valido (JSON rotto o versione futura) rinominato in `progress.json.bad-<ms>` invece di essere sovrascritto. Se invece il disco non si lascia leggere, il controller passa in sola lettura (`readOnly`): si gioca senza salvare, così i progressi sul disco non vengono sovrascritti. Quando arriverà il database locale (RNF-08), questo file sarà importato alla prima migrazione.

## Uso dall'interfaccia

```dart
final progress = await ProgressController.open();
final update = await progress.record(
  gameActivity(game, player: Side.white, opponentElo: 1200, duration: elapsed),
);
if (context.mounted) showProgressFeedback(context, update);
```

Per le partite tra due persone si omettono `player` e `opponentElo`: la partita vale XP e conta per l'obiettivo, senza vittoria o sconfitta.

Le altre schermate registrano:

| Schermata | Attività |
|---|---|
| Puzzle | `PuzzleSolved(themes: {...}, rating: r)` a ogni puzzle risolto; `PuzzleRunFinished(mode: 'rush5', score: n)` a fine sessione a tempo |
| Revisione | `ReviewCompleted(accuracy: 87.5, brilliantMoves: 1)` a fine analisi |
| Lezioni e percorso | `LessonCompleted()` |
| Minigiochi | `MinigameFinished(game: 'coordinate', score: n)` a fine sessione (vedi [minigiochi.md](minigiochi.md)) |
| Tornei | `TournamentFinished(rank: 1, players: 8)` a fine torneo (vedi [tornei.md](tornei.md)) |

## Integrazione prevista

Il Profilo si apre dalla scheda Tu e `HomeShell` crea il `ReminderController` all'avvio su Android e iOS. `GamePage` riceve da `HomeShell` il registratore delle attività e i progressi: a fine partita registra `GamePlayed` (con `gameActivity`) una sola volta per partita e mostra "+N XP" sopra la barra dei comandi; le impostazioni ricevono i progressi per bloccare temi e pezzi non ancora sbloccati.

Valgono solo le partite iniziate da **Nuova** e di almeno 4 semimosse: abbandonare subito o giocare una posizione preparata con l'editor non fa guadagnare XP. La durata che conta per l'obiettivo a minuti è al massimo un'ora per partita, per non gonfiarla con le pause. Dopo un annulla dell'abbandono la stessa partita non assegna XP una seconda volta. Le partite dei guardiani del percorso (vedi [percorso.md](percorso.md)) valgono XP come le altre, e così le partite dei tornei (vedi [tornei.md](tornei.md)).
