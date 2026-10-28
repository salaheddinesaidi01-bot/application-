const express = require('express');
const cors = require('cors');
const PDFDocument = require('pdfkit');
const db = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());

// Initialisation de la base de données
db.initDb();

// Helper : Récupérer la configuration
async function getConfigValue(cle, defaultValue) {
  try {
    const res = await db.query('SELECT valeur FROM config WHERE cle = $1', [cle]);
    return res.rows.length > 0 ? res.rows[0].valeur : defaultValue;
  } catch (err) {
    return defaultValue;
  }
}

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Serveur opérationnel', port: PORT });
});

// ------------------------------------------------------------------------------
// 1. DASHBOARD
// ------------------------------------------------------------------------------
app.get('/api/dashboard', async (req, res) => {
  try {
    // 1. CA Total (Payé et non clôturé, non annulé)
    const caRes = await db.query(`
      SELECT COALESCE(SUM(montant), 0)::int AS ca_total
      FROM seances
      WHERE statut_paiement = 'Payé' AND (cloturee = FALSE OR cloturee IS NULL) AND statut_seance != 'Annulée'
    `);
    const caTotal = caRes.rows[0]?.ca_total || 0;

    // 2. Total Impayé (Non payé et non annulé)
    const impayeRes = await db.query(`
      SELECT COALESCE(SUM(montant), 0)::int AS total_impaye
      FROM seances
      WHERE statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
    `);
    const totalImpaye = impayeRes.rows[0]?.total_impaye || 0;

    // 3. Nombre d'Élèves Actifs
    const elevesRes = await db.query(`
      SELECT COUNT(*)::int AS nombre_eleves
      FROM eleves
      WHERE statut = 'Actif'
    `);
    const nombreEleves = elevesRes.rows[0]?.nombre_eleves || 0;

    // 4. Séances du Jour
    const todayRes = await db.query(`
      SELECT s.*, e.niveau as niveau
      FROM seances s
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.date_seance = CURRENT_DATE AND s.statut_seance != 'Annulée'
      ORDER BY s.date_creation DESC
    `);
    const seancesJour = todayRes.rows;

    // 5. Séances Impayées avec calcul des jours de retard
    const impayeesListRes = await db.query(`
      SELECT s.*, e.niveau as niveau
      FROM seances s
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Impayé' AND s.statut_seance != 'Annulée'
      ORDER BY s.date_seance ASC, s.date_creation ASC
    `);

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    const seancesImpayees = impayeesListRes.rows.map((s) => {
      const seanceDate = new Date(s.date_seance);
      seanceDate.setHours(0, 0, 0, 0);
      const diffTime = todayDate.getTime() - seanceDate.getTime();
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      return {
        ...s,
        joursRetard: diffDays > 0 ? diffDays : 0,
      };
    });

    // 6. Évolution du CA par mois (pour le graphique fl_chart)
    const chartRes = await db.query(`
      SELECT 
        TO_CHAR(date_seance, 'YYYY-MM') AS mois,
        COALESCE(SUM(montant), 0)::int AS total
      FROM seances
      WHERE statut_paiement = 'Payé' AND statut_seance != 'Annulée'
      GROUP BY mois
      ORDER BY mois ASC
      LIMIT 12
    `);
    const caChartData = chartRes.rows;

    // 7. Tarifs de configuration
    const configRes = await db.query('SELECT cle, valeur FROM config');
    const configObj = {};
    configRes.rows.forEach((r) => {
      configObj[r.cle] = r.valeur;
    });

    res.json({
      success: true,
      caTotal,
      totalImpaye,
      nombreEleves,
      seancesJour,
      seancesImpayees,
      caChartData,
      tarifs: {
        normale: parseInt(configObj.PrixNormale || '1000', 10),
        privee: parseInt(configObj.PrixPrivee || '2000', 10),
        normale_1: parseInt(configObj.PrixNormale || '1000', 10),
        normale_2: parseInt(configObj.PrixNormale2 || '1500', 10),
        privee_1: parseInt(configObj.PrixPrivee || '2000', 10),
        privee_2: parseInt(configObj.PrixPrivee2 || '2500', 10),
      },
      profNom: configObj.ProfNom || '',
      emailDestinataire: configObj.EmailDestinataire || 'salaheddinesaidi01@gmail.com',
    });
  } catch (err) {
    console.error('Erreur /api/dashboard :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération du tableau de bord', details: err.message });
  }
});

// ------------------------------------------------------------------------------
// 2. GESTION DES ÉLÈVES
// ------------------------------------------------------------------------------
app.get('/api/eleves', async (req, res) => {
  try {
    const { search, statut } = req.query;
    let query = 'SELECT * FROM eleves WHERE 1=1';
    const params = [];

    if (search && search.trim() !== '') {
      params.push(`%${search.trim().toLowerCase()}%`);
      query += ` AND LOWER(nom) LIKE $${params.length}`;
    }

    if (statut && statut.trim() !== '') {
      params.push(statut.trim());
      query += ` AND statut = $${params.length}`;
    }

    query += ' ORDER BY nom ASC';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Erreur GET /api/eleves :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des élèves' });
  }
});

app.post('/api/eleves', async (req, res) => {
  try {
    const { nom, niveau, telephone, telephone_parent, email, statut } = req.body;
    if (!nom || nom.trim() === '') {
      return res.status(400).json({ error: 'Le nom de l\'élève est obligatoire.' });
    }

    const result = await db.query(
      `INSERT INTO eleves (nom, niveau, telephone, telephone_parent, email, statut)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        nom.trim(),
        niveau?.trim() || null,
        telephone?.trim() || null,
        telephone_parent?.trim() || null,
        email?.trim() || null,
        statut || 'Actif',
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Erreur POST /api/eleves :', err);
    res.status(500).json({ error: 'Erreur lors de l\'ajout de l\'élève' });
  }
});

// ------------------------------------------------------------------------------
// 2.B GESTION DU PROFIL PROFESSEUR ET CONFIGURATION
// ------------------------------------------------------------------------------
app.get('/api/profil', async (req, res) => {
  try {
    const configRes = await db.query('SELECT cle, valeur FROM config');
    const configObj = {};
    configRes.rows.forEach((r) => {
      configObj[r.cle] = r.valeur;
    });

    let matieres = [];
    if (configObj.ProfMatieres) {
      try {
        matieres = JSON.parse(configObj.ProfMatieres);
      } catch (e) {
        matieres = configObj.ProfMatieres.split(',').map((s) => s.trim()).filter(Boolean);
      }
    }

    const nomVal = (configObj.ProfNom || '').trim();
    const isConfVal = configObj.isConfigured === 'true' || configObj.isConfigured === true;
    const isConfigured = nomVal.length > 0 && isConfVal;

    res.json({
      success: true,
      titre: configObj.ProfTitre || 'Prof.',
      nom: nomVal,
      specialite: configObj.ProfSpecialite || '',
      telephone: configObj.ProfTelephone || '',
      email: configObj.ProfEmail || '',
      matieres: matieres.length > 0 ? matieres : ['Mathématiques', 'Physique-Chimie'],
      prix_normale_1: parseInt(configObj.PrixNormale || '1000', 10),
      prix_normale_2: parseInt(configObj.PrixNormale2 || '1500', 10),
      prix_privee_1: parseInt(configObj.PrixPrivee || '2000', 10),
      prix_privee_2: parseInt(configObj.PrixPrivee2 || '2500', 10),
      devise: configObj.Devise || 'DZD',
      pin_code: configObj.PinCode || '',
      avatar: configObj.Avatar || 'school',
      isConfigured: isConfigured,
    });
  } catch (err) {
    console.error('Erreur GET /api/profil :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération du profil professeur' });
  }
});

app.post('/api/profil', async (req, res) => {
  try {
    const {
      titre,
      nom,
      specialite,
      telephone,
      email,
      matieres,
      prix_normale_1,
      prix_normale_2,
      prix_privee_1,
      prix_privee_2,
      devise,
      pin_code,
      avatar,
      isConfigured,
    } = req.body;

    const trimmedNom = (nom || '').trim();
    const isConfiguredBool = trimmedNom.length > 0 && (isConfigured !== false && isConfigured !== 'false');

    const updates = [
      { cle: 'ProfTitre', valeur: (titre || 'Prof.').trim() },
      { cle: 'ProfNom', valeur: trimmedNom },
      { cle: 'ProfSpecialite', valeur: (specialite || '').trim() },
      { cle: 'ProfTelephone', valeur: (telephone || '').trim() },
      { cle: 'ProfEmail', valeur: (email || '').trim() },
      { cle: 'ProfMatieres', valeur: JSON.stringify(Array.isArray(matieres) ? matieres : []) },
      { cle: 'PrixNormale', valeur: String(prix_normale_1 ?? 1000) },
      { cle: 'PrixNormale2', valeur: String(prix_normale_2 ?? 1500) },
      { cle: 'PrixPrivee', valeur: String(prix_privee_1 ?? 2000) },
      { cle: 'PrixPrivee2', valeur: String(prix_privee_2 ?? 2500) },
      { cle: 'Devise', valeur: (devise || 'DZD').trim() },
      { cle: 'PinCode', valeur: (pin_code || '').trim() },
      { cle: 'Avatar', valeur: (avatar || 'school').trim() },
      { cle: 'isConfigured', valeur: isConfiguredBool ? 'true' : 'false' },
    ];

    for (const item of updates) {
      await db.query(
        `INSERT INTO config (cle, valeur) VALUES ($1, $2)
         ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur`,
        [item.cle, item.valeur]
      );
    }

    res.json({ success: true, message: 'Profil professeur enregistré avec succès.' });
  } catch (err) {
    console.error('Erreur POST /api/profil :', err);
    res.status(500).json({ error: 'Erreur lors de l\'enregistrement du profil professeur' });
  }
});

app.patch('/api/eleves/:id/statut', async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;

    let newStatut = statut;
    if (!newStatut) {
      const current = await db.query('SELECT statut FROM eleves WHERE id_eleve = $1', [id]);
      if (current.rows.length === 0) {
        return res.status(404).json({ error: 'Élève non trouvé' });
      }
      newStatut = current.rows[0].statut === 'Actif' ? 'Inactif' : 'Actif';
    }

    const result = await db.query(
      'UPDATE eleves SET statut = $1 WHERE id_eleve = $2 RETURNING *',
      [newStatut, id]
    );

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Erreur PATCH /api/eleves/:id/statut :', err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du statut' });
  }
});

app.delete('/api/eleves/:id', async (req, res) => {
  try {
    const { id } = req.params;
    // La contrainte ON DELETE SET NULL préserve les séances associées
    const result = await db.query('DELETE FROM eleves WHERE id_eleve = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Élève non trouvé' });
    }
    res.json({ success: true, message: 'Élève supprimé avec succès (historique des séances préservé).' });
  } catch (err) {
    console.error('Erreur DELETE /api/eleves/:id :', err);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'élève' });
  }
});

// ------------------------------------------------------------------------------
// 3. FICHE ÉLÈVE DÉTAILLÉE (avec KPIs et Historique complet)
// ------------------------------------------------------------------------------
app.get('/api/eleves/:id/fiche', async (req, res) => {
  try {
    const { id } = req.params;

    // Récupérer l'élève
    const eleveRes = await db.query('SELECT * FROM eleves WHERE id_eleve = $1', [id]);
    const eleve = eleveRes.rows[0] || null;

    // Historique complet des séances (y compris clôturées, hors annulées pour les KPI)
    const seancesRes = await db.query(
      `SELECT * FROM seances 
       WHERE id_eleve = $1 
       ORDER BY date_seance DESC, date_creation DESC`,
      [id]
    );
    const seances = seancesRes.rows;

    // Calcul des 3 KPIs propres à l'élève (hors séances annulées)
    let totalPaye = 0;
    let totalImpaye = 0;
    let totalSeances = 0;

    seances.forEach((s) => {
      if (s.statut_seance !== 'Annulée') {
        totalSeances += 1;
        const montant = parseInt(s.montant, 10) || 0;
        if (s.statut_paiement === 'Payé') {
          totalPaye += montant;
        } else if (s.statut_paiement === 'Impayé') {
          totalImpaye += montant;
        }
      }
    });

    res.json({
      eleve,
      kpis: {
        totalPaye,
        totalImpaye,
        totalSeances,
      },
      seances,
    });
  } catch (err) {
    console.error('Erreur GET /api/eleves/:id/fiche :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération de la fiche élève' });
  }
});

// ------------------------------------------------------------------------------
// 4. GESTION DES SÉANCES
// ------------------------------------------------------------------------------

// Saisie en masse de séances RÉALISÉES
app.post('/api/seances/saisir-multiple', async (req, res) => {
  const client = await db.pool.connect();
  try {
    const { eleves, date_seance, type_seance, montant, statut_paiement } = req.body;

    if (!Array.isArray(eleves) || eleves.length === 0) {
      return res.status(400).json({ error: 'Veuillez sélectionner au moins un élève.' });
    }

    if (!date_seance) {
      return res.status(400).json({ error: 'La date de séance est obligatoire.' });
    }

    // RÈGLE MÉTIER STRICTE : Interdiction de saisir une séance dans le futur
    const inputDate = new Date(date_seance);
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    if (inputDate > today) {
      return res.status(400).json({
        error: 'Interdiction stricte : Impossible de saisir une séance réalisée à une date future. Utilisez la fonction "Planifier".',
      });
    }

    const typeSeanceFinal = type_seance || 'Normale';
    const montantFinal = parseInt(montant, 10);
    const estPaye = statut_paiement === 'Payé';
    const modePaiement = estPaye ? 'Espèces' : null;
    const datePaiement = estPaye ? date_seance : null;

    await client.query('BEGIN');

    const insertedRows = [];
    for (const el of eleves) {
      const insertRes = await client.query(
        `INSERT INTO seances (
          id_eleve, nom_eleve, date_seance, heure, type_seance, montant,
          statut_seance, statut_paiement, mode_paiement, date_paiement, cloturee
        ) VALUES ($1, $2, $3, $4, $5, $6, 'Réalisée', $7, $8, $9, FALSE)
        RETURNING *`,
        [
          el.id_eleve,
          el.nom,
          date_seance,
          null,
          typeSeanceFinal,
          montantFinal,
          estPaye ? 'Payé' : 'Impayé',
          modePaiement,
          datePaiement,
        ]
      );
      insertedRows.push(insertRes.rows[0]);
    }

    await client.query('COMMIT');
    res.status(201).json({
      success: true,
      message: `${insertedRows.length} séance(s) saisie(s) avec succès.`,
      seances: insertedRows,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur POST /api/seances/saisir-multiple :', err);
    res.status(500).json({ error: 'Erreur lors de la saisie des séances', details: err.message });
  } finally {
    client.release();
  }
});

// Planification en masse de séances PLANIFIÉES
app.post('/api/seances/planifier-multiple', async (req, res) => {
  const client = await db.pool.connect();
  try {
    const { eleves, date_seance, heure, type_seance, montant, notes } = req.body;

    if (!Array.isArray(eleves) || eleves.length === 0) {
      return res.status(400).json({ error: 'Veuillez sélectionner au moins un élève.' });
    }

    if (!date_seance) {
      return res.status(400).json({ error: 'La date de séance est obligatoire.' });
    }

    const typeSeanceFinal = type_seance || 'Normale';
    const montantFinal = parseInt(montant, 10);

    await client.query('BEGIN');

    const insertedRows = [];
    for (const el of eleves) {
      const insertRes = await client.query(
        `INSERT INTO seances (
          id_eleve, nom_eleve, date_seance, heure, type_seance, montant,
          statut_seance, statut_paiement, mode_paiement, date_paiement, notes, cloturee
        ) VALUES ($1, $2, $3, $4, $5, $6, 'Planifiée', 'Impayé', NULL, NULL, $7, FALSE)
        RETURNING *`,
        [
          el.id_eleve,
          el.nom,
          date_seance,
          heure || null,
          typeSeanceFinal,
          montantFinal,
          notes || null,
        ]
      );
      insertedRows.push(insertRes.rows[0]);
    }

    await client.query('COMMIT');
    res.status(201).json({
      success: true,
      message: `${insertedRows.length} séance(s) planifiée(s) avec succès.`,
      seances: insertedRows,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur POST /api/seances/planifier-multiple :', err);
    res.status(500).json({ error: 'Erreur lors de la planification des séances', details: err.message });
  } finally {
    client.release();
  }
});

// Paiement en masse de séances (ou individuel)
app.post('/api/seances/payer-masse', async (req, res) => {
  try {
    const { ids } = req.body;
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ error: 'Aucun ID de séance fourni.' });
    }

    const result = await db.query(
      `UPDATE seances
       SET statut_paiement = 'Payé',
           mode_paiement = 'Espèces',
           date_paiement = NOW(),
           statut_seance = 'Réalisée'
       WHERE id_seance = ANY($1::uuid[])
       RETURNING *`,
      [ids]
    );

    res.json({
      success: true,
      count: result.rows.length,
      message: `${result.rows.length} séance(s) marquée(s) comme payée(s).`,
      seances: result.rows,
    });
  } catch (err) {
    console.error('Erreur POST /api/seances/payer-masse :', err);
    res.status(500).json({ error: 'Erreur lors du règlement des séances' });
  }
});

// Annulation d'une séance
app.patch('/api/seances/:id/annuler', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      `UPDATE seances
       SET statut_seance = 'Annulée'
       WHERE id_seance = $1
       RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Séance non trouvée.' });
    }

    res.json({
      success: true,
      message: 'Séance annulée avec succès.',
      seance: result.rows[0],
    });
  } catch (err) {
    console.error('Erreur PATCH /api/seances/:id/annuler :', err);
    res.status(500).json({ error: 'Erreur lors de l\'annulation de la séance' });
  }
});

// Vérification des doublons de séance pour un élève / groupe à une date donnée
app.post('/api/seances/verifier-doublon', async (req, res) => {
  try {
    const { eleveIds = [], dateSeance, idGroupe } = req.body;
    if (!dateSeance) {
      return res.json({ doublons: [] });
    }
    const doublons = [];
    if (Array.isArray(eleveIds) && eleveIds.length > 0) {
      const result = await db.query(`
        SELECT nom_eleve, type_seance, heure
        FROM seances
        WHERE date_seance = $1
          AND (id_eleve::text = ANY($2::text[]) OR nom_eleve IN (SELECT nom FROM eleves WHERE id_eleve::text = ANY($2::text[])))
          AND statut_seance != 'Annulée'
      `, [dateSeance, eleveIds.map((id) => id.toString())]);
      for (const r of result.rows) {
        const nom = r.nom_eleve || 'Un élève';
        const heure = r.heure;
        doublons.push(heure && heure.trim() !== '' ? `${nom} (${heure})` : nom);
      }
    } else if (idGroupe && idGroupe.toString().trim() !== '') {
      const result = await db.query(`
        SELECT nom_eleve, heure
        FROM seances
        WHERE date_seance = $1
          AND id_groupe::text = $2
          AND statut_seance != 'Annulée'
      `, [dateSeance, idGroupe.toString().trim()]);
      if (result.rows.length > 0) {
        doublons.push(`Le groupe a déjà ${result.rows.length} séance(s) ce jour-là`);
      }
    }
    res.json({ doublons });
  } catch (err) {
    console.error('Erreur POST /api/seances/verifier-doublon :', err);
    res.status(500).json({ error: 'Erreur lors de la vérification des doublons', doublons: [] });
  }
});

// ------------------------------------------------------------------------------
// 5. FINANCE & CLÔTURE MENSUELLE (ARCHIVES)
// ------------------------------------------------------------------------------

// Historique des paiements du mois en cours non clôturés
app.get('/api/finance/historique', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT s.*, e.niveau as niveau
      FROM seances s
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Payé' AND (s.cloturee = FALSE OR s.cloturee IS NULL) AND s.statut_seance != 'Annulée'
      ORDER BY s.date_paiement DESC, s.date_seance DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('Erreur GET /api/finance/historique :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'historique financier' });
  }
});

// Séances impayées pour la section Finance avec calcul des jours de retard
app.get('/api/finance/impayees', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT s.*, e.niveau as niveau
      FROM seances s
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Impayé' AND s.statut_seance != 'Annulée'
      ORDER BY s.date_seance ASC, s.date_creation ASC
    `);

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    const seances = result.rows.map((s) => {
      const seanceDate = new Date(s.date_seance);
      seanceDate.setHours(0, 0, 0, 0);
      const diffTime = todayDate.getTime() - seanceDate.getTime();
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      return {
        ...s,
        joursRetard: diffDays > 0 ? diffDays : 0,
      };
    });

    res.json(seances);
  } catch (err) {
    console.error('Erreur GET /api/finance/impayees :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des séances impayées' });
  }
});

// Liste des archives de clôtures mensuelles
app.get('/api/clotures', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT *
      FROM clotures_mensuelles
      ORDER BY date_cloture DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('Erreur GET /api/clotures :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des archives de clôture' });
  }
});

// Clôture mensuelle SANS EMAIL avec ARCHIVAGE IN-APP
app.post('/api/cloturer-mois', async (req, res) => {
  const client = await db.pool.connect();
  try {
    // 1. Récupérer toutes les séances payées et non clôturées
    const seancesRes = await client.query(`
      SELECT s.*, e.niveau as niveau
      FROM seances s
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Payé' AND (s.cloturee = FALSE OR s.cloturee IS NULL) AND s.statut_seance != 'Annulée'
      ORDER BY s.nom_eleve ASC, s.date_seance ASC
    `);

    const seances = seancesRes.rows;
    if (seances.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Aucune séance encaissée à clôturer pour ce mois.',
      });
    }

    // 2. Calcul des totaux et agrégation par élève
    let caTotal = 0;
    const elevesMap = {};

    seances.forEach((s) => {
      const montant = parseInt(s.montant, 10) || 0;
      caTotal += montant;

      const nom = s.nom_eleve || 'Élève';
      if (!elevesMap[nom]) {
        elevesMap[nom] = {
          nom: nom,
          nombreSeances: 0,
          montantTotal: 0,
        };
      }
      elevesMap[nom].nombreSeances += 1;
      elevesMap[nom].montantTotal += montant;
    });

    const recapEleves = Object.values(elevesMap).sort((a, b) => a.nom.localeCompare(b.nom));
    const totalElevesDistincts = recapEleves.length;
    const totalSeances = seances.length;

    const now = new Date();
    const moisNoms = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    const moisNom = `${moisNoms[now.getMonth()]} ${now.getFullYear()}`;
    const annee = now.getFullYear();
    const mois = now.getMonth() + 1;

    // 3. Archivage en base de données dans la table clotures_mensuelles
    await client.query('BEGIN');

    const insertClotureRes = await client.query(`
      INSERT INTO clotures_mensuelles (
        mois_nom, annee, mois, ca_total, total_seances, total_eleves, recap_eleves, seances_details
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      moisNom,
      annee,
      mois,
      caTotal,
      totalSeances,
      totalElevesDistincts,
      JSON.stringify(recapEleves),
      JSON.stringify(seances),
    ]);

    // 4. Marquer les séances comme clôturées (cloturee = TRUE)
    const idsToClose = seances.map((s) => s.id_seance.toString());
    await client.query(
      `UPDATE seances
       SET cloturee = TRUE
       WHERE id_seance::text = ANY($1::text[])`,
      [idsToClose]
    );

    await client.query('COMMIT');

    console.log(`✅ Mois ${moisNom} clôturé et archivé avec succès (${caTotal} DA, ${totalSeances} séances)`);

    res.json({
      success: true,
      message: `Le mois de ${moisNom} a été clôturé et archivé dans l'historique avec succès.`,
      caTotal,
      totalSeances,
      totalEleves: totalElevesDistincts,
      seances_cloturees: totalSeances,
      total_verse_da: caTotal,
      cloture: insertClotureRes.rows[0],
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Erreur POST /api/cloturer-mois :', err);
    res.status(500).json({ error: 'Erreur lors de la clôture mensuelle', details: err.message });
  } finally {
    client.release();
  }
});

// ------------------------------------------------------------------------------
// 6. CENTRE DE NOTIFICATIONS IN-APP
// ------------------------------------------------------------------------------
app.get('/api/notifications', async (req, res) => {
  try {
    const notifications = [];
    const now = new Date();
    const currentHours = now.getHours();
    const currentMinutes = now.getMinutes();
    const currentTimeInMinutes = currentHours * 60 + currentMinutes;

    // 1. Récupérer les séances impayées avec calcul du retard
    const impayeesRes = await db.query(`
      SELECT id_seance, nom_eleve, date_seance, montant, type_seance, date_creation
      FROM seances
      WHERE statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
      ORDER BY date_seance ASC, date_creation ASC
    `);

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    let countRetard3j = 0;
    let countImpayees = 0;

    impayeesRes.rows.forEach((s) => {
      const seanceDate = new Date(s.date_seance);
      seanceDate.setHours(0, 0, 0, 0);
      const diffTime = todayDate.getTime() - seanceDate.getTime();
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      const retard = diffDays > 0 ? diffDays : 0;
      const dateFormatted = seanceDate.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });

      if (retard >= 3) {
        countRetard3j++;
        notifications.push({
          id: `retard_${s.id_seance}`,
          id_seance: s.id_seance,
          type: 'retard_3j',
          severite: 'danger', // 🔴
          titre: `Retard critique (${retard}j sans paiement)`,
          message: `${s.nom_eleve} - Séance du ${dateFormatted} (${s.montant} DA) non réglée depuis ${retard} jours.`,
          nom_eleve: s.nom_eleve,
          montant: s.montant,
          retard_jours: retard,
          date_seance: s.date_seance,
        });
      } else {
        countImpayees++;
      }
    });

    // 2. Récupérer les séances planifiées pour aujourd'hui
    const planifieesRes = await db.query(`
      SELECT id_seance, nom_eleve, date_seance, heure, montant, type_seance, notes
      FROM seances
      WHERE date_seance = CURRENT_DATE AND statut_seance = 'Planifiée'
      ORDER BY heure ASC, date_creation ASC
    `);

    let countSeances30min = 0;

    planifieesRes.rows.forEach((s) => {
      let diffMin = null;
      let isSoon = false;

      if (s.heure && s.heure.includes(':')) {
        const parts = s.heure.trim().split(':');
        const h = parseInt(parts[0], 10);
        const m = parseInt(parts[1], 10);
        if (!isNaN(h) && !isNaN(m)) {
          const seanceMinutes = h * 60 + m;
          diffMin = seanceMinutes - currentTimeInMinutes;
          // Moins de 30 minutes avant la séance (ou commencée depuis moins de 15 min)
          if (diffMin >= -15 && diffMin <= 30) {
            isSoon = true;
          }
        }
      }

      if (isSoon) {
        countSeances30min++;
        const delaiStr = diffMin > 0 ? `dans ${diffMin} min` : 'maintenant';
        notifications.push({
          id: `bientot_${s.id_seance}`,
          id_seance: s.id_seance,
          type: 'seance_30min',
          severite: 'urgent', // 🔵
          titre: `Séance planifiée ${delaiStr} !`,
          message: `Cours avec ${s.nom_eleve} prévu à ${s.heure || 'aujourd\'hui'}. Préparez votre séance.`,
          nom_eleve: s.nom_eleve,
          heure: s.heure,
          type_seance: s.type_seance,
          notes: s.notes,
        });
      } else {
        // Séance planifiée aujourd'hui
        notifications.push({
          id: `planifiee_${s.id_seance}`,
          id_seance: s.id_seance,
          type: 'seance_aujourdhui',
          severite: 'info',
          titre: `Séance planifiée aujourd'hui`,
          message: `Séance avec ${s.nom_eleve} à ${s.heure || 'heure à confirmer'} (${s.type_seance}).`,
          nom_eleve: s.nom_eleve,
          heure: s.heure,
          type_seance: s.type_seance,
        });
      }
    });

    res.json({
      success: true,
      total: notifications.length,
      countRetard3j,
      countImpayees,
      countSeances30min,
      notifications,
    });
  } catch (err) {
    console.error('Erreur GET /api/notifications :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des notifications' });
  }
});

// ------------------------------------------------------------------------------
// 8. GESTION DES GROUPES
// ------------------------------------------------------------------------------

// Récupérer tous les groupes avec liste des élèves et statistiques
app.get('/api/groupes', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        g.id_groupe,
        g.nom,
        g.niveau,
        g.tarif_par_eleve,
        g.description,
        g.date_creation,
        COUNT(DISTINCT ge.id_eleve)::int AS total_eleves,
        COALESCE(
          JSON_AGG(
            JSON_BUILD_OBJECT('id_eleve', e.id_eleve, 'nom', e.nom, 'niveau', e.niveau, 'telephone', e.telephone)
          ) FILTER (WHERE e.id_eleve IS NOT NULL), '[]'::json
        ) AS eleves
      FROM groupes g
      LEFT JOIN groupe_eleves ge ON g.id_groupe = ge.id_groupe
      LEFT JOIN eleves e ON ge.id_eleve = e.id_eleve
      GROUP BY g.id_groupe
      ORDER BY g.nom ASC
    `);

    // Pour chaque groupe, calculer les séances impayées
    const groupesWithStats = await Promise.all(result.rows.map(async (grp) => {
      const impayesRes = await db.query(`
        SELECT COUNT(*)::int as count_impayes, COALESCE(SUM(montant), 0)::int as total_impaye
        FROM seances
        WHERE id_groupe = $1 AND statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
      `, [grp.id_groupe]);

      const derniereSeanceRes = await db.query(`
        SELECT date_seance, heure, COUNT(*)::int as presents
        FROM seances
        WHERE id_groupe = $1
        GROUP BY date_seance, heure
        ORDER BY date_seance DESC, heure DESC
        LIMIT 1
      `, [grp.id_groupe]);

      return {
        ...grp,
        countImpayes: impayesRes.rows[0]?.count_impayes || 0,
        totalImpaye: impayesRes.rows[0]?.total_impaye || 0,
        derniereSeance: derniereSeanceRes.rows[0] || null,
      };
    }));

    res.json(groupesWithStats);
  } catch (err) {
    console.error('Erreur GET /api/groupes :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération des groupes' });
  }
});

// Récupérer le détail d'un groupe avec élèves et séances
app.get('/api/groupes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const groupeRes = await db.query(`
      SELECT g.*,
        COUNT(DISTINCT ge.id_eleve)::int AS total_eleves,
        COALESCE(
          JSON_AGG(
            JSON_BUILD_OBJECT('id_eleve', e.id_eleve, 'nom', e.nom, 'niveau', e.niveau, 'telephone', e.telephone)
          ) FILTER (WHERE e.id_eleve IS NOT NULL), '[]'::json
        ) AS eleves
      FROM groupes g
      LEFT JOIN groupe_eleves ge ON g.id_groupe = ge.id_groupe
      LEFT JOIN eleves e ON ge.id_eleve = e.id_eleve
      WHERE g.id_groupe = $1
      GROUP BY g.id_groupe
    `, [id]);

    if (groupeRes.rows.length === 0) {
      return res.status(404).json({ error: 'Groupe non trouvé' });
    }

    const groupe = groupeRes.rows[0];

    const seancesRes = await db.query(`
      SELECT 
        s.id_seance,
        s.id_seance_groupe,
        s.date_seance,
        s.heure,
        s.nom_eleve,
        s.id_eleve,
        s.montant,
        s.statut_paiement,
        s.statut_seance,
        s.date_paiement
      FROM seances s
      WHERE s.id_groupe = $1
      ORDER BY s.date_seance DESC, s.date_creation DESC
      LIMIT 100
    `, [id]);

    res.json({
      ...groupe,
      seances: seancesRes.rows,
    });
  } catch (err) {
    console.error('Erreur GET /api/groupes/:id :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération du groupe' });
  }
});

// Créer un groupe
app.post('/api/groupes', async (req, res) => {
  try {
    const { nom, niveau, tarif_par_eleve, description, eleves_ids } = req.body;
    if (!nom || nom.trim() === '') {
      return res.status(400).json({ error: 'Le nom du groupe est obligatoire.' });
    }

    const tarif = parseInt(tarif_par_eleve, 10) || 1000;

    const insertRes = await db.query(`
      INSERT INTO groupes (nom, niveau, tarif_par_eleve, description)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [nom.trim(), niveau || null, tarif, description || null]);

    const groupe = insertRes.rows[0];

    // Assigner les élèves initiaux si spécifiés
    if (Array.isArray(eleves_ids) && eleves_ids.length > 0) {
      for (const id_eleve of eleves_ids) {
        await db.query(`
          INSERT INTO groupe_eleves (id_groupe, id_eleve)
          VALUES ($1, $2)
          ON CONFLICT DO NOTHING
        `, [groupe.id_groupe, id_eleve]);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Groupe créé avec succès.',
      groupe,
    });
  } catch (err) {
    console.error('Erreur POST /api/groupes :', err);
    res.status(500).json({ error: 'Erreur lors de la création du groupe' });
  }
});

// Mettre à jour un groupe et ses membres
app.put('/api/groupes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nom, niveau, tarif_par_eleve, description, eleves_ids } = req.body;

    if (!nom || nom.trim() === '') {
      return res.status(400).json({ error: 'Le nom du groupe est obligatoire.' });
    }

    const tarif = parseInt(tarif_par_eleve, 10) || 1000;

    const updateRes = await db.query(`
      UPDATE groupes
      SET nom = $1, niveau = $2, tarif_par_eleve = $3, description = $4
      WHERE id_groupe = $5
      RETURNING *
    `, [nom.trim(), niveau || null, tarif, description || null, id]);

    if (updateRes.rows.length === 0) {
      return res.status(404).json({ error: 'Groupe non trouvé.' });
    }

    // Synchronisation des membres
    if (Array.isArray(eleves_ids)) {
      await db.query('DELETE FROM groupe_eleves WHERE id_groupe = $1', [id]);
      for (const id_eleve of eleves_ids) {
        await db.query(`
          INSERT INTO groupe_eleves (id_groupe, id_eleve)
          VALUES ($1, $2)
          ON CONFLICT DO NOTHING
        `, [id, id_eleve]);
      }
    }

    res.json({
      success: true,
      message: 'Groupe mis à jour avec succès.',
      groupe: updateRes.rows[0],
    });
  } catch (err) {
    console.error('Erreur PUT /api/groupes/:id :', err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du groupe' });
  }
});

// Supprimer un groupe
app.delete('/api/groupes/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const delRes = await db.query('DELETE FROM groupes WHERE id_groupe = $1 RETURNING *', [id]);
    if (delRes.rows.length === 0) {
      return res.status(404).json({ error: 'Groupe non trouvé.' });
    }
    res.json({ success: true, message: 'Groupe supprimé avec succès.' });
  } catch (err) {
    console.error('Erreur DELETE /api/groupes/:id :', err);
    res.status(500).json({ error: 'Erreur lors de la suppression du groupe' });
  }
});

// Planifier ou enregistrer une séance collective pour un groupe
app.post('/api/groupes/:id/seance', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      date_seance,
      heure,
      type_seance = 'Normale',
      montant_par_eleve,
      notes,
      eleves_selectionnes, // Array of { id_eleve, nom, montant? } ou array of UUIDs
      statut_seance = 'Réalisée', // ou 'Planifiée'
    } = req.body;

    if (!date_seance) {
      return res.status(400).json({ error: 'La date de séance est requise.' });
    }

    // Vérifier l'existence du groupe
    const grpRes = await db.query('SELECT * FROM groupes WHERE id_groupe = $1', [id]);
    if (grpRes.rows.length === 0) {
      return res.status(404).json({ error: 'Groupe introuvable.' });
    }
    const groupe = grpRes.rows[0];
    const defaultTarif = parseInt(montant_par_eleve, 10) || groupe.tarif_par_eleve || 1000;

    let elevesToInsert = [];
    if (Array.isArray(eleves_selectionnes) && eleves_selectionnes.length > 0) {
      for (const item of eleves_selectionnes) {
        if (typeof item === 'string') {
          const eRes = await db.query('SELECT id_eleve, nom FROM eleves WHERE id_eleve = $1', [item]);
          if (eRes.rows.length > 0) {
            elevesToInsert.push({ id_eleve: eRes.rows[0].id_eleve, nom: eRes.rows[0].nom, montant: defaultTarif });
          }
        } else if (typeof item === 'object' && item.id_eleve) {
          elevesToInsert.push({
            id_eleve: item.id_eleve,
            nom: item.nom || 'Élève',
            montant: parseInt(item.montant || item.tarif, 10) || defaultTarif,
          });
        }
      }
    } else {
      const allMembersRes = await db.query(`
        SELECT e.id_eleve, e.nom
        FROM groupe_eleves ge
        JOIN eleves e ON ge.id_eleve = e.id_eleve
        WHERE ge.id_groupe = $1
      `, [id]);
      elevesToInsert = allMembersRes.rows.map(e => ({ id_eleve: e.id_eleve, nom: e.nom, montant: defaultTarif }));
    }

    if (elevesToInsert.length === 0) {
      return res.status(400).json({ error: 'Aucun élève sélectionné pour cette séance.' });
    }

    // Le tarif du groupe est par élève. Chaque élève présent reçoit ce tarif.
    for (const el of elevesToInsert) {
      el.montant = parseInt(el.montant || el.tarif, 10) || defaultTarif;
    }

    const crypto = require('crypto');
    const id_seance_groupe = crypto.randomUUID();

    const createdSeances = [];
    for (const el of elevesToInsert) {
      const insRes = await db.query(`
        INSERT INTO seances (
          id_eleve,
          nom_eleve,
          date_seance,
          heure,
          type_seance,
          montant,
          statut_seance,
          statut_paiement,
          id_groupe,
          id_seance_groupe,
          notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'Impayé', $8, $9, $10)
        RETURNING *
      `, [
        el.id_eleve,
        el.nom,
        date_seance,
        heure || null,
        type_seance,
        el.montant,
        statut_seance,
        id,
        id_seance_groupe,
        notes ? `[Groupe: ${groupe.nom}] ${notes}` : `[Groupe: ${groupe.nom}]`,
      ]);
      createdSeances.push(insRes.rows[0]);
    }

    res.status(201).json({
      success: true,
      message: `${createdSeances.length} séances créées pour le groupe "${groupe.nom}".`,
      count: createdSeances.length,
      id_seance_groupe,
      seances: createdSeances,
    });
  } catch (err) {
    console.error('Erreur POST /api/groupes/:id/seance :', err);
    res.status(500).json({ error: 'Erreur lors de la planification de la séance collective' });
  }
});

// Encaisser en 1 clic toutes les séances impayées d'un groupe
app.post('/api/groupes/:id/encaisser', async (req, res) => {
  try {
    const { id } = req.params;
    const { date_seance, id_seance_groupe, seances_ids, mode_paiement = 'Espèces' } = req.body;

    let query = `
      UPDATE seances
      SET statut_paiement = 'Payé',
          date_paiement = CURRENT_TIMESTAMP,
          mode_paiement = $1
      WHERE id_groupe = $2 AND statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
    `;
    const params = [mode_paiement, id];

    if (Array.isArray(seances_ids) && seances_ids.length > 0) {
      query += ` AND id_seance = ANY($3::uuid[])`;
      params.push(seances_ids);
    } else if (id_seance_groupe) {
      query += ` AND id_seance_groupe = $3`;
      params.push(id_seance_groupe);
    } else if (date_seance) {
      query += ` AND date_seance = $3`;
      params.push(date_seance);
    }

    query += ` RETURNING id_seance, montant, nom_eleve`;

    const result = await db.query(query, params);
    const countEncaisses = result.rows.length;
    const montantTotal = result.rows.reduce((sum, r) => sum + r.montant, 0);

    res.json({
      success: true,
      message: `${countEncaisses} séance(s) encaissée(s) avec succès pour un total de ${montantTotal} DA.`,
      countEncaisses,
      montantTotal,
      encaisses: result.rows,
    });
  } catch (err) {
    console.error('Erreur POST /api/groupes/:id/encaisser :', err);
    res.status(500).json({ error: 'Erreur lors de l\'encaissement groupé' });
  }
});

// ------------------------------------------------------------------------------
// 9. HISTORIQUE GLOBAL DES PAIEMENTS
// ------------------------------------------------------------------------------
app.get('/api/paiements/historique', async (req, res) => {
  try {
    const { mois, search, limit = 50, offset = 0 } = req.query;

    let whereClauses = ["s.statut_paiement = 'Payé'", "s.statut_seance != 'Annulée'"];
    const params = [];

    if (mois && mois.trim() !== '') {
      params.push(mois.trim());
      whereClauses.push(`TO_CHAR(s.date_paiement, 'YYYY-MM') = $${params.length}`);
    }

    if (search && search.trim() !== '') {
      params.push(`%${search.trim().toLowerCase()}%`);
      whereClauses.push(`(LOWER(s.nom_eleve) LIKE $${params.length} OR LOWER(COALESCE(g.nom, '')) LIKE $${params.length})`);
    }

    const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    // Total stats
    const totalRes = await db.query(`
      SELECT 
        COUNT(*)::int AS count_paiements,
        COALESCE(SUM(s.montant), 0)::int AS total_montant
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      ${whereSql}
    `, params);

    // List of payments
    const limitNum = parseInt(limit, 10) || 50;
    const offsetNum = parseInt(offset, 10) || 0;
    params.push(limitNum);
    params.push(offsetNum);

    const listRes = await db.query(`
      SELECT 
        s.id_seance,
        s.id_eleve,
        s.nom_eleve,
        e.niveau as niveau,
        s.date_seance,
        s.heure,
        s.type_seance,
        s.montant,
        s.mode_paiement,
        s.date_paiement,
        s.id_groupe,
        s.id_seance_groupe,
        g.nom AS nom_groupe,
        s.notes
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      ${whereSql}
      ORDER BY s.date_paiement DESC, s.date_seance DESC
      LIMIT $${params.length - 1} OFFSET $${params.length}
    `, params);

    res.json({
      success: true,
      count: totalRes.rows[0]?.count_paiements || 0,
      totalMontant: totalRes.rows[0]?.total_montant || 0,
      paiements: listRes.rows,
    });
  } catch (err) {
    console.error('Erreur GET /api/paiements/historique :', err);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'historique des paiements' });
  }
});

// Démarrage du serveur
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Serveur API Gestion Séances actif sur http://localhost:${PORT}`);
  console.log(`📱 Prêt pour l'émulateur Android sur http://10.0.2.2:${PORT}`);
});

