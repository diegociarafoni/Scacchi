# Gamification

Nucleo P0 dei requisiti RG-01, RG-02 e RG-12, con i primi traguardi di RG-05. Il codice è in `lib/progress/`, in Dart puro tranne la schermata e il controller.

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
| Lezione completata | 20 |
| Revisione completata | 20 |
| Obiettivo giornaliero raggiunto | +10 |

Le attività formative (lezioni, revisioni) valgono più della sola vittoria, come chiede il requisito.

### Livelli

Il livello *L* richiede `50 × L × (L − 1)` XP totali: livello 2 a 100 XP, 3 a 300, 4 a 600, 5 a 1000, 10 a 4500. Ogni livello costa 100 XP più del precedente, così i primi arrivano presto e i successivi restano raggiungibili.

## Obiettivo giornaliero e serie (RG-02)

- L'utente sceglie l'obiettivo tra 1 o 3 partite, 5 puzzle, 10 o 20 minuti. Il predefinito è una partita.
- I minuti sommano la durata di tutte le attività del giorno.
- Il giorno è quello di calendario locale: conta la data, non le 24 ore.
- Ogni giorno con l'obiettivo raggiunto allunga la serie di uno. La serie resta valida per tutto il giorno successivo, finché il giorno non finisce.
- **Giorno di riposo**: un giorno della settimana a scelta che non interrompe la serie e non la allunga (se si gioca anche quel giorno, conta normalmente).
- **Protezione (congelamento)**: se ne guadagna una ogni 7 giorni di serie, al massimo 2. Copre automaticamente un giorno saltato. Non è acquistabile.
- Se i giorni saltati sono più delle protezioni disponibili, la serie torna a zero; il record personale resta.

## Traguardi (RG-05)

17 traguardi in quattro categorie (gioco, tattica, costanza, curiosità), sbloccabili una sola volta e annunciati con una notifica in-app (`showProgressFeedback`). Alcuni esempi: prima partita, prima vittoria, matto con il cavallo, matto con un pedone, vittoria con arrocco lungo, 3, 7 e 30 giorni di fila, livello 5 e 10. L'elenco completo è in `lib/progress/achievements.dart`. Il requisito RG-05 (P1) chiede almeno 30 traguardi: gli altri arriveranno con puzzle, revisione e bot.

## Componenti

| File | Ruolo |
|---|---|
| `activity.dart` | Attività registrabili: partita, puzzle, lezione, revisione |
| `game_activity.dart` | Converte una `ChessGame` conclusa in attività: risultato, pezzo del matto, arrocco lungo |
| `xp.dart` | Tabella degli XP e curva dei livelli |
| `daily_goal.dart` | Obiettivo giornaliero e scelte proposte |
| `progress_state.dart` | Stato dei progressi e impostazioni, serializzabili in JSON |
| `progress_tracker.dart` | Regole: XP, obiettivo, serie, protezioni, traguardi. Funzioni pure, con l'ora passata come parametro |
| `achievements.dart` | Elenco dei traguardi e condizioni di sblocco |
| `progress_store.dart` | Salvataggio su file JSON con versione dello schema e scrittura atomica |
| `progress_controller.dart` | `ChangeNotifier` per l'interfaccia: carica, registra, salva |
| `progress_feedback.dart` | Notifica in-app di XP, livello, obiettivo e traguardi |
| `profile_page.dart` | Schermata Profilo con livello, serie, obiettivo, traguardi e impostazioni |

## Salvataggio

Il file `progress.json` sta nella cartella dati dell'app (`getApplicationSupportDirectory`). Contiene `version` (oggi 1), `settings` e `state`. Un file mancante o illeggibile non blocca l'app: si riparte dallo stato iniziale. Quando arriverà il database locale (RNF-08), questo file sarà importato alla prima migrazione.

## Uso dall'interfaccia

```dart
final progress = await ProgressController.open();
final update = await progress.record(
  gameActivity(game, player: Side.white, duration: elapsed),
);
if (context.mounted) showProgressFeedback(context, update);
```

Per le partite tra due persone si omette `player`: la partita vale XP e conta per l'obiettivo, senza vittoria o sconfitta.

## Integrazione prevista

Il collegamento alla schermata di gioco (registrazione a fine partita e accesso al Profilo) arriva in una modifica separata, per non sovrapporsi al lavoro in corso sulla partita contro il computer.
