# Notazione delle mosse

Requisito RF-76. Chi non conosce la notazione inglese non capisce «Nf3» né «Prova Kf1». L'app scrive i pezzi in tre modi, a scelta in **Impostazioni → Notazione delle mosse**:

| Notazione | Esempio | Note |
|---|---|---|
| Figurativa (predefinita) | ♞f3, ♛xd5, e8=♛ | Il simbolo del pezzo al posto della lettera: si legge in qualsiasi lingua |
| Italiana | Cf3, Dxd5, e8=D | R (re), D (donna), T (torre), A (alfiere), C (cavallo) |
| Inglese | Nf3, Qxd5, e8=Q | SAN standard |

Pedoni e arrocchi (O-O, O-O-O) non cambiano. La partita, l'archivio e i PGN restano sempre in SAN inglese: la scelta cambia solo come le mosse vengono mostrate.

## Componenti

| File | Ruolo |
|---|---|
| `lib/settings/notation.dart` | `MoveNotation` e `formatSan` (una mossa in SAN → notazione scelta) |
| `lib/settings/settings.dart` | Impostazione `notation`, salvata in locale |
| `lib/game/move_label.dart` | `moveLabel` accetta la notazione |

## Dove si applica

- Elenco delle mosse e barra «Posizione dopo…» nella schermata di gioco.
- Revisione: lista delle mosse, titolo della mossa, «Migliore», Riprova e spiegazioni del coach (`explainMove` riceve la notazione).
- Analisi: storico e varianti del motore.
- Aperture: continuazioni e mosse dell'esploratore, linee del repertorio.

`formatSan` converte una mossa; `formatMoveText` un testo di mosse separate da spazi. I confronti interni (per esempio «è la mossa migliore?») restano sulla SAN inglese: la notazione è solo di visualizzazione.

I suggerimenti dell'allenatore non usano la notazione: dicono «Sposta il re in f1» (vedi [allenatore.md](allenatore.md)).
