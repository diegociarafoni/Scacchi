// Tre set di pezzi sulla stessa sagoma Staunton, disegnata da noi: Staunton (3D
// leggero in legno, con ombra), Morbido (sfumature e ombra delicata) e Stampa
// (bianco e nero netto, come un'incisione). Ogni funzione restituisce SVG in un
// quadrato 45×45.

const BASE = `<rect x="10" y="36" width="25" height="5" rx="2.5"/>`;
const SHAPES = {
  P: BASE + `<path d="M16.5 36C18 31 20.2 28 20.6 25.5H24.4C24.8 28 27 31 28.5 36Z"/><rect x="15.5" y="23.2" width="14" height="3" rx="1.5"/><circle cx="22.5" cy="17.5" r="5.6"/>`,
  R: BASE + `<path d="M15 36 16.2 19.5H28.8L30 36Z"/><rect x="13.8" y="17" width="17.4" height="3.4" rx="1"/><path d="M13.8 17V9H17.6V12H20.6V9H24.4V12H27.4V9H31.2V17Z"/>`,
  N: BASE + `<path d="M13.2 36 14.6 30C12.8 26.6 13.6 21.8 17.6 17.8L16.6 12 20.4 14.4C21.6 10.6 24.4 8.2 27.8 8.6C28.2 9.8 28.2 10.8 27.8 11.8C33.8 13.4 35.2 20.2 34 27L32.6 36Z"/>`,
  B: BASE + `<path d="M18.6 36C20.4 32 20 29 18.4 26.2H26.6C25 29 24.6 32 26.4 36Z"/><rect x="15.8" y="23.6" width="13.4" height="3" rx="1.5"/><path d="M22.5 6.6C29 11.4 30.4 18 26.6 23.6H18.4C14.6 18 16 11.4 22.5 6.6Z"/><circle cx="22.5" cy="5" r="2.3"/>`,
  Q: BASE + `<path d="M17 36C19.2 31.6 18.6 25.6 17 21.6H28C26.4 25.6 25.8 31.6 28 36Z"/><rect x="14.6" y="19" width="15.8" height="3.4" rx="1.4"/><path d="M13.6 19.2 11.6 10.4 16.6 14.8 19.2 8.4 22.5 14.2 25.8 8.4 28.4 14.8 33.4 10.4 31.4 19.2Z"/><circle cx="11.6" cy="9.2" r="1.9"/><circle cx="19.2" cy="7.2" r="1.9"/><circle cx="25.8" cy="7.2" r="1.9"/><circle cx="33.4" cy="9.2" r="1.9"/>`,
  K: BASE + `<path d="M17 36C19.2 31.6 18.6 25.6 17 21.6H28C26.4 25.6 25.8 31.6 28 36Z"/><rect x="14.6" y="19.4" width="15.8" height="3.4" rx="1.4"/><path d="M15.2 19.6C14.2 13.8 18 11.6 22.5 11.6C27 11.6 30.8 13.8 29.8 19.6Z"/><rect x="21" y="2.6" width="3" height="9.4" rx="1"/><rect x="18.2" y="5.2" width="8.6" height="3" rx="1"/>`
};

// Tratti interni che danno volume e riconoscibilità; il colore lo sceglie lo stile.
const DETAIL = {
  P: `<path d="M16.6 24.8H28.4M13 38.4H32"/>`,
  R: `<path d="M16.4 28H28.6M13 38.4H32M15.6 19.2H29.4"/>`,
  N: `<path d="M24.4 13.6C26.8 14 28.8 16 29.4 19M20.6 17.6C21.6 19 21.6 21 20.4 22.6M13 38.4H32"/><circle cx="24.4" cy="15.8" r="1.1"/>`,
  B: `<path d="M25.2 11.6 21.4 18.4M16.6 25H28.4M13 38.4H32"/>`,
  Q: `<path d="M16.6 22.4H28.4M13 38.4H32M22.5 15.6V19"/>`,
  K: `<path d="M16.6 22.8H28.4M13 38.4H32M17.2 16.4C19.6 14.6 25.4 14.6 27.8 16.4"/>`
};

// Un po' più grandi, ancorati alla base, per riempire la casa come gli altri set.
const grow = (inner) => `<g transform="translate(22.5 43.5) scale(1.08) translate(-22.5 -43.5)">${inner}</g>`;

const shadow = (id, opacity) =>
  `<defs><filter id="${id}" x="-30%" y="-80%" width="160%" height="260%"><feGaussianBlur stdDeviation="1.1"/></filter></defs><ellipse cx="23.5" cy="41.2" rx="12" ry="2.1" fill="#000" opacity="${opacity}" filter="url(#${id})"/>`;

/** 3D leggero: legno chiaro o scuro, luce da sinistra, ombra sotto il pezzo. */
export function pieceStaunton(t, c) {
  const w = c === "w";
  const [a, b, d] = w ? ["#F7E1B4", "#DDAE6A", "#A9712F"] : ["#7A5742", "#47301F", "#1E120B"];
  const edge = w ? "#6B4A22" : "#0F0805", line = w ? "#8A5A24" : "#000";
  const id = `s${c}${t}`;
  return grow(shadow(`sh${id}`, w ? 0.38 : 0.5) +
    `<defs><linearGradient id="g${id}" gradientUnits="userSpaceOnUse" x1="10" y1="0" x2="35" y2="0"><stop offset="0" stop-color="${a}"/><stop offset=".5" stop-color="${b}"/><stop offset="1" stop-color="${d}"/></linearGradient>` +
    `<radialGradient id="h${id}" gradientUnits="userSpaceOnUse" cx="18" cy="16" r="20"><stop offset="0" stop-color="#fff" stop-opacity="${w ? 0.55 : 0.3}"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>` +
    `<g fill="url(#g${id})" stroke="${edge}" stroke-width="0.9" stroke-linejoin="round">${SHAPES[t]}</g>` +
    `<g fill="url(#h${id})" stroke="none">${SHAPES[t]}</g>` +
    `<g fill="${line}" stroke="${line}" stroke-opacity=".55" fill-opacity=".55" stroke-width="0.8" stroke-linecap="round" fill-rule="evenodd" style="fill:none">${DETAIL[t]}</g>`);
}

/** Morbido: sfumature piatte e un'ombra delicata, contorno sottile. */
export function pieceMorbido(t, c) {
  const w = c === "w";
  const [a, b] = w ? ["#FFFFFF", "#D6D9E2"] : ["#646A78", "#252831"];
  const edge = w ? "#8C93A6" : "#0E1016", line = w ? "#AEB4C4" : "#0E1016";
  const id = `m${c}${t}`;
  return grow(shadow(`sh${id}`, 0.28) +
    `<defs><linearGradient id="g${id}" gradientUnits="userSpaceOnUse" x1="12" y1="6" x2="33" y2="40"><stop offset="0" stop-color="${a}"/><stop offset="1" stop-color="${b}"/></linearGradient></defs>` +
    `<g fill="url(#g${id})" stroke="${edge}" stroke-width="1" stroke-linejoin="round">${SHAPES[t]}</g>` +
    `<g stroke="${line}" stroke-width="0.8" stroke-linecap="round" style="fill:none">${DETAIL[t]}</g>`);
}

/** Stampa: bianco e nero netto con tratti interni, come un'incisione. */
export function pieceStampa(t, c) {
  const w = c === "w";
  const fill = w ? "#FFFFFF" : "#141414", line = w ? "#141414" : "#FFFFFF";
  return grow(`<g fill="${fill}" stroke="#000" stroke-width="1.5" stroke-linejoin="round">${SHAPES[t]}</g>` +
    `<g stroke="${line}" stroke-width="0.9" stroke-linecap="round" style="fill:none">${DETAIL[t]}</g>`);
}
