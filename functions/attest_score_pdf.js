const { PDFDocument, StandardFonts, rgb } = require('pdf-lib');

/**
 * One-page attested scorecard. [body] is the callable payload.
 * Returns a Buffer whose bytes start with %PDF.
 */
async function renderAttestPdf(body) {
  if (!body || typeof body !== 'object') {
    throw new Error('Missing payload');
  }
  const courseName = _text(body.courseName, 'Round');
  const name = _text(body.name, 'Me');
  const role = _text(body.role, 'self');
  const summary = _text(body.formatSummary, '');
  const holes = Array.isArray(body.holes) ? body.holes : [];
  const imageBytes = Buffer.from(String(body.imageBase64 || ''), 'base64');
  if (imageBytes.length === 0) throw new Error('Missing image');
  const mime = String(body.imageMime || 'image/png');

  const doc = await PDFDocument.create();
  const page = doc.addPage([595.28, 841.89]);
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const fonts = { font, bold };
  const margin = 36;
  const contentW = 595.28 - margin * 2;
  let y = 790;

  page.drawRectangle({ x: 0, y: 822, width: 595.28, height: 20, color: BRAND });
  page.drawText(courseName, { x: margin, y, size: 20, font: bold, color: BRAND });
  y -= 20;
  page.drawText(`Played ${_text(body.completedLabel, '')}`, {
    x: margin, y, size: 11, font, color: MUTED,
  });
  y -= 15;
  page.drawText('Attested by ', { x: margin, y, size: 11, font, color: MUTED });
  page.drawText(`${name} · ${role}`, {
    x: margin + font.widthOfTextAtSize('Attested by ', 11), y, size: 11, font: bold,
  });
  y -= 15;
  if (summary) {
    page.drawText(summary, { x: margin, y, size: 11, font });
    y -= 15;
  }
  y -= 6;
  page.drawLine({
    start: { x: margin, y }, end: { x: margin + contentW, y }, thickness: 0.75, color: BRAND,
  });
  y -= 18;

  const front = holes.filter((hole) => Number(hole.hole) <= 9);
  const back = holes.filter((hole) => Number(hole.hole) > 9);
  y = _drawNine(page, fonts, margin, y, contentW, front, true, back.length === 0, _playedGross(holes));
  if (back.length > 0) {
    y -= 10;
    y = _drawNine(page, fonts, margin, y, contentW, back, false, true, _playedGross(holes));
  }
  y -= 8;
  y = _drawLegend(page, font, margin, y);

  const image = mime.includes('jpeg') || mime.includes('jpg')
    ? await doc.embedJpg(imageBytes)
    : await doc.embedPng(imageBytes);
  const pad = 8;
  const maxW = contentW - pad * 2;
  const maxH = Math.max(40, Math.min(240, y - 24 - 90 - pad * 2));
  const scale = Math.min(maxW / image.width, maxH / image.height, 1);
  const w = image.width * scale;
  const h = image.height * scale;
  y -= 22;
  page.drawText('Signature', { x: margin, y, size: 10, font: bold, color: BRAND });
  y -= 6;
  const boxH = h + pad * 2;
  page.drawRectangle({
    x: margin, y: y - boxH, width: contentW, height: boxH,
    borderColor: GRID, borderWidth: 0.75, color: rgb(1, 1, 1),
  });
  page.drawImage(image, { x: margin + (contentW - w) / 2, y: y - pad - h, width: w, height: h });

  page.drawLine({
    start: { x: margin, y: 62 }, end: { x: margin + contentW, y: 62 }, thickness: 0.5, color: GRID,
  });
  page.drawText('Personal attestation. Not a committee card.', {
    x: margin, y: 46, size: 9, font, color: MUTED,
  });
  page.drawText(`Attested ${_text(body.attestedLabel, '')}`, {
    x: margin, y: 33, size: 9, font, color: MUTED,
  });
  const brand = 'My Golf Diary';
  page.drawText(brand, {
    x: margin + contentW - bold.widthOfTextAtSize(brand, 9), y: 46, size: 9, font: bold, color: BRAND,
  });

  return Buffer.from(await doc.save());
}

const BRAND = rgb(0x1a / 255, 0x5e / 255, 0x3a / 255);
const HEADER_TEXT = rgb(1, 1, 1);
const STRIPE = rgb(0.93, 0.96, 0.93);
const TOTAL_FILL = rgb(0.86, 0.92, 0.87);
const GRID = rgb(0.62, 0.72, 0.65);
const MUTED = rgb(0.33, 0.36, 0.34);
const SCORE_FILL = {
  under: rgb(0.80, 0.90, 0.98),
  par: null,
  over: rgb(0.99, 0.90, 0.84),
};

function _drawNine(page, fonts, x, y, width, holes, out, withTotal, total) {
  const columns = holes.map((hole) => ({
    label: String(hole.hole),
    par: String(hole.par ?? ''),
    gross: hole.played ? String(hole.gross ?? 0) : '—',
    kind: hole.played ? _scoreKind(hole) : null,
    total: false,
  }));
  columns.push({
    label: out ? 'OUT' : 'IN',
    par: String(_sum(holes, 'par')),
    gross: String(_playedGross(holes)),
    total: true,
  });
  if (withTotal) {
    columns.push({ label: 'TOT', par: '', gross: String(total), total: true });
  }
  const labelW = 52;
  const colW = Math.min(44, (width - labelW) / Math.max(columns.length, 1));
  const rowH = 18;
  const rows = [
    { name: 'Hole', key: 'label', header: true },
    { name: 'Par', key: 'par' },
    { name: 'Gross', key: 'gross', scored: true },
  ];
  const tableW = labelW + colW * columns.length;
  rows.forEach((row, r) => {
    const top = y - r * rowH;
    const fill = row.header ? BRAND : r % 2 === 0 ? STRIPE : rgb(1, 1, 1);
    page.drawRectangle({ x, y: top - rowH, width: tableW, height: rowH, color: fill });
    _cellText(page, row.name, x, top, labelW, rowH, row.header ? fonts.bold : fonts.bold,
      row.header ? HEADER_TEXT : BRAND, 9);
    columns.forEach((col, c) => {
      const cx = x + labelW + c * colW;
      if (!row.header && col.total) {
        page.drawRectangle({ x: cx, y: top - rowH, width: colW, height: rowH, color: TOTAL_FILL });
      }
      if (row.scored && col.kind && SCORE_FILL[col.kind]) {
        page.drawRectangle({
          x: cx + 3, y: top - rowH + 3, width: colW - 6, height: rowH - 6, color: SCORE_FILL[col.kind],
        });
      }
      _cellText(page, col[row.key], cx, top, colW, rowH,
        row.header || col.total ? fonts.bold : fonts.font,
        row.header ? HEADER_TEXT : rgb(0.1, 0.1, 0.1), 9);
    });
  });
  const tableH = rowH * rows.length;
  for (let r = 1; r < rows.length; r++) {
    page.drawLine({ start: { x, y: y - r * rowH }, end: { x: x + tableW, y: y - r * rowH }, thickness: 0.4, color: GRID });
  }
  for (let c = 0; c <= columns.length; c++) {
    const lx = x + labelW + c * colW;
    page.drawLine({ start: { x: lx, y }, end: { x: lx, y: y - tableH }, thickness: 0.4, color: GRID });
  }
  page.drawRectangle({ x, y: y - tableH, width: tableW, height: tableH, borderColor: BRAND, borderWidth: 1 });
  return y - tableH;
}

function _drawLegend(page, font, x, y) {
  const items = [['Birdie or better', SCORE_FILL.under], ['Par', null], ['Bogey or worse', SCORE_FILL.over]];
  let cx = x;
  y -= 10;
  for (const [label, color] of items) {
    page.drawRectangle({
      x: cx, y: y - 1, width: 9, height: 9, color: color || rgb(1, 1, 1), borderColor: GRID, borderWidth: 0.5,
    });
    page.drawText(label, { x: cx + 13, y, size: 8, font, color: MUTED });
    cx += 13 + font.widthOfTextAtSize(label, 8) + 16;
  }
  return y - 4;
}

function _cellText(page, text, x, top, w, h, font, color, size) {
  const value = String(text);
  const tw = font.widthOfTextAtSize(value, size);
  page.drawText(value, { x: x + (w - tw) / 2, y: top - h / 2 - size * 0.35, size, font, color });
}

function _scoreKind(hole) {
  const par = Number(hole.par);
  if (!Number.isFinite(par) || par <= 0) return null;
  const diff = Number(hole.gross || 0) - par;
  if (diff < 0) return 'under';
  if (diff === 0) return 'par';
  return 'over';
}

function _sum(holes, key) {
  return holes.reduce((sum, hole) => sum + Number(hole[key] || 0), 0);
}

function _playedGross(holes) {
  return holes.reduce(
    (sum, hole) => sum + (hole.played ? Number(hole.gross || 0) : 0),
    0,
  );
}

function _text(value, fallback) {
  const text = value == null ? '' : String(value);
  return text.trim() === '' ? fallback : text;
}

module.exports = { renderAttestPdf };
