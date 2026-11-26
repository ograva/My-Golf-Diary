const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { renderAttestPdf } = require('./attest_score_pdf');

exports.attestScorePdf = onCall(
  { region: 'asia-east1', memory: '256MiB', timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required');
    }
    try {
      const pdf = await renderAttestPdf(request.data);
      return { pdfBase64: pdf.toString('base64') };
    } catch (error) {
      throw new HttpsError('invalid-argument', error.message || 'Could not render PDF');
    }
  },
);
