import 'package:flutter/material.dart';
import '../models/prof_profile.dart';
import '../models/app_notification.dart';

class AppDrawer extends StatefulWidget {
  final int currentTabIndex;
  final Function(int index) onSelectTab;
  final VoidCallback onOpenGroupes;
  final VoidCallback onOpenHistoriquePaiements;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLandingReview;
  final ProfProfile? profProfile;
  final NotificationsSummary? notifSummary;

  const AppDrawer({
    super.key,
    required this.currentTabIndex,
    required this.onSelectTab,
    required this.onOpenGroupes,
    required this.onOpenHistoriquePaiements,
    required this.onOpenSettings,
    required this.onOpenLandingReview,
    this.profProfile,
    this.notifSummary,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    // Animation d'entrée en cascade (staggered) à l'ouverture du tiroir
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _entranceController.forward();

    // Animation continue douce pour le halo de l'avatar et le badge NOUVEAU
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSelected = false,
    Widget? trailingBadge,
    Color? accentColor,
  }) {
    // Calcul de l'intervalle pour l'effet cascade
    final double start = (0.1 + index * 0.07).clamp(0.0, 0.75);
    final double end = (start + 0.35).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = accentColor ?? (isSelected ? const Color(0xFF006A61) : null);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(35 * (1 - animation.value), 0),
          child: Transform.scale(
            scale: 0.94 + (0.06 * animation.value),
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: animation.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF1E2A5E).withValues(alpha: 0.65)
                  : const Color(0xFF061449).withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? const Color(0xFF86F2E4).withValues(alpha: 0.5)
                      : const Color(0xFF006A61).withValues(alpha: 0.35),
                  width: 1.4,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Barre d'accentuation verticale à gauche pour l'élément actif
            if (isSelected)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF006A61), Color(0xFF86F2E4)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

            ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF061449)
                      : (itemColor != null
                          ? itemColor.withValues(alpha: 0.14)
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF061449).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: isSelected
                      ? const Color(0xFF86F2E4)
                      : (itemColor ?? (isDark ? Colors.white70 : const Color(0xFF1E2A5E))),
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF061449))
                      : (isDark ? Colors.grey[200] : const Color(0xFF1E2A5E)),
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              trailing: trailingBadge,
              onTap: () {
                Navigator.of(context).pop(); // Fermer le drawer
                onTap();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prof = widget.profProfile;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0A1128) : const Color(0xFFF8F9FF),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // En-tête profil avec dégradé Navy/Indigo et halo animé
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 22,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar animé avec lueur pulsante
                      AnimatedBuilder(
                        animation: _ambientController,
                        builder: (context, child) {
                          final pulse = _ambientController.value;
                          return Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.lerp(
                                  const Color(0xFF86F2E4),
                                  const Color(0xFF006A61),
                                  pulse,
                                )!,
                                width: 2 + (0.8 * pulse),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF86F2E4)
                                      .withValues(alpha: 0.25 + (0.25 * pulse)),
                                  blurRadius: 10 + (6 * pulse),
                                  spreadRadius: 1 + (2 * pulse),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF131D42),
                          child: Icon(
                            prof?.avatarIcon ?? Icons.school_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prof?.nomComplet.isNotEmpty == true
                                  ? prof!.nomComplet
                                  : (prof?.nom.isNotEmpty == true ? prof!.nom : 'Enseignant'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              prof?.specialite.isNotEmpty == true
                                  ? prof!.specialite
                                  : (prof?.telephone.isNotEmpty == true
                                      ? prof!.telephone
                                      : 'Gestion Cours de Soutien'),
                              style: const TextStyle(
                                color: Color(0xFF86F2E4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (prof?.specialite.isNotEmpty == true && prof?.telephone.isNotEmpty == true) ...[
                              const SizedBox(height: 2),
                              Text(
                                prof!.telephone,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (prof != null && prof.matieres.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: prof.matieres.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            m,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Liste des options animées
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'ESPACE PRINCIPAL',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),

                  // 1. Tableau de bord
                  _buildAnimatedItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    title: 'Tableau de bord',
                    subtitle: 'Statistiques & séances du jour',
                    isSelected: widget.currentTabIndex == 0,
                    onTap: () => widget.onSelectTab(0),
                  ),

                  // 2. Élèves
                  _buildAnimatedItem(
                    index: 1,
                    icon: Icons.people_alt_rounded,
                    title: 'Répertoire Élèves',
                    subtitle: 'Fiches, coordonnées & niveaux',
                    isSelected: widget.currentTabIndex == 1,
                    onTap: () => widget.onSelectTab(1),
                  ),

                  // 3. NOUVEAU : Groupes (avec badge pulsant)
                  _buildAnimatedItem(
                    index: 2,
                    icon: Icons.groups_2_rounded,
                    title: 'Groupes de Soutien',
                    subtitle: 'Affectation, séances & paiement groupé',
                    accentColor: const Color(0xFF006A61),
                    trailingBadge: AnimatedBuilder(
                      animation: _ambientController,
                      builder: (context, _) {
                        final val = _ambientController.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF006A61), Color(0xFF86F2E4)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF006A61)
                                    .withValues(alpha: 0.3 + (0.3 * val)),
                                blurRadius: 6 + (4 * val),
                                spreadRadius: 0.5 * val,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: widget.onOpenGroupes,
                  ),

                  // 4. Finances
                  _buildAnimatedItem(
                    index: 3,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Finances & Règlements',
                    subtitle: 'Suivi des impayés & chiffre d\'affaires',
                    isSelected: widget.currentTabIndex == 2,
                    accentColor: const Color(0xFFFFB95F),
                    trailingBadge: (widget.notifSummary != null &&
                            widget.notifSummary!.countImpayes > 0)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              '${widget.notifSummary!.countImpayes}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => widget.onSelectTab(2),
                  ),

                  // 5. NOUVEAU : Historique des Paiements
                  _buildAnimatedItem(
                    index: 4,
                    icon: Icons.history_edu_rounded,
                    title: 'Historique des Paiements',
                    subtitle: 'Flux encaissé & archives mensuelles',
                    accentColor: const Color(0xFF10B981),
                    onTap: widget.onOpenHistoriquePaiements,
                  ),

                  // 6. Notes pédagogiques
                  _buildAnimatedItem(
                    index: 5,
                    icon: Icons.note_alt_rounded,
                    title: 'Notes Pédagogiques',
                    subtitle: 'Devoirs, remarques & mémos',
                    isSelected: widget.currentTabIndex == 3,
                    onTap: () => widget.onSelectTab(3),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Divider(height: 1),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'PRÉFÉRENCES & INFOS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),

                  // 7. Paramètres & Tarifs
                  _buildAnimatedItem(
                    index: 6,
                    icon: Icons.settings_rounded,
                    title: 'Paramètres & Tarifs DZD',
                    subtitle: 'Matières, tarifs de base & profil',
                    onTap: widget.onOpenSettings,
                  ),

                  // 8. Présentation de l'application
                  _buildAnimatedItem(
                    index: 7,
                    icon: Icons.info_outline_rounded,
                    title: 'À propos & Guide',
                    subtitle: 'Revoir la présentation complète',
                    onTap: widget.onOpenLandingReview,
                  ),
                ],
              ),
            ),

            // Pied du Drawer avec version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: Color(0xFF006A61),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gestion Cours de Soutien • v1.2',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
