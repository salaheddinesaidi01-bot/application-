import 'package:flutter/material.dart';
import '../models/groupe.dart';
import '../models/prof_profile.dart';
import '../services/api_service.dart';
import '../widgets/nouveau_groupe_dialog.dart';
import '../widgets/seance_groupe_dialog.dart';

class GroupesScreen extends StatefulWidget {
  final ProfProfile? profProfile;
  final VoidCallback? onBack;

  const GroupesScreen({super.key, this.profProfile, this.onBack});

  @override
  State<GroupesScreen> createState() => _GroupesScreenState();
}

class _GroupesScreenState extends State<GroupesScreen> {
  List<Groupe> _groupes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();
  final Set<String> _groupesDeplies = {};

  @override
  void initState() {
    super.initState();
    _chargerGroupes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerGroupes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await ApiService.getGroupes();
      if (mounted) {
        setState(() {
          _groupes = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des groupes : $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _creerGroupe() async {
    final nouveau = await showDialog<Groupe>(
      context: context,
      builder: (_) => const NouveauGroupeDialog(),
    );
    if (!mounted) return;
    if (nouveau != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Groupe "${nouveau.nom}" créé avec succès !'),
          backgroundColor: const Color(0xFF006A61),
        ),
      );
      _chargerGroupes();
    }
  }

  Future<void> _modifierGroupe(Groupe g) async {
    final modifie = await showDialog<Groupe>(
      context: context,
      builder: (_) => NouveauGroupeDialog(groupeInitial: g),
    );
    if (!mounted) return;
    if (modifie != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Groupe "${modifie.nom}" mis à jour !'),
          backgroundColor: const Color(0xFF006A61),
        ),
      );
      _chargerGroupes();
    }
  }

  Future<void> _supprimerGroupe(Groupe g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce groupe ?'),
        content: Text(
          'Voulez-vous vraiment supprimer le groupe "${g.nom}" ?\nLes élèves ne seront pas supprimés de la base de données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.supprimerGroupe(g.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Groupe supprimé.')),
          );
          _chargerGroupes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _planifierSeance(Groupe g, {bool estPlanification = true}) async {
    final res = await showDialog<dynamic>(
      context: context,
      builder: (_) => SeanceGroupeDialog(
        groupe: g,
        profProfile: widget.profProfile,
        estPlanification: estPlanification,
      ),
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Séance de groupe enregistrée pour "${g.nom}" !'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _chargerGroupes();
    }
  }

  Future<void> _encaisserToutEnUnClic(Groupe g) async {
    final count = g.seancesImpayeesCount;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun impayé pour ce groupe.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.flash_on_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Encaisser en 1 Clic'),
          ],
        ),
        content: Text(
          'Valider le paiement de $count séance(s) impayée(s) pour le groupe "${g.nom}" ?\n\nToutes les séances enregistrées passeront automatiquement au statut "Payée".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Confirmer l\'encaissement'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await ApiService.encaisserGroupe(idGroupe: g.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${res['nb_seances_payees']} séances encaissées (+${res['total_encaisse']} DZD) !',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _chargerGroupes();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchController.text.trim().toLowerCase();

    final groupesFiltres = _groupes.where((g) {
      if (query.isEmpty) return true;
      return g.nom.toLowerCase().contains(query) ||
          (g.niveau?.toLowerCase().contains(query) ?? false);
    }).toList();

    final int totalEleves = _groupes.fold(0, (sum, g) => sum + g.totalEleves);
    final int totalImpayes = _groupes.fold(0, (sum, g) => sum + g.seancesImpayeesCount);

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text(
          'Groupes de Soutien',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _chargerGroupes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerGroupe,
        backgroundColor: const Color(0xFF006A61),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text(
          'Nouveau Groupe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
          : Column(
              children: [
                // En-tête statistiques
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF061449).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        icon: Icons.groups_2_rounded,
                        count: '${_groupes.length}',
                        label: 'Groupes',
                        color: const Color(0xFF86F2E4),
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      _buildHeaderStat(
                        icon: Icons.people_alt_rounded,
                        count: '$totalEleves',
                        label: 'Élèves groupés',
                        color: Colors.white,
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      _buildHeaderStat(
                        icon: Icons.warning_amber_rounded,
                        count: '$totalImpayes',
                        label: 'Impayés',
                        color: totalImpayes > 0 ? const Color(0xFFFFB95F) : const Color(0xFF86F2E4),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un groupe ou niveau (ex: 3AS)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF131D42) : Colors.white,
                    ),
                  ),
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),

                // Liste des groupes
                Expanded(
                  child: _groupes.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: groupesFiltres.length,
                          itemBuilder: (context, index) {
                            final g = groupesFiltres[index];
                            return _buildGroupeCard(g, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF006A61).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_2_rounded,
                size: 56,
                color: Color(0xFF006A61),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aucun groupe de soutien',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier groupe pour regrouper vos élèves (ex: Terminale Maths, 4AM Sciences), planifier leurs séances d\'un coup et valider leurs paiements en 1 clic !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF061449),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _creerGroupe,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer mon premier groupe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupeCard(Groupe g, bool isDark) {
    final seancesImpayees = g.seancesImpayeesCount;
    final isDeplie = _groupesDeplies.contains(g.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: seancesImpayees > 0
              ? const Color(0xFFFFB95F).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Nom du groupe et nombre d'élèves (Cliquable pour déplier/replier)
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                if (isDeplie) {
                  _groupesDeplies.remove(g.id);
                } else {
                  _groupesDeplies.add(g.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A61).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF006A61),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.nom,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${g.totalEleves} élève(s)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDeplie ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        if (isDeplie) {
                          _groupesDeplies.remove(g.id);
                        } else {
                          _groupesDeplies.add(g.id);
                        }
                      });
                    },
                    tooltip: isDeplie ? 'Réduire' : 'Afficher détails',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) {
                      if (val == 'pointer') _planifierSeance(g, estPlanification: false);
                      if (val == 'edit') _modifierGroupe(g);
                      if (val == 'delete') _supprimerGroupe(g);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'pointer',
                        child: Row(
                          children: [
                            Icon(Icons.how_to_reg_rounded, size: 18, color: Color(0xFF006A61)),
                            SizedBox(width: 8),
                            Text('Saisir / Pointer séance'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Contenu visible une fois cliqué (déplié) : Niveau, Tarif, Élèves et Actions
          if (isDeplie) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A102B)
                      : const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF233166) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    if (g.niveau != null && g.niveau!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF061449).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          g.niveau!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF061449),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        'Tarif : ${g.tarifParDefaut.toInt()} DZD / élève • Total (${g.totalEleves} él.) : ${(g.tarifParDefaut * g.totalEleves).toInt()} DZD',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A61),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Aperçu des élèves membres
            if (g.eleves.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: g.eleves.map((m) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFF1E2A5E),
                        child: Text(
                          m.nomEleve.isNotEmpty ? m.nomEleve[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                      label: Text(m.nomEleve, style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                ),
              ),

            const Divider(height: 14),

            // Actions : Planifier séance & Encaisser
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: const Color(0xFF006A61),
                        side: const BorderSide(color: Color(0xFF006A61)),
                      ),
                      onPressed: () => _planifierSeance(g),
                      icon: const Icon(Icons.event_available_rounded, size: 16),
                      label: const Text('Planifier séance', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: seancesImpayees > 0
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        foregroundColor: seancesImpayees > 0 ? Colors.white : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: seancesImpayees > 0 ? 2 : 0,
                      ),
                      onPressed: seancesImpayees > 0 ? () => _encaisserToutEnUnClic(g) : null,
                      icon: Icon(
                        Icons.flash_on_rounded,
                        size: 16,
                        color: seancesImpayees > 0 ? Colors.white : Colors.grey[600],
                      ),
                      label: Text(
                        seancesImpayees > 0 ? 'Encaisser ($seancesImpayees)' : 'À jour',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: seancesImpayees > 0 ? Colors.white : Colors.grey[600],
                        ),
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
}
