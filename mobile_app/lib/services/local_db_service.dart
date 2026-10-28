import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_notification.dart';
import '../models/cloture_mensuelle.dart';
import '../models/dashboard_data.dart';
import '../models/eleve.dart';
import '../models/fiche_eleve.dart';
import '../models/groupe.dart';
import '../models/paiement_historique.dart';
import '../models/prof_profile.dart';
import '../models/seance.dart';

/// Service de base de données SQLite 100% autonome et locale.
/// Permet à l'enseignant d'utiliser l'application sur son téléphone
/// sans ordinateur, sans serveur et sans aucune connexion internet.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._internal();
  LocalDbService._internal();

  Database? _db;

  static String _generateUuid() {
    final random = Random();
    String hex(int len) =>
        List.generate(len, (_) => random.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-8${hex(3)}-${hex(12)}';
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'tutorcraft_v4.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN id_groupe TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN id_seance_groupe TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN cloturee INTEGER NOT NULL DEFAULT 0');
        } catch (_) {}
      },
      onOpen: (db) async {
        await _createTables(db);
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN id_groupe TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN id_seance_groupe TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE seances ADD COLUMN cloturee INTEGER NOT NULL DEFAULT 0');
        } catch (_) {}
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // 1. Table config
    await db.execute('''
      CREATE TABLE IF NOT EXISTS config (
        cle TEXT PRIMARY KEY,
        valeur TEXT NOT NULL
      )
    ''');

    // 2. Table eleves
    await db.execute('''
      CREATE TABLE IF NOT EXISTS eleves (
        id_eleve TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        niveau TEXT,
        telephone TEXT,
        telephone_parent TEXT,
        email TEXT,
        statut TEXT NOT NULL DEFAULT 'Actif',
        date_ajout TEXT
      )
    ''');

    // 3. Table groupes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groupes (
        id_groupe TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        niveau TEXT,
        tarif_par_eleve INTEGER NOT NULL DEFAULT 1000,
        description TEXT,
        date_creation TEXT
      )
    ''');

    // 4. Table liaison groupe_eleves
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groupe_eleves (
        id_groupe TEXT NOT NULL,
        id_eleve TEXT NOT NULL,
        date_inscription TEXT,
        PRIMARY KEY (id_groupe, id_eleve)
      )
    ''');

    // 5. Table seances
    await db.execute('''
      CREATE TABLE IF NOT EXISTS seances (
        id_seance TEXT PRIMARY KEY,
        id_eleve TEXT,
        nom_eleve TEXT NOT NULL,
        date_seance TEXT NOT NULL,
        heure TEXT,
        type_seance TEXT NOT NULL,
        montant INTEGER NOT NULL,
        statut_seance TEXT NOT NULL DEFAULT 'Réalisée',
        statut_paiement TEXT NOT NULL DEFAULT 'Impayé',
        mode_paiement TEXT,
        date_paiement TEXT,
        notes TEXT,
        cloturee INTEGER NOT NULL DEFAULT 0,
        date_creation TEXT,
        id_groupe TEXT,
        id_seance_groupe TEXT
      )
    ''');

    // 6. Table clotures_mensuelles
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clotures_mensuelles (
        id_cloture TEXT PRIMARY KEY,
        date_cloture TEXT,
        mois_nom TEXT NOT NULL,
        annee INTEGER NOT NULL,
        mois INTEGER NOT NULL,
        ca_total INTEGER NOT NULL,
        total_seances INTEGER NOT NULL,
        total_eleves INTEGER NOT NULL,
        recap_eleves TEXT,
        seances_details TEXT
      )
    ''');
  }

  /// Initialisation propre de la configuration par défaut (aucun compte fictif ni élève bidon)
  Future<void> _seedInitialData(DatabaseExecutor db) async {
    final configs = [
      {'cle': 'ProfTitre', 'valeur': 'Prof.'},
      {'cle': 'ProfNom', 'valeur': ''},
      {'cle': 'ProfSpecialite', 'valeur': ''},
      {'cle': 'ProfTelephone', 'valeur': ''},
      {'cle': 'ProfEmail', 'valeur': ''},
      {'cle': 'Matieres', 'valeur': jsonEncode(['Mathématiques', 'Physique-Chimie', 'Sciences Naturelles'])},
      {'cle': 'PrixNormale_1', 'valeur': '1000'},
      {'cle': 'PrixNormale_2', 'valeur': '1500'},
      {'cle': 'PrixPrivee_1', 'valeur': '2000'},
      {'cle': 'PrixPrivee_2', 'valeur': '2500'},
      {'cle': 'Devise', 'valeur': 'DZD'},
      {'cle': 'PinCode', 'valeur': ''},
      {'cle': 'Avatar', 'valeur': 'school'},
      {'cle': 'isConfigured', 'valeur': 'false'},
    ];
    for (final c in configs) {
      await db.insert('config', c, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ==========================================
  // 1. DASHBOARD
  // ==========================================
  Future<DashboardData> getDashboard() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentHHmm = DateFormat('HH:mm').format(now);
    final currentYear = now.year;
    final currentMonth = now.month;

    // CA Encaissé non clôturé
    final caRes = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as ca
      FROM seances
      WHERE statut_paiement = 'Payé' AND (cloturee = 0 OR cloturee IS NULL) AND statut_seance != 'Annulée'
    ''');
    final caTotal = (caRes.first['ca'] as num?)?.toInt() ?? 0;

    // Total Impayé (exclut les séances planifiées futures non encore arrivées)
    final impayeRes = await db.rawQuery('''
      SELECT COALESCE(SUM(montant), 0) as impaye
      FROM seances
      WHERE statut_paiement = 'Impayé' 
        AND statut_seance != 'Annulée'
        AND (statut_seance != 'Planifiée' 
             OR date_seance < ? 
             OR (date_seance = ? AND (heure IS NULL OR heure = '' OR heure <= ?)))
    ''', [todayStr, todayStr, currentHHmm]);
    final totalImpaye = (impayeRes.first['impaye'] as num?)?.toInt() ?? 0;

    // Nombre d'élèves actifs
    final elevesRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM eleves WHERE statut = 'Actif'
    ''');
    final nombreEleves = (elevesRes.first['count'] as num?)?.toInt() ?? 0;

    // Séances du jour
    final seancesJourRows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.date_seance = ? AND s.statut_seance != 'Annulée'
      ORDER BY s.heure ASC, s.date_creation ASC
    ''', [todayStr]);
    final seancesJour = seancesJourRows.map((r) => _mapRowToSeance(r)).toList();

    // Séances impayées (exclut les séances planifiées futures non encore arrivées)
    final impayeesRows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Impayé' 
        AND s.statut_seance != 'Annulée'
        AND (s.statut_seance != 'Planifiée' 
             OR s.date_seance < ? 
             OR (s.date_seance = ? AND (s.heure IS NULL OR s.heure = '' OR s.heure <= ?)))
      ORDER BY s.date_seance ASC, s.heure ASC
    ''', [todayStr, todayStr, currentHHmm]);
    final seancesImpayees = impayeesRows.map((r) => _mapRowToSeance(r)).toList();

    // Chart Data (historique CA mensuel)
    final cloturesRows = await db.rawQuery('''
      SELECT annee, mois, ca_total FROM clotures_mensuelles
      ORDER BY annee ASC, mois ASC
    ''');
    final caChartData = <CaChartPoint>[];
    for (final row in cloturesRows) {
      final annee = row['annee'] as int;
      final mois = row['mois'] as int;
      final total = (row['ca_total'] as num).toInt();
      caChartData.add(CaChartPoint(
        mois: '$annee-${mois.toString().padLeft(2, '0')}',
        total: total,
      ));
    }

    // Ajouter le mois en cours s'il y a du CA encaissé non clôturé
    final curMoisKey = '$currentYear-${currentMonth.toString().padLeft(2, '0')}';
    final existingIdx = caChartData.indexWhere((p) => p.mois == curMoisKey);
    if (existingIdx >= 0) {
      final old = caChartData[existingIdx];
      caChartData[existingIdx] = CaChartPoint(mois: old.mois, total: old.total + caTotal);
    } else if (caTotal > 0 || caChartData.isEmpty) {
      caChartData.add(CaChartPoint(mois: curMoisKey, total: caTotal));
    }

    // Alertes retards > 3 jours
    final seuil3j = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));
    final retards3jRes = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(montant), 0) as total
      FROM seances
      WHERE statut_paiement = 'Impayé' 
        AND statut_seance != 'Annulée'
        AND date_seance <= ?
    ''', [seuil3j]);
    final retards3JCount = (retards3jRes.first['count'] as num?)?.toInt() ?? 0;
    final retards3JMontant = (retards3jRes.first['total'] as num?)?.toInt() ?? 0;

    // Config tarifs & prof
    final configMap = await _getAllConfig();
    final profNom = configMap['ProfNom'] ?? 'Enseignant';
    final email = configMap['EmailDestinataire'] ?? '';

    final n1 = int.tryParse(configMap['PrixNormale_1'] ?? '1000') ?? 1000;
    final n2 = int.tryParse(configMap['PrixNormale_2'] ?? '1500') ?? 1500;
    final p1 = int.tryParse(configMap['PrixPrivee_1'] ?? '2000') ?? 2000;
    final p2 = int.tryParse(configMap['PrixPrivee_2'] ?? '2500') ?? 2500;

    List<int> tn = [];
    if (configMap['TarifsNormale'] != null) {
      try {
        tn = List<int>.from(jsonDecode(configMap['TarifsNormale']!) as List);
      } catch (_) {}
    }
    if (tn.isEmpty) tn = [n1, n2];

    List<int> tp = [];
    if (configMap['TarifsPrivee'] != null) {
      try {
        tp = List<int>.from(jsonDecode(configMap['TarifsPrivee']!) as List);
      } catch (_) {}
    }
    if (tp.isEmpty) tp = [p1, p2];

    final tarifs = TarifsConfig(
      normale: tn.isNotEmpty ? tn.first : n1,
      privee: tp.isNotEmpty ? tp.first : p1,
      normale1: n1,
      normale2: n2,
      privee1: p1,
      privee2: p2,
      tarifsNormale: tn,
      tarifsPrivee: tp,
    );

    return DashboardData(
      caTotal: caTotal,
      totalImpaye: totalImpaye,
      nombreEleves: nombreEleves,
      seancesJour: seancesJour,
      seancesImpayees: seancesImpayees,
      caChartData: caChartData,
      tarifs: tarifs,
      emailDestinataire: email,
      profNom: profNom,
      retards3JCount: retards3JCount,
      retards3JMontant: retards3JMontant,
    );
  }

  // ==========================================
  // 2. ÉLÈVES
  // ==========================================
  Future<List<Eleve>> getEleves({String? search, String? statut}) async {
    final db = await database;
    String query = '''
      SELECT e.*, ge.id_groupe, g.nom as nom_groupe
      FROM eleves e
      LEFT JOIN groupe_eleves ge ON e.id_eleve = ge.id_eleve
      LEFT JOIN groupes g ON ge.id_groupe = g.id_groupe
      WHERE 1=1
    ''';
    final args = <dynamic>[];

    if (search != null && search.trim().isNotEmpty) {
      query += ' AND LOWER(e.nom) LIKE ?';
      args.add('%${search.trim().toLowerCase()}%');
    }
    if (statut != null && statut.trim().isNotEmpty) {
      query += ' AND e.statut = ?';
      args.add(statut.trim());
    }

    query += ' ORDER BY e.nom COLLATE NOCASE ASC';
    final rows = await db.rawQuery(query, args);
    return rows.map((r) => _mapRowToEleve(r)).toList();
  }

  Future<Eleve> ajouterEleve({
    required String nom,
    String? niveau,
    String? telephone,
    String? telephoneParent,
    String? email,
  }) async {
    final db = await database;
    final idEleve = _generateUuid();
    final dateAjout = DateTime.now().toIso8601String();

    await db.insert('eleves', {
      'id_eleve': idEleve,
      'nom': nom.trim(),
      'niveau': niveau?.trim(),
      'telephone': telephone?.trim(),
      'telephone_parent': telephoneParent?.trim(),
      'email': email?.trim(),
      'statut': 'Actif',
      'date_ajout': dateAjout,
    });

    return Eleve(
      idEleve: idEleve,
      nom: nom.trim(),
      niveau: niveau?.trim(),
      telephone: telephone?.trim(),
      telephoneParent: telephoneParent?.trim(),
      email: email?.trim(),
      statut: 'Actif',
      dateAjout: DateTime.parse(dateAjout),
    );
  }

  Future<Eleve> toggleStatutEleve(String idEleve, {String? nouveauStatut}) async {
    final db = await database;
    final rows = await db.query('eleves', where: 'id_eleve = ?', whereArgs: [idEleve]);
    if (rows.isEmpty) throw Exception('Élève non trouvé');

    final current = rows.first;
    final currentStatut = current['statut'] as String? ?? 'Actif';
    final updatedStatut = nouveauStatut ?? (currentStatut == 'Actif' ? 'Inactif' : 'Actif');

    await db.update(
      'eleves',
      {'statut': updatedStatut},
      where: 'id_eleve = ?',
      whereArgs: [idEleve],
    );

    return Eleve(
      idEleve: idEleve,
      nom: current['nom'] as String,
      niveau: current['niveau'] as String?,
      telephone: current['telephone'] as String?,
      telephoneParent: current['telephone_parent'] as String?,
      email: current['email'] as String?,
      statut: updatedStatut,
      dateAjout: current['date_ajout'] != null
          ? DateTime.tryParse(current['date_ajout'] as String)
          : null,
    );
  }

  Future<void> supprimerEleve(String idEleve) async {
    final db = await database;
    await db.delete('eleves', where: 'id_eleve = ?', whereArgs: [idEleve]);
    await db.delete('groupe_eleves', where: 'id_eleve = ?', whereArgs: [idEleve]);
    // Préserver le nom_eleve dans les séances historiques mais détacher id_eleve
    await db.update('seances', {'id_eleve': null}, where: 'id_eleve = ?', whereArgs: [idEleve]);
  }

  // ==========================================
  // 3. FICHE ÉLÈVE
  // ==========================================
  Future<FicheEleveData> getFicheEleve(String idEleve) async {
    final db = await database;
    final eleveRows = await db.rawQuery('''
      SELECT e.*, ge.id_groupe, g.nom as nom_groupe
      FROM eleves e
      LEFT JOIN groupe_eleves ge ON e.id_eleve = ge.id_eleve
      LEFT JOIN groupes g ON ge.id_groupe = g.id_groupe
      WHERE e.id_eleve = ?
    ''', [idEleve]);
    final eleve = eleveRows.isNotEmpty ? _mapRowToEleve(eleveRows.first) : null;

    final seancesRows = await db.rawQuery('''
      SELECT * FROM seances
      WHERE id_eleve = ?
      ORDER BY date_seance DESC, heure DESC, date_creation DESC
    ''', [idEleve]);

    final seances = seancesRows.map((r) => _mapRowToSeance(r)).toList();

    int totalPaye = 0;
    int totalImpaye = 0;
    int totalSeances = 0;

    for (final s in seances) {
      if (!s.estAnnulee) {
        totalSeances++;
        if (s.estPaye) {
          totalPaye += s.montant;
        } else if (s.estImpaye && s.estArrivee) {
          totalImpaye += s.montant;
        }
      }
    }

    return FicheEleveData(
      eleve: eleve,
      kpis: FicheKpis(
        totalPaye: totalPaye,
        totalImpaye: totalImpaye,
        totalSeances: totalSeances,
      ),
      seances: seances,
    );
  }

  // ==========================================
  // 4. SÉANCES (SAISIE & PLANIFICATION)
  // ==========================================
  Future<Map<String, dynamic>> saisirSeancesMultiple({
    required List<Eleve> eleves,
    required String dateSeance,
    required String typeSeance,
    required int montant,
    required String statutPaiement,
    String? idGroupe,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    final effectiveGroupeSeanceId =
        (idGroupe != null && idGroupe.isNotEmpty && eleves.length > 1)
            ? _generateUuid()
            : null;

    for (final e in eleves) {
      batch.insert('seances', {
        'id_seance': _generateUuid(),
        'id_eleve': e.idEleve,
        'nom_eleve': e.nom,
        'date_seance': dateSeance,
        'heure': null,
        'type_seance': typeSeance,
        'montant': montant,
        'statut_seance': 'Réalisée',
        'statut_paiement': statutPaiement,
        'mode_paiement': statutPaiement == 'Payé' ? 'Espèces' : null,
        'date_paiement': statutPaiement == 'Payé' ? now : null,
        'notes': null,
        'cloturee': 0,
        'date_creation': now,
        'id_groupe': idGroupe,
        'id_seance_groupe': effectiveGroupeSeanceId,
      });
    }

    await batch.commit(noResult: true);
    return {
      'success': true, 
      'count': eleves.length,
      'id_seance_groupe': effectiveGroupeSeanceId,
    };
  }

  Future<Map<String, dynamic>> planifierSeancesMultiple({
    required List<Eleve> eleves,
    required String dateSeance,
    String? heure,
    required String typeSeance,
    required int montant,
    String? notes,
    String? idGroupe,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    final effectiveGroupeSeanceId =
        (idGroupe != null && idGroupe.isNotEmpty && eleves.length > 1)
            ? _generateUuid()
            : null;
    final createdSeances = <Map<String, dynamic>>[];

    for (final e in eleves) {
      final id = _generateUuid();
      final item = {
        'id_seance': id,
        'id_eleve': e.idEleve,
        'nom_eleve': e.nom,
        'date_seance': dateSeance,
        'heure': heure,
        'type_seance': typeSeance,
        'montant': montant,
        'statut_seance': 'Planifiée',
        'statut_paiement': 'Impayé',
        'mode_paiement': null,
        'date_paiement': null,
        'notes': notes,
        'cloturee': 0,
        'date_creation': now,
        'id_groupe': idGroupe,
        'id_seance_groupe': effectiveGroupeSeanceId,
      };
      batch.insert('seances', item);
      createdSeances.add(item);
    }

    await batch.commit(noResult: true);
    return {
      'success': true, 
      'count': eleves.length,
      'seances': createdSeances,
      'id_seance_groupe': effectiveGroupeSeanceId,
    };
  }

  Future<int> payerSeancesMasse(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentHHmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final placeholders = List.filled(ids.length, '?').join(',');
    final count = await db.rawUpdate('''
      UPDATE seances
      SET statut_paiement = 'Payé', 
          date_paiement = ?, 
          mode_paiement = 'Espèces',
          statut_seance = CASE WHEN statut_seance = 'Planifiée' THEN 'Réalisée' ELSE statut_seance END
      WHERE id_seance IN ($placeholders)
        AND (statut_seance != 'Planifiée' 
             OR date_seance < ? 
             OR (date_seance = ? AND (heure IS NULL OR heure = '' OR heure <= ?)))
    ''', [nowIso, ...ids, todayStr, todayStr, currentHHmm]);

    return count;
  }

  Future<void> annulerSeance(String idSeance) async {
    final db = await database;
    await db.update(
      'seances',
      {'statut_seance': 'Annulée'},
      where: 'id_seance = ?',
      whereArgs: [idSeance],
    );
  }

  Future<Map<String, dynamic>> validerPointageGroupeComplet({
    required List<String> seancesPayeesIds,
    required List<String> seancesImpayeesIds,
    required List<String> seancesAbsentesIds,
    String modePaiement = 'Espèces',
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    int countPayees = 0;
    int countAbsentes = 0;

    // 1. Payées : Présent + Payé maintenant
    for (final id in seancesPayeesIds) {
      final res = await db.update(
        'seances',
        {
          'statut_seance': 'Réalisée',
          'statut_paiement': 'Payé',
          'mode_paiement': modePaiement,
          'date_paiement': now,
        },
        where: 'id_seance = ?',
        whereArgs: [id],
      );
      countPayees += res;
    }

    // 2. Impayées : Présent + Payer plus tard (dette)
    for (final id in seancesImpayeesIds) {
      await db.update(
        'seances',
        {
          'statut_seance': 'Réalisée',
          'statut_paiement': 'Impayé',
        },
        where: 'id_seance = ?',
        whereArgs: [id],
      );
    }

    // 3. Absentes : Absent -> séance Annulée et montant = 0 (pas de dette)
    for (final id in seancesAbsentesIds) {
      final res = await db.update(
        'seances',
        {
          'statut_seance': 'Annulée',
          'statut_paiement': 'Non payé',
          'montant': 0,
        },
        where: 'id_seance = ?',
        whereArgs: [id],
      );
      countAbsentes += res;
    }

    return {
      'success': true,
      'payees': countPayees,
      'impayees': seancesImpayeesIds.length,
      'absentes': countAbsentes,
    };
  }

  // ==========================================
  // 5. FINANCE & CLÔTURE MENSUELLE
  // ==========================================
  Future<List<Seance>> getFinanceHistorique() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Payé' AND (s.cloturee = 0 OR s.cloturee IS NULL) AND s.statut_seance != 'Annulée'
      ORDER BY s.date_seance DESC, s.date_creation DESC
    ''');
    return rows.map((r) => _mapRowToSeance(r)).toList();
  }

  Future<List<Seance>> getFinanceImpayees() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentHHmm = DateFormat('HH:mm').format(now);

    final rows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Impayé' 
        AND s.statut_seance != 'Annulée'
        AND (s.statut_seance != 'Planifiée' 
             OR s.date_seance < ? 
             OR (s.date_seance = ? AND (s.heure IS NULL OR s.heure = '' OR s.heure <= ?)))
      ORDER BY s.date_seance DESC, s.date_creation DESC
    ''', [todayStr, todayStr, currentHHmm]);
    return rows.map((r) => _mapRowToSeance(r)).toList();
  }

  Future<Map<String, dynamic>> cloturerMois() async {
    final db = await database;
    final seancesPayees = await db.rawQuery('''
      SELECT * FROM seances
      WHERE statut_paiement = 'Payé' AND (cloturee = 0 OR cloturee IS NULL) AND statut_seance != 'Annulée'
    ''');

    if (seancesPayees.isEmpty) {
      return {
        'success': false,
        'message': 'Aucune séance encaissée à clôturer pour ce mois.',
        'seances_cloturees': 0,
        'total_verse_da': 0,
        'caTotal': 0,
        'totalSeances': 0,
      };
    }

    final now = DateTime.now();
    const moisNoms = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final moisNomCap = '${moisNoms[now.month - 1]} ${now.year}';

    int caTotal = 0;
    final Map<String, Map<String, dynamic>> recapMap = {};
    final List<String> seancesIds = [];

    for (final s in seancesPayees) {
      final id = s['id_seance'].toString();
      final nomEleve = s['nom_eleve'] as String? ?? 'Élève';
      final montant = (s['montant'] as num?)?.toInt() ?? 0;

      seancesIds.add(id);
      caTotal += montant;

      if (!recapMap.containsKey(nomEleve)) {
        recapMap[nomEleve] = {
          'nom': nomEleve,
          'nombreSeances': 0,
          'montantTotal': 0,
        };
      }
      recapMap[nomEleve]!['nombreSeances'] =
          (recapMap[nomEleve]!['nombreSeances'] as int) + 1;
      recapMap[nomEleve]!['montantTotal'] =
          (recapMap[nomEleve]!['montantTotal'] as int) + montant;
    }

    final recapList = recapMap.values.toList();
    final idCloture = _generateUuid();

    await db.insert('clotures_mensuelles', {
      'id_cloture': idCloture,
      'date_cloture': now.toIso8601String(),
      'mois_nom': moisNomCap,
      'annee': now.year,
      'mois': now.month,
      'ca_total': caTotal,
      'total_seances': seancesPayees.length,
      'total_eleves': recapList.length,
      'recap_eleves': jsonEncode(recapList),
      'seances_details': jsonEncode(seancesPayees),
    });

    // Marquer les séances comme clôturées
    final placeholders = List.filled(seancesIds.length, '?').join(',');
    await db.rawUpdate('''
      UPDATE seances SET cloturee = 1 WHERE id_seance IN ($placeholders)
    ''', seancesIds);

    return {
      'success': true,
      'message': 'Clôture mensuelle enregistrée avec succès ($caTotal DZD)',
      'id_cloture': idCloture,
      'seances_cloturees': seancesPayees.length,
      'total_verse_da': caTotal,
      'caTotal': caTotal,
      'totalSeances': seancesPayees.length,
    };
  }

  Future<List<ClotureMensuelle>> getClotures() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT * FROM clotures_mensuelles
      ORDER BY annee DESC, mois DESC, date_cloture DESC
    ''');

    return rows.map((r) {
      dynamic recapRaw = r['recap_eleves'];
      List<RecapEleveCloture> recaps = [];
      if (recapRaw != null) {
        try {
          final decoded = jsonDecode(recapRaw.toString()) as List;
          recaps = decoded
              .map((item) => RecapEleveCloture.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        } catch (_) {}
      }

      dynamic detailsRaw = r['seances_details'];
      List<dynamic> details = [];
      if (detailsRaw != null) {
        try {
          details = jsonDecode(detailsRaw.toString()) as List;
        } catch (_) {}
      }

      return ClotureMensuelle(
        idCloture: r['id_cloture'] as String,
        dateCloture: DateTime.parse(r['date_cloture'] as String),
        moisNom: r['mois_nom'] as String,
        annee: r['annee'] as int,
        mois: r['mois'] as int,
        caTotal: (r['ca_total'] as num).toInt(),
        totalSeances: (r['total_seances'] as num).toInt(),
        totalEleves: (r['total_eleves'] as num).toInt(),
        recapEleves: recaps,
        seancesDetails: details,
      );
    }).toList();
  }

  Future<List<ClotureMensuelle>> getCloturesMensuelles() => getClotures();

  // ==========================================
  // 6. NOTIFICATIONS IN-APP
  // ==========================================
  static const _dismissedNotifsKey = 'dismissed_notification_ids';

  Future<void> dismissNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dismissedNotifsKey) ?? [];
    if (!list.contains(id)) {
      list.add(id);
      await prefs.setStringList(_dismissedNotifsKey, list);
    }
  }

  Future<void> dismissAllNotifications(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_dismissedNotifsKey) ?? [];
    final set = list.toSet()..addAll(ids);
    await prefs.setStringList(_dismissedNotifsKey, set.toList());
  }

  Future<NotificationsSummary> getNotifications() async {
    final db = await database;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds = (prefs.getStringList(_dismissedNotifsKey) ?? []).toSet();

    // 1. Impayés > 3 jours
    final impayeesRows = await db.rawQuery('''
      SELECT s.*, e.telephone
      FROM seances s
      LEFT JOIN eleves e ON s.id_eleve = e.id_eleve
      WHERE s.statut_paiement = 'Impayé' AND s.statut_seance != 'Annulée'
    ''');

    final notifs = <AppNotification>[];
    int countRetard3j = 0;
    int countImpayees = impayeesRows.length;
    int countSeances30min = 0;

    for (final r in impayeesRows) {
      final notifId = 'retard_${r['id_seance']}';
      if (dismissedIds.contains(notifId)) continue;

      final dateStr = r['date_seance']?.toString() ?? '';
      DateTime? d = DateTime.tryParse(dateStr);
      int retard = 0;
      if (d != null) {
        retard = now.difference(d).inDays;
      }

      if (retard >= 3) {
        countRetard3j++;
        notifs.add(AppNotification(
          id: notifId,
          idSeance: r['id_seance'] as String?,
          type: 'retard_3j',
          severite: retard >= 7 ? 'danger' : 'warning',
          titre: 'Paiement en retard ($retard jours)',
          message:
              'La séance de ${r['nom_eleve']} du $dateStr (${r['montant']} DZD) n\'a pas encore été réglée.',
          nomEleve: r['nom_eleve'] as String?,
          montant: (r['montant'] as num?)?.toInt(),
          retardJours: retard,
          telephone: r['telephone'] as String?,
          dateSeance: dateStr,
        ));
      }
    }

    // 2. Séances planifiées aujourd'hui
    final planifieesRows = await db.rawQuery('''
      SELECT s.*, e.telephone
      FROM seances s
      LEFT JOIN eleves e ON s.id_eleve = e.id_eleve
      WHERE s.date_seance = ? AND s.statut_seance = 'Planifiée'
    ''', [todayStr]);

    for (final r in planifieesRows) {
      final notifId = 'planif_${r['id_seance']}';
      if (dismissedIds.contains(notifId)) continue;

      final heure = r['heure'] as String?;
      countSeances30min++;
      notifs.add(AppNotification(
        id: notifId,
        idSeance: r['id_seance'] as String?,
        type: 'seance_30min',
        severite: 'info',
        titre: 'Séance planifiée aujourd\'hui',
        message:
            'Séance avec ${r['nom_eleve']}${heure != null ? ' à $heure' : ''} (${r['type_seance']}).',
        nomEleve: r['nom_eleve'] as String?,
        montant: (r['montant'] as num?)?.toInt(),
        heure: heure,
        dateSeance: todayStr,
        notes: r['notes'] as String?,
        telephone: r['telephone'] as String?,
      ));
    }

    return NotificationsSummary(
      total: notifs.length,
      countRetard3j: countRetard3j,
      countImpayees: countImpayees,
      countSeances30min: countSeances30min,
      notifications: notifs,
    );
  }

  // ==========================================
  // 7. PROFIL & TARIFS PERSONNALISÉS
  // ==========================================
  Future<ProfProfile> getProfProfile() async {
    final configMap = await _getAllConfig();
    final titre = configMap['ProfTitre'] ?? 'Prof.';
    final nom = configMap['ProfNom'] ?? '';
    final specialite = configMap['ProfSpecialite'] ?? '';
    final telephone = configMap['ProfTelephone'] ?? '';
    final email = configMap['ProfEmail'] ?? '';
    final devise = configMap['Devise'] ?? 'DZD';
    final pinCode = configMap['PinCode'] ?? '';
    final avatar = configMap['Avatar'] ?? 'school';

    List<String> matieres = ['Mathématiques', 'Physique-Chimie', 'Sciences Naturelles'];
    if (configMap['Matieres'] != null) {
      try {
        matieres = List<String>.from(jsonDecode(configMap['Matieres']!) as List);
      } catch (_) {}
    }

    final n1 = int.tryParse(configMap['PrixNormale_1'] ?? '1000') ?? 1000;
    final n2 = int.tryParse(configMap['PrixNormale_2'] ?? '1500') ?? 1500;
    final p1 = int.tryParse(configMap['PrixPrivee_1'] ?? '2000') ?? 2000;
    final p2 = int.tryParse(configMap['PrixPrivee_2'] ?? '2500') ?? 2500;
    final isConf = (configMap['isConfigured'] == 'true') && nom.trim().isNotEmpty;

    List<int> tn = [];
    if (configMap['TarifsNormale'] != null) {
      try {
        tn = List<int>.from(jsonDecode(configMap['TarifsNormale']!) as List);
      } catch (_) {}
    }
    if (tn.isEmpty) tn = [n1, n2];

    List<int> tp = [];
    if (configMap['TarifsPrivee'] != null) {
      try {
        tp = List<int>.from(jsonDecode(configMap['TarifsPrivee']!) as List);
      } catch (_) {}
    }
    if (tp.isEmpty) tp = [p1, p2];

    return ProfProfile(
      titre: titre,
      nom: nom,
      specialite: specialite,
      telephone: telephone,
      email: email,
      matieres: matieres,
      prixNormale1: n1,
      prixNormale2: n2,
      prixPrivee1: p1,
      prixPrivee2: p2,
      tarifsNormale: tn,
      tarifsPrivee: tp,
      devise: devise,
      pinCode: pinCode,
      avatar: avatar,
      isConfigured: isConf,
    );
  }

  Future<void> saveProfProfile(ProfProfile profile) async {
    final db = await database;
    final batch = db.batch();

    batch.insert('config', {'cle': 'ProfTitre', 'valeur': profile.titre.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'ProfNom', 'valeur': profile.nom.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'ProfSpecialite', 'valeur': profile.specialite.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'ProfTelephone', 'valeur': profile.telephone.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'ProfEmail', 'valeur': profile.email.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'Matieres', 'valeur': jsonEncode(profile.matieres)},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'PrixNormale_1', 'valeur': profile.prixNormale1.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'PrixNormale_2', 'valeur': profile.prixNormale2.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'PrixPrivee_1', 'valeur': profile.prixPrivee1.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'PrixPrivee_2', 'valeur': profile.prixPrivee2.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'TarifsNormale', 'valeur': jsonEncode(profile.tarifsNormale)},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'TarifsPrivee', 'valeur': jsonEncode(profile.tarifsPrivee)},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'Devise', 'valeur': profile.devise.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'PinCode', 'valeur': profile.pinCode.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('config', {'cle': 'Avatar', 'valeur': profile.avatar.trim()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert(
        'config',
        {
          'cle': 'isConfigured',
          'valeur': profile.nom.trim().isNotEmpty ? 'true' : 'false'
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    await batch.commit(noResult: true);
  }

  /// Remise à zéro des données (utile pour une nouvelle année scolaire)
  Future<void> resetAllData({bool keepProfile = true}) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('seances');
      await txn.delete('groupe_eleves');
      await txn.delete('groupes');
      await txn.delete('eleves');
      await txn.delete('clotures_mensuelles');
      if (!keepProfile) {
        await txn.delete('config');
        await _seedInitialData(txn);
      }
    });
  }

  /// Exportation intégrale de sauvegarde JSON
  Future<String> exportDataToJson() async {
    final db = await database;
    final configs = await db.query('config');
    final eleves = await db.query('eleves');
    final groupes = await db.query('groupes');
    final groupeEleves = await db.query('groupe_eleves');
    final seances = await db.query('seances');
    final clotures = await db.query('clotures_mensuelles');

    final backup = {
      'app': 'TutorCraft Pro',
      'version': '4.0.0',
      'date_export': DateTime.now().toIso8601String(),
      'config': configs,
      'eleves': eleves,
      'groupes': groupes,
      'groupe_eleves': groupeEleves,
      'seances': seances,
      'clotures_mensuelles': clotures,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  // ==========================================
  // 8. GROUPES
  // ==========================================
  Future<List<Groupe>> getGroupes() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT * FROM groupes ORDER BY nom COLLATE NOCASE ASC');
    final list = <Groupe>[];

    for (final r in rows) {
      final idGroupe = r['id_groupe'] as String;
      final membres = await _getMembresGroupe(idGroupe);

      // Statistiques impayés pour le groupe
      final statRes = await db.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(SUM(montant), 0) as total
        FROM seances
        WHERE id_groupe = ? AND statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
      ''', [idGroupe]);
      final countImpayes = (statRes.first['count'] as num?)?.toInt() ?? 0;
      final totalImpaye = (statRes.first['total'] as num?)?.toInt() ?? 0;

      // Dernière séance du groupe
      final lastSeanceRows = await db.rawQuery('''
        SELECT date_seance, heure FROM seances
        WHERE id_groupe = ? AND statut_seance != 'Annulée'
        ORDER BY date_seance DESC, heure DESC LIMIT 1
      ''', [idGroupe]);

      String? lastDate;
      String? lastHeure;
      if (lastSeanceRows.isNotEmpty) {
        lastDate = lastSeanceRows.first['date_seance']?.toString();
        lastHeure = lastSeanceRows.first['heure']?.toString();
      }

      list.add(Groupe(
        idGroupe: idGroupe,
        nom: r['nom'] as String,
        niveau: r['niveau'] as String?,
        tarifParEleve: (r['tarif_par_eleve'] as num?)?.toInt() ?? 1000,
        description: r['description'] as String?,
        dateCreation: r['date_creation'] != null
            ? DateTime.tryParse(r['date_creation'] as String)
            : null,
        totalEleves: membres.length,
        eleves: membres,
        countImpayes: countImpayes,
        totalImpaye: totalImpaye,
        derniereSeanceDate: lastDate,
        derniereSeanceHeure: lastHeure,
      ));
    }
    return list;
  }

  Future<Groupe> getGroupeById(String id) async {
    final db = await database;
    final rows = await db.query('groupes', where: 'id_groupe = ?', whereArgs: [id]);
    if (rows.isEmpty) throw Exception('Groupe introuvable');
    final r = rows.first;

    final membres = await _getMembresGroupe(id);
    final statRes = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(montant), 0) as total
      FROM seances
      WHERE id_groupe = ? AND statut_paiement = 'Impayé' AND statut_seance != 'Annulée'
    ''', [id]);

    return Groupe(
      idGroupe: id,
      nom: r['nom'] as String,
      niveau: r['niveau'] as String?,
      tarifParEleve: (r['tarif_par_eleve'] as num?)?.toInt() ?? 1000,
      description: r['description'] as String?,
      dateCreation: r['date_creation'] != null
          ? DateTime.tryParse(r['date_creation'] as String)
          : null,
      totalEleves: membres.length,
      eleves: membres,
      countImpayes: (statRes.first['count'] as num?)?.toInt() ?? 0,
      totalImpaye: (statRes.first['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Groupe> createGroupe({
    required String nom,
    String? niveau,
    int tarifParEleve = 1000,
    String? description,
    List<String> elevesIds = const [],
  }) async {
    final db = await database;
    final idGroupe = _generateUuid();
    final now = DateTime.now().toIso8601String();

    await db.insert('groupes', {
      'id_groupe': idGroupe,
      'nom': nom.trim(),
      'niveau': niveau?.trim(),
      'tarif_par_eleve': tarifParEleve,
      'description': description?.trim(),
      'date_creation': now,
    });

    final batch = db.batch();
    for (final eleveId in elevesIds) {
      batch.insert('groupe_eleves', {
        'id_groupe': idGroupe,
        'id_eleve': eleveId,
        'date_inscription': now,
      });
    }
    await batch.commit(noResult: true);

    return getGroupeById(idGroupe);
  }

  Future<Groupe> updateGroupe({
    required String id,
    required String nom,
    String? niveau,
    int tarifParEleve = 1000,
    String? description,
    List<String> elevesIds = const [],
  }) async {
    final db = await database;
    await db.update(
      'groupes',
      {
        'nom': nom.trim(),
        'niveau': niveau?.trim(),
        'tarif_par_eleve': tarifParEleve,
        'description': description?.trim(),
      },
      where: 'id_groupe = ?',
      whereArgs: [id],
    );

    // Mettre à jour les membres
    await db.delete('groupe_eleves', where: 'id_groupe = ?', whereArgs: [id]);
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final eleveId in elevesIds) {
      batch.insert('groupe_eleves', {
        'id_groupe': id,
        'id_eleve': eleveId,
        'date_inscription': now,
      });
    }
    await batch.commit(noResult: true);

    return getGroupeById(id);
  }

  Future<bool> deleteGroupe(String id) async {
    final db = await database;
    await db.delete('groupes', where: 'id_groupe = ?', whereArgs: [id]);
    await db.delete('groupe_eleves', where: 'id_groupe = ?', whereArgs: [id]);
    await db.update('seances', {'id_groupe': null}, where: 'id_groupe = ?', whereArgs: [id]);
    return true;
  }

  Future<Map<String, dynamic>> creerSeanceGroupe({
    required String idGroupe,
    required dynamic dateSeance,
    String? heure,
    String typeSeance = 'Normale',
    int? montantParEleve,
    String? notes,
    List<Map<String, dynamic>>? elevesSelectionnes,
    String statutSeance = 'Réalisée',
    String? matiere,
    List<dynamic>? presences,
    int? dureeMinutes,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final idSeanceGroupe = _generateUuid();

    String dateStr;
    String? heureStr = heure;
    if (dateSeance is DateTime) {
      dateStr = DateFormat('yyyy-MM-dd').format(dateSeance);
      heureStr ??= DateFormat('HH:mm').format(dateSeance);
    } else {
      dateStr = dateSeance.toString();
    }

    // Récupérer le tarif par élève configuré pour le groupe
    int tarifParEleve = montantParEleve ?? 500;
    try {
      final grpRows = await db.query('groupes', where: 'id_groupe = ?', whereArgs: [idGroupe]);
      if (grpRows.isNotEmpty) {
        tarifParEleve = (grpRows.first['tarif_par_eleve'] as num?)?.toInt() ?? tarifParEleve;
      }
    } catch (_) {}

    final selection = elevesSelectionnes ??
        presences?.map((p) {
          if (p is Map) {
            return {
              'id_eleve': p['id_eleve'],
              'nom': p['nom'],
              'montant': p['tarif'] ?? p['montant'],
              'paye': p['paye'] == true,
              'present': p['present'] != false,
            };
          }
          return {'id_eleve': p.toString(), 'present': true};
        }).toList() ??
        [];

    final batch = db.batch();
    for (final item in selection) {
      final idEleve = item['id_eleve']?.toString();
      String nomEleve = item['nom']?.toString() ?? '';
      if (nomEleve.isEmpty && idEleve != null) {
        final elRows = await db.query('eleves', where: 'id_eleve = ?', whereArgs: [idEleve]);
        if (elRows.isNotEmpty) nomEleve = elRows.first['nom'] as String;
      }
      final bool isPresent = item['present'] != false;
      bool estPaye = item['paye'] == true;
      if (statutSeance == 'Planifiée') {
        final parsedDt = DateTime.tryParse('${dateStr}T${(heureStr != null && heureStr.isNotEmpty) ? heureStr : "00:00"}:00');
        if (parsedDt != null && parsedDt.isAfter(DateTime.now())) {
          estPaye = false;
        }
      }

      final int montant = !isPresent
          ? 0
          : (int.tryParse(item['montant']?.toString() ?? '') ??
              int.tryParse(item['tarif']?.toString() ?? '') ??
              tarifParEleve);
      final String effectiveStatutSeance = !isPresent ? 'Annulée' : statutSeance;
      final String effectiveStatutPaiement = !isPresent ? 'Non payé' : (estPaye ? 'Payé' : 'Impayé');

      batch.insert('seances', {
        'id_seance': _generateUuid(),
        'id_eleve': idEleve,
        'nom_eleve': nomEleve.isNotEmpty ? nomEleve : 'Élève',
        'date_seance': dateStr,
        'heure': heureStr,
        'type_seance': matiere ?? typeSeance,
        'montant': montant,
        'statut_seance': effectiveStatutSeance,
        'statut_paiement': effectiveStatutPaiement,
        'mode_paiement': (isPresent && estPaye) ? 'Espèces' : null,
        'date_paiement': (isPresent && estPaye) ? now : null,
        'notes': notes,
        'cloturee': 0,
        'date_creation': now,
        'id_groupe': idGroupe,
        'id_seance_groupe': idSeanceGroupe,
      });
    }

    await batch.commit(noResult: true);
    return {
      'success': true,
      'id_seance_groupe': idSeanceGroupe,
      'seances_creees': selection.length,
    };
  }

  Future<Map<String, dynamic>> encaisserGroupe({
    required String idGroupe,
    String? dateSeance,
    String? idSeanceGroupe,
    List<String>? seancesIds,
    String modePaiement = 'Espèces',
  }) async {
    final db = await database;
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final currentHHmm = DateFormat('HH:mm').format(now);

    int count = 0;
    if (seancesIds != null && seancesIds.isNotEmpty) {
      final placeholders = List.filled(seancesIds.length, '?').join(',');
      count = await db.rawUpdate('''
        UPDATE seances
        SET statut_paiement = 'Payé', 
            date_paiement = ?, 
            mode_paiement = ?,
            statut_seance = CASE WHEN statut_seance = 'Planifiée' THEN 'Réalisée' ELSE statut_seance END
        WHERE id_seance IN ($placeholders)
          AND (statut_seance != 'Planifiée' 
               OR date_seance < ? 
               OR (date_seance = ? AND (heure IS NULL OR heure = '' OR heure <= ?)))
      ''', [nowIso, modePaiement, ...seancesIds, todayStr, todayStr, currentHHmm]);
    } else if (idSeanceGroupe != null) {
      count = await db.rawUpdate('''
        UPDATE seances
        SET statut_paiement = 'Payé', 
            date_paiement = ?, 
            mode_paiement = ?,
            statut_seance = CASE WHEN statut_seance = 'Planifiée' THEN 'Réalisée' ELSE statut_seance END
        WHERE id_seance_groupe = ?
          AND (statut_seance != 'Planifiée' 
               OR date_seance < ? 
               OR (date_seance = ? AND (heure IS NULL OR heure = '' OR heure <= ?)))
      ''', [nowIso, modePaiement, idSeanceGroupe, todayStr, todayStr, currentHHmm]);
    } else {
      count = await db.rawUpdate('''
        UPDATE seances
        SET statut_paiement = 'Payé', 
            date_paiement = ?, 
            mode_paiement = ?,
            statut_seance = CASE WHEN statut_seance = 'Planifiée' THEN 'Réalisée' ELSE statut_seance END
        WHERE id_groupe = ? AND statut_paiement = 'Impayé'
          AND (statut_seance != 'Planifiée' 
               OR date_seance < ? 
               OR (date_seance = ? AND (heure IS NULL OR heure = '' OR heure <= ?)))
      ''', [nowIso, modePaiement, idGroupe, todayStr, todayStr, currentHHmm]);
    }

    return {'success': true, 'seances_encaissees': count};
  }


  // ==========================================
  // 9. HISTORIQUE GLOBAL DES PAIEMENTS
  // ==========================================
  Future<HistoriquePaiementsResponse> getHistoriquePaiements({
    String? mois,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    String whereClause = "s.statut_paiement = 'Payé' AND s.statut_seance != 'Annulée'";
    final args = <dynamic>[];

    if (mois != null && mois.isNotEmpty) {
      whereClause += " AND s.date_seance LIKE ?";
      args.add('$mois%');
    }
    if (search != null && search.trim().isNotEmpty) {
      whereClause += " AND (LOWER(s.nom_eleve) LIKE ? OR LOWER(COALESCE(g.nom, '')) LIKE ?)";
      final q = '%${search.trim().toLowerCase()}%';
      args.add(q);
      args.add(q);
    }

    // Total Montant & Count
    final sumRes = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(s.montant), 0) as total
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      WHERE $whereClause
    ''', args);

    final totalCount = (sumRes.first['count'] as num?)?.toInt() ?? 0;
    final totalMontant = (sumRes.first['total'] as num?)?.toInt() ?? 0;

    // Lignes paginées
    final rows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE $whereClause
      ORDER BY s.date_seance DESC, s.date_paiement DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);

    final paiements = rows.map((r) {
      return PaiementHistorique(
        idSeance: r['id_seance'] as String,
        idEleve: r['id_eleve'] as String?,
        nomEleve: r['nom_eleve'] as String? ?? 'Élève',
        niveau: r['niveau'] as String?,
        dateSeance: r['date_seance'] != null
            ? DateTime.tryParse(r['date_seance'].toString())
            : null,
        heure: r['heure'] as String?,
        typeSeance: r['type_seance'] as String? ?? 'Normale',
        montant: (r['montant'] as num?)?.toInt() ?? 0,
        modePaiement: r['mode_paiement'] as String? ?? 'Espèces',
        datePaiement: r['date_paiement'] != null
            ? DateTime.tryParse(r['date_paiement'].toString())
            : null,
        idGroupe: r['id_groupe'] as String?,
        idSeanceGroupe: r['id_seance_groupe'] as String?,
        nomGroupe: r['nom_groupe'] as String?,
        notes: r['notes'] as String?,
      );
    }).toList();

    return HistoriquePaiementsResponse(
      count: totalCount,
      totalMontant: totalMontant,
      paiements: paiements,
    );
  }

  // ==========================================
  // HELPERS PRIVÉS
  // ==========================================
  Future<List<GroupeEleveMembre>> _getMembresGroupe(String idGroupe) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT e.id_eleve, e.nom, e.niveau, e.telephone
      FROM groupe_eleves ge
      JOIN eleves e ON ge.id_eleve = e.id_eleve
      WHERE ge.id_groupe = ?
      ORDER BY e.nom COLLATE NOCASE ASC
    ''', [idGroupe]);

    return rows.map((r) => GroupeEleveMembre.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<Map<String, String>> _getAllConfig() async {
    final db = await database;
    final rows = await db.query('config');
    final map = <String, String>{};
    for (final r in rows) {
      map[r['cle'] as String] = r['valeur'] as String;
    }
    return map;
  }

  Eleve _mapRowToEleve(Map<String, dynamic> r) {
    return Eleve(
      idEleve: r['id_eleve'] as String,
      nom: r['nom'] as String,
      niveau: r['niveau'] as String?,
      telephone: r['telephone'] as String?,
      telephoneParent: r['telephone_parent'] as String?,
      email: r['email'] as String?,
      statut: r['statut'] as String? ?? 'Actif',
      dateAjout: r['date_ajout'] != null
          ? DateTime.tryParse(r['date_ajout'] as String)
          : null,
      idGroupe: r['id_groupe'] as String?,
      nomGroupe: r['nom_groupe'] as String?,
    );
  }

  Seance _mapRowToSeance(Map<String, dynamic> r) {
    String rawDate = r['date_seance']?.toString() ?? '';
    if (rawDate.contains('T')) {
      rawDate = rawDate.split('T')[0];
    }

    int retard = 0;
    if (r['statut_paiement'] == 'Impayé' && rawDate.isNotEmpty) {
      final d = DateTime.tryParse(rawDate);
      if (d != null) {
        retard = DateTime.now().difference(d).inDays;
        if (retard < 0) retard = 0;
      }
    }

    return Seance(
      idSeance: r['id_seance'] as String,
      idEleve: r['id_eleve'] as String?,
      nomEleve: r['nom_eleve'] as String? ?? 'Élève',
      niveau: r['niveau'] as String?,
      dateSeance: rawDate,
      heure: r['heure'] as String?,
      typeSeance: r['type_seance'] as String? ?? 'Normale',
      montant: (r['montant'] as num?)?.toInt() ?? 0,
      statutSeance: r['statut_seance'] as String? ?? 'Réalisée',
      statutPaiement: r['statut_paiement'] as String? ?? 'Impayé',
      modePaiement: r['mode_paiement'] as String?,
      datePaiement: r['date_paiement'] as String?,
      notes: r['notes'] as String?,
      cloturee: r['cloturee'] == 1 || r['cloturee'] == true || r['cloturee']?.toString() == 'true',
      joursRetard: retard,
      idGroupe: r['id_groupe'] as String?,
      idSeanceGroupe: r['id_seance_groupe'] as String?,
      nomGroupe: r['nom_groupe'] as String?,
    );
  }

  // ==========================================
  // AFFECTATION GROUPE & SÉCURITÉS PLANNING
  // ==========================================
  Future<void> affecterEleveGroupe({
    required String idEleve,
    required String? idGroupe,
  }) async {
    final db = await database;
    await db.delete('groupe_eleves', where: 'id_eleve = ?', whereArgs: [idEleve]);
    if (idGroupe != null && idGroupe.trim().isNotEmpty) {
      final now = DateTime.now().toIso8601String();
      await db.insert('groupe_eleves', {
        'id_groupe': idGroupe.trim(),
        'id_eleve': idEleve,
        'date_inscription': now,
      });
    }
  }

  Future<List<String>> verifierDoublonsSeance({
    required List<String> eleveIds,
    required String dateSeance,
    String? idGroupe,
  }) async {
    final db = await database;
    final List<String> doublons = [];
    if (eleveIds.isNotEmpty) {
      final placeholders = List.filled(eleveIds.length, '?').join(',');
      final rows = await db.rawQuery('''
        SELECT nom_eleve, type_seance, heure
        FROM seances
        WHERE date_seance = ? 
          AND (id_eleve IN ($placeholders) OR nom_eleve IN (SELECT nom FROM eleves WHERE id_eleve IN ($placeholders)))
          AND statut_seance != 'Annulée'
      ''', [dateSeance, ...eleveIds, ...eleveIds]);
      for (final r in rows) {
        final nom = r['nom_eleve'] as String? ?? 'Un élève';
        final heure = r['heure'] as String?;
        doublons.add(heure != null && heure.isNotEmpty ? '$nom ($heure)' : nom);
      }
    } else if (idGroupe != null && idGroupe.trim().isNotEmpty) {
      final rows = await db.rawQuery('''
        SELECT nom_eleve, heure
        FROM seances
        WHERE date_seance = ? 
          AND id_groupe = ?
          AND statut_seance != 'Annulée'
      ''', [dateSeance, idGroupe.trim()]);
      if (rows.isNotEmpty) {
        doublons.add('Le groupe a déjà ${rows.length} séance(s) ce jour-là');
      }
    }
    return doublons;
  }

  Future<List<String>> verifierConflitHoraire({
    required String dateSeance,
    required String heure,
    List<String>? eleveIds,
    String? idGroupe,
  }) async {
    final db = await database;
    final List<String> conflits = [];
    if (heure.trim().isEmpty) return conflits;

    final rows = await db.rawQuery('''
      SELECT nom_eleve, type_seance, id_groupe
      FROM seances
      WHERE date_seance = ? 
        AND heure = ?
        AND statut_seance != 'Annulée'
    ''', [dateSeance, heure.trim()]);

    for (final r in rows) {
      final nom = r['nom_eleve'] as String? ?? 'Séance';
      final type = r['type_seance'] as String? ?? '';
      conflits.add('$nom ($type)');
    }
    return conflits;
  }

  Future<List<Seance>> getSeancesEnRetard3J() async {
    final db = await database;
    final now = DateTime.now();
    final seuil3j = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));
    final rows = await db.rawQuery('''
      SELECT s.*, g.nom as nom_groupe, e.niveau as niveau
      FROM seances s
      LEFT JOIN groupes g ON s.id_groupe = g.id_groupe
      LEFT JOIN eleves e ON (s.id_eleve = e.id_eleve OR (s.id_eleve IS NULL AND s.nom_eleve = e.nom))
      WHERE s.statut_paiement = 'Impayé' 
        AND s.statut_seance != 'Annulée'
        AND s.date_seance <= ?
      ORDER BY s.date_seance ASC, s.heure ASC
    ''', [seuil3j]);
    return rows.map((r) => _mapRowToSeance(r)).toList();
  }

  Future<Map<String, dynamic>> getStatistiquesRetards3J() async {
    final db = await database;
    final now = DateTime.now();
    final seuil3j = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 3)));
    final res = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(montant), 0) as total
      FROM seances
      WHERE statut_paiement = 'Impayé' 
        AND statut_seance != 'Annulée'
        AND date_seance <= ?
    ''', [seuil3j]);
    final count = (res.first['count'] as num?)?.toInt() ?? 0;
    final total = (res.first['total'] as num?)?.toInt() ?? 0;
    return {
      'count': count,
      'total': total,
      'montant': total,
    };
  }
}
