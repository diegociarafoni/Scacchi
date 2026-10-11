# Documentazione di Scacchi

Scacchi è un'applicazione di scacchi offline, open source e gratuita, pensata prima di tutto per il telefono (Android e iOS) e disponibile anche su desktop (Windows, macOS, Linux).

## Indice

| Documento | Contenuto |
|---|---|
| [architettura.md](architettura.md) | Stack, struttura delle cartelle, componenti e flusso di una mossa |
| [regole-di-gioco.md](regole-di-gioco.md) | Regole implementate e condizioni di fine partita |
| [interfaccia.md](interfaccia.md) | Schermata di gioco, layout su telefono e tablet, comandi |
| [gamification.md](gamification.md) | XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense estetiche, promemoria |
| [archivio.md](archivio.md) | Salvataggio delle partite, storico, import ed export PGN |
| [puzzle.md](puzzle.md) | Puzzle: dati, punteggio, modalità, puzzle del giorno |
| [aperture.md](aperture.md) | Nomi delle aperture, mosse di libro, explorer, repertorio |
| [percorso.md](percorso.md) | Percorso a tappe con stelle e bot guardiani |
| [statistiche.md](statistiche.md) | Statistiche delle partite e rating locale stimato |
| [minigiochi.md](minigiochi.md) | Coordinate a tempo, cattura tutto, visualizzazione alla cieca, conta del materiale |
| [tornei.md](tornei.md) | Tornei offline contro bot: girone, eliminazione diretta, bacheca |
| [sviluppo.md](sviluppo.md) | Ambiente, comandi, test, CI e convenzioni |
| [rilascio-android.md](rilascio-android.md) | Rilascio dell'APK, installazione sul telefono, chiave di firma |
| [licenza.md](licenza.md) | Licenza del progetto e componenti di terze parti |

## Stato del progetto

| Funzione | Stato |
|---|---|
| Partita tra due persone sullo stesso dispositivo | Disponibile |
| Regole complete e fine partita | Disponibile |
| Layout per telefono e tablet | Disponibile |
| Pezzi catturati e vantaggio di materiale | Disponibile |
| Impostazioni salvate: mosse legali, coordinate, promozione, frecce, temi, pezzi, animazioni | Disponibile |
| Partita contro il computer (Stockfish) | In sviluppo |
| Puzzle con punteggio, temi e puzzle del giorno | Disponibile |
| Puzzle Storm, Rush, sopravvivenza, Serie, ripasso degli errori | Disponibile |
| Nome dell'apertura in partita, explorer ridotto | Disponibile |
| Repertorio di aperture con ripasso dilazionato | Disponibile |
| Gamification: XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense estetiche, promemoria | Profilo e promemoria disponibili dalla scheda Tu; XP delle partite in arrivo con il collegamento alla partita |
| Archivio partite, import ed export PGN | Disponibile dalla scheda Tu; salvataggio automatico delle partite in arrivo con il collegamento alla partita |
| Percorso a tappe con stelle | Disponibile dalla scheda Tu; guardiani in arrivo con la partita contro il computer |
| Statistiche e rating locale | Disponibile dalla scheda Tu |
| Varianti: Chess960, Re della collina, Tre scacchi | Disponibile nella partita a due |
| Minigiochi | Disponibile dalla scheda Tu, con record e XP |
| Tornei contro bot | Formule, classifica, tabellone e bacheca pronti; partite e accesso in arrivo con la partita contro il computer |
| Orologio con cadenze e incremento | Disponibile |
| Suoni, vibrazione, modalità tavolo | Disponibile |

I requisiti completi sono nel documento dei requisiti del progetto.
