# Rokko

Rokko è un'applicazione di scacchi offline, open source e completamente gratuita, per Android, iOS e desktop (Windows, macOS, Linux). Nessuna pubblicità, nessun account, nessun dato che lascia il dispositivo.

## Stato

- partita tra due persone sullo stesso dispositivo;
- mosse per trascinamento o con due tocchi, evidenziazione delle mosse legali, dell'ultima mossa e dello scacco;
- promozione con scelta del pezzo;
- fine partita: scacco matto, stallo, materiale insufficiente, triplice ripetizione, regola delle 50 mosse, patta concordata, abbandono;
- annullamento delle mosse, nuova partita, lista delle mosse in notazione algebrica;
- capovolgimento della scacchiera, anche automatico a ogni turno;
- partita contro il computer (Stockfish sul dispositivo: Android e iOS, e Windows e Linux con Stockfish installato) con 8 livelli, bot con personalità e allenatore;
- orologio con cadenze, archivio delle partite con import ed export PGN, revisione e analisi della partita;
- puzzle, aperture, percorso a tappe, minigiochi, tornei contro i bot, gamification e profilo bambino.

Lo stato di ogni funzione è in [docs/README.md](docs/README.md#stato-del-progetto).

## Documentazione

La documentazione completa è in [docs/](docs/README.md): architettura, funzioni, sviluppo, CI, sicurezza, rilascio e licenza. La [mappa del codice](docs/mappa-del-codice.md) collega ogni cartella di `lib/` al suo documento.

## Licenza

GPL-3.0, vedi [LICENSE](LICENSE), con un permesso aggiuntivo per la pubblicazione sugli store (vedi [NOTICE.md](NOTICE.md)). Le risorse di terze parti sono elencate in [CREDITS.md](CREDITS.md).
