# Editor di posizione

Requisito RF-53. Si apre dalla partita con la voce **Editor di posizione** del menu ⋮ nella barra in alto (non c'è nelle sfide contro guardiani e tornei né nel profilo bambino) e parte dalla posizione mostrata in quel momento, con il set di pezzi e i colori scelti nelle impostazioni. La partita che si avvia è sempre di scacchi classici, anche se si parte da una variante.

## Comandi

| Comando | Effetto |
|---|---|
| Tavolozza dei pezzi | Sceglie il pezzo da posare; toccando una casa lo si mette, toccando un pezzo uguale lo si toglie |
| Gomma | Toccando una casa la svuota |
| Bianco / Nero | Giocatore con il tratto |
| O-O / O-O-O per colore | Diritti di arrocco; attivabili solo con re e torre sulle case iniziali, e tolti da soli quando uno dei due si sposta |
| Iniziale, Svuota | Posizione iniziale o scacchiera vuota |
| Inverti colori | Scambia i colori dei pezzi e li specchia tra le due metà della scacchiera, inverte il tratto e i diritti di arrocco: la stessa posizione vista dall'altro colore |
| Capovolgi la scacchiera (icona in alto) | Cambia solo il lato da cui si guarda la scacchiera |
| Incolla FEN, Copia FEN | Import ed export della posizione; il FEN corrente è sempre visibile e selezionabile |
| Gioca da qui | Avvia una partita a due senza orologio dalla posizione; attivo solo se la posizione è legale |

## Validazione

La posizione è controllata con dartchess (`Chess.fromSetup`). Il messaggio sotto la scacchiera spiega il problema:

- scacchiera vuota;
- non c'è esattamente un re per colore;
- pedoni in prima o in ottava traversa;
- il giocatore che non ha il tratto è sotto scacco;
- scacco non raggiungibile con mosse legali (troppi pezzi che danno scacco, o scacco impossibile dopo la spinta di due case indicata dall'en passant);
- partita già finita: matto, stallo, materiale insufficiente o regola delle 50 mosse raggiunta dal contatore del FEN.

La casa en passant viene letta dal FEN, scartata se non è sulla traversa giusta o non c'è il pedone appena spinto, e conservata finché i pezzi non cambiano. I contatori delle semimosse e delle mosse del FEN incollato sono conservati, anche invertendo i colori.

## Codice

- `lib/editor/position_draft.dart`: modello immutabile della posizione in costruzione (Dart puro), con arrocco, tratto, FEN e validazione.
- `lib/editor/position_editor_page.dart`: schermata; restituisce la `Position` scelta con `Navigator.pop`.
- `GamePage._editPosition`: apre l'editor, chiede come giocare la posizione e avvia la partita.

## Giocare la posizione contro il computer (RF-24)

Dopo **Gioca da qui**, se il computer è disponibile (vedi [avversario-computer.md](avversario-computer.md)), compare il pannello **Gioca questa posizione**, con la stessa scelta della nuova partita: **Due giocatori** (predefinito) o **Bot** (colore, Adattivo o un bot). **Gioca** avvia la partita dalla posizione; il computer muove subito se tocca a lui. Il bot non usa il suo libro d'apertura, perché la posizione non è quella iniziale. Chiudere il pannello senza scegliere lascia la partita com'era. Se il computer non è disponibile, la posizione si gioca direttamente in due.

La partita dalla posizione non ha orologio e resta di scacchi classici.

Le partite da una posizione creata non aggiornano la stima dell'avversario adattivo né la collezione dei bot: contano solo quelle dalla posizione iniziale degli scacchi classici.

Sopra la stringa FEN c'è il titolo **Posizione (FEN)** con l'icona di aiuto (?) che apre una breve spiegazione: cos'è il FEN e come copiarlo o incollarlo in altre app. Titolo e testi sono nei file di traduzione (`editorFen*`).
