// Genera i PNG/WebP di pezzi, aloni e scacchiere da art.mjs con Chromium.
//
//   npm install --no-save playwright   (oppure NODE_PATH verso una copia globale)
//   node tool/board_art/render.mjs
//
// Serve la rete solo per il carattere Noto Sans Symbols 2 (Google Fonts).
import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { PIECE_SETS, THEMES, boardSvg } from "./art.mjs";

// require rispetta NODE_PATH, import no.
const { chromium } = createRequire(import.meta.url)("playwright");

const root = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
const out = (...p) => path.join(root, "assets", ...p);
const kinds = ["wK", "wQ", "wR", "wB", "wN", "wP", "bK", "bQ", "bR", "bB", "bN", "bP"];
const sizes = [["", 128], ["3.0x", 384]];
const BOARD_PX = 1024;

// Set di chessground con licenza ammessa: ricevono solo l'alone.
const chessgroundSets = { cburnett: "cburnett", merida: "merida", chessnut: "chessnut", fantasy: "fantasy", spatial: "spatial", celtic: "celtic", shapes: "shapes", firi: "firi", mpchess: "mpchess", kiwenSuwi: "kiwen-suwi", totoy: "totoy", rhosgfx: "rhosgfx" };

function chessgroundDir() {
  const config = JSON.parse(fs.readFileSync(path.join(root, ".dart_tool/package_config.json"), "utf8"));
  const pkg = config.packages.find((p) => p.name === "chessground");
  return path.join(new URL(pkg.rootUri, "file://" + path.join(root, ".dart_tool/")).pathname, "assets/piece_sets");
}

const svgUrl = (inner) => "data:image/svg+xml;base64," + Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45" width="45" height="45">${inner}</svg>`).toString("base64");

function write(file, dataUrl) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.from(dataUrl.split(",")[1], "base64"));
}

// BOARDS=marmo,vetro rigenera solo quelle scacchiere, senza toccare i pezzi.
const only = process.env.BOARDS?.split(",");

const browser = await chromium.launch();
const page = await browser.newPage();
await page.setContent(`<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Symbols+2&display=block"><span style="font-family:'Noto Sans Symbols 2'">♔♚</span>`);
await page.evaluate(() => document.fonts.ready);

// Disegna un'immagine (o un glifo) su una tela quadrata, con alone facoltativo.
await page.evaluate(() => {
  const load = (src) => new Promise((ok, ko) => { const i = new Image(); i.onload = () => ok(i); i.onerror = ko; i.src = src; });
  window.render = async ({ src, glyph, size, halo, type = "image/webp", quality = 0.92 }) => {
    const art = document.createElement("canvas");
    art.width = art.height = size;
    const a = art.getContext("2d");
    if (glyph) {
      a.font = `${size * 40 / 45}px 'Noto Sans Symbols 2'`;
      a.textAlign = "center";
      a.textBaseline = "alphabetic";
      const y = size * 37 / 45;
      if (glyph.under) { a.fillStyle = "#FFFFFF"; a.fillText(glyph.under, size / 2, y); }
      a.fillStyle = glyph.fill;
      a.fillText(glyph.text, size / 2, y);
      if (glyph.stroke) { a.lineWidth = size * 0.6 / 45; a.strokeStyle = glyph.stroke; a.strokeText(glyph.text, size / 2, y); }
    } else {
      a.drawImage(await load(src), 0, 0, size, size);
    }
    if (!halo) return art.toDataURL(type, quality);
    const tint = document.createElement("canvas");
    tint.width = tint.height = size;
    const t = tint.getContext("2d");
    t.drawImage(art, 0, 0);
    t.globalCompositeOperation = "source-in";
    t.fillStyle = "rgba(255,246,233,0.85)";
    t.fillRect(0, 0, size, size);
    const c = document.createElement("canvas");
    c.width = c.height = size;
    const g = c.getContext("2d");
    const r = size * 1.2 / 45;
    for (let i = 0; i < 24; i++) { const ang = (i / 24) * Math.PI * 2; g.drawImage(tint, Math.cos(ang) * r, Math.sin(ang) * r); }
    g.drawImage(art, 0, 0);
    return c.toDataURL(type, quality);
  };
});

async function piece(set, kind, src, glyph) {
  for (const [dir, size] of sizes) {
    write(out("pieces", set, dir, `${kind}.webp`), await page.evaluate((o) => window.render(o), { src, glyph, size }));
    if (kind[0] === "b") write(out("pieces", "halo", set, dir, `${kind}.webp`), await page.evaluate((o) => window.render(o), { src, glyph, size, halo: true }));
  }
}

const GLYPH = { K: ["♔", "♚"], Q: ["♕", "♛"], R: ["♖", "♜"], B: ["♗", "♝"], N: ["♘", "♞"], P: ["♙", "♟"] };
// SETS=staunton,morbido rigenera solo quei set di pezzi (e i loro aloni).
const onlySets = process.env.SETS?.split(",");
for (const [set, draw] of Object.entries(PIECE_SETS).filter(([k]) => onlySets ? onlySets.includes(k) : !only)) {
  for (const kind of kinds) {
    if (set === "noto") {
      const white = kind[0] === "w";
      // Il glifo bianco è solo un contorno: sotto si disegna la sagoma piena in bianco.
      await piece(set, kind, null, white ? { text: GLYPH[kind[1]][0], under: GLYPH[kind[1]][1], fill: "#111111" } : { text: GLYPH[kind[1]][1], fill: "#111111", stroke: "#EEEEEE" });
    } else {
      await piece(set, kind, svgUrl(draw(kind[1], kind[0])));
    }
  }
}
for (const kind of only || onlySets ? [] : kinds) {
  const svg = fs.readFileSync(path.join(root, "tool/board_art/papercut", `${kind}.svg`));
  await piece("papercut", kind, "data:image/svg+xml;base64," + svg.toString("base64"));
}

const cg = chessgroundDir();
for (const [name, dir] of only || onlySets ? [] : Object.entries(chessgroundSets)) {
  for (const kind of kinds.filter((k) => k[0] === "b")) {
    const src = "data:image/webp;base64," + fs.readFileSync(path.join(cg, dir, "4.0x", `${kind}.webp`)).toString("base64");
    for (const [d, size] of sizes) write(out("pieces", "halo", name, d, `${kind}.webp`), await page.evaluate((o) => window.render(o), { src, size, halo: true }));
  }
}

for (const key of Object.keys(THEMES).filter((k) => !only || only.includes(k))) {
  const src = "data:image/svg+xml;base64," + Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="${BOARD_PX}" height="${BOARD_PX}">${boardSvg(key)}</svg>`).toString("base64");
  write(out("boards", `${key}.webp`), await page.evaluate((o) => window.render(o), { src, size: BOARD_PX, quality: 0.85 }));
}
await browser.close();
console.log("immagini generate in assets/pieces e assets/boards");
