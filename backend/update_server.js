const fs = require('fs');

let file = fs.readFileSync('backend/server.js', 'utf8');
const hasCRLF = file.includes('\r\n');
let normalized = file.replace(/\r\n/g, '\n');

const target = `    if (elevesToInsert.length === 0) {
      return res.status(400).json({ error: 'Aucun élève sélectionné pour cette séance.' });
    }

    const crypto = require('crypto');`;

const repl = `    if (elevesToInsert.length === 0) {
      return res.status(400).json({ error: 'Aucun élève sélectionné pour cette séance.' });
    }

    // Le tarif du groupe est le montant total de la séance.
    // Chaque élève présent ou inscrit se voit attribuer une quote-part = (tarif_total / nb_eleves).
    const nbEleves = elevesToInsert.length;
    const quotePartParDefaut = Math.round(defaultTarif / nbEleves);
    for (const el of elevesToInsert) {
      // Si le montant n'a pas été explicitement personnalisé par élève, on utilise la quote-part divisée
      if (!el.montant || el.montant === defaultTarif) {
        el.montant = quotePartParDefaut;
      }
    }

    const crypto = require('crypto');`;

if (!normalized.includes(target)) {
  console.error('Target not found in server.js');
  process.exit(1);
}

normalized = normalized.replace(target, repl);
if (hasCRLF) normalized = normalized.replace(/\n/g, '\r\n');

fs.writeFileSync('backend/server.js', normalized, 'utf8');
console.log('Successfully updated backend/server.js');
