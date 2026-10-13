# Licenza

Il progetto è distribuito sotto licenza GPL-3.0 o successiva, il cui testo completo è nel file [LICENSE](../LICENSE). È open source e completamente gratuito: niente pubblicità, acquisti, abbonamenti o tracciamento.

La GPL è richiesta dalle librerie `dartchess` e `chessground` e dal motore Stockfish. La licenza è accompagnata da un permesso aggiuntivo che consente la distribuzione su App Store, Google Play e Microsoft Store, descritto in [NOTICE.md](../NOTICE.md). Il permesso vale solo per il codice del progetto: Stockfish resta GPL-3.0 senza eccezioni (requisito RV-05).

## Dove si vede

La schermata **Impostazioni → Informazioni** (`lib/about/about_page.dart`) mostra la licenza, l'indirizzo dei sorgenti (requisiti RV-03 e RV-04), la dichiarazione di privacy, i crediti di motore, pezzi e caratteri (`lib/about/credits.dart`) e apre le licenze di tutte le librerie con `showLicensePage`. Quando si aggiunge un asset a `CREDITS.md` con una licenza che richiede attribuzione (CC BY, CC BY-SA), va aggiunto anche a `credits.dart`.

## Componenti di terze parti

L'elenco aggiornato, con le rispettive licenze, è in [CREDITS.md](../CREDITS.md). Ogni nuova risorsa (pezzi, suoni, dataset) deve avere una licenza compatibile con la GPL ed essere aggiunta a quel file.

I set di pezzi selezionabili escludono quelli CC BY-NC-SA, che vietano l'uso commerciale e non sono compatibili con la GPL; il test `test/settings/settings_test.dart` controlla la licenza di ogni set. Punto aperto: `chessground` dichiara come asset tutti i suoi set di pezzi e le immagini delle scacchiere (queste ultime sono AGPL e non si usano), quindi i file restano nel pacchetto dell'app anche se non sono selezionabili. Prima della pubblicazione sugli store vanno rimossi dal pacchetto (ad esempio con un fork di `chessground` che dichiari solo i set usati).
