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
  const margin = 36;
  let y = 800;
  page.drawText(courseName, { x: margin, y, size: 18, font: bold });
  y -= 22;
  page.drawText(`Played ${_text(body.completedLabel, '')}`, {
    x: margin,
    y,
    size: 11,
    font,
  });
  y -= 16;
  page.drawText(`${name} · ${role}`, { x: margin, y, size: 11, font });
  y -= 16;
  if (summary) {
    page.drawText(summary, { x: margin, y, size: 11, font });
    y -= 18;
  }

  const front = holes.filter((hole) => Number(hole.hole) <= 9);
  const back = holes.filter((hole) => Number(hole.hole) > 9);
  y = _drawNine(page, font, margin, y, front, true, back.length === 0);
  if (back.length > 0) {
    y -= 8;
    y = _drawNine(page, font, margin, y, back, false, true, _playedGross(holes));
  }

  const image = mime.includes('jpeg') || mime.includes('jpg')
    ? await doc.embedJpg(imageBytes)
    : await doc.embedPng(imageBytes);
  const maxW = 523;
  const maxH = 220;
  const scale = Math.min(maxW / image.width, maxH / image.height, 1);
  const w = image.width * scale;
  const h = image.height * scale;
  y -= h + 16;
  if (y < 80) y = 80;
  page.drawImage(image, { x: margin, y, width: w, height: h });

  page.drawText('Personal attestation. Not a committee card.', {
    x: margin,
    y: 48,
    size: 10,
    font,
    color: rgb(0.2, 0.2, 0.2),
  });
  page.drawText(`Attested ${_text(body.attestedLabel, '')}`, {
    x: margin,
    y: 34,
    size: 10,
    font,
  });

  return Buffer.from(await doc.save());
}

function _drawNine(page, font, x, y, holes, out, withTotal, total) {
  const labels = ['Hole', ...holes.map((hole) => String(hole.hole)), out ? 'OUT' : 'IN'];
  const pars = ['Par', ...holes.map((hole) => String(hole.par ?? '')), String(_sum(holes, 'par'))];
  const gross = [
    'Gross',
    ...holes.map((hole) => (hole.played ? String(hole.gross ?? 0) : '—')),
    String(_playedGross(holes)),
  ];
  if (withTotal && !out) {
    labels.push('TOT');
    pars.push('');
    gross.push(String(total));
  }
  if (withTotal && out && holes.every((hole) => Number(hole.hole) <= 9)) {
    labels.push('TOT');
    pars.push('');
    gross.push(String(_playedGross(holes)));
  }
  const col = 28;
  for (const row of [labels, pars, gross]) {
    row.forEach((cell, index) => {
      page.drawText(String(cell), { x: x + index * col, y, size: 8, font });
    });
    y -= 12;
  }
  return y;
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
