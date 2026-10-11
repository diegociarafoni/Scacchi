# Documentazione di Scacchi

Scacchi è un'applicazione di scacchi offline, open source e gratuita, pensata prima di tutto per il telefono (Android e iOS) e disponibile anche su desktop (Windows, macOS, Linux).

## Indice

| Documento | Contenuto |
|---|---|
| [architettura.md](architettura.md) | Stack, struttura delle cartelle, componenti e flusso di una mossa |
| [regole-di-gioco.md](regole-di-gioco.md) | Regole implementate e condizioni di fine partita |
| [interfaccia.md](interfaccia.md) | Schermata di gioco, layout su telefono e tablet, comandi |
| [gamification.md](gamification.md) | XP, livelli, obiettivo giornaliero, serie, traguardi |
| [archivio.md](archivio.md) | Salvataggio delle partite, storico, import ed export PGN |
| [puzzle.md](puzzle.md) | Puzzle: dati, punteggio, modalità, puzzle del giorno |
| [aperture.md](aperture.md) | Nomi delle aperture, mosse di libro, explorer |
| [percorso.md](percorso.md) | Percorso a tappe con stelle e bot guardiani |
| [statistiche.md](statistiche.md) | Statistiche delle partite e rating locale stimato |
| [minigiochi.md](minigiochi.md) | Coordinate a tempo, cattura tutto, visualizzazione alla cieca, conta del materiale |
| [tornei.md](tornei.md) | Tornei offline contro bot: girone, eliminazione diretta, bacheca |
| [sviluppo.md](sviluppo.md) | Ambiente, comandi, test, CI e convenzioni |
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
| Gamification: XP, livelli, obiettivo giornaliero, serie, traguardi | Logica e Profilo disponibili, collegamento alla partita in sviluppo |
| Archivio partite, import ed export PGN | Logica e schermata disponibili, collegamento alla partita in sviluppo |
| Percorso a tappe con stelle | Mappa ed esercizi pronti; accesso dalla schermata principale e guardiani in arrivo con il collegamento alla partita |
| Statistiche e rating locale | Calcolo e schermata pronti; accesso dalla schermata principale in arrivo |
| Minigiochi | Quattro minigiochi pronti con record e XP; accesso dalla schermata principale in arrivo |
| Tornei contro bot | Formule, classifica, tabellone e bacheca pronti; partite e accesso in arrivo con la partita contro il computer |
| Orologio con cadenze e incremento | Disponibile |

I requisiti completi sono nel documento dei requisiti del progetto.
