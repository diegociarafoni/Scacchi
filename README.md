# Scacchi

Un'applicazione offline per gli scacchi: una web app TypeScript installabile come PWA, che dopo la prima visita funziona senza connessione.

## Requisiti

- Node.js 22 (vedi `.nvmrc`)

## Comandi

| Comando | Descrizione |
| --- | --- |
| `npm install` | Installa le dipendenze |
| `npm run dev` | Server di sviluppo Vite |
| `npm run build` | Controllo dei tipi e build di produzione in `dist/` (incluso service worker e manifest) |
| `npm run preview` | Serve la build di produzione in locale |
| `npm run lint` | ESLint con regole TypeScript strict |
| `npm test` | Test unitari (Vitest) |
| `npm run test:e2e` | Test end-to-end (Playwright): installabilità e avvio offline sulla build |

Per i test end-to-end serve Chromium: `npx playwright install chromium`, oppure si indica un binario esistente con `PLAYWRIGHT_CHROMIUM_EXECUTABLE`.

## Struttura

- `src/` codice dell'applicazione
- `public/` icone e asset statici copiati così come sono
- `e2e/` test Playwright
- `vite.config.ts` build e configurazione PWA (`vite-plugin-pwa`, Workbox in modalità `generateSW`)

## Offline e installazione

Il service worker mette in cache tutti gli asset della build alla prima visita e si aggiorna automaticamente quando viene pubblicata una nuova versione. Il manifest (`manifest.webmanifest`) rende l'app installabile da Chrome, Edge e Safari (Aggiungi a Home).
