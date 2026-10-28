import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_notification.dart';
import 'models/cloture_mensuelle.dart';
import 'models/dashboard_data.dart';
import 'models/eleve.dart';
import 'models/prof_profile.dart';
import 'models/seance.dart';
import 'screens/landing_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'widgets/ca_chart.dart';
import 'widgets/fiche_eleve_dialog.dart';
import 'widgets/kpi_card.dart';
import 'widgets/notes_tab.dart';
import 'widgets/nouvel_eleve_dialog.dart';
import 'widgets/planifier_seance_dialog.dart';
import 'models/groupe.dart';
import 'widgets/seance_groupe_dialog.dart';
import 'widgets/saisir_seance_dialog.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/app_drawer.dart';
import 'screens/groupes_screen.dart';
import 'screens/historique_paiements_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('fr_FR', null);
    Intl.defaultLocale = 'fr_FR';
  } catch (e) {
    debugPrint('Erreur initialisation locale fr_FR: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('is_dark_mode') ?? true;

  // Initialisation du service de notifications natives système
  await NotificationService().init();

  runApp(AppRoot(initialDarkMode: isDark));
}

class MyApp extends StatelessWidget {
  final bool initialDarkMode;
  const MyApp({super.key, this.initialDarkMode = true});

  @override
  Widget build(BuildContext context) {
    return AppRoot(initialDarkMode: initialDarkMode);
  }
}

class AppRoot extends StatefulWidget {
  final bool initialDarkMode;
  const AppRoot({super.key, required this.initialDarkMode});

  static AppRootState of(BuildContext context) =>
      context.findAncestorStateOfType<AppRootState>()!;

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDarkMode;
  }

  void toggleTheme() async {
    setState(() {
      _isDark = !_isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDark);
  }

  bool get isDarkMode => _isDark;

  @override
  Widget build(BuildContext context) {
    const tcNavy = Color(0xFF061449);
    const tcIndigo = Color(0xFF1E2A5E);
    const tcTeal = Color(0xFF006A61);
    const tcMint = Color(0xFF86F2E4);
    const tcAmber = Color(0xFFFFB95F);
    const tcLightBg = Color(0xFFF8F9FF);
    const tcLightSurface = Colors.white;
    const tcLightBorder = Color(0xFFE5EEFF);
    const tcDarkBg = Color(0xFF070B16);
    const tcDarkSurface = Color(0xFF0F172E);
    const tcDarkBorder = Color(0x28FFFFFF);
    const tcNeonMint = Color(0xFF2DD4BF);
    const tcDarkText = Color(0xFF070B16);
    const tcMutedText = Color(0xFF94A3B8);

    final lightBaseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.light,
      scaffoldBackgroundColor: tcLightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tcNavy,
        primary: tcNavy,
        onPrimary: Colors.white,
        primaryContainer: tcIndigo,
        secondary: tcTeal,
        onSecondary: Colors.white,
        secondaryContainer: tcMint,
        tertiary: tcAmber,
        brightness: Brightness.light,
        surface: tcLightSurface,
        outlineVariant: tcLightBorder,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: tcLightBorder, width: 1),
        ),
        color: tcLightSurface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: tcLightSurface,
        foregroundColor: tcNavy,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tcLightSurface,
        elevation: 0,
        indicatorColor: tcNavy,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return IconThemeData(color: tcNavy.withValues(alpha: 0.6));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tcNavy,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tcNavy.withValues(alpha: 0.6),
          );
        }),
      ),
    );

    final darkBaseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: tcDarkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tcNeonMint,
        primary: tcNeonMint,
        onPrimary: tcDarkText,
        primaryContainer: const Color(0xFF1E293B),
        onPrimaryContainer: Colors.white,
        secondary: const Color(0xFF818CF8),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF1E293B),
        tertiary: tcAmber,
        brightness: Brightness.dark,
        surface: tcDarkSurface,
        onSurface: Colors.white,
        onSurfaceVariant: tcMutedText,
        outlineVariant: tcDarkBorder,
      ),
      iconTheme: const IconThemeData(
        color: tcMutedText,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
        bodySmall: TextStyle(color: tcMutedText),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: tcMutedText),
        labelSmall: TextStyle(color: tcMutedText),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: tcDarkBorder, width: 1.2),
        ),
        color: tcDarkSurface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: tcDarkSurface,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tcDarkSurface,
        elevation: 0,
        indicatorColor: Colors.white,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: tcDarkText);
          }
          return const IconThemeData(color: tcMutedText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tcDarkText,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: tcMutedText,
          );
        }),
      ),
    );

    return MaterialApp(
      title: 'Gestion Cours de Soutien',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: lightBaseTheme,
      darkTheme: darkBaseTheme,
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isLoading = true;
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _verifierProfil();
  }

  Future<void> _verifierProfil() async {
    try {
      final prof = await ApiService.getProfProfile();
      if (mounted) {
        setState(() {
          _isConfigured = prof.isConfigured;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isConfigured = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF006A61)),
        ),
      );
    }
    if (!_isConfigured) {
      return const LandingScreen();
    }
    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentTabIndex = 0;
  ProfProfile? _profProfile;

  NotificationsSummary? _notifSummary;
  List<AppNotification> _notifications = [];
  Timer? _notifTimer;

  // Global Keys pour rafraîchir chaque onglet si nécessaire
  final _accueilKey = GlobalKey<_AccueilTabState>();
  final _elevesKey = GlobalKey<_ElevesTabState>();
  final _financeKey = GlobalKey<_FinanceTabState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chargerProfilSilencieux();
    _chargerNotificationsSilencieux();

    // Vérification périodique toutes les 5 minutes pour les alertes sur le téléphone
    _notifTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _chargerNotificationsSilencieux();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chargerNotificationsSilencieux();
    }
  }

  void _onRefreshCurrentTab() {
    _chargerProfilSilencieux();
    _chargerNotificationsSilencieux();
    switch (_currentTabIndex) {
      case 0:
        _accueilKey.currentState?.recharger();
        break;
      case 1:
        _elevesKey.currentState?.recharger();
        break;
      case 2:
        _financeKey.currentState?.recharger();
        break;
      case 3:
        // Notes tab is persistent via SharedPreferences
        break;
    }
  }

  Future<void> _chargerProfilSilencieux() async {
    try {
      final prof = await ApiService.getProfProfile();
      if (mounted) {
        setState(() {
          _profProfile = prof;
        });
      }
    } catch (_) {}
  }

  Future<void> _chargerNotificationsSilencieux() async {
    try {
      final res = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifSummary = res.summary;
          _notifications = res.notifications;
        });
      }
      // Envoyer les notifications système natives (Android / iOS status bar & tiroir)
      await NotificationService().verifierEtNotifierSysteme(res.notifications);
    } catch (_) {}
  }

  void _openSettings() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
    await _chargerProfilSilencieux();
    if (changed == true) {
      _onRefreshCurrentTab();
    }
  }

  void _openNotificationsCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final countTotal = _notifications.length;
            final countRetard3j = _notifications.where((n) => n.type == 'retard_3j').length;

            return Container(
              height: MediaQuery.of(modalCtx).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  // Poignée de glissement
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // En-tête modal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: countRetard3j > 0
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.15)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            countRetard3j > 0 ? Icons.warning_rounded : Icons.notifications_active_rounded,
                            color: countRetard3j > 0 ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF006A61)),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Centre de Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFE2E8F0) : null,
                                ),
                              ),
                              Text(
                                countTotal == 0
                                    ? 'Tout est à jour'
                                    : '$countTotal notification(s) active(s)${countRetard3j > 0 ? ' • $countRetard3j en retard critique' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: countRetard3j > 0
                                      ? const Color(0xFFEF4444)
                                      : (isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                                  fontWeight: countRetard3j > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Tout effacer', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () async {
                              final ids = _notifications.map((n) => n.id).toList();
                              await ApiService.dismissAllNotifications(ids);
                              await _chargerNotificationsSilencieux();
                              setModalState(() {});
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Actualiser',
                          onPressed: () async {
                            await _chargerNotificationsSilencieux();
                            setModalState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                  ),

                  if (countRetard3j > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Alerte : $countRetard3j séance(s) impayée(s) depuis plus de 3 jours ! Relancez les paiements rapidement.',
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1),

                  // Liste des notifications
                  Expanded(
                    child: _notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 48),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Aucune alerte en attente',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Toutes vos séances sont payées ou planifiées plus tard. Les alertes de retard (>3 jours) et les rappels 30 min apparaîtront ici.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _notifications.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notif = _notifications[index];
                              final isCritique = notif.type == 'retard_3j';
                              final isImpaye = notif.type == 'impaye';
                              final is30min = notif.type == 'seance_30min';

                              Color cardBorderColor;
                              Color cardBgColor;
                              Color badgeColor;
                              IconData badgeIcon;
                              String badgeLabel;

                              if (isCritique) {
                                cardBorderColor = const Color(0xFFEF4444);
                                cardBgColor = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.18 : 0.08);
                                badgeColor = const Color(0xFFEF4444);
                                badgeIcon = Icons.warning_rounded;
                                badgeLabel = 'RETARD > 3 JOURS';
                              } else if (isImpaye) {
                                cardBorderColor = const Color(0xFFF59E0B);
                                cardBgColor = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.08);
                                badgeColor = const Color(0xFFF59E0B);
                                badgeIcon = Icons.hourglass_top_rounded;
                                badgeLabel = 'NON PAYÉE';
                              } else if (is30min) {
                                cardBorderColor = const Color(0xFF3B82F6);
                                cardBgColor = const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.18 : 0.08);
                                badgeColor = const Color(0xFF3B82F6);
                                badgeIcon = Icons.alarm_rounded;
                                badgeLabel = 'DANS MOINS DE 30 MIN';
                              } else {
                                cardBorderColor = const Color(0xFF6366F1);
                                cardBgColor = const Color(0xFF6366F1).withValues(alpha: isDark ? 0.18 : 0.08);
                                badgeColor = const Color(0xFF6366F1);
                                badgeIcon = Icons.today_rounded;
                                badgeLabel = 'AUJOURD\'HUI';
                              }

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: cardBorderColor.withValues(alpha: 0.5), width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor,
                                            borderRadius: BorderRadius.circular(9999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(badgeIcon, color: Colors.white, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                badgeLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          DateFormat('dd/MM à HH:mm').format(notif.dateReference),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () async {
                                            await ApiService.dismissNotification(notif.id);
                                            await _chargerNotificationsSilencieux();
                                            setModalState(() {});
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      notif.titre,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                                      ),
                                    ),
                                    if (isCritique || isImpaye) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (notif.telephone != null && notif.telephone!.isNotEmpty) ...[
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                launchUrl(Uri.parse('tel:${notif.telephone}'));
                                              },
                                              icon: const Icon(Icons.phone_outlined, size: 14),
                                              label: const Text('Appeler', style: TextStyle(fontSize: 11)),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF006A61),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: const Size(60, 32),
                                                side: const BorderSide(color: Color(0xFF006A61)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final sid = notif.referenceId;
                                              if (sid == null) return;
                                              try {
                                                await ApiService.marquerPayee(sid);
                                                if (modalCtx.mounted) {
                                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: const Color(0xFF10B981),
                                                      content: Text('Séance de ${notif.nomEleve ?? "l'élève"} encaissée !'),
                                                    ),
                                                  );
                                                }
                                                await _chargerNotificationsSilencieux();
                                                _onRefreshCurrentTab();
                                                setModalState(() {});
                                              } catch (err) {
                                                if (modalCtx.mounted) {
                                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                                    SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $err')),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                            label: const Text('Encaisser', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF10B981),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: const Size(70, 32),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Pied de page modal : bouton test notification et bouton accès direct aux Finances
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                      border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await NotificationService().testerNotificationSysteme();
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('🔔 Notification test envoyée dans la barre d\'état du téléphone !'),
                                    backgroundColor: Color(0xFF006A61),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.notifications_active_rounded, size: 18),
                            label: const Text('Tester la notification sur le téléphone'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF006A61),
                              side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFF006A61)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              setState(() {
                                _currentTabIndex = 2; // Basculer sur l'onglet Finance
                              });
                            },
                            icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                            label: const Text('Voir toutes les finances & impayés'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF061449),
                              foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppRoot.of(context).isDarkMode;

    return Scaffold(
      drawer: AppDrawer(
        currentTabIndex: _currentTabIndex,
        profProfile: _profProfile,
        notifSummary: _notifSummary,
        onSelectTab: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        onOpenGroupes: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupesScreen(
                profProfile: _profProfile,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          );
          _onRefreshCurrentTab();
        },
        onOpenHistoriquePaiements: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoriquePaiementsScreen(
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
          );
          _onRefreshCurrentTab();
        },
        onOpenSettings: _openSettings,
        onOpenLandingReview: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LandingScreen(isReviewMode: true),
            ),
          );
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: 'Menu latéral',
            icon: const Icon(Icons.menu_rounded, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _profProfile?.nom.isNotEmpty == true
                          ? 'Bienvenue ${_profProfile!.nom}'
                          : 'Gestion Cours',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _profProfile != null && _profProfile!.matieres.isNotEmpty
                          ? _profProfile!.matieres.join(', ')
                          : 'Gestion des cours de soutien',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : const Color(0xFF45464F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: (_notifSummary != null && _notifSummary!.total > 0),
              label: Text(
                '${_notifSummary?.total ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              backgroundColor: (_notifSummary?.countRetard3j ?? 0) > 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _openNotificationsCenter(context),
          ),
          IconButton(
            tooltip: isDark ? 'Mode clair' : 'Mode sombre',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () => AppRoot.of(context).toggleTheme(),
          ),
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _onRefreshCurrentTab,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          AccueilTab(key: _accueilKey),
          ElevesTab(key: _elevesKey),
          FinanceTab(key: _financeKey),
          const NotesTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 60,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172E).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFE5EEFF),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFloatingNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Accueil', isDark),
              _buildFloatingNavItem(1, Icons.people_outline, Icons.people_rounded, 'Élèves', isDark),
              _buildFloatingNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Finance', isDark),
              _buildFloatingNavItem(3, Icons.note_alt_outlined, Icons.note_alt_rounded, 'Notes', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    bool isDark,
  ) {
    final isSelected = _currentTabIndex == index;
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selectedIcon, size: 18, color: const Color(0xFF0B0D1B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0B0D1B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Icon(
          unselectedIcon,
          size: 22,
          color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
        ),
      ),
    );
  }
}

// ==========================================
// MODÈLE AUXILIAIRE : ÉLÉMENT SÉANCE DU JOUR (GROUPE OU INDIVIDUEL)
// ==========================================
class ItemSeanceJour {
  final bool isGroupe;
  final String titre;
  final String? sousTitre;
  final String dateSeance;
  final String? heure;
  final String typeSeance;
  final int montantTotal;
  final String statutPaiementGlobal;
  final String statutSeanceGlobal;
  final List<Seance> seances;

  ItemSeanceJour._({
    required this.isGroupe,
    required this.titre,
    this.sousTitre,
    required this.dateSeance,
    this.heure,
    required this.typeSeance,
    required this.montantTotal,
    required this.statutPaiementGlobal,
    required this.statutSeanceGlobal,
    required this.seances,
  });

  factory ItemSeanceJour.individuel(Seance s) {
    return ItemSeanceJour._(
      isGroupe: false,
      titre: s.nomEleveEtNiveau,
      sousTitre: s.typeSeance.isNotEmpty ? s.typeSeance : 'Séance individuelle',
      dateSeance: s.dateSeance,
      heure: s.heure,
      typeSeance: s.typeSeance,
      montantTotal: s.montant,
      statutPaiementGlobal: s.statutPaiement,
      statutSeanceGlobal: s.statutSeance,
      seances: [s],
    );
  }

  factory ItemSeanceJour.groupe({
    required String nomGroupe,
    required String dateSeance,
    String? heure,
    required String typeSeance,
    required List<Seance> seances,
  }) {
    final total = seances.fold<int>(0, (sum, s) => sum + s.montant);
    final tousPayes = seances.every((s) => s.statutPaiement.toLowerCase() == 'payé' || s.statutPaiement.toLowerCase() == 'paye');
    final auMoinsUnPaye = seances.any((s) => s.statutPaiement.toLowerCase() == 'payé' || s.statutPaiement.toLowerCase() == 'paye');
    final statutPaiement = tousPayes
        ? 'Payé'
        : (auMoinsUnPaye ? 'Partiel' : 'En attente');
    final tousTermines = seances.every((s) => s.statutSeance.toLowerCase() == 'terminee' || s.statutSeance.toLowerCase() == 'terminée');
    final statutSeance = tousTermines ? 'Terminée' : (seances.first.statutSeance);
    final nomsEleves = seances.map((s) => s.nomEleve.trim()).where((n) => n.isNotEmpty).join(', ');

    return ItemSeanceJour._(
      isGroupe: true,
      titre: nomGroupe,
      sousTitre: '${seances.length} élèves : $nomsEleves',
      dateSeance: dateSeance,
      heure: heure,
      typeSeance: typeSeance,
      montantTotal: total,
      statutPaiementGlobal: statutPaiement,
      statutSeanceGlobal: statutSeance,
      seances: seances,
    );
  }

  ItemImpaye toItemImpaye() {
    if (isGroupe) {
      return ItemImpaye.groupe(
        nomGroupe: titre,
        dateSeance: dateSeance,
        heure: heure,
        typeSeance: typeSeance,
        seances: seances,
      );
    } else {
      return ItemImpaye.individuel(seances.first);
    }
  }

  bool get estPaye => statutPaiementGlobal.toLowerCase() == 'payé' || statutPaiementGlobal.toLowerCase() == 'paye';
  Seance get premiereSeance => seances.first;
  bool get estArrivee => seances.any((s) => s.estArrivee);
  bool get necessiteAction => estArrivee && !estPaye;
}

// ==========================================
// MODÈLE AUXILIAIRE : ÉLÉMENT IMPAYÉ (GROUPE OU INDIVIDUEL)
// ==========================================
class ItemImpaye {
  final bool isGroupe;
  final String titre;
  final String dateSeance;
  final String? heure;
  final String typeSeance;
  final int montantTotal;
  final int maxRetard;
  final List<Seance> seances;

  ItemImpaye._({
    required this.isGroupe,
    required this.titre,
    required this.dateSeance,
    this.heure,
    required this.typeSeance,
    required this.montantTotal,
    required this.maxRetard,
    required this.seances,
  });

  factory ItemImpaye.individuel(Seance s) {
    return ItemImpaye._(
      isGroupe: false,
      titre: s.nomEleveEtNiveau,
      dateSeance: s.dateSeance,
      heure: s.heure,
      typeSeance: s.typeSeance,
      montantTotal: s.montant,
      maxRetard: s.joursRetard,
      seances: [s],
    );
  }

  factory ItemImpaye.groupe({
    required String nomGroupe,
    required String dateSeance,
    String? heure,
    required String typeSeance,
    required List<Seance> seances,
  }) {
    final total = seances.fold<int>(0, (sum, s) => sum + s.montant);
    final retard = seances.map((s) => s.joursRetard).fold<int>(0, (max, r) => r > max ? r : max);
    return ItemImpaye._(
      isGroupe: true,
      titre: nomGroupe,
      dateSeance: dateSeance,
      heure: heure,
      typeSeance: typeSeance,
      montantTotal: total,
      maxRetard: retard,
      seances: seances,
    );
  }

  bool get estPayable => seances.any((s) => s.estPayable);
  int get totalMontant => montantTotal;
  int get joursRetardMax => maxRetard;
  Seance? get seance => seances.isNotEmpty ? seances.first : null;
}

/// Dialogue centralisé de pointage et d'encaissement d'une séance groupée
Future<void> afficherDialoguePointageGroupe({
  required BuildContext context,
  required ItemImpaye item,
  required VoidCallback onComplete,
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  // États locaux par séance élève :
  // presenceMap : true = Présent, false = Absent
  // payeMap : true = Payé maintenant, false = Payer plus tard (dette)
  final Map<String, bool> presenceMap = {};
  final Map<String, bool> payeMap = {};

  for (final s in item.seances) {
    final isAbsentInitial = s.statutSeance == 'Annulée' || s.montant == 0;
    presenceMap[s.idSeance] = !isAbsentInitial;
    final isPayeInitial = s.statutPaiement == 'Payé';
    payeMap[s.idSeance] = isPayeInitial || !isAbsentInitial;
  }

  bool isSubmitting = false;
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sbContext, setDialogState) {
          final presents = item.seances.where((s) => presenceMap[s.idSeance] == true).toList();
          final absents = item.seances.where((s) => presenceMap[s.idSeance] != true).toList();

          final payes = presents.where((s) => payeMap[s.idSeance] == true).toList();
          final impayes = presents.where((s) => payeMap[s.idSeance] != true).toList();

          final totalAEncaisser = payes.fold<int>(0, (sum, s) => sum + s.montant);
          final totalDette = impayes.fold<int>(0, (sum, s) => sum + s.montant);

          final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.tryParse(item.dateSeance) ?? DateTime.now());

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Container(
              width: 560,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A61).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.how_to_reg_rounded,
                          color: Color(0xFF006A61),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pointer séance : ${item.titre}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$dateStr${item.heure != null && item.heure!.isNotEmpty ? " à ${item.heure}" : ""} • ${item.seances.length} élève(s)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Actions rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pointage des élèves :',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[200] : const Color(0xFF061449),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: const Color(0xFF10B981),
                            ),
                            icon: const Icon(Icons.done_all_rounded, size: 14),
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      for (final s in item.seances) {
                                        presenceMap[s.idSeance] = true;
                                        payeMap[s.idSeance] = true;
                                      }
                                    });
                                  },
                            label: const Text('Tout payé', style: TextStyle(fontSize: 11.5)),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: const Color(0xFFD97706),
                            ),
                            icon: const Icon(Icons.schedule_rounded, size: 14),
                            onPressed: isSubmitting
                                ? null
                                : () {
                                    setDialogState(() {
                                      for (final s in item.seances) {
                                        presenceMap[s.idSeance] = true;
                                        payeMap[s.idSeance] = false;
                                      }
                                    });
                                  },
                            label: const Text('Tout dette', style: TextStyle(fontSize: 11.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Liste des élèves avec cartes modernes
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: item.seances.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final s = item.seances[idx];
                        final isPresent = presenceMap[s.idSeance] ?? true;
                        final isPaye = payeMap[s.idSeance] ?? true;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPresent
                                  ? const Color(0xFF006A61).withValues(alpha: 0.35)
                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                              width: isPresent ? 1.5 : 1.0,
                            ),
                            boxShadow: isPresent
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ligne 1 : Avatar, Nom (15pt bold), Badge et Sélecteur Présent/Absent
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: isPresent
                                        ? const Color(0xFF006A61).withValues(alpha: 0.15)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    child: Text(
                                      s.nomEleve.isNotEmpty ? s.nomEleve[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isPresent ? const Color(0xFF006A61) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.nomEleveEtNiveau,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isPresent
                                                ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449))
                                                : (isDark ? const Color(0xFF64748B) : Colors.grey[500]),
                                            decoration: isPresent ? null : TextDecoration.lineThrough,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPresent
                                                ? (isPaye
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                    : Colors.amber.withValues(alpha: 0.15))
                                                : Colors.red.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isPresent
                                                ? (isPaye
                                                    ? '✓ Présent • Payé (${NumberFormat('#,###').format(s.montant)} DZD)'
                                                    : '⏳ Présent • Dette (${NumberFormat('#,###').format(s.montant)} DZD)')
                                                : '✕ Absent • 0 DZD (non facturé)',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isPresent
                                                  ? (isPaye ? const Color(0xFF059669) : const Color(0xFFD97706))
                                                  : Colors.red[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Sélecteur Présent / Absent distincts
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: isSubmitting
                                              ? null
                                              : () => setDialogState(() => presenceMap[s.idSeance] = true),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isPresent ? const Color(0xFF006A61) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Présent',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isPresent
                                                    ? Colors.white
                                                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: isSubmitting
                                              ? null
                                              : () => setDialogState(() => presenceMap[s.idSeance] = false),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: !isPresent ? Colors.red[700] : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Absent',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: !isPresent
                                                    ? Colors.white
                                                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Ligne 2 : Si présent, choix du paiement
                              if (isPresent) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: isSubmitting
                                            ? null
                                            : () => setDialogState(() => payeMap[s.idSeance] = true),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isPaye
                                                ? const Color(0xFF10B981)
                                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isPaye
                                                  ? const Color(0xFF10B981)
                                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: isPaye ? Colors.white : const Color(0xFF10B981),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Payé maintenant',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPaye
                                                      ? Colors.white
                                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF061449)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: isSubmitting
                                            ? null
                                            : () => setDialogState(() => payeMap[s.idSeance] = false),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: !isPaye
                                                ? const Color(0xFFF59E0B)
                                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: !isPaye
                                                  ? const Color(0xFFF59E0B)
                                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 14,
                                                color: !isPaye ? Colors.white : const Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Payer plus tard',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: !isPaye
                                                      ? Colors.white
                                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF061449)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Récapitulatif dynamique des montants
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF006A61)),
                                const SizedBox(width: 6),
                                Text(
                                  'Encaisser maintenant (${payes.length}) :',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              '${NumberFormat('#,###').format(totalAEncaisser)} DZD',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006A61),
                              ),
                            ),
                          ],
                        ),
                        if (impayes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'À payer plus tard / dette (${impayes.length}) :',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Text(
                                '${NumberFormat('#,###').format(totalDette)} DZD',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (absents.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.cancel_outlined, size: 16, color: Colors.red[400]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Absents annulés (${absents.length}) :',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Text(
                                '0 DZD (non facturé)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Actions du bas
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Fermer'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isSubmitting = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      final seancesPayeesIds = payes.map((s) => s.idSeance).toList();
                                      final seancesImpayeesIds = impayes.map((s) => s.idSeance).toList();
                                      final seancesAbsentesIds = absents.map((s) => s.idSeance).toList();

                                      await ApiService.validerPointageGroupeComplet(
                                        seancesPayeesIds: seancesPayeesIds,
                                        seancesImpayeesIds: seancesImpayeesIds,
                                        seancesAbsentesIds: seancesAbsentesIds,
                                      );

                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(0xFF10B981),
                                            content: Text(
                                              'Pointage validé : ${payes.length} payé(s) (${NumberFormat('#,###').format(totalAEncaisser)} DZD), ${impayes.length} en dette, ${absents.length} absent(s) !',
                                            ),
                                          ),
                                        );
                                      }

                                      onComplete();
                                    } catch (e) {
                                      setDialogState(() {
                                        isSubmitting = false;
                                        errorMessage = 'Erreur lors du pointage : $e';
                                      });
                                    }
                                  },
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_rounded, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                totalAEncaisser > 0
                                    ? 'Valider & Encaisser (${NumberFormat('#,###').format(totalAEncaisser)} DZD)'
                                    : 'Valider le pointage',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006A61),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ==========================================
// CAROUSEL ANIMÉ DU RAPPEL DES SÉANCES DU JOUR
// ==========================================
class RappelSeancesCarousel extends StatefulWidget {
  final List<ItemSeanceJour> items;
  final bool isDark;
  final Widget Function(ItemSeanceJour item) itemBuilder;

  const RappelSeancesCarousel({
    super.key,
    required this.items,
    required this.isDark,
    required this.itemBuilder,
  });

  @override
  State<RappelSeancesCarousel> createState() => _RappelSeancesCarouselState();
}

class _RappelSeancesCarouselState extends State<RappelSeancesCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;
  double _pagePosition = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.hasClients && _pageController.position.haveDimensions) {
      final pos = _pageController.page ?? _pageController.initialPage.toDouble();
      setState(() {
        _pagePosition = pos;
        _currentIndex = pos.round().clamp(0, widget.items.length - 1);
      });
    }
  }

  @override
  void didUpdateWidget(covariant RappelSeancesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.items.length) {
      _currentIndex = (widget.items.length - 1).clamp(0, 999);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  double _cardHeight(ItemSeanceJour item) {
    return item.necessiteAction ? 290.0 : 210.0;
  }

  double _getInterpolatedHeight() {
    if (widget.items.isEmpty) return 0.0;
    if (widget.items.length == 1) return _cardHeight(widget.items[0]);

    final floorIndex = _pagePosition.floor().clamp(0, widget.items.length - 1);
    final ceilIndex = _pagePosition.ceil().clamp(0, widget.items.length - 1);
    final t = _pagePosition - floorIndex;

    final h1 = _cardHeight(widget.items[floorIndex]);
    final h2 = _cardHeight(widget.items[ceilIndex]);
    return h1 + (h2 - h1) * t;
  }

  void _animateToPage(int index) {
    if (index >= 0 && index < widget.items.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.items.length == 1) {
      return widget.itemBuilder(widget.items[0]);
    }

    final total = widget.items.length;
    final currentHeight = _getInterpolatedHeight();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // En-tête : Compteur animé "Séance X sur N" + Flèches < >
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 2.0, right: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swipe_rounded,
                      size: 13,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Séance ${_currentIndex + 1} sur $total',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavArrowButton(
                    icon: Icons.chevron_left_rounded,
                    enabled: _currentIndex > 0,
                    isDark: widget.isDark,
                    onTap: () => _animateToPage(_currentIndex - 1),
                  ),
                  const SizedBox(width: 6),
                  _NavArrowButton(
                    icon: Icons.chevron_right_rounded,
                    enabled: _currentIndex < total - 1,
                    isDark: widget.isDark,
                    onTap: () => _animateToPage(_currentIndex + 1),
                  ),
                ],
              ),
            ],
          ),
        ),

        // PageView animé avec hauteur dynamique interpolée
        SizedBox(
          height: currentHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: total,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              final pageOffset = (_pagePosition - index).abs();
              final scale = (1.0 - (pageOffset * 0.05)).clamp(0.95, 1.0);
              final opacity = (1.0 - (pageOffset * 0.3)).clamp(0.7, 1.0);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.itemBuilder(item),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Indicateurs de pagination animés
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (index) {
            final isCurrent = index == _currentIndex;
            final isItemPaye = widget.items[index].estPaye;
            final isItemAction = widget.items[index].necessiteAction;

            Color activeColor = const Color(0xFF6366F1);
            if (isItemPaye) {
              activeColor = const Color(0xFF10B981);
            } else if (isItemAction) {
              activeColor = const Color(0xFFF59E0B);
            }

            return GestureDetector(
              onTap: () => _animateToPage(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: isCurrent ? 24.0 : 7.0,
                height: 7.0,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? activeColor
                      : (widget.isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(4.0),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final VoidCallback onTap;

  const _NavArrowButton({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final fg = enabled
        ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}

// ==========================================
// ONGLET 1 : ACCUEIL (DASHBOARD & ACTIONS)
// ==========================================
class AccueilTab extends StatefulWidget {
  const AccueilTab({super.key});

  @override
  State<AccueilTab> createState() => _AccueilTabState();
}

class _AccueilTabState extends State<AccueilTab> {
  DashboardData? _dashboard;
  bool _isLoading = true;
  String? _error;

  // Filtre et sélection multiple des impayés
  String _filtreImpayes = 'Tout'; // 'Tout', 'Normale', 'Privée'
  final Set<String> _impayesSelectionnes = {};
  bool _isPayingMasse = false;

  // Contrôle de la liste déroulante des séances du jour
  bool _seancesDuJourEtendues = false;
  late final ScrollController _seancesScrollController;

  @override
  void initState() {
    super.initState();
    _seancesScrollController = ScrollController();
    recharger();
  }

  @override
  void dispose() {
    _seancesScrollController.dispose();
    super.dispose();
  }

  Future<void> recharger() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _isLoading = false;
          _impayesSelectionnes.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

    Future<String?> _demanderTypeSeance(BuildContext context, {required String actionTitre}) async {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  actionTitre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choisissez le format de séance :',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFF061449).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF061449)),
                  ),
                  title: const Text('Séance Individuelle', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Cours pour un seul élève particulier', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : null),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.of(ctx).pop('individuel'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.groups_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF006A61)),
                  ),
                  title: const Text('Séance de Groupe', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Pointage des présences et tarif partagé par groupe', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : null)),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : null),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.of(ctx).pop('groupe'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Groupe?> _selectionnerGroupe(BuildContext context, List<Groupe> groupes, String titre) async {
    return showDialog<Groupe>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.groups_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF006A61)),
              const SizedBox(width: 10),
              Expanded(child: Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: groupes.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : null),
              itemBuilder: (c, i) {
                final g = groupes[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.15),
                    child: Text(
                      g.nom.isNotEmpty ? g.nom[0].toUpperCase() : 'G',
                      style: TextStyle(color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF006A61), fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(g.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    '${g.eleves.length} élève(s) • ${g.tarifParDefaut.toInt()} DZD / élève • Total : ${(g.tarifParDefaut * g.eleves.length).toInt()} DZD',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF94A3B8) : null),
                  onTap: () => Navigator.of(ctx).pop(g),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  void _ouvrirSaisirSeance() async {
    try {
      final eleves = await ApiService.getEleves(statut: 'Actif');
      final groupes = await ApiService.getGroupes();
      final prof = await ApiService.getProfProfile();
      final tarifsEffectifs = TarifsConfig(
        normale: prof.prixNormale1,
        privee: prof.prixPrivee1,
        normale1: prof.prixNormale1,
        normale2: prof.prixNormale2,
        privee1: prof.prixPrivee1,
        privee2: prof.prixPrivee2,
        tarifsNormale: prof.tarifsNormale,
        tarifsPrivee: prof.tarifsPrivee,
      );
      if (!mounted) return;

      String choix = 'individuel';
      if (groupes.isNotEmpty) {
        final selection = await _demanderTypeSeance(context, actionTitre: 'Saisir une séance');
        if (selection == null) return;
        choix = selection;
      }

      if (choix == 'groupe') {
        if (!mounted) return;
        final Groupe? groupeChoisi = await _selectionnerGroupe(context, groupes, 'Choisir un groupe');
        if (groupeChoisi == null || !mounted) return;
        await showDialog<dynamic>(
          context: context,
          builder: (context) => SeanceGroupeDialog(
            groupe: groupeChoisi,
            profProfile: prof,
          ),
        );
        recharger();
      } else {
        if (!mounted) return;
        await showDialog<bool>(
          context: context,
          builder: (context) => SaisirSeanceDialog(
            eleves: eleves,
            tarifs: tarifsEffectifs,
            onSuccess: () => recharger(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _ouvrirPlanifierSeance() async {
    try {
      final eleves = await ApiService.getEleves(statut: 'Actif');
      final groupes = await ApiService.getGroupes();
      final prof = await ApiService.getProfProfile();
      final tarifsEffectifs = TarifsConfig(
        normale: prof.prixNormale1,
        privee: prof.prixPrivee1,
        normale1: prof.prixNormale1,
        normale2: prof.prixNormale2,
        privee1: prof.prixPrivee1,
        privee2: prof.prixPrivee2,
        tarifsNormale: prof.tarifsNormale,
        tarifsPrivee: prof.tarifsPrivee,
      );
      if (!mounted) return;

      String choix = 'individuel';
      if (groupes.isNotEmpty) {
        final selection = await _demanderTypeSeance(context, actionTitre: 'Planifier une séance');
        if (selection == null) return;
        choix = selection;
      }

      if (choix == 'groupe') {
        if (!mounted) return;
        final Groupe? groupeChoisi = await _selectionnerGroupe(context, groupes, 'Planifier pour un groupe');
        if (groupeChoisi == null || !mounted) return;
        await showDialog<dynamic>(
          context: context,
          builder: (context) => SeanceGroupeDialog(
            groupe: groupeChoisi,
            profProfile: prof,
            estPlanification: true,
          ),
        );
        recharger();
      } else {
        if (!mounted) return;
        await showDialog<bool>(
          context: context,
          builder: (context) => PlanifierSeanceDialog(
            eleves: eleves,
            tarifs: tarifsEffectifs,
            onSuccess: () => recharger(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }


  Future<void> _reglerMasse() async {
    if (_impayesSelectionnes.isEmpty) return;

    final seancesSelectionnees = _dashboard?.seancesImpayes
            .where((s) => _impayesSelectionnes.contains(s.idSeance))
            .toList() ??
        [];
    final seancesPayables = seancesSelectionnees
        .where((s) => s.estPayable)
        .map((s) => s.idSeance)
        .toList();

    if (seancesPayables.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFBA1A1A),
            content: Text('Aucune des séances sélectionnées n\'est payable pour le moment.'),
          ),
        );
      }
      return;
    }

    final nonPayablesCount = _impayesSelectionnes.length - seancesPayables.length;

    setState(() {
      _isPayingMasse = true;
    });

    try {
      final count = await ApiService.payerSeancesMasse(seancesPayables);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(nonPayablesCount > 0
                ? '$count séance(s) payée(s). ($nonPayablesCount séance(s) planifiée(s) future(s) ignorée(s))'
                : '$count séance(s) marquée(s) comme payée(s) avec succès !'),
          ),
        );
        recharger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur règlement : ${e.toString().replaceFirst('Exception: ', '')}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPayingMasse = false;
        });
      }
    }
  }

  Future<void> _payerIndividuel(Seance seance) async {
    if (!seance.estPayable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFBA1A1A),
            content: Text('Impossible de régler une séance planifiée avant sa date et heure prévues.'),
          ),
        );
      }
      return;
    }

    try {
      await ApiService.payerSeancesMasse([seance.idSeance]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('Séance de ${seance.nomEleve} réglée !'),
          ),
        );
        recharger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur : $e'),
          ),
        );
      }
    }
  }

  Future<void> _annulerSeance(Seance seance) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la séance ?'),
        content: Text('Confirmez-vous l\'annulation de la séance de ${seance.nomEleve} (${seance.montant} DZD) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await ApiService.annulerSeance(seance.idSeance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance annulée')),
        );
        recharger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _annulerSeanceGroupe(ItemImpaye item) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la séance de groupe ?'),
        content: Text(
          'Confirmez-vous l\'annulation de la séance pour tout le groupe "${item.titre}" (${item.seances.length} élèves, ${NumberFormat('#,###').format(item.montantTotal)} DZD) ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, tout annuler'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      for (final s in item.seances) {
        await ApiService.annulerSeance(s.idSeance);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance de groupe annulée')),
        );
        recharger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _ouvrirDialoguePointageGroupe(ItemImpaye item) async {
    await afficherDialoguePointageGroupe(
      context: context,
      item: item,
      onComplete: recharger,
    );
  }

  Future<void> _validerPaiementSeanceIndividuelle(Seance seance) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.payment_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 10),
            Text('Valider le paiement ?'),
          ],
        ),
        content: Text(
          'Confirmez-vous l\'encaissement de la séance de ${seance.nomEleve} pour un montant de ${NumberFormat('#,###').format(seance.montant)} DZD ?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer l\'encaissement'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _payerIndividuel(seance);
    }
  }

  Widget _buildRappelSeanceCard(ItemSeanceJour item, BuildContext context, bool isDark) {
    final isPaye = item.estPaye;
    final estArrivee = item.estArrivee;
    final actionRequise = estArrivee && !isPaye;
    final heureStr = item.heure ?? '--:--';
    final titreStr = item.titre;
    final sousTitreStr = item.isGroupe
        ? '👥 ${item.sousTitre}'
        : (item.sousTitre ?? 'Séance individuelle');

    // Palette visuelle adaptée au statut
    final List<Color> gradientColors = isPaye
        ? const [Color(0xFF047857), Color(0xFF0D9488), Color(0xFF14B8A6)]
        : (actionRequise
            ? const [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF8B5CF6)]
            : const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF4F46E5)]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPaye
                    ? const Color(0xFF059669)
                    : (actionRequise ? const Color(0xFF6366F1) : const Color(0xFF1E293B)))
                .withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Badge Type + Badge Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isGroupe ? Icons.groups_rounded : Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.isGroupe ? 'RAPPEL • SÉANCE DE GROUPE' : 'RAPPEL • SÉANCE DU JOUR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isPaye
                      ? const Color(0xFF10B981).withValues(alpha: 0.35)
                      : (actionRequise
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                          : Colors.white.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isPaye
                        ? const Color(0xFF34D399)
                        : (actionRequise ? const Color(0xFFFBBF24) : Colors.white.withValues(alpha: 0.4)),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPaye
                            ? const Color(0xFF34D399)
                            : (actionRequise ? const Color(0xFFFBBF24) : Colors.white70),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isPaye
                          ? 'Réglé'
                          : (actionRequise
                              ? (item.isGroupe ? 'Pointage requis' : 'À encaisser')
                              : 'À venir'),
                      style: TextStyle(
                        color: isPaye
                            ? const Color(0xFFA7F3D0)
                            : (actionRequise ? const Color(0xFFFEF3C7) : Colors.white),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne Heure + Tags
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                heureStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${NumberFormat('#,###').format(item.montantTotal)} DZD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (item.isGroupe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.seances.length} élèves',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Titre
          Text(
            titreStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Sous-titre
          Text(
            sousTitreStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // BANDEAU D'ACTION SI LA SÉANCE EST ARRIVÉE ET PASSÉE NON RÉGLÉE
          if (actionRequise) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.isGroupe
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                          : const Color(0xFF10B981).withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isGroupe ? Icons.how_to_reg_rounded : Icons.payment_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isGroupe
                              ? 'Séance terminée • Pointage requis'
                              : 'Séance terminée • En attente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.isGroupe
                              ? 'Pointez les présences & encaissez'
                              : 'Validez le paiement (${NumberFormat('#,###').format(item.montantTotal)} DZD)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: item.isGroupe ? const Color(0xFF5B21B6) : const Color(0xFF047857),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (item.isGroupe) {
                        _ouvrirDialoguePointageGroupe(item.toItemImpaye());
                      } else {
                        _validerPaiementSeanceIndividuelle(item.premiereSeance);
                      }
                    },
                    icon: Icon(
                      item.isGroupe ? Icons.how_to_reg_rounded : Icons.check_circle_rounded,
                      size: 15,
                      color: item.isGroupe ? const Color(0xFF5B21B6) : const Color(0xFF047857),
                    ),
                    label: Text(
                      item.isGroupe ? 'Pointer & Encaisser' : 'Valider paiement',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemSeanceDuJourTile(ItemSeanceJour item, bool isDark) {
    final isPaye = item.estPaye;
    final isPartiel = item.statutPaiementGlobal.toLowerCase() == 'partiel';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        dense: true,
        onTap: () {
          if (item.isGroupe) {
            afficherDialoguePointageGroupe(
              context: context,
              item: item.toItemImpaye(),
              onComplete: recharger,
            );
          }
        },
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: item.isGroupe
                ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: item.isGroupe
                ? null
                : [
                    const Color(0xFF2DD4BF),
                    const Color(0xFFFB7185),
                    const Color(0xFFA5B4FC),
                    const Color(0xFFFDE047),
                  ][item.titre.hashCode.abs() % 4],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: item.isGroupe
                ? const Icon(Icons.groups_rounded, color: Colors.white, size: 22)
                : Text(
                    item.titre.isNotEmpty ? item.titre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF070B16),
                    ),
                  ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.titre,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF061449),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.isGroupe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'GROUPE (${item.seances.length})',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFA78BFA),
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${item.isGroupe ? "👥 ${item.sousTitre}" : (item.sousTitre ?? "👤 Séance individuelle")} • ${NumberFormat('#,###').format(item.montantTotal)} DZD',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? (isPaye
                    ? const Color(0xFF2DD4BF).withValues(alpha: 0.15)
                    : (isPartiel
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B)))
                : (isPaye
                    ? const Color(0xFF86F2E4)
                    : (isPartiel ? const Color(0xFFFFE082) : const Color(0xFFFFDDB8))),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? (isPaye
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
                      : const Color(0x33FFFFFF))
                  : (isPaye
                      ? const Color(0xFF006A61).withValues(alpha: 0.3)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.heure != null && item.heure!.isNotEmpty) ...[
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006F66),
                ),
                const SizedBox(width: 4),
                Text(
                  item.heure!,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006F66),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ] else ...[
                if (isPaye) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 12,
                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006F66),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  item.statutPaiementGlobal,
                  style: TextStyle(
                    color: isDark
                        ? (isPaye
                            ? const Color(0xFF2DD4BF)
                            : (isPartiel ? const Color(0xFFFBBF24) : const Color(0xFFFB7185)))
                        : (isPaye
                            ? const Color(0xFF006F66)
                            : (isPartiel ? const Color(0xFFB45309) : const Color(0xFF78350F))),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCapsule({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF4FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF061449),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF006A61)),
            SizedBox(height: 16),
            Text('Chargement des données du tableau de bord...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 54),
              const SizedBox(height: 12),
              Text(
                'Impossible de contacter le serveur',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: recharger,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF061449),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboard!;
    final kpi = dashboard.kpi;

    // Filtrer les séances impayées
    final impayesFiltres = dashboard.seancesImpayes.where((s) {
      if (_filtreImpayes == 'Tout') return true;
      return s.typeSeance.toLowerCase() == _filtreImpayes.toLowerCase();
    }).toList();

    // Grouper les séances de groupe pour affichage consolidé
    final Map<String, List<Seance>> groupMap = {};
    final List<String> groupOrder = [];

    for (final s in impayesFiltres) {
      final key = (s.idSeanceGroupe != null && s.idSeanceGroupe!.isNotEmpty)
          ? 'seance_grp_${s.idSeanceGroupe}'
          : ((s.idGroupe != null && s.idGroupe!.isNotEmpty)
              ? 'grp_${s.idGroupe}_${s.dateSeance}_${s.heure ?? ""}'
              : 'ind_${s.idSeance}');

      if (!groupMap.containsKey(key)) {
        groupMap[key] = [];
        groupOrder.add(key);
      }
      groupMap[key]!.add(s);
    }

    final List<ItemImpaye> itemsImpayes = [];
    for (final key in groupOrder) {
      final list = groupMap[key]!;
      if (list.length > 1) {
        final first = list.first;
        final nomGroupe = (first.nomGroupe != null && first.nomGroupe!.isNotEmpty)
            ? first.nomGroupe!
            : 'Séance de groupe';
        itemsImpayes.add(
          ItemImpaye.groupe(
            nomGroupe: nomGroupe,
            dateSeance: first.dateSeance,
            heure: first.heure,
            typeSeance: first.typeSeance,
            seances: list,
          ),
        );
      } else {
        itemsImpayes.add(ItemImpaye.individuel(list.first));
      }
    }

    final totalSelectionne = dashboard.seancesImpayes
        .where((s) => _impayesSelectionnes.contains(s.idSeance))
        .fold<int>(0, (sum, s) => sum + s.montant);

    // Grouper les séances du jour (si groupe planifié = 1 seule tuile consolidée)
    final Map<String, List<Seance>> seancesDuJourGroupMap = {};
    final List<String> seancesDuJourOrder = [];

    for (final s in dashboard.seancesDuJour) {
      final key = (s.idSeanceGroupe != null && s.idSeanceGroupe!.isNotEmpty)
          ? 'seance_grp_${s.idSeanceGroupe}'
          : ((s.idGroupe != null && s.idGroupe!.isNotEmpty)
              ? 'grp_${s.idGroupe}_${s.dateSeance}_${s.heure ?? ""}'
              : 'ind_${s.idSeance}');

      if (!seancesDuJourGroupMap.containsKey(key)) {
        seancesDuJourGroupMap[key] = [];
        seancesDuJourOrder.add(key);
      }
      seancesDuJourGroupMap[key]!.add(s);
    }

    final List<ItemSeanceJour> itemsSeancesDuJour = [];
    for (final key in seancesDuJourOrder) {
      final list = seancesDuJourGroupMap[key]!;
      if (list.length > 1) {
        final first = list.first;
        final nomGroupe = (first.nomGroupe != null && first.nomGroupe!.isNotEmpty)
            ? first.nomGroupe!
            : 'Séance de groupe';
        itemsSeancesDuJour.add(
          ItemSeanceJour.groupe(
            nomGroupe: nomGroupe,
            dateSeance: first.dateSeance,
            heure: first.heure,
            typeSeance: first.typeSeance,
            seances: list,
          ),
        );
      } else {
        itemsSeancesDuJour.add(ItemSeanceJour.individuel(list.first));
      }
    }

    return RefreshIndicator(
      onRefresh: recharger,
      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF061449),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SALUTATION (SANS ICÔNE DE NOTIFICATION & CONTRASTE PARFAIT CLAIR/SOMBRE)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour 👋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${itemsSeancesDuJour.length} séance(s) programmée(s) aujourd\'hui',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // RAPPEL SÉANCES DU JOUR (TOUTES LES SÉANCES DU JOUR SONT AFFICHÉES AVEC ACTIONS APPROPRIÉES)
            if (itemsSeancesDuJour.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : const [Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planning libre aujourd\'hui',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aucune séance programmée pour aujourd\'hui',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              RappelSeancesCarousel(
                items: itemsSeancesDuJour,
                isDark: isDark,
                itemBuilder: (item) => _buildRappelSeanceCard(item, context, isDark),
              ),
            const SizedBox(height: 16),

            // 4 ACTIONS RAPIDES EN CAPSULES (Saisir, Planifier, Groupes, Historique)
            Row(
              children: [
                _buildQuickActionCapsule(
                  label: 'Saisir',
                  icon: Icons.add_task_rounded,
                  onTap: _ouvrirSaisirSeance,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickActionCapsule(
                  label: 'Planifier',
                  icon: Icons.calendar_month_rounded,
                  onTap: _ouvrirPlanifierSeance,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickActionCapsule(
                  label: 'Groupes',
                  icon: Icons.groups_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupesScreen(
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                    recharger();
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickActionCapsule(
                  label: 'Historique',
                  icon: Icons.receipt_long_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoriquePaiementsScreen(
                          onBack: () => Navigator.of(context).pop(),
                        ),
                      ),
                    );
                    recharger();
                  },
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),



            // 4 KPIS COMPLETS (Grille 2x2 sur mobile)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final cards = [
                  KpiCard(
                    title: 'Total Encaissé ce mois',
                    value: '${NumberFormat('#,###').format(kpi.totalPayeMois)} DZD',
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFF006A61),
                    subtitle: 'Mois en cours',
                  ),
                  KpiCard(
                    title: 'Séances du mois',
                    value: '${kpi.nombreSeancesMois}',
                    icon: Icons.event_available_rounded,
                    accentColor: const Color(0xFF061449),
                    subtitle: 'Séances réalisées/prévues',
                  ),
                  KpiCard(
                    title: 'Total Impayé en attente',
                    value: '${NumberFormat('#,###').format(kpi.totalImpaye)} DZD',
                    icon: Icons.pending_actions_rounded,
                    accentColor: const Color(0xFFBA1A1A),
                    subtitle: 'Non annulées',
                  ),
                  KpiCard(
                    title: 'Élèves inscrits',
                    value: '${kpi.nombreEleves}',
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF1E2A5E),
                    subtitle: 'Effectif total',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // SÉANCES DU JOUR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Séances du Jour',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${itemsSeancesDuJour.length}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF061449),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (itemsSeancesDuJour.length > 3)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _seancesDuJourEtendues = !_seancesDuJourEtendues;
                      });
                    },
                    borderRadius: BorderRadius.circular(9999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _seancesDuJourEtendues
                                ? Icons.unfold_less_rounded
                                : Icons.unfold_more_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF006A61),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _seancesDuJourEtendues ? 'Réduire' : 'Dérouler tout',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF006A61),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (itemsSeancesDuJour.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF), width: 1.2),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[400], size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune séance enregistrée pour aujourd\'hui',
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final bool isLongList = itemsSeancesDuJour.length > 3;
                  final bool doitDerouler = isLongList && !_seancesDuJourEtendues;

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF), width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: doitDerouler ? 285 : double.infinity,
                          ),
                          child: doitDerouler
                              ? Scrollbar(
                                  controller: _seancesScrollController,
                                  thumbVisibility: true,
                                  radius: const Radius.circular(8),
                                  thickness: 4,
                                  child: ListView.separated(
                                    controller: _seancesScrollController,
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: itemsSeancesDuJour.length,
                                    separatorBuilder: (context, index) => Divider(
                                      height: 1,
                                      color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = itemsSeancesDuJour[index];
                                      return _buildItemSeanceDuJourTile(item, isDark);
                                    },
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: itemsSeancesDuJour.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = itemsSeancesDuJour[index];
                                    return _buildItemSeanceDuJourTile(item, isDark);
                                  },
                                ),
                        ),
                        if (isLongList)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _seancesDuJourEtendues = !_seancesDuJourEtendues;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF070B16) : const Color(0xFFF3F7FF),
                                border: Border(
                                  top: BorderSide(
                                    color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _seancesDuJourEtendues
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _seancesDuJourEtendues
                                        ? 'Réduire la liste'
                                        : 'Dérouler les ${itemsSeancesDuJour.length} séances',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                                    ),
                                  ),
                                  if (doitDerouler) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(ou faites défiler)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            // SÉANCES IMPAYÉES (MODULE DE GESTION & PAIEMENT DE MASSE)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Séances Impayées',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFDDB8),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${dashboard.seancesImpayes.length}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                // Chips de filtre
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Tout', 'Normale', 'Privée'].map((type) {
                      final selected = _filtreImpayes == type;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: isDark
                                  ? (selected ? const Color(0xFF070B16) : const Color(0xFF94A3B8))
                                  : (selected ? Colors.white : null),
                            ),
                          ),
                          selected: selected,
                          selectedColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF061449),
                          backgroundColor: isDark ? const Color(0xFF0F172E) : null,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          side: BorderSide(
                            color: selected ? Colors.transparent : (isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF)),
                            width: 1.2,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _filtreImpayes = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (dashboard.seancesImpayes.isEmpty || itemsImpayes.isEmpty)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF), width: 1.2),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Aucun impayé ! Tous les cours sont réglés.',
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF), width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Barre de sélection globale
                    Padding(
                       padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      child: Row(
                        children: [
                          Checkbox(
                            value: impayesFiltres.isNotEmpty &&
                                impayesFiltres.every((s) => _impayesSelectionnes.contains(s.idSeance)),
                            tristate: _impayesSelectionnes.isNotEmpty &&
                                !impayesFiltres.every((s) => _impayesSelectionnes.contains(s.idSeance)),
                            activeColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF061449),
                            checkColor: isDark ? const Color(0xFF070B16) : Colors.white,
                            side: isDark ? const BorderSide(color: Color(0x28FFFFFF), width: 1.2) : null,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _impayesSelectionnes.addAll(impayesFiltres.map((s) => s.idSeance));
                                } else {
                                  _impayesSelectionnes.removeAll(impayesFiltres.map((s) => s.idSeance));
                                }
                              });
                            },
                          ),
                          Text(
                            'Tout sélectionner (${impayesFiltres.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFE2E8F0) : null,
                            ),
                          ),
                          const Spacer(),
                          if (_impayesSelectionnes.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _isPayingMasse ? null : _reglerMasse,
                              icon: _isPayingMasse
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070B16)),
                                    )
                                  : const Icon(Icons.payment_rounded, size: 16),
                              label: Text('Payer (${NumberFormat('#,###').format(totalSelectionne)} DZD)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                                foregroundColor: isDark ? const Color(0xFF070B16) : Colors.white,
                                elevation: 0,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                    ),

                    // Liste consolidée des impayés (Groupes + Individuels)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemsImpayes.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? const Color(0x28FFFFFF) : const Color(0xFFE5EEFF),
                      ),
                      itemBuilder: (context, index) {
                        final item = itemsImpayes[index];

                        if (item.isGroupe) {
                          final allIds = item.seances.map((s) => s.idSeance).toSet();
                          final isAllSelected = allIds.isNotEmpty && allIds.every((id) => _impayesSelectionnes.contains(id));
                          final isSomeSelected = allIds.any((id) => _impayesSelectionnes.contains(id));
                          final retard = item.seances.fold<int>(0, (max, s) => s.joursRetard > max ? s.joursRetard : max);
                          final isAlerteRetard = retard > 7;
                          final dateParsed = DateTime.tryParse(item.dateSeance) ?? DateTime.now();
                          final dateStr = DateFormat('dd/MM/yyyy').format(dateParsed);

                          return Container(
                            color: isAllSelected
                                ? (isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.12) : const Color(0xFF061449).withValues(alpha: 0.06))
                                : (isSomeSelected
                                    ? (isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.06) : const Color(0xFF061449).withValues(alpha: 0.02))
                                    : Colors.transparent),
                            child: ListTile(
                              dense: true,
                              onTap: () => _ouvrirDialoguePointageGroupe(item),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Checkbox(
                                value: isAllSelected ? true : (isSomeSelected ? null : false),
                                tristate: true,
                                activeColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF061449),
                                checkColor: isDark ? const Color(0xFF070B16) : Colors.white,
                                side: isDark ? const BorderSide(color: Color(0x28FFFFFF), width: 1.2) : null,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _impayesSelectionnes.addAll(allIds);
                                    } else {
                                      _impayesSelectionnes.removeAll(allIds);
                                    }
                                  });
                                },
                              ),
                              title: Row(
                                children: [
                                  Icon(Icons.groups_rounded, size: 18, color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.titre,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFFE2E8F0) : null,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0x28FFFFFF) : const Color(0xFF006A61).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      '${item.seances.length} élèves',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (isAlerteRetard)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFBA1A1A),
                                        borderRadius: BorderRadius.circular(9999),
                                      ),
                                      child: Text(
                                        'Retard: ${retard}j',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFFECACA) : Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (retard > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: const EdgeInsets.only(left: 6),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFDDB8),
                                        borderRadius: BorderRadius.circular(9999),
                                      ),
                                      child: Text(
                                        '${retard}j',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '$dateStr${item.heure != null && item.heure!.isNotEmpty ? " • ${item.heure}" : ""} • ${item.typeSeance} • ${NumberFormat('#,###').format(item.totalMontant)} DZD',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.seances.map((s) => s.nomEleveEtNiveau).join(', '),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                                    label: const Text('Pointer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61),
                                      foregroundColor: isDark ? const Color(0xFF070B16) : Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      visualDensity: VisualDensity.compact,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _ouvrirDialoguePointageGroupe(item),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.cancel_outlined, color: isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A), size: 20),
                                    tooltip: 'Annuler la séance de groupe',
                                    onPressed: () => _annulerSeanceGroupe(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Séance individuelle
                        final s = item.seances.first;
                        final isSelected = _impayesSelectionnes.contains(s.idSeance);
                        final retard = s.joursRetard;
                        final isAlerteRetard = retard > 7;
                        final dateParsed = DateTime.tryParse(s.dateSeance) ?? DateTime.now();
                        final dateStr = DateFormat('dd/MM/yyyy').format(dateParsed);

                        return Container(
                          color: isSelected
                              ? (isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.12) : const Color(0xFF061449).withValues(alpha: 0.06))
                              : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF061449),
                              checkColor: isDark ? const Color(0xFF070B16) : Colors.white,
                              side: isDark ? const BorderSide(color: Color(0x28FFFFFF), width: 1.2) : null,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _impayesSelectionnes.add(s.idSeance);
                                  } else {
                                    _impayesSelectionnes.remove(s.idSeance);
                                  }
                                });
                              },
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.nomEleveEtNiveau,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFE2E8F0) : null,
                                    ),
                                  ),
                                ),
                                if (!s.estPayable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0x28FFFFFF) : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_clock_rounded, size: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                        const SizedBox(width: 3),
                                        Text('À venir', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                if (isAlerteRetard)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFBA1A1A),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      'Retard: ${retard}j',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFFECACA) : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else if (retard > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFDDB8),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Text(
                                      '${retard}j',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '$dateStr${s.heure != null && s.heure!.isNotEmpty ? " • ${s.heure}" : ""} • ${(s.nomGroupe != null && s.nomGroupe!.isNotEmpty) ? "👥 ${s.nomGroupe}" : (s.typeSeance == "Privée" ? "👤 Privée" : "👤 Individuelle")} • ${NumberFormat('#,###').format(s.montant)} DZD',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    s.estPayable ? Icons.check_circle_outline : Icons.lock_outline_rounded,
                                    color: s.estPayable ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF006A61)) : (isDark ? const Color(0xFF64748B) : Colors.grey),
                                    size: 22,
                                  ),
                                  tooltip: s.estPayable ? 'Régler maintenant' : 'Séance future (non payable)',
                                  onPressed: s.estPayable ? () => _payerIndividuel(s) : null,
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel_outlined, color: isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A), size: 20),
                                  tooltip: 'Annuler la séance',
                                  onPressed: () => _annulerSeance(s),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ÉVOLUTION DU CHIFFRE D'AFFAIRES (GRAPH fl_chart)
            Text(
              'Évolution du Chiffre d\'Affaires (6 derniers mois)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
              ),
            ),
            const SizedBox(height: 10),
            CaChart(chartData: dashboard.caChartData),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ONGLET 2 : ÉLÈVES (RECHERCHE & GESTION)
// ==========================================
class ElevesTab extends StatefulWidget {
  const ElevesTab({super.key});

  @override
  State<ElevesTab> createState() => _ElevesTabState();
}

class _ElevesTabState extends State<ElevesTab> {
  final _searchController = TextEditingController();
  List<Eleve> _eleves = [];
  bool _isLoading = true;
  String? _error;
  String _filtreStatut = 'Tous'; // 'Tous', 'Actif', 'Inactif'
  int _selectedSubTab = 0; // 0: Élèves, 1: Groupes

  @override
  void initState() {
    super.initState();
    recharger();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> recharger() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.getEleves(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        statut: _filtreStatut == 'Tous' ? null : _filtreStatut,
      );
      if (mounted) {
        setState(() {
          _eleves = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _ajouterEleve() async {
    final Eleve? nouvelEleve = await showDialog<Eleve>(
      context: context,
      builder: (context) => const NouvelEleveDialog(),
    );
    if (!mounted) return;
    if (nouvelEleve != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('Élève ${nouvelEleve.nom} ajouté avec succès !'),
        ),
      );
      recharger();
    }
  }

  void _appeler(String? telephone) async {
    if (telephone == null || telephone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun numéro de téléphone renseigné pour cet élève')),
      );
      return;
    }
    final uri = Uri.parse('tel:${telephone.trim().replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de composer le numéro : $telephone')),
        );
      }
    }
  }

  void _ouvrirFiche(Eleve eleve) {
    showDialog(
      context: context,
      builder: (context) => FicheEleveDialog(eleve: eleve),
    );
  }

  void _basculerStatut(Eleve eleve) async {
    final nouveauStatut = eleve.isActif ? 'Inactif' : 'Actif';
    try {
      await ApiService.toggleStatutEleve(eleve.idEleve, nouveauStatut: nouveauStatut);
      recharger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _supprimerEleve(Eleve eleve) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Supprimer l\'élève ?'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${eleve.nom}" ?\n\n'
          '⚠️ Règle métier : Toutes les séances passées et leur historique comptable seront conservés avec le nom figé, mais l\'élève n\'apparaîtra plus dans les nouvelles listes.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await ApiService.supprimerEleve(eleve.idEleve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Élève ${eleve.nom} supprimé')),
        );
        recharger();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Erreur suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedSubTab == 1) {
      return GroupesScreen(
        onBack: () => setState(() => _selectedSubTab = 0),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterEleve,
        backgroundColor: isDark ? const Color(0xFF2CE5A7) : const Color(0xFF061449),
        foregroundColor: isDark ? const Color(0xFF0B0D1B) : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Nouvel Élève', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Commutateur Élèves / Groupes
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            color: isDark ? const Color(0xFF0B0D1B) : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16192E) : const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF252A4A) : const Color(0xFFE5EEFF),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedSubTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedSubTab == 0
                              ? (isDark ? const Color(0xFF2CE5A7) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSubTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Élèves (${_eleves.length})',
                            style: TextStyle(
                              fontWeight: _selectedSubTab == 0 ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              color: _selectedSubTab == 0
                                  ? (isDark ? const Color(0xFF0B0D1B) : const Color(0xFF061449))
                                  : (isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedSubTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedSubTab == 1
                              ? (isDark ? const Color(0xFF2CE5A7) : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedSubTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: _selectedSubTab == 1
                                    ? (isDark ? const Color(0xFF0B0D1B) : const Color(0xFF061449))
                                    : (isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Groupes',
                                style: TextStyle(
                                  fontWeight: _selectedSubTab == 1 ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                  color: _selectedSubTab == 1
                                      ? (isDark ? const Color(0xFF0B0D1B) : const Color(0xFF061449))
                                      : (isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0D1B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF252A4A) : const Color(0xFFE5EEFF),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => recharger(),
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF061449),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un élève par nom...',
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF061449),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              size: 18,
                              color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              recharger();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF16192E) : const Color(0xFFEFF4FF),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: isDark ? const BorderSide(color: Color(0xFF252A4A), width: 1.2) : BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: isDark ? const BorderSide(color: Color(0xFF252A4A), width: 1.2) : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9999),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2CE5A7) : const Color(0xFF061449),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Statut : ', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689))),
                    const SizedBox(width: 6),
                    Wrap(
                      spacing: 6,
                      children: ['Tous', 'Actif', 'Inactif'].map((st) {
                        final selected = _filtreStatut == st;
                        return ChoiceChip(
                          label: Text(
                            st,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                              color: selected
                                  ? (isDark ? const Color(0xFF0B0D1B) : Colors.white)
                                  : (isDark ? const Color(0xFF8E95B3) : const Color(0xFF061449)),
                            ),
                          ),
                          selected: selected,
                          selectedColor: isDark ? const Color(0xFF2CE5A7) : const Color(0xFF061449),
                          backgroundColor: isDark ? const Color(0xFF16192E) : const Color(0xFFEFF4FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: selected
                                ? (isDark ? const Color(0xFF2CE5A7) : const Color(0xFF061449))
                                : (isDark ? const Color(0xFF252A4A) : const Color(0xFFE5EEFF)),
                            width: 1.2,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _filtreStatut = st);
                              recharger();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Text(
                      '${_eleves.length} élève(s)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF061449),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des élèves
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text(_error!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: recharger,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF061449),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _eleves.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_search_rounded, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun élève trouvé',
                                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                            itemCount: _eleves.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final e = _eleves[index];
                              final isActif = e.isActif;
                              final pastelColors = [
                                const Color(0xFF2DD4BF), // Menthe pastel
                                const Color(0xFFFB7185), // Corail pastel
                                const Color(0xFFA5B4FC), // Lavande pastel
                                const Color(0xFFFDE047), // Jaune pastel
                              ];
                              final cardAccentColor = pastelColors[index % pastelColors.length];

                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF16192E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF252A4A) : const Color(0xFFE5EEFF),
                                    width: 1.2,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF061449).withValues(alpha: 0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => _ouvrirFiche(e),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(14.0),
                                        child: Row(
                                          children: [
                                            // Avatar avec coins arrondis pastel (Photo 3)
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                color: isActif ? cardAccentColor : Colors.grey.withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(13),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                e.nom.isNotEmpty ? e.nom[0].toUpperCase() : '?',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18,
                                                  color: Color(0xFF0B0D1B),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            // Détails élève
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          e.nom,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 15,
                                                            color: isDark ? Colors.white : const Color(0xFF061449),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                                        decoration: BoxDecoration(
                                                          color: isActif
                                                              ? (isDark ? const Color(0xFF2CE5A7).withValues(alpha: 0.15) : const Color(0xFF86F2E4))
                                                              : Colors.grey.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(9999),
                                                          border: Border.all(
                                                            color: isActif
                                                                ? (isDark ? const Color(0xFF2CE5A7) : const Color(0xFF006F66))
                                                                : Colors.grey.withValues(alpha: 0.4),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          e.statut,
                                                          style: TextStyle(
                                                            color: isActif
                                                                ? (isDark ? const Color(0xFF2CE5A7) : const Color(0xFF006F66))
                                                                : (isDark ? const Color(0xFF8E95B3) : Colors.grey[700]),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                      if (e.sansGroupe) ...[
                                                        const SizedBox(width: 6),
                                                        InkWell(
                                                          onTap: () => _ouvrirFiche(e),
                                                          borderRadius: BorderRadius.circular(9999),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                            decoration: BoxDecoration(
                                                              color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFFDDB8),
                                                              borderRadius: BorderRadius.circular(9999),
                                                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(Icons.group_add_rounded, size: 11, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F)),
                                                                const SizedBox(width: 3),
                                                                Text('Sans groupe', style: TextStyle(color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F), fontWeight: FontWeight.bold, fontSize: 10)),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      if (e.niveau != null && e.niveau!.isNotEmpty) ...[
                                                        Icon(
                                                          Icons.school_outlined,
                                                          size: 14,
                                                          color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          e.niveau!,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                      ],
                                                      if (e.telephone != null && e.telephone!.isNotEmpty) ...[
                                                        Icon(
                                                          Icons.phone_outlined,
                                                          size: 14,
                                                          color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          e.telephone!,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF5A6689),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Actions
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Appel direct
                                                if (e.telephone != null && e.telephone!.isNotEmpty)
                                                  IconButton(
                                                    icon: Icon(Icons.call_rounded, color: isDark ? const Color(0xFF2CE5A7) : const Color(0xFF006A61), size: 20),
                                                    tooltip: 'Appeler',
                                                    onPressed: () => _appeler(e.telephone),
                                                  ),
                                                // Fiche
                                                IconButton(
                                                  icon: Icon(Icons.receipt_long_rounded, color: isDark ? const Color(0xFF8E95B3) : const Color(0xFF061449), size: 20),
                                                  tooltip: 'Fiche Élève',
                                                  onPressed: () => _ouvrirFiche(e),
                                                ),
                                                // Menu contextuel
                                                PopupMenuButton<String>(
                                                  icon: Icon(Icons.more_vert_rounded, color: isDark ? const Color(0xFF8E95B3) : null, size: 20),
                                                  color: isDark ? const Color(0xFF16192E) : null,
                                                  onSelected: (val) {
                                                    if (val == 'affecter') _ouvrirFiche(e);
                                                    if (val == 'statut') _basculerStatut(e);
                                                    if (val == 'supprimer') _supprimerEleve(e);
                                                  },
                                                  itemBuilder: (context) => [
                                                    if (e.sansGroupe)
                                                      const PopupMenuItem(
                                                        value: 'affecter',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.group_add_rounded, color: Color(0xFFD97706), size: 18),
                                                            SizedBox(width: 8),
                                                            Text('Affecter à un groupe', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                                                          ],
                                                        ),
                                                      ),
                                                    PopupMenuItem(
                                                      value: 'statut',
                                                      child: Row(
                                                        children: [
                                                          Icon(isActif ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                                                          const SizedBox(width: 8),
                                                          Text(isActif ? 'Marquer Inactif' : 'Marquer Actif'),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'supprimer',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                                          SizedBox(width: 8),
                                                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Barre inférieure d'accent pastel (Photo 3)
                                      Container(
                                        height: 4,
                                        width: double.infinity,
                                        color: isDark ? cardAccentColor : cardAccentColor.withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ONGLET 3 : FINANCE (HISTORIQUE & CLÔTURE)
// ==========================================
class FinanceTab extends StatefulWidget {
  const FinanceTab({super.key});

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  List<Seance> _seancesPayees = [];
  List<Seance> _seancesImpayees = [];
  List<ClotureMensuelle> _clotures = [];
  bool _isLoading = true;
  String? _error;
  int _subTabIndex = 0; // 0: En attente, 1: Non payées, 2: Archives des clôtures

  @override
  void initState() {
    super.initState();
    recharger();
  }

  Future<void> recharger() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getFinanceHistorique(),
        ApiService.getFinanceImpayees(),
        ApiService.getClotures(),
      ]);

      if (mounted) {
        setState(() {
          _seancesPayees = results[0] as List<Seance>;
          _seancesImpayees = results[1] as List<Seance>;
          _clotures = results[2] as List<ClotureMensuelle>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _encaisser(Seance s) async {
    if (!s.estPayable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFF59E0B),
            content: Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Impossible d\'encaisser une séance planifiée avant sa date et son heure.'),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    try {
      await ApiService.marquerPayee(s.idSeance);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Séance de ${s.nomEleve} encaissée (${s.montant} DZD) !')),
              ],
            ),
          ),
        );
      }
      await recharger();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur : $err'),
          ),
        );
      }
    }
  }

  Future<void> _ouvrirDialoguePointageGroupe(ItemImpaye item) async {
    await afficherDialoguePointageGroupe(
      context: context,
      item: item,
      onComplete: recharger,
    );
  }

  void _cloturerMoisFinance() async {
    final totalEncaisse = _seancesPayees.fold<int>(0, (sum, s) => sum + s.montant);

    if (_seancesPayees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune séance payée en attente de clôture.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.archive_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text('Clôturer & Archiver ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Vous êtes sur le point de clôturer le mois en cours :\n\n'
            '• Chiffre d\'affaires à clôturer : ${NumberFormat('#,###').format(totalEncaisse)} DZD\n'
            '• Nombre de séances payées : ${_seancesPayees.length}\n\n'
            'Cette action va archiver l\'historique complet directement dans l\'application (aucun email n\'est envoyé).\n\n'
            'L\'archive sera consultable à tout moment dans le sous-onglet "Archives".',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Clôturer & Archiver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );

    if (confirme != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Archivage du mois en cours dans l\'application...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    try {
      final res = await ApiService.cloturerMois();
      if (!mounted) return;
      if (res['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Aucune séance payée à clôturer.'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text('Clôture Archivée !'),
            ],
          ),
          content: Text(
            '${res['message']}\n\n'
            '• Séances archivées : ${res['seances_cloturees'] ?? 0}\n'
            '• Chiffre d\'affaires archivé : ${NumberFormat('#,###').format(res['total_verse_da'] ?? 0)} DZD\n\n'
            'Le compteur d\'encaissé a été réinitialisé à 0 DZD. Les séances impayées restent actives jusqu\'à leur règlement.\n\n'
            'L\'archive est sauvegardée dans votre historique in-app consultable dans l\'onglet "Archives".',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _subTabIndex = 2; // Basculer automatiquement sur l'onglet Archives
                });
              },
              child: const Text('Voir l\'archive'),
            ),
          ],
        ),
      );
      recharger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Erreur : $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalEncaisse = _seancesPayees.fold<int>(0, (sum, s) => sum + s.montant);
    final totalImpaye = _seancesImpayees.fold<int>(0, (sum, s) => sum + s.montant);
    final totalArchive = _clotures.fold<int>(0, (sum, c) => sum + c.caTotal);
    final countRetard3j = _seancesImpayees.where((s) => s.joursRetard >= 3).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: recharger,
        color: const Color(0xFF006A61),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNIÈRE EN-TÊTE FINANCE (BENTO HERO AVEC LES 3 MÉTRIQUES)
              Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF061449), Color(0xFF131D42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF233166)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF061449).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFF86F2E4).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFF86F2E4).withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.account_balance_wallet_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF86F2E4), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tableau de Bord Financier',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF86F2E4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${NumberFormat('#,###').format(totalEncaisse)} DZD',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'En attente de clôture mensuelle (${_seancesPayees.length} séances)',
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFF233166), height: 1),
                      const SizedBox(height: 14),
                      // 2 Cartes récapitulatives en ligne
                      Row(
                        children: [
                          // Carte Impayés
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (countRetard3j > 0
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B))
                                    .withValues(alpha: isDark ? 0.15 : 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: (countRetard3j > 0
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFFF59E0B))
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        countRetard3j > 0 ? Icons.warning_rounded : Icons.pending_actions_rounded,
                                        size: 15,
                                        color: countRetard3j > 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Impayés',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: countRetard3j > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${NumberFormat('#,###').format(totalImpaye)} DZD',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: countRetard3j > 0 ? const Color(0xFFFCA5A5) : (isDark ? const Color(0xFFE2E8F0) : Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${_seancesImpayees.length} séance(s)${countRetard3j > 0 ? " • $countRetard3j > 3j" : ""}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Carte Total Archivé
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFF60A5FA).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFF60A5FA).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 15, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF60A5FA)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Total Archivé',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFFBFDBFE),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${NumberFormat('#,###').format(totalArchive)} DZD',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${_clotures.length} clôture(s) archivée(s)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // SÉLECTEUR DE SOUS-ONGLETS (SEGMENTED TABS)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    // Onglet 0 : En attente
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _subTabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _subTabIndex == 0
                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _subTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'En attente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _subTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                    color: _subTabIndex == 0
                                        ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449))
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F766E).withValues(alpha: 0.3) : const Color(0xFF006A61).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_seancesPayees.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF006A61),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Onglet 1 : Non payées
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _subTabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _subTabIndex == 1
                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _subTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Non payées',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _subTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: _subTabIndex == 1
                                        ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449))
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: (countRetard3j > 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_seancesImpayees.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: countRetard3j > 0 ? const Color(0xFFEF4444) : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Onglet 2 : Archives des clôtures
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _subTabIndex = 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _subTabIndex == 2
                                ? (isDark ? const Color(0xFF334155) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _subTabIndex == 2
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Archives',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _subTabIndex == 2 ? FontWeight.bold : FontWeight.w500,
                                    color: _subTabIndex == 2
                                        ? (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449))
                                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFF60A5FA).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_clotures.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF006A61)),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 32),
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : Colors.black87)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: recharger,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF061449),
                            foregroundColor: isDark ? const Color(0xFFE2E8F0) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_subTabIndex == 0)
                _buildSousOngletEnAttente(isDark, totalEncaisse)
              else if (_subTabIndex == 1)
                _buildSousOngletImpayees(isDark, countRetard3j)
              else
                _buildSousOngletArchives(isDark),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // VUE 0 : SÉANCES EN ATTENTE DE CLÔTURE
  // -------------------------------------------------------------
  Widget _buildSousOngletEnAttente(bool isDark, int totalEncaisse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Clôturer
        Row(
          children: [
            Expanded(
              child: Text(
                'Séances Encaissées (${_seancesPayees.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                ),
              ),
            ),
            if (_seancesPayees.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _cloturerMoisFinance,
                icon: const Icon(Icons.archive_rounded, size: 16),
                label: const Text('Clôturer le mois', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_seancesPayees.isEmpty)
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5EEFF)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune séance payée en attente de clôture',
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toutes les séances payées précédentes ont été clôturées et archivées dans l\'application.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5EEFF)),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF061449).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _seancesPayees.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE5EEFF),
              ),
              itemBuilder: (context, index) {
                final s = _seancesPayees[index];
                final dateSeanceStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(s.dateSeance));
                final datePaiementStr = s.datePaiement != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(s.datePaiement!))
                    : 'Récemment';

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF86F2E4).withValues(alpha: 0.3),
                    child: Icon(Icons.arrow_downward_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF006A61), size: 20),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.nomEleveEtNiveau,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                          ),
                        ),
                      ),
                      Text(
                        '+ ${NumberFormat('#,###').format(s.montant)} DZD',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF006A61),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Séance : $dateSeanceStr (${(s.nomGroupe != null && s.nomGroupe!.isNotEmpty) ? "👥 ${s.nomGroupe}" : (s.typeSeance == "Privée" ? "👤 Privée" : "👤 Individuelle")}) • Encaissé le : $datePaiementStr',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6689)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // VUE 1 : SÉANCES NON PAYÉES / IMPAYÉS (AVEC RETARD & ENCAISSEMENT DIRECT)
  // -------------------------------------------------------------
  Widget _buildSousOngletImpayees(bool isDark, int countRetard3j) {
    // Regroupement identique à l'accueil pour les séances de groupe
    final Map<String, List<Seance>> groupMap = {};
    final List<String> groupOrder = [];

    for (final s in _seancesImpayees) {
      final key = (s.idSeanceGroupe != null && s.idSeanceGroupe!.isNotEmpty)
          ? 'seance_grp_${s.idSeanceGroupe}'
          : ((s.idGroupe != null && s.idGroupe!.isNotEmpty)
              ? 'grp_${s.idGroupe}_${s.dateSeance}_${s.heure ?? ""}'
              : 'ind_${s.idSeance}');

      if (!groupMap.containsKey(key)) {
        groupMap[key] = [];
        groupOrder.add(key);
      }
      groupMap[key]!.add(s);
    }

    final List<ItemImpaye> itemsImpayes = [];
    for (final key in groupOrder) {
      final list = groupMap[key]!;
      if (list.length > 1) {
        final first = list.first;
        final nomGroupe = (first.nomGroupe != null && first.nomGroupe!.isNotEmpty)
            ? first.nomGroupe!
            : 'Séance de groupe';
        itemsImpayes.add(
          ItemImpaye.groupe(
            nomGroupe: nomGroupe,
            dateSeance: first.dateSeance,
            heure: first.heure,
            typeSeance: first.typeSeance,
            seances: list,
          ),
        );
      } else {
        itemsImpayes.add(ItemImpaye.individuel(list.first));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Séances Non Payées (${_seancesImpayees.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                ),
              ),
            ),
            if (countRetard3j > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$countRetard3j en retard > 3j',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Suivi des cours dispensés en attente de règlement par les parents ou élèves.',
          style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        if (itemsImpayes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5EEFF)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun impayé en cours !',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toutes les séances dispensées ont été réglées par vos élèves.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsImpayes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = itemsImpayes[index];

              if (item.isGroupe) {
                final dateSeanceStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(item.dateSeance));
                final retardMax = item.joursRetardMax;
                final isCritique = retardMax >= 3;
                final isPayable = item.seances.any((s) => s.estPayable);

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCritique
                          ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.35)),
                      width: isCritique ? 1.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF006A61).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.groups_rounded, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF006A61), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.titre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Groupe • ${item.seances.length} élèves • $dateSeanceStr${item.heure != null ? " • ${item.heure}" : ""}',
                                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCritique
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFF006A61).withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${NumberFormat('#,###').format(item.montantTotal)} DZD',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: isCritique ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF34D399) : const Color(0xFF006A61)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCritique
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                  : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCritique ? Icons.error_rounded : Icons.schedule_rounded,
                                  size: 13,
                                  color: isCritique ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCritique
                                      ? '🔴 En retard ($retardMax j)'
                                      : '⏳ Non payé ($retardMax j)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isCritique ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _ouvrirDialoguePointageGroupe(item),
                            icon: Icon(
                              isPayable ? Icons.how_to_reg_rounded : Icons.lock_clock_rounded,
                              size: 15,
                            ),
                            label: Text(
                              isPayable ? 'Pointer / Encaisser' : 'À venir (Verrouillé)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPayable ? const Color(0xFF006A61) : (isDark ? const Color(0xFF334155) : Colors.grey[400]),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              // Cas individuel
              final s = item.seance!;
              final retard = s.joursRetard;
              final isCritique = retard >= 3;
              final dateSeanceStr = DateFormat('dd/MM/yyyy').format(DateTime.parse(s.dateSeance));

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCritique
                        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isCritique ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCritique
                          ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.nomEleveEtNiveau,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF061449),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCritique
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF59E0B).withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${NumberFormat('#,###').format(s.montant)} DZD',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isCritique ? const Color(0xFFEF4444) : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Séance : $dateSeanceStr (${(s.nomGroupe != null && s.nomGroupe!.isNotEmpty) ? "👥 ${s.nomGroupe}" : (s.typeSeance == "Privée" ? "👤 Privée" : "👤 Individuelle")})${s.heure != null ? " • ${s.heure}" : ""}',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCritique
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCritique ? Icons.error_rounded : Icons.schedule_rounded,
                                size: 13,
                                color: isCritique ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCritique
                                    ? '🔴 En retard de $retard jours'
                                    : '⏳ Non payé ($retard j)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCritique ? const Color(0xFFEF4444) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: s.estPayable ? () => _encaisser(s) : null,
                          icon: Icon(
                            s.estPayable ? Icons.check_circle_outline_rounded : Icons.lock_clock_rounded,
                            size: 15,
                          ),
                          label: Text(
                            s.estPayable ? 'Encaisser' : 'À venir',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: s.estPayable ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : Colors.grey[400]),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300],
                            disabledForegroundColor: isDark ? const Color(0xFF64748B) : Colors.grey[600],
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // VUE 2 : ARCHIVES DES CLÔTURES MENSUELLES (HISTORIQUE CONSULTABLE)
  // -------------------------------------------------------------
  Widget _buildSousOngletArchives(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Historique des Clôtures Archivées (${_clotures.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF061449),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Archives mensuelles conservées en base de données. Déroulez chaque mois pour voir le détail par élève.',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),

        if (_clotures.isEmpty)
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D42) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.archive_outlined, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune clôture archivée pour le moment',
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey[300] : const Color(0xFF061449)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lorsque vous clôturez un mois de séances payées, son historique complet apparaîtra ici avec le détail par élève.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _clotures.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = _clotures[index];
              final dateClotureStr = DateFormat('dd/MM/yyyy à HH:mm').format(c.dateCloture);

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D42) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF233166) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.moisNom,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF061449),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Archivé in-app',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Clôturé le $dateClotureStr',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${NumberFormat('#,###').format(c.caTotal)} DZD',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF006A61),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${c.totalSeances} séance(s) • ${c.totalEleves} élève(s)',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : const Color(0xFF45464F)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF006A61)),
                          const SizedBox(width: 6),
                          Text(
                            'Récapitulatif par élève :',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF061449),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (c.recapEleves.isEmpty)
                        Text(
                          'Aucun détail d\'élève enregistré.',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: c.recapEleves.length,
                          itemBuilder: (context, elIndex) {
                            final el = c.recapEleves[elIndex];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF061449).withValues(alpha: 0.1),
                                    child: Text(
                                      el.nom.isNotEmpty ? el.nom[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF061449)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      el.nom,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[200] : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${el.nombreSeances} séance(s) : ',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###').format(el.montantTotal)} DZD',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A61),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

