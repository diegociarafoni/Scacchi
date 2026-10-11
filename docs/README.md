# Documentazione di Scacchi

Scacchi è un'applicazione di scacchi offline, open source e gratuita, pensata prima di tutto per il telefono (Android e iOS) e disponibile anche su desktop (Windows, macOS, Linux).

## Indice

| Documento | Contenuto |
|---|---|
| [architettura.md](architettura.md) | Stack, struttura delle cartelle, componenti e flusso di una mossa |
| [regole-di-gioco.md](regole-di-gioco.md) | Regole implementate e condizioni di fine partita |
| [interfaccia.md](interfaccia.md) | Schermata di gioco, layout su telefono e tablet, comandi |
| [gamification.md](gamification.md) | XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense estetiche, promemoria |
| [editor-posizione.md](editor-posizione.md) | Editor di posizione, FEN e validazione |
| [archivio.md](archivio.md) | Salvataggio delle partite, storico, import ed export PGN |
| [ritratto-settimana.md](ritratto-settimana.md) | Scheda degli ultimi sette giorni, condivisibile come immagine |
| [scacchiera-fisica.md](scacchiera-fisica.md) | Orologio e registro di una partita su scacchiera reale |
| [backup.md](backup.md) | Backup e ripristino di tutti i dati locali in un file |
| [puzzle.md](puzzle.md) | Puzzle: dati, punteggio, modalità, puzzle del giorno |
| [aperture.md](aperture.md) | Nomi delle aperture, mosse di libro, explorer, repertorio |
| [percorso.md](percorso.md) | Percorso a tappe con stelle e bot guardiani |
| [statistiche.md](statistiche.md) | Statistiche delle partite e rating locale stimato |
| [minigiochi.md](minigiochi.md) | Coordinate a tempo, cattura tutto, visualizzazione alla cieca, conta del materiale |
| [tornei.md](tornei.md) | Tornei offline contro bot: girone, eliminazione diretta, bacheca |
| [profilo-bambino.md](profilo-bambino.md) | Profilo bambino: interfaccia semplificata, bot amichevoli, niente numeri |
| [localizzazione.md](localizzazione.md) | Lingua predefinita e come aggiungere testi e lingue |
| [sviluppo.md](sviluppo.md) | Ambiente, comandi, test, CI e convenzioni |
| [convenzioni-git.md](convenzioni-git.md) | Rami, commit Angular, hook locali, merge e protezione di `main` |
| [sicurezza.md](sicurezza.md) | Scanner di sicurezza, SBOM e catena di fornitura |
| [dipendenze-e-licenze.md](dipendenze-e-licenze.md) | Aggiornamenti automatici e licenze ammesse |
| [avversario-computer.md](avversario-computer.md) | Partita contro il computer: livelli, motore Stockfish, piattaforme |
| [bot.md](bot.md) | Bot con personalità: scala degli 8 bot, stile di gioco, libro d'apertura, frasi |
| [revisione-partita.md](revisione-partita.md) | Revisione della partita: probabilità di vittoria, classificazione delle mosse, precisione |
| [allenatore.md](allenatore.md) | Partita con l'allenatore: avvisi in tempo reale, ripresa della mossa, suggerimenti a livelli |
| [analisi.md](analisi.md) | Analisi libera della posizione: linee del motore, barra, esplorazione |
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
| Partita contro il computer (Stockfish) | Disponibile su Android e iOS |
| Puzzle con punteggio, temi e puzzle del giorno | Disponibile |
| Puzzle Storm, Rush, sopravvivenza, Serie, ripasso degli errori | Disponibile |
| Nome dell'apertura in partita, explorer ridotto | Disponibile |
| Repertorio di aperture con ripasso dilazionato | Disponibile |
| Gamification: XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense estetiche, promemoria | Disponibile: XP a fine partita, Profilo e promemoria dalla scheda Tu |
| La tua settimana: scheda condivisibile degli ultimi sette giorni | Disponibile dalla scheda Tu |
| Scacchiera fisica: orologio e registro della partita dal vivo | Disponibile dalla scheda Tu |
| Backup e ripristino dei dati in un file | Disponibile dalle Impostazioni |
| Archivio partite, import ed export PGN | Disponibile dalla scheda Tu; le partite finite si salvano da sole, riprendere una partita è in arrivo |
| Percorso a tappe con stelle | Disponibile dalla scheda Tu, con i guardiani su Android e iOS |
| Statistiche e rating locale | Disponibile dalla scheda Tu |
| Editor di posizione con FEN e validazione | Disponibile |
| Varianti: Chess960, Re della collina, Tre scacchi | Disponibile nella partita a due |
| Minigiochi | Disponibile dalla scheda Tu, con record e XP |
| Tornei contro bot | Formule, classifica, tabellone e bacheca; si giocano dalla scheda Tu contro il motore (Android e iOS) |
| Orologio con cadenze e incremento | Disponibile |
| Suoni, vibrazione, modalità tavolo | Disponibile |
| Revisione della partita: classificazione, precisione, grafico, Riprova | Disponibile dove c'è il motore (Android e iOS) |
| Analisi libera della posizione con linee del motore | Disponibile dove c'è il motore (Android e iOS) |

I requisiti completi sono nel documento dei requisiti del progetto.
