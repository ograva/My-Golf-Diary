const test = require('node:test');
const assert = require('node:assert/strict');
const { renderAttestPdf } = require('./attest_score_pdf');

const png =
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

test('attest PDF starts with %PDF and omits IN on nine holes', async () => {
  const pdf = await renderAttestPdf({
    courseName: 'Local Course',
    completedLabel: '2026-11-26 13:00',
    attestedLabel: '2026-11-26 13:05',
    name: 'Pat',
    role: 'self',
    formatSummary: 'Gross 36',
    holes: [
      { hole: 1, par: 4, gross: 4, played: true },
      { hole: 9, par: 4, gross: 5, played: true },
    ],
    imageBase64: png,
    imageMime: 'image/png',
  });
  assert.equal(pdf.subarray(0, 4).toString('ascii'), '%PDF');
});

test('eighteen holes include IN', async () => {
  const pdf = await renderAttestPdf({
    courseName: 'Local Course',
    name: 'Pat',
    role: 'marker',
    formatSummary: 'Gross 72',
    holes: [
      { hole: 1, par: 4, gross: 4, played: true },
      { hole: 10, par: 4, gross: 4, played: true },
    ],
    imageBase64: png,
    imageMime: 'image/png',
  });
  assert.equal(pdf.subarray(0, 4).toString('ascii'), '%PDF');
});

const { PDFDocument } = require('pdf-lib');

const base = {
  courseName: 'Local Course',
  name: 'Pat',
  role: 'self',
  holes: [{ hole: 1, par: 4, gross: 5, played: true }],
  imageBase64: png,
  imageMime: 'image/png',
};

async function pageCount(body) {
  const pdf = await renderAttestPdf(body);
  return (await PDFDocument.load(pdf)).getPageCount();
}

test('no strokeStats keeps a single page', async () => {
  assert.equal(await pageCount(base), 1);
  assert.equal(await pageCount({ ...base, strokeStats: { holes: [{ hole: 1, tracked: false }] } }), 1);
});

test('strokeStats with tracked holes adds page 2', async () => {
  const strokeStats = {
    version: 1,
    clubs: [
      { name: 'Driver', count: 1, minYds: 230, avgYds: 230, maxYds: 230 },
      { name: '7 Iron', count: 2, minYds: null, avgYds: null, maxYds: null },
    ],
    holes: Array.from({ length: 18 }, (_, i) => ({
      hole: i + 1, par: 4, tracked: i !== 5, gross: 5, strokesToApproach: 2,
      approachEstimated: i === 3, putts: 2, penalties: i === 2 ? 1 : 0, mulligans: 0,
      gimme: i === 7, sequence: ['Driver', '7 Iron', 'A very long club name indeed', 'x', 'y', 'z'],
    })),
    totals: { strokes: 80, putts: 34, penalties: 1, mulligans: 0, gimmes: 1, strokesToApproach: 34 },
    highlights: { longest: { club: 'Driver', yds: 230, hole: 1 }, mostUsed: { club: '7 Iron', count: 9 } },
    putting: {
      firstPuttAvgYds: 6.4,
      firstPuttHoles: 12,
      ranges: [
        { label: '0-3', made: 9, attempts: 10 },
        { label: '4-7', made: 3, attempts: 8 },
        { label: '8-15', made: 0, attempts: 5 },
        { label: '16+', made: 0, attempts: 0 },
      ],
    },
    extras: { girHit: 4, girOf: 17, fairwaysHit: 7, fairwaysOf: 14, upAndDownMade: 3, upAndDownOf: 13, threePutts: 1 },
  };
  assert.equal(await pageCount({ ...base, strokeStats }), 2);
});

test('malformed strokeStats values render without throwing', async () => {
  const strokeStats = {
    clubs: [{ name: null, count: 'x' }],
    holes: [{ hole: 1, tracked: true, sequence: 'nope' }],
    highlights: { longest: null },
  };
  assert.equal(await pageCount({ ...base, strokeStats }), 2);
});
