# Licenza

Il progetto è distribuito sotto licenza GPL-3.0 o successiva, il cui testo completo è nel file [LICENSE](../LICENSE). È open source e completamente gratuito: niente pubblicità, acquisti, abbonamenti o tracciamento.

La GPL è richiesta dalle librerie `dartchess` e `chessground` e dal motore Stockfish. La licenza è accompagnata da un permesso aggiuntivo che consente la distribuzione su App Store, Google Play e Microsoft Store, descritto in [NOTICE.md](../NOTICE.md). Il permesso vale solo per il codice del progetto: Stockfish resta GPL-3.0 senza eccezioni (requisito RV-05).

## Dove si vede

La schermata **Impostazioni → Informazioni** (`lib/about/about_page.dart`) mostra la licenza, l'indirizzo dei sorgenti (requisiti RV-03 e RV-04), la dichiarazione di privacy, i crediti di motore, pezzi e caratteri (`lib/about/credits.dart`) e apre le licenze di tutte le librerie con `showLicensePage`. Quando si aggiunge un asset a `CREDITS.md` con una licenza che richiede attribuzione (CC BY, CC BY-SA), va aggiunto anche a `credits.dart`.

## Componenti di terze parti

L'elenco aggiornato, con le rispettive licenze, è in [CREDITS.md](../CREDITS.md). Ogni nuova risorsa (pezzi, suoni, dataset) deve avere una licenza compatibile con la GPL ed essere aggiunta a quel file.

I set di pezzi selezionabili escludono quelli CC BY-NC-SA, che vietano l'uso commerciale e non sono compatibili con la GPL; il test `test/settings/settings_test.dart` controlla la licenza di ogni set. `chessground` dichiara come asset tutti i suoi set di pezzi e le immagini delle scacchiere (queste ultime sono AGPL e non si usano): per non distribuirli, l'app usa la copia ridotta in `third_party/chessground`, con i soli set offerti e nessuna immagine di scacchiera (vedi `third_party/chessground/MODIFICHE.md`).

## App Store e iOS (RV-05)

**Decisione del 14 ottobre 2026: Rokko non si pubblica sull'App Store, né su TestFlight, finché un parere legale non conferma che è compatibile con la GPL.** Google Play, F-Droid e l'APK diretto non hanno questo problema.

Perché. Rokko è un'unica opera che collega Stockfish, `dartchess` e `chessground`, tutti GPL-3.0 senza eccezioni. Il permesso di [NOTICE.md](../NOTICE.md) (GPL v3, sezione 7) riguarda solo il codice di cui i titolari di Rokko sono i titolari: non può autorizzare codice altrui. Le regole d'uso dell'App Store (limite di dispositivi, firma e cifratura imposte dallo store) sono restrizioni ulteriori che la GPL-3.0 non ammette; per questo in passato progetti GPL sono stati ritirati dallo store. Chiedere un permesso a tutti i titolari di Stockfish non è realistico, e sostituire il motore su iOS costerebbe forza di gioco e una seconda linea di manutenzione.

Che cosa resta possibile per chi usa un iPhone: la build senza firma in CI (`.github/workflows/ios.yml`) continua a girare per accorgersi se un cambiamento rompe iOS; negozi alternativi dove consentiti (per esempio nell'Unione europea) e la distribuzione del sorgente sono strade da valutare con un parere.

Questa è un'analisi tecnica, non un parere legale. Per riaprire la questione serve un parere scritto: allora si aggiungono la firma, Fastlane per iOS e le dichiarazioni dello store (vedi [store.md](store.md) e [sicurezza.md](sicurezza.md)).
