// Disegni di pezzi e scacchiere di Rokko, condivisi con l'anteprima dell'Officina.
// Ogni funzione restituisce SVG: i pezzi in un quadrato 45×45, le scacchiere in 400×400.

const CREAM = "#FFF6E9", BROWN = "#8A3B12", DARK = "#3A2418", NIGHT = "#1C1714", ORANGE = "#F2994A";
const face = (cx, cy, eye, mouth) => `<g fill="${eye}"><circle cx="${cx - 2.6}" cy="${cy}" r="1.5"/><circle cx="${cx + 2.6}" cy="${cy}" r="1.5"/></g><path d="M${cx - 2.4} ${cy + 3}Q${cx} ${cy + 5.2} ${cx + 2.4} ${cy + 3}" fill="none" stroke="${mouth}" stroke-width="1.3" stroke-linecap="round"/>`;
const ROKKO_SHAPES = {
  P: `<rect x="12" y="36" width="21" height="5" rx="2"/><path d="M16 36 18.5 27H26.5L29 36Z"/><circle cx="22.5" cy="20" r="7"/>`,
  R: `<rect x="10" y="36" width="25" height="5" rx="2"/><path d="M14.5 36 16 21H29L30.5 36Z"/><path d="M12.5 22V13a1.5 1.5 0 0 1 1.5-1.5H17.5V15H20.5V11.5H24.5V15H27.5V11.5H31a1.5 1.5 0 0 1 1.5 1.5V22Z"/>`,
  N: `<rect x="10" y="36" width="25" height="5" rx="2"/><path d="M14 36 15.5 28C12.5 27 10.5 24.5 11 22L19 11.5 19.5 6.5 23.5 10C30.5 10.5 34 17 33 25L31 36Z"/>`,
  B: `<rect x="10" y="36" width="25" height="5" rx="2"/><path d="M15 36 17.5 25H27.5L30 36Z"/><path d="M22.5 5.5C29.5 10.5 31 17.5 27.5 24.5H17.5C14 17.5 15.5 10.5 22.5 5.5Z"/><circle cx="22.5" cy="5" r="2.2"/>`,
  Q: `<rect x="9" y="36" width="27" height="5" rx="2"/><path d="M14 36 16.5 23H28.5L31 36Z"/><path d="M12.5 24 11 12.5 17 17.5 22.5 9 28 17.5 34 12.5 32.5 24Z"/><circle cx="11" cy="11.5" r="2"/><circle cx="22.5" cy="8" r="2"/><circle cx="34" cy="11.5" r="2"/>`,
  K: `<rect x="9" y="36" width="27" height="5" rx="2"/><path d="M14 36 16.5 23H28.5L31 36Z"/><path d="M13 24V16.5Q22.5 11 32 16.5V24Z"/><rect x="21" y="3.5" width="3" height="10" rx="1"/><rect x="18" y="6" width="9" height="3" rx="1"/>`
};
const ROKKO_DETAIL = {
  P: [22.5, 19.5], R: [22.5, 27.5], N: null, B: [22.5, 30], Q: [22.5, 29.5], K: [22.5, 29.5]
};
function pieceRokko(t, color, opt) {
  const fill = color === "w" ? CREAM : DARK, line = color === "w" ? BROWN : NIGHT, eye = color === "w" ? BROWN : ORANGE;
  let s = `<g fill="${fill}" stroke="${line}" stroke-width="1.6" stroke-linejoin="round">${ROKKO_SHAPES[t]}</g>`;
  if (t === "N") s += `<circle cx="24.5" cy="16.5" r="1.6" fill="${eye}"/><path d="M14 23.5Q16 24.5 17.5 23" fill="none" stroke="${eye}" stroke-width="1.2" stroke-linecap="round"/>`;
  else if (t === "B") s += `<path d="M24.5 12 21 18" stroke="${line}" stroke-width="1.6" stroke-linecap="round"/>` + (opt.faces ? face(22.5, 29, eye, eye) : "");
  else if (t === "R" || opt.faces) s += face(...ROKKO_DETAIL[t], eye, eye);
  return s;
}

const PIXELS = {
  P: ["", "", "    oooo", "   offffo", "   offffo", "    oooo", "    offo", "   offffo", "   offffo", "  offffffo", "  oooooooo"],
  R: ["", "  oo oo oo", "  oooooooo", "  offffffo", "   oeffeo", "   offffo", "   osssso", "   offffo", "  offffffo", " offffffffo", " oooooooooo"],
  N: ["", "    oo", "   offoo", "  offffoo", "  ofeffffo", " offfffffo", " oofooffo", "   ooffffo", "    offffo", "   offffffo", "  oooooooo"],
  B: ["", "     oo", "    offo", "   offofo", "   offofo", "   offffo", "    offo", "    offo", "   offffo", "  offffffo", "  oooooooo"],
  Q: ["", " o   oo   o", " oo offo oo", " ofooffoofo", " offffffffo", "  offffffo", "   offffo", "   offffo", "  offffffo", " offffffffo", " oooooooooo"],
  K: ["     oo", "    oooo", "     oo", "   oooooo", "  offffffo", "  offffffo", "   offffo", "   offffo", "  offffffo", " offffffffo", " oooooooooo"]
};
function piecePixel(t, color) {
  const pal = color === "w" ? { o: BROWN, f: CREAM, e: BROWN, s: BROWN } : { o: NIGHT, f: "#5A3A28", e: ORANGE, s: ORANGE };
  let s = `<g shape-rendering="crispEdges">`;
  PIXELS[t].forEach((row, y) => [...row].forEach((ch, x) => { if (pal[ch]) s += `<rect x="${x * 3.4 + 2.1}" y="${y * 3.4 + 3.5}" width="3.45" height="3.45" fill="${pal[ch]}"/>`; }));
  return s + `</g>`;
}

/* Arcano: atmosfera magica originale, nessun riferimento a opere protette. */
const ARC_SHAPES = {
  P: `<path d="M15.5 36 22.5 23 29.5 36Z"/><circle cx="22.5" cy="21" r="4"/><path d="M17.5 19H27.5L22.5 9Z"/>`,
  R: `<path d="M15 36 16.5 21H28.5L30 36Z"/><path d="M13.5 22 22.5 7.5 31.5 22Z"/><path d="M22.5 7.5V3L27 4.5 22.5 6" />`,
  N: `<path d="M14 36 15.5 28C12.5 27 10.5 24.5 11 22L19 11.5 19.5 6.5 23.5 10C30.5 10.5 34 17 33 25L31 36Z"/><path d="M22 11 27.5 2 25.5 12Z"/>`,
  B: `<path d="M14 36 22.5 20 31 36Z"/><path d="M14.5 22Q22.5 18.5 30.5 22L25 2.5Q23 8 21 12Z"/>`,
  Q: `<path d="M13 36 22.5 19 32 36Z"/><path d="M13 22.5H32L22.5 4Z"/><path d="M14.5 22.5 14 17 18 20 22.5 15 27 20 31 17 30.5 22.5Z"/>`,
  K: `<path d="M13 36 22.5 19 32 36Z"/><path d="M13.5 23 12.5 12 18 16.5 22.5 9 27 16.5 32.5 12 31.5 23Z"/>`
};
const star = (x, y, r, c) => `<path d="M${x} ${y - r}L${x + r * .3} ${y - r * .3}L${x + r} ${y}L${x + r * .3} ${y + r * .3}L${x} ${y + r}L${x - r * .3} ${y + r * .3}L${x - r} ${y}L${x - r * .3} ${y - r * .3}Z" fill="${c}"/>`;
function pieceArcano(t, color) {
  const fill = color === "w" ? "#F3E6C4" : "#2E2758", line = color === "w" ? "#3B2A1A" : "#120E26", gold = color === "w" ? "#B8860B" : "#E8C766";
  let s = `<g fill="${fill}" stroke="${line}" stroke-width="1.5" stroke-linejoin="round"><rect x="10" y="36" width="25" height="5" rx="2"/>${ARC_SHAPES[t]}</g>`;
  if (t === "P") s += star(22.5, 15, 2, gold);
  if (t === "R") s += face(22.5, 27.5, gold, gold);
  if (t === "N") s += `<circle cx="24.5" cy="16.5" r="1.6" fill="${gold}"/>`;
  if (t === "B") s += `<path d="M20 16a3 3 0 1 0 3-3.6 2.4 2.4 0 1 1-3 3.6Z" fill="${gold}"/>` + star(22.5, 29, 2.4, gold);
  if (t === "Q") s += star(22.5, 10, 2.2, gold) + star(22.5, 29, 2.6, gold);
  if (t === "K") s += star(22.5, 5.5, 3, gold) + `<circle cx="22.5" cy="29" r="2.4" fill="${gold}"/>`;
  return s;
}

const GLYPH = { w: { K: "♔", Q: "♕", R: "♖", B: "♗", N: "♘", P: "♙" }, b: { K: "♚", Q: "♛", R: "♜", B: "♝", N: "♞", P: "♟" } };

function rng(seed) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function stars(n, seed, color, maxR) { const r = rng(seed); let s = ""; for (let i = 0; i < n; i++) s += `<circle cx="${(r() * 400).toFixed(1)}" cy="${(r() * 400).toFixed(1)}" r="${(r() * maxR + .3).toFixed(2)}" fill="${color}" opacity="${(r() * .6 + .3).toFixed(2)}"/>`; return s; }
const lightMask = (id) => { let s = `<mask id="${id}"><rect width="400" height="400" fill="#000"/>`; for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) if (!((r + c) % 2)) s += `<rect x="${c * 50}" y="${r * 50}" width="50" height="50" fill="#fff"/>`; return s + `</mask>`; };
const darkMask = (id) => { let s = `<mask id="${id}"><rect width="400" height="400" fill="#000"/>`; for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) if ((r + c) % 2) s += `<rect x="${c * 50}" y="${r * 50}" width="50" height="50" fill="#fff"/>`; return s + `</mask>`; };


const THEMES = {
  arancia: { label: "Arancia", own: true, light: "#FCEBD5", dark: "#EE9B55", coord: "#8A3B12", hl: "rgba(138,59,18,.28)", dot: "rgba(138,59,18,.45)",
    over: () => `<defs><pattern id="pa" width="10" height="10" patternUnits="userSpaceOnUse"><circle cx="5" cy="5" r="1.1" fill="#fff" opacity=".28"/></pattern>${darkMask("ma")}</defs><rect width="400" height="400" fill="url(#pa)" mask="url(#ma)"/>`,
    desc: "I colori dell'icona: crema e arancio caldo, con una trama a puntini leggerissima sulle case scure. Il tema predefinito di Rokko." },
  crepuscolo: { label: "Crepuscolo", own: true, dim: true, light: "#D5C7E3", dark: "#6E5B8F", coord: "#F2994A", hl: "rgba(242,153,74,.45)", dot: "rgba(242,153,74,.75)",
    over: () => `<defs>${darkMask("mc")}</defs><g mask="url(#mc)">${stars(90, 7, "#FFF6E9", 1.1)}</g>`,
    desc: "Lavanda e viola con piccole stelle sulle case scure ed evidenziazioni arancioni. Per giocare la sera; i pezzi neri prendono un alone chiaro." },
  pergamena: { label: "Pergamena", own: true, light: "#F1E2BC", dark: "#B48A55", coord: "#4A2E14", hand: true, hl: "rgba(120,30,20,.3)", dot: "rgba(74,46,20,.5)", src: "Disegnato da noi",
    over: () => `<defs><filter id="fp"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="4" seed="9"/><feColorMatrix values="0 0 0 0 .35  0 0 0 0 .22  0 0 0 0 .08  0 0 0 .7 -.25"/></filter><radialGradient id="gv" cx=".5" cy=".5" r=".72"><stop offset=".6" stop-color="#3B2410" stop-opacity="0"/><stop offset="1" stop-color="#3B2410" stop-opacity=".45"/></radialGradient></defs><rect width="400" height="400" filter="url(#fp)"/><rect width="400" height="400" fill="url(#gv)"/>`,
    desc: "Una vecchia pergamena con le case scure macchiate d'inchiostro, bordi bruniti e coordinate a penna d'oca." },
  castello: { label: "Castello", own: true, dim: true, light: "#A49C90", dark: "#5A544D", coord: "#FFD98A", hl: "rgba(255,190,90,.45)", dot: "rgba(255,217,138,.7)", src: "Disegnato da noi",
    over: () => { const r = rng(5), runes = ["M0 -6V6M0 -6 4 -2M0 0 4 4", "M-3 -6V6M-3 -6 3 0 -3 6", "M-4 -6 4 6M4 -6 -4 6M-4 0H4", "M0 -6V6M-4 -2 0 2 4 -2"]; let g = "";
      for (let rr = 0; rr < 8; rr++) for (let c = 0; c < 8; c++) if ((rr + c) % 2 && r() < .35) g += `<path transform="translate(${c * 50 + 25} ${rr * 50 + 25})" d="${runes[Math.floor(r() * 4)]}" stroke="#FFC861" stroke-width="1.6" fill="none" stroke-linecap="round" opacity=".55"/>`;
      return `<defs><pattern id="pk" width="25" height="16" patternUnits="userSpaceOnUse"><path d="M0 0H25M0 8H25M6 0V8M18.5 8V16" stroke="#2A2622" stroke-width=".8" opacity=".35" fill="none"/></pattern><radialGradient id="gc" cx=".15" cy=".1" r=".9"><stop offset="0" stop-color="#FFB85C" stop-opacity=".35"/><stop offset=".6" stop-color="#FFB85C" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".3"/></radialGradient></defs><rect width="400" height="400" fill="url(#pk)"/>${g}<rect width="400" height="400" fill="url(#gc)"/>`; },
    desc: "Pietra di un antico castello, alcune case scure incise con rune luminose e la luce calda di una candela che arriva dall'angolo." },
  bosco: { label: "Bosco elfico", own: true, light: "#ECE6D0", dark: "#5E7F5A", coord: "#2E4A33", font: "Cinzel, serif", hl: "rgba(120,170,210,.45)", dot: "rgba(46,74,51,.5)", src: "Disegnato da noi",
    over: () => `<defs><pattern id="pl" width="25" height="25" patternUnits="userSpaceOnUse"><path d="M3 22Q12 16 22 4" stroke="#DCEBD3" stroke-width=".8" fill="none" opacity=".35"/><path d="M8 17C7 12 10 9 14 8.5 14.5 13 12 16 8 17Z" fill="#DCEBD3" opacity=".3"/><path d="M15 12C19 12 21 15 21 18 17 18 15 16 15 12Z" fill="#DCEBD3" opacity=".22"/></pattern><filter id="fb"><feTurbulence type="fractalNoise" baseFrequency="0.01 0.25" numOctaves="2" seed="2"/><feColorMatrix values="0 0 0 0 .55  0 0 0 0 .5  0 0 0 0 .35  0 0 0 .35 -.05"/></filter>${darkMask("mb")}<radialGradient id="gm" cx=".85" cy=".1" r=".7"><stop offset="0" stop-color="#E8F0FF" stop-opacity=".3"/><stop offset="1" stop-color="#E8F0FF" stop-opacity="0"/></radialGradient></defs><rect width="400" height="400" filter="url(#fb)"/><rect width="400" height="400" fill="url(#pl)" mask="url(#mb)"/><rect width="400" height="400" fill="url(#gm)"/>`,
    desc: "Betulla chiara e muschio, con foglie e rami intrecciati sulle case scure, una luce di luna dall'angolo e coordinate incise in maiuscole classiche." },
  noce: { label: "Noce", light: "#E6C597", dark: "#93603A", coord: "#4A2A14", hl: "rgba(255,214,102,.45)", dot: "rgba(40,20,5,.35)", src: "Texture generata da noi, oppure legno CC0 di Poly Haven",
    over: () => `<defs><filter id="fw"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.32" numOctaves="3" seed="4"/><feColorMatrix values="0 0 0 0 .35  0 0 0 0 .2  0 0 0 0 .08  0 0 0 .55 -.1"/></filter></defs><rect width="400" height="400" filter="url(#fw)" opacity=".7"/>`,
    desc: "Legno di noce con venature: il classico da circolo, ma caldo. Tema già atteso dagli adulti." },
  spazio: { label: "Spazio", dim: true, light: "#4A4F86", dark: "#1D1F45", coord: "#C9CCF5", hl: "rgba(242,153,74,.45)", dot: "rgba(255,255,255,.55)", src: "Disegnato da noi",
    over: () => `<defs><radialGradient id="gn" cx=".72" cy=".3" r=".55"><stop offset="0" stop-color="#E06BB0" stop-opacity=".35"/><stop offset="1" stop-color="#E06BB0" stop-opacity="0"/></radialGradient></defs><rect width="400" height="400" fill="url(#gn)"/>${stars(160, 3, "#fff", 1.2)}`,
    desc: "Blu notte con nebulosa e stelle su tutta la scacchiera. Spettacolare; va scelto con un set dal contorno chiaro, come accade qui con l'alone." },
  retro: { label: "Retrò", light: "#9BBC0F", dark: "#306230", coord: "#0F380F", hl: "rgba(15,56,15,.35)", dot: "rgba(15,56,15,.6)", pixel: true, src: "Disegnato da noi (solo i colori ricordano la console)",
    over: () => `<defs><pattern id="pd" width="4" height="4" patternUnits="userSpaceOnUse"><rect width="2" height="2" fill="#0F380F" opacity=".25"/></pattern>${darkMask("md")}</defs><rect width="400" height="400" fill="url(#pd)" mask="url(#md)" shape-rendering="crispEdges"/>`,
    desc: "Quattro verdi e una retinatura a pixel. Con il set Pixel diventa una piccola console." },
  giardino: { label: "Giardino", light: "#DCEBB4", dark: "#6E9A4C", coord: "#2F4A1E", hl: "rgba(255,236,120,.5)", dot: "rgba(30,60,20,.45)", src: "Disegnato da noi",
    over: () => { const r = rng(21); let g = ""; for (let i = 0; i < 260; i++) { const x = r() * 400, y = r() * 400; g += `<path d="M${x.toFixed(1)} ${y.toFixed(1)}q${(r() * 2 - 1).toFixed(1)} -4 ${(r() * 3 - 1.5).toFixed(1)} -6" stroke="#2F5A1E" stroke-width=".9" fill="none" opacity=".35"/>`; } return `<defs>${darkMask("mg")}</defs><g mask="url(#mg)">${g}</g>`; },
    desc: "Erba e fili d'erba sulle case scure, come una scacchiera gigante in un parco." },
  marmo: { label: "Marmo", light: "#E9E7E3", dark: "#4A5853", coord: "#E9E7E3", hl: "rgba(255,200,90,.5)", dot: "rgba(0,0,0,.4)", src: "Disegnato da noi",
    over: () => `<defs><filter id="fm1" x="0" y="0" width="100%" height="100%"><feTurbulence type="turbulence" baseFrequency="0.009 0.014" numOctaves="4" seed="11"/><feColorMatrix type="matrix" values="0 0 0 0 .42  0 0 0 0 .45  0 0 0 0 .48  -3.4 0 0 0 1"/></filter><filter id="fm2" x="0" y="0" width="100%" height="100%"><feTurbulence type="turbulence" baseFrequency="0.013 0.008" numOctaves="4" seed="27"/><feColorMatrix type="matrix" values="0 0 0 0 .93  0 0 0 0 .95  0 0 0 0 .93  -2.2 0 0 0 .9"/></filter><linearGradient id="fms" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".12"/></linearGradient>${darkMask("mm")}${lightMask("ml")}</defs><g mask="url(#ml)"><rect width="400" height="400" filter="url(#fm1)" opacity=".8"/></g><g mask="url(#mm)"><rect width="400" height="400" filter="url(#fm2)" opacity=".9"/></g><rect width="400" height="400" fill="url(#fms)"/>`,
    desc: "Marmo bianco venato di grigio contro marmo verde scuro con vene chiare, lucidato da un riflesso diagonale." },
  metallo: { label: "Metallo", light: "#C8CDD3", dark: "#69727C", coord: "#E8ECF0", hl: "rgba(255,190,60,.5)", dot: "rgba(0,0,0,.4)", src: "Disegnato da noi",
    over: () => `<defs><filter id="fb" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.004 0.8" numOctaves="2" seed="5"/><feColorMatrix type="matrix" values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  1.6 0 0 0 -.62"/></filter><filter id="fb2" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.004 0.8" numOctaves="2" seed="9"/><feColorMatrix type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  1.6 0 0 0 -.7"/></filter><linearGradient id="fbs" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".35" stop-color="#fff" stop-opacity=".28"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".1"/></linearGradient></defs><rect width="400" height="400" filter="url(#fb)" opacity=".5"/><rect width="400" height="400" filter="url(#fb2)" opacity=".35"/><rect width="400" height="400" fill="url(#fbs)"/>` + (() => { let g = ""; for (let i = 0; i <= 8; i++) g += `<path d="M${i * 50} 0V400M0 ${i * 50}H400" stroke="#2B3138" stroke-opacity=".22" stroke-width="1"/><path d="M${i * 50 + 1} 0V400M0 ${i * 50 + 1}H400" stroke="#fff" stroke-opacity=".28" stroke-width="1"/>`; return g; })(),
    desc: "Acciaio satinato: striature orizzontali, un riflesso che scorre sulla piastra e sottili bordi smussati tra le case." },
  vetro: { label: "Vetro", light: "#CFE8EE", dark: "#3F8FA3", coord: "#E8F6FA", hl: "rgba(255,200,70,.55)", dot: "rgba(0,40,60,.45)", src: "Disegnato da noi",
    over: () => { let g = `<defs><linearGradient id="fg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".55"/><stop offset=".45" stop-color="#fff" stop-opacity=".05"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="fr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".0"/><stop offset=".5" stop-color="#fff" stop-opacity=".16"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>`;
      for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) g += `<rect x="${c * 50 + 1.5}" y="${r * 50 + 1.5}" width="47" height="47" rx="3" fill="url(#fg)" stroke="#fff" stroke-opacity=".55" stroke-width="1"/><path d="M${c * 50 + 6} ${r * 50 + 44}L${c * 50 + 44} ${r * 50 + 6}" stroke="#fff" stroke-opacity=".25" stroke-width="1.2" stroke-linecap="round"/>`;
      return g + `<path d="M-20 250L250 -20H330L-20 330Z M120 420L420 120V190L190 420Z" fill="url(#fr)"/>`; },
    desc: "Lastre di vetro azzurro con bordi luminosi e riflessi diagonali: leggera e trasparente, come un acquario." },
  terracotta: { label: "Terracotta", light: "#F3DFC6", dark: "#C4643C", coord: "#6B2A12", hl: "rgba(255,240,200,.45)", dot: "rgba(80,30,10,.4)", src: "Disegnato da noi",
    over: () => `<defs><pattern id="pt" width="25" height="25" patternUnits="userSpaceOnUse"><path d="M12.5 4 15 10 21 12.5 15 15 12.5 21 10 15 4 12.5 10 10Z" fill="#fff" opacity=".13"/></pattern>${darkMask("mt")}</defs><rect width="400" height="400" fill="url(#pt)" mask="url(#mt)"/>`,
    desc: "Piastrelle mediterranee con un piccolo decoro a stella. Si lega al nostro arancio senza ripeterlo." }
};

import { pieceStaunton, pieceMorbido, pieceStampa } from "./staunton.mjs";

export const PIECE_SETS = {
  staunton: (t, c) => pieceStaunton(t, c),
  morbido: (t, c) => pieceMorbido(t, c),
  stampa: (t, c) => pieceStampa(t, c),
  rokko: (t, c) => pieceRokko(t, c, { faces: false }),
  pixel: (t, c) => piecePixel(t, c),
  arcano: (t, c) => pieceArcano(t, c),
  noto: (t, c) =>
    `<text x="22.5" y="37" text-anchor="middle" font-size="40" font-family="'Noto Sans Symbols 2'" fill="${c === "w" ? "#FFFFFF" : "#111111"}" stroke="${c === "w" ? "#222" : "#EEE"}" stroke-width="${c === "w" ? 0 : 0.6}">${GLYPH[c][t]}</text>`,
};

export { THEMES };

export function boardSvg(key) {
  const th = THEMES[key];
  let s = "";
  for (let r = 0; r < 8; r++)
    for (let c = 0; c < 8; c++)
      s += `<rect x="${c * 50}" y="${r * 50}" width="50" height="50" fill="${(r + c) % 2 ? th.dark : th.light}"/>`;
  return s + th.over();
}
