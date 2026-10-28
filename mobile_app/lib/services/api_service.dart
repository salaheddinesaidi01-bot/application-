import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_data.dart';
import '../models/eleve.dart';
import '../models/fiche_eleve.dart';
import '../models/prof_profile.dart';
import '../models/seance.dart';
import '../models/cloture_mensuelle.dart';
import '../models/app_notification.dart';
import '../models/groupe.dart';
import '../models/paiement_historique.dart';
import 'local_db_service.dart';

class ApiService {
  static const String _prefKeyBaseUrl = 'api_base_url';
  static const String _prefKeyAutonomousMode = 'mode_autonome_local';

  /// Mode autonome local (SQLite) activé par défaut sur mobile (Android/iOS).
  /// Permet d'utiliser l'application à 100% sans ordinateur, sans connexion et sans serveur.
  static Future<bool> isAutonomousMode() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyAutonomousMode) ?? true;
  }

  static Future<void> setAutonomousMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAutonomousMode, enabled);
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return 'http://$host:3001';
      }
      return 'http://localhost:3001';
    }
    if (Platform.isAndroid) return 'http://127.0.0.1:3001';
    return 'http://localhost:3001';
  }

  static dynamic _decodeJson(http.Response response, String contextName) {
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.startsWith('<')) {
      throw Exception('Erreur $contextName: le serveur a renvoyé du HTML. Vérifiez l\'adresse du serveur dans Paramètres.');
    }
    return jsonDecode(body);
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      if (!kIsWeb && Platform.isAndroid && saved.contains('localhost')) {
        return saved.replaceAll('localhost', '127.0.0.1');
      }
      return saved;
    }
    return _defaultBaseUrl();
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  // 1. Dashboard
  static Future<DashboardData> getDashboard() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getDashboard();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/dashboard'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'dashboard');
        return DashboardData.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Erreur dashboard (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getDashboard ($e)');
      return LocalDbService.instance.getDashboard();
    }
  }

  // 2. Liste des Élèves
  static Future<List<Eleve>> getEleves({String? search, String? statut}) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getEleves(search: search, statut: statut);
    }
    try {
      final baseUrl = await getBaseUrl();
      final queryParams = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (statut != null && statut.trim().isNotEmpty) {
        queryParams['statut'] = statut.trim();
      }

      final uri = Uri.parse('$baseUrl/api/eleves').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'élèves') as List<dynamic>;
        return list.map((item) => Eleve.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur élèves (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getEleves ($e)');
      return LocalDbService.instance.getEleves(search: search, statut: statut);
    }
  }

  // 3. Ajouter un Élève
  static Future<Eleve> ajouterEleve({
    required String nom,
    String? niveau,
    String? telephone,
    String? telephoneParent,
    String? email,
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.ajouterEleve(
        nom: nom,
        niveau: niveau,
        telephone: telephone,
        telephoneParent: telephoneParent,
        email: email,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/eleves'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': nom.trim(),
              'niveau': niveau?.trim(),
              'telephone': telephone?.trim(),
              'telephone_parent': telephoneParent?.trim(),
              'email': email?.trim(),
              'statut': 'Actif',
            }),
          )
          .timeout(const Duration(seconds: 5));

      final json = _decodeJson(response, 'ajouter élève');
      if (response.statusCode == 201) {
        return Eleve.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception(json['error'] ?? 'Erreur lors de l\'ajout de l\'élève');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour ajouterEleve ($e)');
      return LocalDbService.instance.ajouterEleve(
        nom: nom,
        niveau: niveau,
        telephone: telephone,
        telephoneParent: telephoneParent,
        email: email,
      );
    }
  }

  // 4. Basculer le statut d'un élève
  static Future<Eleve> toggleStatutEleve(String idEleve, {String? nouveauStatut}) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.toggleStatutEleve(idEleve, nouveauStatut: nouveauStatut);
    }
    try {
      final baseUrl = await getBaseUrl();
      final body = nouveauStatut != null ? {'statut': nouveauStatut} : {};
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/eleves/$idEleve/statut'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'statut élève');
        return Eleve.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Erreur statut élève (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour toggleStatutEleve ($e)');
      return LocalDbService.instance.toggleStatutEleve(idEleve, nouveauStatut: nouveauStatut);
    }
  }

  // 5. Supprimer un élève
  static Future<void> supprimerEleve(String idEleve) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.supprimerEleve(idEleve);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .delete(Uri.parse('$baseUrl/api/eleves/$idEleve'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        final json = _decodeJson(response, 'suppression');
        throw Exception(json['error'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour supprimerEleve ($e)');
      return LocalDbService.instance.supprimerEleve(idEleve);
    }
  }

  // 6. Fiche Élève (3 KPIs + historique complet)
  static Future<FicheEleveData> getFicheEleve(String idEleve) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getFicheEleve(idEleve);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/eleves/$idEleve/fiche'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'fiche élève');
        return FicheEleveData.fromJson(json as Map<String, dynamic>);
      } else {
        throw Exception('Erreur fiche élève (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getFicheEleve ($e)');
      return LocalDbService.instance.getFicheEleve(idEleve);
    }
  }

  // 7. Saisir Séance Réalisée (Multiple)
  static Future<Map<String, dynamic>> saisirSeancesMultiple({
    required List<Eleve> eleves,
    required String dateSeance,
    required String typeSeance,
    required int montant,
    required String statutPaiement, // 'Payé' ou 'Impayé'
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.saisirSeancesMultiple(
        eleves: eleves,
        dateSeance: dateSeance,
        typeSeance: typeSeance,
        montant: montant,
        statutPaiement: statutPaiement,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/seances/saisir-multiple'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'eleves': eleves.map((e) => {'id_eleve': e.idEleve, 'nom': e.nom}).toList(),
              'date_seance': dateSeance,
              'type_seance': typeSeance,
              'montant': montant,
              'statut_paiement': statutPaiement,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final json = _decodeJson(response, 'saisie séances');
      if (response.statusCode == 201) {
        return json as Map<String, dynamic>;
      } else {
        throw Exception(json['error'] ?? 'Erreur lors de la saisie des séances');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour saisirSeancesMultiple ($e)');
      return LocalDbService.instance.saisirSeancesMultiple(
        eleves: eleves,
        dateSeance: dateSeance,
        typeSeance: typeSeance,
        montant: montant,
        statutPaiement: statutPaiement,
      );
    }
  }

  // 8. Planifier Séance Future (Multiple)
  static Future<Map<String, dynamic>> planifierSeancesMultiple({
    required List<Eleve> eleves,
    required String dateSeance,
    String? heure,
    required String typeSeance,
    required int montant,
    String? notes,
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.planifierSeancesMultiple(
        eleves: eleves,
        dateSeance: dateSeance,
        heure: heure,
        typeSeance: typeSeance,
        montant: montant,
        notes: notes,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/seances/planifier-multiple'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'eleves': eleves.map((e) => {'id_eleve': e.idEleve, 'nom': e.nom}).toList(),
              'date_seance': dateSeance,
              'heure': heure,
              'type_seance': typeSeance,
              'montant': montant,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final json = _decodeJson(response, 'planification séances');
      if (response.statusCode == 201) {
        return json as Map<String, dynamic>;
      } else {
        throw Exception(json['error'] ?? 'Erreur lors de la planification');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour planifierSeancesMultiple ($e)');
      return LocalDbService.instance.planifierSeancesMultiple(
        eleves: eleves,
        dateSeance: dateSeance,
        heure: heure,
        typeSeance: typeSeance,
        montant: montant,
        notes: notes,
      );
    }
  }

  // 9. Régler en masse (ou individuellement)
  static Future<int> payerSeancesMasse(List<String> ids) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.payerSeancesMasse(ids);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/seances/payer-masse'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ids': ids}),
          )
          .timeout(const Duration(seconds: 5));

      final json = _decodeJson(response, 'règlement séances');
      if (response.statusCode == 200) {
        return (json['count'] as num?)?.toInt() ?? 0;
      } else {
        throw Exception(json['error'] ?? 'Erreur lors du règlement');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour payerSeancesMasse ($e)');
      return LocalDbService.instance.payerSeancesMasse(ids);
    }
  }

  // 9b. Marquer une séance payée individuellement
  static Future<int> marquerPayee(String idSeance) async {
    return payerSeancesMasse([idSeance]);
  }

  // 9c. Valider le pointage complet d'une séance groupée (présents payés, présents impayés, absents)
  static Future<Map<String, dynamic>> validerPointageGroupeComplet({
    required List<String> seancesPayeesIds,
    required List<String> seancesImpayeesIds,
    required List<String> seancesAbsentesIds,
    String modePaiement = 'Espèces',
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.validerPointageGroupeComplet(
        seancesPayeesIds: seancesPayeesIds,
        seancesImpayeesIds: seancesImpayeesIds,
        seancesAbsentesIds: seancesAbsentesIds,
        modePaiement: modePaiement,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/seances/valider-pointage-groupe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'seancesPayeesIds': seancesPayeesIds,
              'seancesImpayeesIds': seancesImpayeesIds,
              'seancesAbsentesIds': seancesAbsentesIds,
              'mode_paiement': modePaiement,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return _decodeJson(response, 'pointage groupe complet') as Map<String, dynamic>;
      } else {
        throw Exception('Erreur pointage (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour validerPointageGroupeComplet ($e)');
      return LocalDbService.instance.validerPointageGroupeComplet(
        seancesPayeesIds: seancesPayeesIds,
        seancesImpayeesIds: seancesImpayeesIds,
        seancesAbsentesIds: seancesAbsentesIds,
        modePaiement: modePaiement,
      );
    }
  }

  // 10. Annuler une séance
  static Future<void> annulerSeance(String idSeance) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.annulerSeance(idSeance);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .patch(Uri.parse('$baseUrl/api/seances/$idSeance/annuler'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        final json = _decodeJson(response, 'annulation séance');
        throw Exception(json['error'] ?? 'Erreur lors de l\'annulation de la séance');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour annulerSeance ($e)');
      return LocalDbService.instance.annulerSeance(idSeance);
    }
  }

  // 11. Historique Finance (mois en cours, payé non clôturé)
  static Future<List<Seance>> getFinanceHistorique() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getFinanceHistorique();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/finance/historique'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'historique finance') as List<dynamic>;
        return list.map((item) => Seance.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur finance (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getFinanceHistorique ($e)');
      return LocalDbService.instance.getFinanceHistorique();
    }
  }

  // 11b. Séances impayées pour l'onglet Finance
  static Future<List<Seance>> getFinanceImpayees() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getFinanceImpayees();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/finance/impayees'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'séances impayées') as List<dynamic>;
        return list.map((item) => Seance.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur séances impayées (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getFinanceImpayees ($e)');
      return LocalDbService.instance.getFinanceImpayees();
    }
  }

  // 12. Clôturer le mois & Archivage in-app
  static Future<Map<String, dynamic>> cloturerMois() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.cloturerMois();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(Uri.parse('$baseUrl/api/cloturer-mois'))
          .timeout(const Duration(seconds: 10));

      final json = _decodeJson(response, 'clôture mois');
      if (response.statusCode == 200) {
        return json as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': json['message'] ?? json['error'] ?? 'Erreur lors de la clôture mensuelle',
        };
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour cloturerMois ($e)');
      return LocalDbService.instance.cloturerMois();
    }
  }

  // 12b. Récupérer les archives des clôtures passées
  static Future<List<ClotureMensuelle>> getClotures() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getClotures();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/clotures'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'archives clôtures') as List<dynamic>;
        return list.map((item) => ClotureMensuelle.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Erreur archives clôtures (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getClotures ($e)');
      return LocalDbService.instance.getClotures();
    }
  }

  // 12c. Centre de Notifications In-App
  static Future<NotificationsSummary> getNotifications() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getNotifications();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/notifications'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'notifications') as Map<String, dynamic>;
        return NotificationsSummary.fromJson(json);
      } else {
        throw Exception('Erreur notifications (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour getNotifications ($e)');
      return LocalDbService.instance.getNotifications();
    }
  }

  static Future<void> dismissNotification(String id) async {
    await LocalDbService.instance.dismissNotification(id);
  }

  static Future<void> dismissAllNotifications(List<String> ids) async {
    await LocalDbService.instance.dismissAllNotifications(ids);
  }

  // 13. Profil Professeur & Tarifs Personnalisés
  static const String _prefProfTitre = 'prof_titre';
  static const String _prefProfNom = 'prof_nom';
  static const String _prefProfSpecialite = 'prof_specialite';
  static const String _prefProfTelephone = 'prof_telephone';
  static const String _prefProfEmail = 'prof_email';
  static const String _prefProfMatieres = 'prof_matieres';
  static const String _prefPrixNormale1 = 'prof_prix_normale_1';
  static const String _prefPrixNormale2 = 'prof_prix_normale_2';
  static const String _prefPrixPrivee1 = 'prof_prix_privee_1';
  static const String _prefPrixPrivee2 = 'prof_prix_privee_2';
  static const String _prefProfDevise = 'prof_devise';
  static const String _prefProfPinCode = 'prof_pin_code';
  static const String _prefProfAvatar = 'prof_avatar';
  static const String _prefProfConfigured = 'prof_configured';

  static Future<ProfProfile> getProfProfile() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getProfProfile();
    }
    final prefs = await SharedPreferences.getInstance();

    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/profil'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final profile = ProfProfile.fromJson(json);

        // Mettre à jour le cache local
        await prefs.setString(_prefProfTitre, profile.titre);
        await prefs.setString(_prefProfNom, profile.nom);
        await prefs.setString(_prefProfSpecialite, profile.specialite);
        await prefs.setString(_prefProfTelephone, profile.telephone);
        await prefs.setString(_prefProfEmail, profile.email);
        await prefs.setStringList(_prefProfMatieres, profile.matieres);
        await prefs.setInt(_prefPrixNormale1, profile.prixNormale1);
        await prefs.setInt(_prefPrixNormale2, profile.prixNormale2);
        await prefs.setInt(_prefPrixPrivee1, profile.prixPrivee1);
        await prefs.setInt(_prefPrixPrivee2, profile.prixPrivee2);
        await prefs.setString(_prefProfDevise, profile.devise);
        await prefs.setString(_prefProfPinCode, profile.pinCode);
        await prefs.setString(_prefProfAvatar, profile.avatar);
        await prefs.setBool(_prefProfConfigured, profile.isConfigured);

        return profile;
      }
    } catch (_) {
      // Ignorer l'erreur réseau et continuer avec le cache local
    }

    if (!kIsWeb) {
      try {
        return await LocalDbService.instance.getProfProfile();
      } catch (_) {}
    }

    // Fallback cache local SharedPreferences
    final titre = prefs.getString(_prefProfTitre) ?? 'Prof.';
    final nom = prefs.getString(_prefProfNom) ?? '';
    final specialite = prefs.getString(_prefProfSpecialite) ?? '';
    final telephone = prefs.getString(_prefProfTelephone) ?? '';
    final email = prefs.getString(_prefProfEmail) ?? '';
    final matieres = prefs.getStringList(_prefProfMatieres) ??
        ['Mathématiques', 'Physique-Chimie'];
    final n1 = prefs.getInt(_prefPrixNormale1) ?? 1000;
    final n2 = prefs.getInt(_prefPrixNormale2) ?? 1500;
    final p1 = prefs.getInt(_prefPrixPrivee1) ?? 2000;
    final p2 = prefs.getInt(_prefPrixPrivee2) ?? 2500;
    final devise = prefs.getString(_prefProfDevise) ?? 'DZD';
    final pinCode = prefs.getString(_prefProfPinCode) ?? '';
    final avatar = prefs.getString(_prefProfAvatar) ?? 'school';
    final isConf = (prefs.getBool(_prefProfConfigured) ?? false) && nom.trim().isNotEmpty;

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
      devise: devise,
      pinCode: pinCode,
      avatar: avatar,
      isConfigured: isConf,
    );
  }

  static Future<void> saveProfProfile(ProfProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Sauvegarder dans le cache local SharedPreferences
    await prefs.setString(_prefProfTitre, profile.titre);
    await prefs.setString(_prefProfNom, profile.nom.trim());
    await prefs.setString(_prefProfSpecialite, profile.specialite.trim());
    await prefs.setString(_prefProfTelephone, profile.telephone.trim());
    await prefs.setString(_prefProfEmail, profile.email.trim());
    await prefs.setStringList(_prefProfMatieres, profile.matieres);
    await prefs.setInt(_prefPrixNormale1, profile.prixNormale1);
    await prefs.setInt(_prefPrixNormale2, profile.prixNormale2);
    await prefs.setInt(_prefPrixPrivee1, profile.prixPrivee1);
    await prefs.setInt(_prefPrixPrivee2, profile.prixPrivee2);
    await prefs.setString(_prefProfDevise, profile.devise);
    await prefs.setString(_prefProfPinCode, profile.pinCode);
    await prefs.setString(_prefProfAvatar, profile.avatar);
    await prefs.setBool(_prefProfConfigured, profile.nom.trim().isNotEmpty);

    // 2. Sauvegarder dans SQLite local sur mobile
    if (!kIsWeb) {
      try {
        await LocalDbService.instance.saveProfProfile(profile);
      } catch (e) {
        debugPrint('Erreur sauvegarde profil SQLite local: $e');
      }
    }

    // 3. Synchroniser vers le backend PostgreSQL si accessible
    try {
      final baseUrl = await getBaseUrl();
      await http
          .post(
            Uri.parse('$baseUrl/api/profil'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Synchronisation profil vers backend ignorée: $e');
    }
  }

  static Future<void> resetProfProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefProfTitre);
    await prefs.remove(_prefProfNom);
    await prefs.remove(_prefProfSpecialite);
    await prefs.remove(_prefProfTelephone);
    await prefs.remove(_prefProfEmail);
    await prefs.remove(_prefProfMatieres);
    await prefs.remove(_prefProfDevise);
    await prefs.remove(_prefProfPinCode);
    await prefs.remove(_prefProfAvatar);
    await prefs.setBool(_prefProfConfigured, false);

    if (!kIsWeb) {
      try {
        await LocalDbService.instance.saveProfProfile(ProfProfile.empty());
      } catch (e) {
        debugPrint('Erreur réinitialisation profil SQLite: $e');
      }
    }

    try {
      final baseUrl = await getBaseUrl();
      await http
          .post(
            Uri.parse('$baseUrl/api/profil'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(ProfProfile.empty().toJson()),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // 10. Groupes
  static Future<List<Groupe>> getGroupes() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getGroupes();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/groupes'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'getGroupes') as List;
        return list.map((j) => Groupe.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw Exception('Erreur lors du chargement des groupes: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService: fallback local pour getGroupes ($e)');
      return LocalDbService.instance.getGroupes();
    }
  }

  static Future<Groupe> getGroupeById(String id) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getGroupeById(id);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/groupes/$id'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'getGroupeById') as Map<String, dynamic>;
        return Groupe.fromJson(json);
      }
      throw Exception('Erreur lors du chargement du groupe: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService: fallback local pour getGroupeById ($e)');
      return LocalDbService.instance.getGroupeById(id);
    }
  }

  static Future<Groupe> createGroupe({
    required String nom,
    String? niveau,
    int tarifParEleve = 1000,
    String? description,
    List<String> elevesIds = const [],
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.createGroupe(
        nom: nom,
        niveau: niveau,
        tarifParEleve: tarifParEleve,
        description: description,
        elevesIds: elevesIds,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/groupes'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': nom,
              'niveau': niveau,
              'tarif_par_eleve': tarifParEleve,
              'description': description,
              'eleves_ids': elevesIds,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        final data = _decodeJson(response, 'createGroupe');
        return Groupe.fromJson(data['groupe'] as Map<String, dynamic>);
      }
      final err = _decodeJson(response, 'createGroupe');
      throw Exception(err['error'] ?? 'Erreur lors de la création du groupe');
    } catch (e) {
      debugPrint('ApiService: fallback local pour createGroupe ($e)');
      return LocalDbService.instance.createGroupe(
        nom: nom,
        niveau: niveau,
        tarifParEleve: tarifParEleve,
        description: description,
        elevesIds: elevesIds,
      );
    }
  }

  static Future<Groupe> updateGroupe({
    required String id,
    required String nom,
    String? niveau,
    int tarifParEleve = 1000,
    String? description,
    List<String> elevesIds = const [],
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.updateGroupe(
        id: id,
        nom: nom,
        niveau: niveau,
        tarifParEleve: tarifParEleve,
        description: description,
        elevesIds: elevesIds,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/groupes/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nom': nom,
              'niveau': niveau,
              'tarif_par_eleve': tarifParEleve,
              'description': description,
              'eleves_ids': elevesIds,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = _decodeJson(response, 'updateGroupe');
        return Groupe.fromJson(data['groupe'] as Map<String, dynamic>);
      }
      final err = _decodeJson(response, 'updateGroupe');
      throw Exception(err['error'] ?? 'Erreur lors de la mise à jour du groupe');
    } catch (e) {
      debugPrint('ApiService: fallback local pour updateGroupe ($e)');
      return LocalDbService.instance.updateGroupe(
        id: id,
        nom: nom,
        niveau: niveau,
        tarifParEleve: tarifParEleve,
        description: description,
        elevesIds: elevesIds,
      );
    }
  }

  static Future<Groupe> creerGroupe({
    required String nom,
    String? niveau,
    int? tarifParEleve,
    double? tarifParDefaut,
    String? description,
    List<String>? elevesIds,
    List<String>? eleveIds,
  }) {
    final tarif = tarifParDefaut?.toInt() ?? tarifParEleve ?? 1000;
    final ids = eleveIds ?? elevesIds ?? const [];
    return createGroupe(
      nom: nom,
      niveau: niveau,
      tarifParEleve: tarif,
      description: description,
      elevesIds: ids,
    );
  }

  static Future<Groupe> modifierGroupe({
    required String id,
    required String nom,
    String? niveau,
    int? tarifParEleve,
    double? tarifParDefaut,
    String? description,
    List<String>? elevesIds,
    List<String>? eleveIds,
  }) {
    final tarif = tarifParDefaut?.toInt() ?? tarifParEleve ?? 1000;
    final ids = eleveIds ?? elevesIds ?? const [];
    return updateGroupe(
      id: id,
      nom: nom,
      niveau: niveau,
      tarifParEleve: tarif,
      description: description,
      elevesIds: ids,
    );
  }

  static Future<bool> deleteGroupe(String id) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.deleteGroupe(id);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .delete(Uri.parse('$baseUrl/api/groupes/$id'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) return true;
      final err = _decodeJson(response, 'deleteGroupe');
      throw Exception(err['error'] ?? 'Erreur lors de la suppression du groupe');
    } catch (e) {
      debugPrint('ApiService: fallback local pour deleteGroupe ($e)');
      return LocalDbService.instance.deleteGroupe(id);
    }
  }

  static Future<bool> supprimerGroupe(String id) => deleteGroupe(id);

  static Future<Map<String, dynamic>> creerSeanceGroupe({
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
    if (await isAutonomousMode()) {
      return LocalDbService.instance.creerSeanceGroupe(
        idGroupe: idGroupe,
        dateSeance: dateSeance,
        heure: heure,
        typeSeance: typeSeance,
        montantParEleve: montantParEleve,
        notes: notes,
        elevesSelectionnes: elevesSelectionnes,
        statutSeance: statutSeance,
        matiere: matiere,
        presences: presences,
        dureeMinutes: dureeMinutes,
      );
    }
    try {
      final baseUrl = await getBaseUrl();

      String dateStr;
      String? heureStr = heure;
      if (dateSeance is DateTime) {
        dateStr =
            "${dateSeance.year.toString().padLeft(4, '0')}-${dateSeance.month.toString().padLeft(2, '0')}-${dateSeance.day.toString().padLeft(2, '0')}";
        heureStr ??=
            "${dateSeance.hour.toString().padLeft(2, '0')}:${dateSeance.minute.toString().padLeft(2, '0')}";
      } else {
        dateStr = dateSeance.toString();
      }

      final selection = elevesSelectionnes ??
          presences?.map((p) {
            if (p is Map) {
              return {
                'id_eleve': p['id_eleve'],
                'nom': p['nom'],
                'montant': p['montant'] ?? p['tarif'] ?? montantParEleve,
                'tarif': p['tarif'] ?? p['montant'] ?? montantParEleve,
                'paye': p['paye'] == true,
              };
            }
            return {'id_eleve': p.toString()};
          }).toList();

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/groupes/$idGroupe/seance'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'date_seance': dateStr,
              'heure': heureStr,
              'type_seance': matiere ?? typeSeance,
              'montant_par_eleve': montantParEleve,
              'notes': notes,
              'eleves_selectionnes': selection,
              'statut_seance': statutSeance,
              'duree_minutes': dureeMinutes,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return _decodeJson(response, 'creerSeanceGroupe') as Map<String, dynamic>;
      }
      final err = _decodeJson(response, 'creerSeanceGroupe');
      throw Exception(err['error'] ?? 'Erreur lors de la création de la séance de groupe');
    } catch (e) {
      debugPrint('ApiService: fallback local pour creerSeanceGroupe ($e)');
      return LocalDbService.instance.creerSeanceGroupe(
        idGroupe: idGroupe,
        dateSeance: dateSeance,
        heure: heure,
        typeSeance: typeSeance,
        montantParEleve: montantParEleve,
        notes: notes,
        elevesSelectionnes: elevesSelectionnes,
        statutSeance: statutSeance,
        matiere: matiere,
        presences: presences,
        dureeMinutes: dureeMinutes,
      );
    }
  }

  static Future<Map<String, dynamic>> encaisserGroupe({
    required String idGroupe,
    String? dateSeance,
    String? idSeanceGroupe,
    List<String>? seancesIds,
    String modePaiement = 'Espèces',
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.encaisserGroupe(
        idGroupe: idGroupe,
        dateSeance: dateSeance,
        idSeanceGroupe: idSeanceGroupe,
        seancesIds: seancesIds,
        modePaiement: modePaiement,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/groupes/$idGroupe/encaisser'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'date_seance': dateSeance,
              'id_seance_groupe': idSeanceGroupe,
              'seances_ids': seancesIds,
              'mode_paiement': modePaiement,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return _decodeJson(response, 'encaisserGroupe') as Map<String, dynamic>;
      }
      final err = _decodeJson(response, 'encaisserGroupe');
      throw Exception(err['error'] ?? 'Erreur lors de l\'encaissement groupé');
    } catch (e) {
      debugPrint('ApiService: fallback local pour encaisserGroupe ($e)');
      return LocalDbService.instance.encaisserGroupe(
        idGroupe: idGroupe,
        dateSeance: dateSeance,
        idSeanceGroupe: idSeanceGroupe,
        seancesIds: seancesIds,
        modePaiement: modePaiement,
      );
    }
  }


  // 11. Historique Global des Paiements
  static Future<HistoriquePaiementsResponse> getHistoriquePaiements({
    String? mois,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getHistoriquePaiements(
        mois: mois,
        search: search,
        limit: limit,
        offset: offset,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (mois != null && mois.isNotEmpty) queryParams['mois'] = mois;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$baseUrl/api/paiements/historique').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = _decodeJson(response, 'getHistoriquePaiements') as Map<String, dynamic>;
        return HistoriquePaiementsResponse.fromJson(json);
      }
      throw Exception('Erreur lors du chargement de l\'historique des paiements: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService: fallback local pour getHistoriquePaiements ($e)');
      return LocalDbService.instance.getHistoriquePaiements(
        mois: mois,
        search: search,
        limit: limit,
        offset: offset,
      );
    }
  }

  // 12. Clôtures Mensuelles
  static Future<List<ClotureMensuelle>> getCloturesMensuelles() async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.getCloturesMensuelles();
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/clotures'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = _decodeJson(response, 'clotures') as List<dynamic>;
        return list
            .map((item) => ClotureMensuelle.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Erreur lors du chargement des clôtures: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService: fallback local pour getCloturesMensuelles ($e)');
      return LocalDbService.instance.getCloturesMensuelles();
    }
  }

  // 13. Affectation Groupe & Sécurités Planning
  static Future<void> affecterEleveGroupe({
    required String idEleve,
    required String? idGroupe,
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.affecterEleveGroupe(idEleve: idEleve, idGroupe: idGroupe);
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/eleves/$idEleve/affecter-groupe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_groupe': idGroupe}),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return;
      throw Exception('Erreur affectation groupe: ${response.statusCode}');
    } catch (e) {
      debugPrint('ApiService: fallback local pour affecterEleveGroupe ($e)');
      return LocalDbService.instance.affecterEleveGroupe(idEleve: idEleve, idGroupe: idGroupe);
    }
  }

  static Future<List<String>> verifierDoublonsSeance({
    required List<String> eleveIds,
    required String dateSeance,
    String? idGroupe,
  }) async {
    if (await isAutonomousMode()) {
      return LocalDbService.instance.verifierDoublonsSeance(
        eleveIds: eleveIds,
        dateSeance: dateSeance,
        idGroupe: idGroupe,
      );
    }
    try {
      final baseUrl = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/seances/verifier-doublon'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'eleveIds': eleveIds,
              'dateSeance': dateSeance,
              'idGroupe': idGroupe,
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = _decodeJson(response, 'verifier doublons');
        return List<String>.from(data['doublons'] ?? []);
      }
    } catch (e) {
      debugPrint('ApiService: fallback local pour verifierDoublonsSeance ($e)');
    }
    return LocalDbService.instance.verifierDoublonsSeance(
      eleveIds: eleveIds,
      dateSeance: dateSeance,
      idGroupe: idGroupe,
    );
  }

  static Future<List<String>> verifierConflitHoraire({
    required String dateSeance,
    required String heure,
    List<String>? eleveIds,
    String? idGroupe,
  }) async {
    return LocalDbService.instance.verifierConflitHoraire(
      dateSeance: dateSeance,
      heure: heure,
      eleveIds: eleveIds,
      idGroupe: idGroupe,
    );
  }

  static Future<List<Seance>> getSeancesEnRetard3J() async {
    return LocalDbService.instance.getSeancesEnRetard3J();
  }

  static Future<Map<String, dynamic>> getStatistiquesRetards3J() async {
    return LocalDbService.instance.getStatistiquesRetards3J();
  }
}
