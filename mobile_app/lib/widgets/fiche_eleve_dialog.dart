import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/eleve.dart';
import '../models/fiche_eleve.dart';
import '../models/groupe.dart';
import '../models/seance.dart';
import '../services/api_service.dart';

class FicheEleveDialog extends StatefulWidget {
  final Eleve eleve;

  FicheEleveDialog({
    super.key,
    Eleve? eleve,
    String? idEleve,
    String? nomEleve,
  }) : eleve = eleve ??
            Eleve(
              idEleve: idEleve ?? '',
              nom: nomEleve ?? '',
              statut: 'Actif',
            );

  @override
  State<FicheEleveDialog> createState() => _FicheEleveDialogState();
}

class _FicheEleveDialogState extends State<FicheEleveDialog> {
  late Future<FicheEleveData> _ficheFuture;
  late Eleve _currentEleve;
  bool _aEteModifie = false;

  @override
  void initState() {
    super.initState();
    _currentEleve = widget.eleve;
    _loadFiche();
  }

  void _loadFiche() {
    _ficheFuture = ApiService.getFicheEleve(_currentEleve.idEleve);
  }

  Future<void> _affecterAuGroupe() async {
    List<Groupe> groupes = [];
    try {
      groupes = await ApiService.getGroupes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des groupes: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    if (groupes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun groupe disponible actuellement.')),
      );
      return;
    }

    String? selectedGroupeId = _currentEleve.idGroupe;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.group_add_rounded, color: Color(0xFF006A61)),
                  const SizedBox(width: 8),
                  Text(
                    _currentEleve.sansGroupe
                        ? 'Affecter à un groupe'
                        : 'Changer de groupe',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Élève : ${_currentEleve.nom}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...groupes.map((g) {
                      final isSelected = selectedGroupeId == g.idGroupe;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF006A61)
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          tileColor: isSelected
                              ? const Color(0xFF006A61).withValues(alpha: 0.08)
                              : null,
                          title: Text(
                            g.nom,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? const Color(0xFF006A61) : null,
                            ),
                          ),
                          subtitle: g.niveau != null ? Text(g.niveau!) : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF006A61))
                              : null,
                          onTap: () {
                            setDialogState(() {
                              selectedGroupeId = g.idGroupe;
                            });
                          },
                        ),
                      );
                    }),
                    if (_currentEleve.aGroupe) ...[
                      const Divider(height: 20),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_remove_outlined,
                            color: Colors.red),
                        title: const Text('Retirer du groupe (Sans groupe)',
                            style: TextStyle(color: Colors.red, fontSize: 13)),
                        onTap: () {
                          setDialogState(() {
                            selectedGroupeId = '';
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Annuler')),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF061449),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () =>
                              Navigator.of(ctx).pop(selectedGroupeId ?? ''),
                          child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Confirmer')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final newGroupeId = result.isEmpty ? null : result;
      try {
        await ApiService.affecterEleveGroupe(
          idEleve: _currentEleve.idEleve,
          idGroupe: newGroupeId,
        );
        if (mounted) {
          final nouveauGroupe = newGroupeId != null
              ? groupes.firstWhere(
                  (g) => g.idGroupe == newGroupeId,
                  orElse: () => Groupe(
                    idGroupe: newGroupeId,
                    nom: 'Groupe',
                    tarifParEleve: 0,
                    totalEleves: 0,
                    eleves: [],
                    countImpayes: 0,
                    totalImpaye: 0,
                  ),
                )
              : null;

          setState(() {
            _currentEleve = _currentEleve.copyWith(
              idGroupe: newGroupeId,
              nomGroupe: nouveauGroupe?.nom,
            );
            _aEteModifie = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF006A61),
              content: Text(
                newGroupeId != null
                    ? 'Élève affecté au groupe "${nouveauGroupe?.nom}" avec succès'
                    : 'Élève retiré du groupe avec succès',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur affectation groupe : $e')),
          );
        }
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'appeler le numéro : $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 580,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec nom de l'élève
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF061449).withValues(alpha: 0.12),
                  child: Text(
                    _currentEleve.nom.isNotEmpty
                        ? _currentEleve.nom.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF061449),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentEleve.nom,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_currentEleve.niveau != null &&
                              _currentEleve.niveau!.isNotEmpty)
                            Text(
                              _currentEleve.niveau!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _currentEleve.estActif
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentEleve.statut,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _currentEleve.estActif
                                    ? const Color(0xFF10B981)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (_currentEleve.aGroupe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006A61).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF006A61).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group,
                                      size: 11, color: Color(0xFF006A61)),
                                  const SizedBox(width: 3),
                                  Text(
                                    _currentEleve.nomGroupe ?? 'Groupe',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006A61),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_off_outlined,
                                      size: 11, color: Color(0xFFD97706)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Sans groupe',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          InkWell(
                            onTap: _affecterAuGroupe,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF061449).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF061449).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group_add_rounded,
                                      size: 11, color: Color(0xFF061449)),
                                  const SizedBox(width: 3),
                                  Text(
                                    _currentEleve.sansGroupe
                                        ? 'Affecter'
                                        : 'Changer',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF061449),
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
                if (_currentEleve.telephone != null &&
                    _currentEleve.telephone!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFF10B981)),
                    tooltip: 'Appeler élève (${_currentEleve.telephone})',
                    onPressed: () => _makePhoneCall(_currentEleve.telephone!),
                  ),
                if (_currentEleve.telephoneParent != null &&
                    _currentEleve.telephoneParent!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.family_restroom, color: Color(0xFF3B82F6)),
                    tooltip: 'Appeler parents (${_currentEleve.telephoneParent})',
                    onPressed: () => _makePhoneCall(_currentEleve.telephoneParent!),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(_aEteModifie),
                ),
              ],
            ),
            if ((_currentEleve.telephone != null && _currentEleve.telephone!.isNotEmpty) ||
                (_currentEleve.telephoneParent != null && _currentEleve.telephoneParent!.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_currentEleve.telephone != null && _currentEleve.telephone!.isNotEmpty)
                    InkWell(
                      onTap: () => _makePhoneCall(_currentEleve.telephone!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              _currentEleve.telephone!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_currentEleve.telephoneParent != null && _currentEleve.telephoneParent!.isNotEmpty)
                    InkWell(
                      onTap: () => _makePhoneCall(_currentEleve.telephoneParent!),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.family_restroom, size: 14, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 4),
                            Text(
                              'Parents : ${_currentEleve.telephoneParent!}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const Divider(height: 20),
            if (_currentEleve.sansGroupe) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cet élève n\'est rattaché à aucun groupe.',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _affecterAuGroupe,
                      icon: const Icon(Icons.group_add_rounded, size: 16),
                      label: const FittedBox(fit: BoxFit.scaleDown, child: Text('Affecter')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Chargement et contenu de la fiche
            Expanded(
              child: FutureBuilder<FicheEleveData>(
                future: _ficheFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF006A61)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          Text('Erreur: ${snapshot.error}',
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() => _loadFiche()),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final kpis = data.kpis;
                  final seances = data.seances;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3 Cartes KPIs de l'élève
                      Row(
                        children: [
                          // KPI 1 : Total Payé
                          Expanded(
                            child: _buildMiniKpi(
                              context,
                              title: 'Total Payé',
                              value: '${kpis.totalPaye} DZD',
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // KPI 2 : Total Impayé
                          Expanded(
                            child: _buildMiniKpi(
                              context,
                              title: 'Total Impayé',
                              value: '${kpis.totalImpaye} DZD',
                              icon: Icons.hourglass_top_rounded,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // KPI 3 : Nombre Total de Séances
                          Expanded(
                            child: _buildMiniKpi(
                              context,
                              title: 'Séances',
                              value: '${kpis.totalSeances}',
                              icon: Icons.school_rounded,
                              color: const Color(0xFF061449),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Titre Historique
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Historique complet des séances',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${seances.length} séance${seances.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Liste des séances
                      Expanded(
                        child: seances.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucune séance enregistrée pour cet élève.',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            : ListView.separated(
                                itemCount: seances.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final s = seances[index];
                                  return _buildSeanceItem(context, s);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _affecterAuGroupe,
                      icon: const Icon(Icons.group_add_rounded, size: 18),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_currentEleve.sansGroupe ? 'Affecter à un groupe' : 'Changer de groupe'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF061449),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(_aEteModifie),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Fermer'),
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
  }

  Widget _buildMiniKpi(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeanceItem(BuildContext context, Seance s) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color badgeColor;
    String badgeLabel;

    if (s.estAnnulee) {
      badgeColor = Colors.grey;
      badgeLabel = 'Annulée';
    } else if (s.estPaye) {
      badgeColor = const Color(0xFF10B981);
      badgeLabel = s.cloturee ? 'Payé (Clôturé)' : 'Payé';
    } else {
      badgeColor = Colors.orange;
      badgeLabel = s.estPlanifiee ? 'Planifiée' : 'Impayé';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Date & Heure
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.dateSeance,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (s.heure != null && s.heure!.isNotEmpty)
                Text(
                  s.heure!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF006A61).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              s.typeSeance,
              style: const TextStyle(
                color: Color(0xFF006A61),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),

          // Montant
          Text(
            '${s.montant} DZD',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 10),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
