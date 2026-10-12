# Documentazione di Rokko

Rokko è un'applicazione di scacchi offline, open source e gratuita, pensata prima di tutto per il telefono (Android e iOS) e disponibile anche su desktop (Windows, macOS, Linux).

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
| [scambio-qr.md](scambio-qr.md) | Passare una partita, anche in corso, a un altro telefono con il QR, senza rete |
| [multigiocatore.md](multigiocatore.md) | Partita tra due telefoni: protocollo, canali locali e a distanza, sicurezza |
| [backup.md](backup.md) | Backup e ripristino di tutti i dati locali in un file |
| [puzzle.md](puzzle.md) | Puzzle: dati, punteggio, modalità, puzzle del giorno |
| [aperture.md](aperture.md) | Nomi delle aperture, mosse di libro, Esplora aperture, repertorio |
| [percorso.md](percorso.md) | Percorso a tappe con stelle e bot guardiani |
| [storia.md](storia.md) | Percorso a storia: capitoli, puzzle e sfide a tema sopra il percorso |
| [finali.md](finali.md) | Allenatore dei finali contro il motore: Lucena, Philidor, matti elementari |
| [statistiche.md](statistiche.md) | Statistiche delle partite e rating locale stimato |
| [minigiochi.md](minigiochi.md) | Coordinate a tempo, cattura tutto, visualizzazione alla cieca, conta del materiale |
| [tornei.md](tornei.md) | Tornei offline contro bot: girone, eliminazione diretta, bacheca |
| [profilo-bambino.md](profilo-bambino.md) | Profilo bambino: interfaccia semplificata, bot amichevoli, niente numeri |
| [pezzi-e-scacchiere.md](pezzi-e-scacchiere.md) | Set di pezzi e scacchiere di Rokko, alone sui temi scuri, coordinate esterne, rigenerazione delle immagini |
| [identita-visiva.md](identita-visiva.md) | Nome, icona, schermata di avvio e come rigenerarli |
| [localizzazione.md](localizzazione.md) | Lingua predefinita e come aggiungere testi e lingue |
| [sviluppo.md](sviluppo.md) | Ambiente, comandi, test, CI e convenzioni |
| [convenzioni-git.md](convenzioni-git.md) | Rami, commit Angular, hook locali, merge e protezione di `main` |
| [qualita.md](qualita.md) | Copertura, golden test, accessibilità e relativi limiti |
| [mappa-del-codice.md](mappa-del-codice.md) | Cartelle di `lib/` e documento che le descrive, controllo automatico della documentazione |
| [sicurezza.md](sicurezza.md) | Scanner di sicurezza, SBOM e catena di fornitura |
| [dipendenze-e-licenze.md](dipendenze-e-licenze.md) | Aggiornamenti automatici e licenze ammesse |
| [avversario-computer.md](avversario-computer.md) | Partita contro il computer: livelli, motore Stockfish, piattaforme |
| [bot.md](bot.md) | Bot con personalità: scala degli 8 bot, stile di gioco, libro d'apertura, frasi |
| [revisione-partita.md](revisione-partita.md) | Revisione della partita: probabilità di vittoria, classificazione, precisione (anche per fase), coach testuale, puzzle dagli errori |
| [notazione.md](notazione.md) | Notazione delle mosse: figurativa, italiana, inglese |
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
| Partita contro il computer (Stockfish) | Disponibile su Android e iOS; su Windows e Linux con Stockfish installato |
| Puzzle con punteggio, temi e puzzle del giorno | Disponibile |
| Puzzle: combo a tempo, corsa, sopravvivenza, serie, ripasso degli errori, con la spiegazione di ogni modalità | Disponibile |
| Nome dell'apertura in partita (in italiano), Esplora aperture | Disponibile |
| Repertorio di aperture con ripasso dilazionato | Disponibile |
| Gamification: XP, livelli, obiettivo giornaliero, serie, traguardi, ricompense estetiche, promemoria | Disponibile: XP a fine partita, Profilo e promemoria dalla scheda Tu |
| La tua settimana: scheda condivisibile degli ultimi sette giorni | Disponibile dalla scheda Tu |
| Scacchiera fisica: orologio e registro della partita dal vivo | Disponibile dalla scheda Tu |
| Scambio di partite tra telefoni con il QR, senza rete | Disponibile dal menu della partita e dall'archivio; lettura con la fotocamera su Android e iOS |
| Multigiocatore tra due telefoni (Wi-Fi, Bluetooth, a distanza) | Nucleo del protocollo pronto, canali e schermate in arrivo |
| Backup e ripristino dei dati in un file | Disponibile dalle Impostazioni |
| Archivio partite, import ed export PGN | Disponibile dalla scheda Tu; le partite finite si salvano da sole, riprendere una partita è in arrivo |
| Percorso a tappe con stelle e spiegazione di ogni tappa: pezzi, regole, matti elementari e famosi, tattiche, finali di pedoni, aperture | Disponibile dalla scheda Tu, con i guardiani dove c'è il motore |
| Statistiche e rating locale | Disponibile dalla scheda Tu |
| Editor di posizione con FEN e validazione | Disponibile |
| Varianti: Chess960, Re della collina, Tre scacchi | Disponibile nella partita a due |
| Minigiochi | Disponibile dalla scheda Tu, con record e XP |
| Tornei contro bot | Formule, classifica, tabellone e bacheca; si giocano dalla scheda Tu contro il motore (Android e iOS; Windows e Linux con Stockfish installato) |
| Orologio con cadenze e incremento | Disponibile |
| Suoni, vibrazione, modalità tavolo | Disponibile |
| Revisione della partita: classificazione, precisione anche per fase, grafico, Riprova | Disponibile dove c'è il motore (Android e iOS; Windows e Linux con Stockfish installato), anche dall'archivio |
| Analisi libera della posizione con linee del motore e freccia della minaccia | Disponibile dove c'è il motore (Android e iOS; Windows e Linux con Stockfish installato) |
| Bot con personalità, collezione e avversario adattivo | Disponibile dove c'è il motore |
| Partita con l'allenatore: avvisi, ripresa della mossa, suggerimenti in parole con cerchio e freccia | Disponibile dove c'è il motore |
| Profilo bambino: schede semplificate, bot amichevoli, niente numeri | Disponibile dalle Impostazioni |
| Tema dell'app chiaro, scuro o di sistema, colori per daltonici | Disponibile dalle Impostazioni |
| Nome Rokko, icona e schermata di avvio chiara e scura | Disponibile (vedi [identita-visiva.md](identita-visiva.md)) |

I requisiti completi sono nel documento dei requisiti del progetto.
