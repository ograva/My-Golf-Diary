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
