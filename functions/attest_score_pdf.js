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

  const stats = _strokeStats(body.strokeStats);
  if (stats) _drawStatsPage(doc, fonts, body, stats);

  return Buffer.from(await doc.save());
}

/** Validated page-2 stats, or null when no hole has tracked strokes. */
function _strokeStats(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const holes = (Array.isArray(raw.holes) ? raw.holes : []).slice(0, 27);
  if (!holes.some((hole) => hole && hole.tracked)) return null;
  return {
    clubs: (Array.isArray(raw.clubs) ? raw.clubs : []).slice(0, 20),
    holes,
    totals: raw.totals || {},
    highlights: raw.highlights || {},
    extras: raw.extras || {},
    putting: raw.putting || {},
  };
}

function _drawStatsPage(doc, fonts, body, stats) {
  const { font, bold } = fonts;
  const page = doc.addPage([595.28, 841.89]);
  const margin = 36;
  const contentW = 595.28 - margin * 2;
  let y = 790;
  page.drawRectangle({ x: 0, y: 822, width: 595.28, height: 20, color: BRAND });
  page.drawText('On-course stats', { x: margin, y, size: 20, font: bold, color: BRAND });
  y -= 20;
  page.drawText(`${_text(body.courseName, 'Round')} · ${_text(body.completedLabel, '')}`, {
    x: margin, y, size: 11, font, color: MUTED,
  });
  y -= 12;
  page.drawLine({
    start: { x: margin, y }, end: { x: margin + contentW, y }, thickness: 0.75, color: BRAND,
  });
  y -= 12;

  const t = stats.totals;
  const h = stats.highlights;
  const e = stats.extras;
  const longest = h.longest || null;
  const mostUsed = h.mostUsed || null;
  const tracked = stats.holes.filter((hole) => hole.tracked).length;
  const cards = [
    ['Longest', longest ? `${_num(longest.yds)} yds` : '—',
      longest ? `${_clip(longest.club)} · hole ${_num(longest.hole)}` : 'No distances'],
    ['Most used', mostUsed ? _clip(mostUsed.club) : '—',
      mostUsed ? `${_num(mostUsed.count)} shots` : 'Excl. putter, approach'],
    ['Putts', _num(t.putts), [
      tracked ? `${(Number(t.putts || 0) / tracked).toFixed(1)} per hole` : '',
      stats.putting.firstPuttAvgYds != null ? `1st putt ${_num(stats.putting.firstPuttAvgYds)} yds` : '',
    ].filter(Boolean).join(' · ')],
    ['Pen · Mull · Gimme', `${_num(t.penalties)} · ${_num(t.mulligans)} · ${_num(t.gimmes)}`, 'Round totals'],
  ];
  y = _drawCards(page, fonts, margin, y, contentW, cards);
  y -= 10;
  const extras = [
    ['GIR', _ratio(e.girHit, e.girOf), ''],
    ['Fairways hit', _ratio(e.fairwaysHit, e.fairwaysOf), 'Par 4 and 5'],
    ['Up and down', _ratio(e.upAndDownMade, e.upAndDownOf), 'Inside 60 yds'],
    ['3-putts', _num(e.threePutts), ''],
  ];
  y = _drawCards(page, fonts, margin, y, contentW, extras, true);
  y -= 18;

  page.drawText('Clubs', { x: margin, y, size: 11, font: bold, color: BRAND });
  y -= 6;
  const clubRows = stats.clubs.map((club) => [
    _clip(club.name), _num(club.count), _yds(club.minYds), _yds(club.avgYds), _yds(club.maxYds),
  ]);
  if (clubRows.length === 0) clubRows.push(['No woods, hybrids, or irons', '', '', '', '']);
  const clubTop = y;
  y = _drawTable(page, fonts, margin, y, [150, 55, 55, 55, 55],
    ['Club', 'Shots', 'Min', 'Avg', 'Max'], clubRows, []);
  const ranges = Array.isArray(stats.putting.ranges) ? stats.putting.ranges.slice(0, 6) : [];
  if (ranges.some((range) => Number(range && range.attempts) > 0)) {
    const px = margin + 370 + 12;
    page.drawText('Putts made (paced yds)', { x: px, y: clubTop + 6, size: 11, font: bold, color: BRAND });
    const puttY = _drawTable(page, fonts, px, clubTop, [45, 50, 46],
      ['Yds', 'Made', 'Rate'],
      ranges.map((range) => {
        const tries = Number(range.attempts) || 0;
        return [
          _clip(range.label),
          `${_num(range.made)}/${_num(tries)}`,
          tries > 0 ? `${Math.round((Number(range.made) || 0) / tries * 100)}%` : '—',
        ];
      }), []);
    y = Math.min(y, puttY);
  }
  y -= 18;

  page.drawText('Holes', { x: margin, y, size: 11, font: bold, color: BRAND });
  y -= 6;
  const holeRows = stats.holes.map((hole) => [
    _num(hole.hole),
    _num(hole.par),
    hole.tracked ? _num(hole.gross) : '—',
    hole.tracked ? `${_num(hole.strokesToApproach)}${hole.approachEstimated ? '*' : ''}` : '—',
    hole.tracked ? `${_num(hole.putts)}${hole.gimme ? ' G' : ''}` : (hole.gimme ? 'G' : '—'),
    hole.tracked && hole.firstPuttYds != null ? _num(hole.firstPuttYds) : '',
    _num(hole.penalties),
    _num(hole.mulligans),
    hole.tracked ? _sequence(hole.sequence) : '',
  ]);
  const totalRow = [
    'TOT', '', '', _num(t.strokesToApproach), _num(t.putts), '', _num(t.penalties), _num(t.mulligans), '',
  ];
  const rowH = stats.holes.length > 18 ? 13 : 15;
  y = _drawTable(page, fonts, margin, y, [34, 30, 40, 58, 42, 50, 34, 38, 197],
    ['Hole', 'Par', 'Gross', 'To appr.', 'Putts', '1st putt', 'Pen', 'Mull', 'Clubs before approach'],
    holeRows, [totalRow], rowH);

  page.drawLine({
    start: { x: margin, y: 62 }, end: { x: margin + contentW, y: 62 }, thickness: 0.5, color: GRID,
  });
  page.drawText(
    'To appr. = strokes before the first shot inside 60 yds (penalties excluded). * estimated. G = gimme, one putt. 1st putt in paced yds.',
    { x: margin, y: 46, size: 7.5, font, color: MUTED },
  );
  page.drawText('Stats from on-course tracking.', { x: margin, y: 33, size: 9, font, color: MUTED });
  const brand = 'My Golf Diary';
  page.drawText(brand, {
    x: margin + contentW - bold.widthOfTextAtSize(brand, 9), y: 46, size: 9, font: bold, color: BRAND,
  });
}

function _drawCards(page, fonts, x, y, width, cards, compact = false) {
  const gap = 8;
  const w = (width - gap * (cards.length - 1)) / cards.length;
  const h = compact ? 50 : 58;
  cards.forEach(([title, value, sub], i) => {
    const cx = x + i * (w + gap);
    page.drawRectangle({
      x: cx, y: y - h, width: w, height: h, color: compact ? rgb(1, 1, 1) : STRIPE,
      borderColor: compact ? GRID : BRAND, borderWidth: compact ? 0.5 : 1,
    });
    page.drawText(title, { x: cx + 8, y: y - 13, size: 8, font: fonts.bold, color: MUTED });
    page.drawText(_fit(fonts.bold, value, compact ? 14 : 17, w - 16), {
      x: cx + 8, y: y - (compact ? 30 : 34), size: compact ? 14 : 17, font: fonts.bold, color: BRAND,
    });
    if (sub) {
      page.drawText(_fit(fonts.font, sub, 7.5, w - 16), {
        x: cx + 8, y: y - h + 7, size: 7.5, font: fonts.font, color: MUTED,
      });
    }
  });
  return y - h;
}

function _drawTable(page, fonts, x, y, widths, header, rows, totals, rowH = 15) {
  const tableW = widths.reduce((a, b) => a + b, 0);
  const all = [header, ...rows, ...totals];
  all.forEach((row, r) => {
    const top = y - r * rowH;
    const isHeader = r === 0;
    const isTotal = r > rows.length;
    const fill = isHeader ? BRAND : isTotal ? TOTAL_FILL : r % 2 === 1 ? STRIPE : rgb(1, 1, 1);
    page.drawRectangle({ x, y: top - rowH, width: tableW, height: rowH, color: fill });
    let cx = x;
    row.forEach((cell, c) => {
      const f = isHeader || isTotal ? fonts.bold : fonts.font;
      const value = _fit(f, String(cell ?? ''), 8.5, widths[c] - 6);
      if (c === 0 || c === row.length - 1 && widths[c] > 100) {
        page.drawText(value, {
          x: cx + 4, y: top - rowH / 2 - 3, size: 8.5, font: f,
          color: isHeader ? HEADER_TEXT : rgb(0.1, 0.1, 0.1),
        });
      } else {
        _cellText(page, value, cx, top, widths[c], rowH, f, isHeader ? HEADER_TEXT : rgb(0.1, 0.1, 0.1), 8.5);
      }
      cx += widths[c];
    });
  });
  const tableH = rowH * all.length;
  for (let r = 1; r < all.length; r++) {
    page.drawLine({ start: { x, y: y - r * rowH }, end: { x: x + tableW, y: y - r * rowH }, thickness: 0.4, color: GRID });
  }
  let lx = x;
  for (let c = 0; c < widths.length - 1; c++) {
    lx += widths[c];
    page.drawLine({ start: { x: lx, y }, end: { x: lx, y: y - tableH }, thickness: 0.4, color: GRID });
  }
  page.drawRectangle({ x, y: y - tableH, width: tableW, height: tableH, borderColor: BRAND, borderWidth: 1 });
  return y - tableH;
}

function _fit(font, text, size, maxW) {
  let value = String(text);
  if (font.widthOfTextAtSize(value, size) <= maxW) return value;
  while (value.length > 1 && font.widthOfTextAtSize(`${value}…`, size) > maxW) {
    value = value.slice(0, -1);
  }
  return `${value}…`;
}

function _num(value) {
  const n = Number(value);
  return Number.isFinite(n) ? String(Math.round(n)) : '—';
}

function _yds(value) {
  return value == null ? '—' : _num(value);
}

function _ratio(made, of) {
  const total = Number(of);
  if (!Number.isFinite(total) || total <= 0) return '—';
  return `${_num(made)}/${_num(total)}`;
}

function _clip(value) {
  return _text(value, '?').slice(0, 24);
}

function _sequence(list) {
  if (!Array.isArray(list) || list.length === 0) return '';
  const names = list.slice(0, 5).map(_clip);
  return names.join(' · ') + (list.length > 5 ? ' …' : '');
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
