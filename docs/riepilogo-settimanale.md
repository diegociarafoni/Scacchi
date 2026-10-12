# Riepilogo settimanale

Requisito RG-16: una scheda offline sugli ultimi sette giorni con i progressi, l'errore ricorrente più frequente e un solo consiglio con il collegamento alla lezione o ai puzzle adatti. Si apre da **Tu → Riepilogo settimanale**. Differisce da [La tua settimana](ritratto-settimana.md), che racconta le partite (aperture, matti) e si condivide come immagine: qui si guarda ai progressi e a cosa allenare.

## Cosa mostra

- **Progressi**: partite (vinte, patte, perse), puzzle risolti, lezioni completate, revisioni, minuti di allenamento e precisione media delle revisioni, con la differenza rispetto ai sette giorni precedenti. Le righe a zero non compaiono.
- **Errore più frequente**: il tema che il coach ha riconosciuto più spesso negli errori delle tue partite riviste (pezzi lasciati in presa, forchette subite o mancate, inchiodature, matti, re scoperto, catture mancate, perdite di materiale). Conta solo se compare almeno due volte; i commenti generici non contano.
- **Un consiglio**, scelto così, nell'ordine:
  1. se c'è un errore ricorrente, la lezione del Percorso o i puzzle del tema che lo corregge (tabella sotto), con un pulsante per aprirli;
  2. se hai giocato ma non rivisto nulla, rivedere una partita;
  3. se non hai risolto puzzle, risolverne qualcuno;
  4. altrimenti, continuare così.

| Errore | Collegamento |
|---|---|
| Pezzo in presa | Lezione «Pezzi indifesi» |
| Forchetta subita o mancata | Lezione «La forchetta» |
| Inchiodatura subita | Lezione «L'inchiodatura» |
| Attacco di scoperta mancato | Lezione «L'attacco di scoperta» |
| Re esposto | Lezione «L'arrocco» |
| Matto mancato | Lezione «Matto in due» |
| Matto subito | Puzzle «Mossa difensiva» |
| Perdita di materiale | Puzzle «Mossa difensiva» |
| Cattura mancata | Puzzle «Pezzo in presa» |

## Da dove vengono i dati

Un diario locale (`week.json`, nella cartella dati dell'app) tiene, per ciascuno degli ultimi 14 giorni, soltanto i **conteggi**: partite per esito, puzzle, lezioni, revisioni, secondi di allenamento, somma delle precisioni e conteggio degli errori per tema. Non contiene mosse, posizioni né nomi. Lo aggiorna `ProgressController.record` a ogni attività registrata; i giorni più vecchi si eliminano da soli. Ogni revisione porta l'identificativo della partita, così rivedere due volte la stessa partita non raddoppia gli errori.

Le partite tra due persone sullo stesso dispositivo non contano (non c'è un lato dell'utente). Con i progressi disattivati (RG-12) il diario non registra nulla.

## Profilo bambino

Niente numeri (RP-06): al posto dei conteggi, stelle per i giorni in cui ti sei allenato e frasi come «Questa settimana hai giocato e risolto puzzle»; l'errore è nominato a parole e il consiglio è una frase breve.

## Accessibilità e testi

Tutti i testi sono nei file `.arb` (italiano e inglese). Le sezioni sono intestazioni per i lettori di schermo, le stelle hanno un'etichetta parlata e il pulsante del consiglio ha un'area di tocco da almeno 48 punti.

## Codice

- `lib/summary/week_log.dart`: diario dei conteggi e archivio su file.
- `lib/summary/weekly_summary.dart`: calcolo del riepilogo e scelta del consiglio, in Dart puro.
- `lib/summary/weekly_summary_page.dart`: scheda.
- `lib/review/error_themes.dart` e `lib/review/review_activity.dart`: conteggio degli errori per tema e attività registrata a revisione finita.

Test in `test/summary/` e `test/review/error_themes_test.dart`.
