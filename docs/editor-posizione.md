# Editor di posizione

Requisito RF-53. Si apre dalla partita con l'icona **Editor di posizione** nella barra in alto e parte dalla posizione mostrata in quel momento (per le varianti parte dalla posizione iniziale degli scacchi).

## Comandi

| Comando | Effetto |
|---|---|
| Tavolozza dei pezzi | Sceglie il pezzo da posare; toccando una casa lo si mette, toccando un pezzo uguale lo si toglie |
| Gomma | Toccando una casa la svuota |
| Bianco / Nero | Giocatore con il tratto |
| O-O / O-O-O per colore | Diritti di arrocco; attivabili solo con re e torre sulle case iniziali, e tolti da soli quando uno dei due si sposta |
| Iniziale, Svuota | Posizione iniziale o scacchiera vuota |
| Inverti colori | Scambia i colori dei pezzi e capovolge la scacchiera, per studiare la stessa posizione dall'altro lato |
| Incolla FEN, Copia FEN | Import ed export della posizione; il FEN corrente è sempre visibile e selezionabile |
| Gioca da qui | Avvia una partita a due senza orologio dalla posizione; attivo solo se la posizione è legale |

## Validazione

La posizione è controllata con dartchess (`Chess.fromSetup`). Il messaggio sotto la scacchiera spiega il problema:

- scacchiera vuota;
- non c'è esattamente un re per colore;
- pedoni in prima o in ottava traversa;
- il giocatore che non ha il tratto è sotto scacco;
- scacco non raggiungibile con mosse legali (troppi pezzi che danno scacco, o scacco impossibile dopo la spinta di due case indicata dall'en passant).

La casa en passant viene letta dal FEN e conservata finché la posizione non cambia; qualsiasi modifica la cancella. I contatori delle semimosse e delle mosse del FEN incollato sono conservati.

## Codice

- `lib/editor/position_draft.dart`: modello immutabile della posizione in costruzione (Dart puro), con arrocco, tratto, FEN e validazione.
- `lib/editor/position_editor_page.dart`: schermata; restituisce la `Position` scelta con `Navigator.pop`.
- `GamePage._editPosition`: apre l'editor e avvia la partita.

Da fare: partenza dalla posizione contro il computer (RF-24), quando la partita contro Stockfish sarà su `main`.
