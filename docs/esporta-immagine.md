# Esporta la posizione come immagine

Requisito RF-104: la posizione sulla scacchiera diventa un'immagine PNG da condividere con il menu di sistema, senza server e senza account. Il codice è in `lib/share/`.

## Dove si trova

| Schermata | Comando | Posizione esportata |
|---|---|---|
| Partita | Menu ⋮ › **Esporta come immagine** | Quella mostrata, anche scorrendo le mosse, con l'ultima mossa evidenziata |
| Analisi | Icona immagine nella barra del titolo | La posizione analizzata, con la freccia della mossa migliore e la minaccia se attive |
| Puzzle | Icona immagine nella barra del titolo | La posizione da risolvere; non compaiono né la soluzione né gli errori |
| Editor di posizione | Icona immagine nella barra del titolo | La posizione costruita, con la scacchiera girata come nell'editor |

L'esportazione non c'è nel profilo bambino, nelle sfide contro guardiani e tornei e nelle serie a tempo dei puzzle, dove aprire un'altra schermata farebbe correre l'orologio.

## La schermata

L'anteprima mostra ciò che finirà nel file, con il tema della scacchiera e il set di pezzi scelti nelle impostazioni (vedi [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md)).

- **Capovolgi la scacchiera** (icona in alto): si parte dall'orientamento della schermata di provenienza.
- **Coordinate**: lettere e numeri nella cornice intorno alla scacchiera, dove non coprono mai i pezzi. Il valore iniziale segue «Mostra le coordinate» delle impostazioni.
- **Ultima mossa**: l'interruttore compare solo se la posizione ha un'ultima mossa.
- **Didascalia**: testo facoltativo fino a 80 caratteri, sotto la scacchiera su fondo scuro; righe e spazi in eccesso vengono ripuliti.
- **Condividi**: disegna il PNG e apre il menu di condivisione. Il file temporaneo (cartella `condivisione`) non si elimina subito, perché il sistema può leggerlo dopo l'invio: lo ripulisce la condivisione successiva o l'avvio dell'app; se la condivisione fallisce compare un avviso.

## File prodotto

PNG largo 1080 px (il fattore di scala si calcola dalla larghezza dell'anteprima), chiamato `rokko-posizione.png`. La scacchiera è disegnata con lo stesso componente di chessground usato nell'app: non serve alcuna libreria di immagini e l'APK non cresce.

## Accessibilità e testi

Pulsanti alti almeno 48 px, anteprima descritta come «Anteprima della scacchiera» al lettore di schermo (le case si leggono già dalla scacchiera accessibile delle schermate di provenienza). I testi sono nei file `.arb` con il prefisso `shareImage`, in italiano e inglese.

## Codice

- `lib/share/position_image.dart`: contenuto dell'immagine (`PositionImage`), pulizia della didascalia, larghezza di esportazione.
- `lib/share/position_image_page.dart`: schermata, pulsante `PositionImageButton` e `openPositionImage`.
- `lib/share/image_sharing.dart`: cattura di un `RepaintBoundary` in PNG e consegna al menu di condivisione, condivisi con [ritratto-settimana.md](ritratto-settimana.md).
- `lib/share/share_temp.dart`: cartella dei file temporanei di condivisione (anche del backup), ripulita alla condivisione successiva e all'avvio.

Test in `test/share/`, `test/game/game_image_test.dart`, nei test di analisi, puzzle ed editor e in `integration_test/position_image_test.dart`.
