import { registerSW } from 'virtual:pwa-register';
import { START_FEN, parseFenPlacement, pieceGlyph, squareName } from './board';
import './style.css';

function renderBoard(container: HTMLElement): void {
  const board = parseFenPlacement(START_FEN);
  const grid = document.createElement('div');
  grid.className = 'board';
  grid.setAttribute('role', 'grid');
  grid.setAttribute('aria-label', 'Scacchiera');

  board.forEach((rank, row) => {
    rank.forEach((piece, col) => {
      const cell = document.createElement('div');
      cell.className = `square ${(row + col) % 2 === 0 ? 'light' : 'dark'}`;
      cell.setAttribute('role', 'gridcell');
      cell.dataset.square = squareName(row, col);
      cell.setAttribute('aria-label', squareName(row, col));
      if (piece) {
        cell.textContent = pieceGlyph(piece);
        cell.classList.add(piece === piece.toUpperCase() ? 'white' : 'black');
      }
      grid.append(cell);
    });
  });

  container.append(grid);
}

function renderStatus(element: HTMLElement): void {
  const update = (): void => {
    element.textContent = navigator.onLine ? 'Online' : 'Offline';
    element.dataset.state = navigator.onLine ? 'online' : 'offline';
  };
  window.addEventListener('online', update);
  window.addEventListener('offline', update);
  update();
}

function requireElement<T extends HTMLElement>(selector: string, root: ParentNode = document): T {
  const element = root.querySelector<T>(selector);
  if (!element) {
    throw new Error(`Elemento ${selector} non trovato`);
  }
  return element;
}

const app = requireElement<HTMLDivElement>('#app');

app.innerHTML = `
  <header class="topbar">
    <h1>Scacchi</h1>
    <span class="status" id="status"></span>
  </header>
  <main id="board-container"></main>
`;

renderBoard(requireElement('#board-container', app));
renderStatus(requireElement('#status', app));

registerSW({ immediate: true });
