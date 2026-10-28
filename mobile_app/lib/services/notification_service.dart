import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelRetard3j = 'retard_3j_channel';
  static const String _channelSeance30min = 'seance_30min_channel';
  static const String _channelImpayes = 'impayes_channel';

  static const String _prefKeyNotifiedIds = 'notified_system_alerts_cache';

  bool _isInitialized = false;

  /// Initialisation du service et configuration des canaux Android
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialiser le fuseau horaire
      tz.initializeTimeZones();

      // 2. Initialiser les paramètres Android & iOS
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification cliquée: ${response.payload}');
        },
      );

      // 3. Créer les canaux de notification Android à haute priorité
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // Canal pour les retards critiques (+3 jours)
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelRetard3j,
              'Alertes Retards Critiques (+3j)',
              description:
                  'Notifications pour les séances impayées depuis plus de 3 jours',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          // Canal pour les rappels de séances
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelSeance30min,
              'Rappels de Séances',
              description: 'Notifications au début d\'une séance planifiée',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          // Canal pour les séances impayées standard
          await androidImplementation.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelImpayes,
              'Séances Non Payées',
              description: 'Alertes pour les séances en attente de paiement',
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );

          // 4. Demander la permission Android 13+ (POST_NOTIFICATIONS)
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        }
      }

      // 4. Demander la permission iOS
      if (!kIsWeb && Platform.isIOS) {
        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _isInitialized = true;
      debugPrint('NotificationService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de NotificationService: $e');
    }
  }

  /// Vérifie les alertes et envoie les notifications natives dans la barre d'état du téléphone
  Future<void> verifierEtNotifierSysteme(List<AppNotification> notifications) async {
    if (kIsWeb || notifications.isEmpty) return;
    if (!_isInitialized) await init();

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cachedNotified =
          prefs.getStringList(_prefKeyNotifiedIds) ?? [];
      final Set<String> newlyNotified = Set<String>.from(cachedNotified);

      // Garder le cache propre (max 100 dernières notifications pour éviter l'encombrement)
      if (newlyNotified.length > 100) {
        newlyNotified.clear();
      }

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      for (final notif in notifications) {
        // Clé unique pour éviter de spammer plusieurs fois le même jour pour le même fait
        final uniqueKey = '${notif.type}_${notif.referenceId ?? notif.id}_$todayStr';

        if (newlyNotified.contains(uniqueKey)) {
          continue; // Déjà notifié aujourd'hui
        }

        final int numericId =
            (int.tryParse(notif.referenceId ?? '') ?? notif.id.hashCode).abs();

        if (notif.type == 'retard_3j') {
          final int jours = notif.retardJours ?? 3;
          final int montant = notif.montant ?? 0;
          final String eleve = notif.nomEleve ?? 'Un élève';

          await _afficherNotification(
            id: numericId % 100000 + 1000,
            title: '🔴 Retard de paiement (+$jours j)',
            body: '$eleve a une séance impayée depuis $jours jours ($montant DZD).',
            channelId: _channelRetard3j,
            channelName: 'Alertes Retards Critiques (+3j)',
            payload: 'impaye_${notif.referenceId}',
          );
          newlyNotified.add(uniqueKey);
        } else if (notif.type == 'seance_30min') {
          final String eleve = notif.nomEleve ?? 'l\'élève';
          final String heure = notif.heure ?? '';
          final String matiere = notif.notes ?? 'Soutien Scolaire';

          await _afficherNotification(
            id: numericId % 100000 + 2000,
            title: '⏰ Séance dans 30 min !',
            body: 'Séance avec $eleve à $heure ($matiere).',
            channelId: _channelSeance30min,
            channelName: 'Rappels Séances (30 min avant)',
            payload: 'seance_${notif.referenceId}',
          );
          newlyNotified.add(uniqueKey);
        }
      }

      await prefs.setStringList(_prefKeyNotifiedIds, newlyNotified.toList());
    } catch (e) {
      debugPrint('Erreur verifierEtNotifierSysteme: $e');
    }
  }

  /// Planifie des notifications système avant l'heure de la séance (30 min et 15 min avant).
  /// Ces alarmes fonctionnent même si l'application est en veille ou fermée !
  Future<void> planifierRappelSeance({
    required dynamic idSeance,
    required String nomEleve,
    required String matiere,
    required DateTime dateHeureSeance,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      final now = DateTime.now();
      final baseId =
          (int.tryParse(idSeance.toString()) ?? idSeance.toString().hashCode).abs() % 100000;

      final androidDetails = AndroidNotificationDetails(
        _channelSeance30min,
        'Rappels de Séances',
        channelDescription: 'Notifications envoyées avant et au début d\'une séance',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final heureStr = _formatHeure(dateHeureSeance);

      // 1. Rappel à -30 minutes
      final rappel30min = dateHeureSeance.subtract(const Duration(minutes: 30));
      if (rappel30min.isAfter(now)) {
        final scheduledDate30 = tz.TZDateTime.from(rappel30min, tz.local);
        final notifId30 = baseId * 10 + 1;
        await _notificationsPlugin.zonedSchedule(
          id: notifId30,
          title: '⏰ Rappel : Séance dans 30 minutes',
          body: 'Cours de $matiere avec $nomEleve à $heureStr.',
          scheduledDate: scheduledDate30,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'seance_${idSeance}_30m',
        );
      }

      // 2. Rappel à -15 minutes
      final rappel15min = dateHeureSeance.subtract(const Duration(minutes: 15));
      if (rappel15min.isAfter(now)) {
        final scheduledDate15 = tz.TZDateTime.from(rappel15min, tz.local);
        final notifId15 = baseId * 10 + 2;
        await _notificationsPlugin.zonedSchedule(
          id: notifId15,
          title: '⏳ Rappel imminent : Séance dans 15 minutes',
          body: 'Cours de $matiere avec $nomEleve à $heureStr.',
          scheduledDate: scheduledDate15,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'seance_${idSeance}_15m',
        );
      }

      debugPrint(
          'Rappels système planifiés pour séance #$idSeance (-30m & -15m) à $heureStr');
    } catch (e) {
      debugPrint('Erreur planifierRappelSeance: $e');
    }
  }

  /// Annule les rappels système d'une séance
  Future<void> annulerRappelSeance(dynamic idSeance) async {
    if (kIsWeb) return;
    try {
      final baseId =
          (int.tryParse(idSeance.toString()) ?? idSeance.toString().hashCode).abs() % 100000;
      await _notificationsPlugin.cancel(id: baseId * 10 + 1);
      await _notificationsPlugin.cancel(id: baseId * 10 + 2);
      debugPrint('Rappels système annulés pour séance #$idSeance');
    } catch (e) {
      debugPrint('Erreur annulerRappelSeance: $e');
    }
  }

  /// Affiche immédiatement une notification système
  Future<void> _afficherNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Envoi d'une notification de test immédiate pour démonstration
  Future<void> testerNotificationSysteme() async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    await _afficherNotification(
      id: 9999,
      title: '🔔 Notification Système Active',
      body:
          'Les notifications sur le téléphone sont configurées (retard +3j, impayés, rappel 30 min).',
      channelId: _channelRetard3j,
      channelName: 'Alertes Soutien Scolaire',
    );
  }

  /// Vérifie s'il existe des séances impayées depuis plus de 3 jours et déclenche une notification locale dédiée
  Future<void> verifierEtNotifierRetards3J() async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    try {
      final stats = await ApiService.getStatistiquesRetards3J();
      final int count = stats['count'] ?? 0;
      final int montant = stats['montant'] ?? (stats['total'] ?? 0);

      if (count > 0) {
        final prefs = await SharedPreferences.getInstance();
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final uniqueKey = 'retards_globaux_3j_$todayStr';
        final cached = prefs.getStringList(_prefKeyNotifiedIds) ?? [];

        if (!cached.contains(uniqueKey)) {
          await _afficherNotification(
            id: 8888,
            title: '🔴 Paiements en retard (> 3 jours)',
            body: '$count séance${count > 1 ? 's' : ''} en attente de règlement ($montant DZD).',
            channelId: _channelRetard3j,
            channelName: 'Alertes Retards Critiques (+3j)',
            payload: 'retards_3j_global',
          );
          final updated = List<String>.from(cached)..add(uniqueKey);
          await prefs.setStringList(_prefKeyNotifiedIds, updated);
        }
      }
    } catch (e) {
      debugPrint('Erreur verifierEtNotifierRetards3J: $e');
    }
  }

  static String _formatHeure(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
