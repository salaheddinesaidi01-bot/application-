import 'package:flutter/material.dart';
import '../models/prof_profile.dart';
import '../screens/landing_screen.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import 'prof_profile_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  ProfProfile? _profProfile;
  bool _isLoading = true;
  bool _profileUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    ProfProfile? prof;
    try {
      prof = await ApiService.getProfProfile();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profProfile = prof;
        _isLoading = false;
      });
    }
  }

  Future<void> _modifierProfil() async {
    final updated = await showDialog<ProfProfile>(
      context: context,
      builder: (_) => ProfProfileDialog(currentProfile: _profProfile),
    );
    if (updated != null && mounted) {
      setState(() {
        _profProfile = updated;
        _profileUpdated = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil et tarifs mis à jour avec succès !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmerChangementEnseignant() async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Changer d\'enseignant ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Voulez-vous réinitialiser le compte enseignant ?\n\n'
          'Vous serez redirigé vers l\'assistant d\'accueil pour créer et configurer un nouveau profil avec son nom, ses matières et ses tarifs.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser le compte'),
          ),
        ],
      ),
    );

    if (conf == true && mounted) {
      await ApiService.resetProfProfile();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmerResetDonnees() async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Vider les données locales ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Attention : Cette action efface tous les élèves, groupes, séances et paiements enregistrés localement sur le téléphone.\n\nVotre profil enseignant sera conservé.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer l\'effacement'),
          ),
        ],
      ),
    );

    if (conf == true && mounted) {
      await LocalDbService.instance.resetAllData(keepProfile: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données locales réinitialisées avec succès.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  void _voirPresentation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LandingScreen(isReviewMode: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF061449);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF131D42) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: _isLoading
              ? const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête Paramètres
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tune_rounded, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Paramètres & Configuration',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  'Gérer vos tarifs et votre profil',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(_profileUpdated),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SECTION 1 : Profil Enseignant & Tarifs
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    _profProfile?.avatarIcon ?? Icons.school_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profil Enseignant & Tarifs',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                                        ),
                                      ),
                                      Text(
                                        _profProfile?.nomComplet.isNotEmpty == true
                                            ? _profProfile!.nomComplet
                                            : (_profProfile?.nom.isNotEmpty == true
                                                ? _profProfile!.nom
                                                : 'Nom non configuré'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _profProfile?.isConfigured == true ? 'Configuré' : 'À configurer',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_profProfile?.telephone.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _profProfile!.telephone,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                            if (_profProfile != null && _profProfile!.matieres.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: _profProfile!.matieres.map((m) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF131D42) : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      m,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Grille des prix déclarés en DZD
                            const Text(
                              'Tarifs configurés :',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTarifBadge(
                                    'Normale 1',
                                    '${_profProfile?.prixNormale1 ?? 0} DZD',
                                    const Color(0xFF3B82F6),
                                    isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if ((_profProfile?.prixNormale2 ?? 0) > 0) ...[
                                  Expanded(
                                    child: _buildTarifBadge(
                                      'Normale 2',
                                      '${_profProfile!.prixNormale2} DZD',
                                      const Color(0xFF3B82F6),
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: _buildTarifBadge(
                                    'Privée 1',
                                    '${_profProfile?.prixPrivee1 ?? 0} DZD',
                                    const Color(0xFF006A61),
                                    isDark,
                                  ),
                                ),
                                if ((_profProfile?.prixPrivee2 ?? 0) > 0) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildTarifBadge(
                                      'Privée 2',
                                      '${_profProfile!.prixPrivee2} DZD',
                                      const Color(0xFF006A61),
                                      isDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Boutons Modifier Profil & Changer Compte
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _modifierProfil,
                                    icon: const Icon(Icons.edit_outlined, size: 15),
                                    label: const Text('Modifier profil', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _confirmerChangementEnseignant,
                                  icon: const Icon(Icons.switch_account_rounded, size: 15, color: Colors.orange),
                                  label: const Text('Changer compte', style: TextStyle(fontSize: 12, color: Colors.orange)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.orange),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Lien vers la Présentation / Landing
                      InkWell(
                        onTap: _voirPresentation,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131D42) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Revoir la présentation de l\'application',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[200] : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Données Locales & Confidentialité
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Données & Confidentialité',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Toutes vos données (élèves, séances, paiements) sont stockées de façon sécurisée et privée directement sur votre appareil.',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _confirmerResetDonnees,
                                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                                label: const Text('Vider les données locales', style: TextStyle(fontSize: 11.5, color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Fermer
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(_profileUpdated),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Fermer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTarifBadge(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
