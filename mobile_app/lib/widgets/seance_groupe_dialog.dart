import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/groupe.dart';
import '../models/prof_profile.dart';
import '../services/api_service.dart';

class SeanceGroupeDialog extends StatefulWidget {
  final Groupe groupe;
  final ProfProfile? profProfile;
  final bool estPlanification;

  const SeanceGroupeDialog({
    super.key,
    required this.groupe,
    this.profProfile,
    this.estPlanification = false,
  });

  @override
  State<SeanceGroupeDialog> createState() => _SeanceGroupeDialogState();
}

class _SeanceGroupeDialogState extends State<SeanceGroupeDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _dureeMinutes = 120; // 2h par défaut
  String _matiereChoisie = 'Mathématiques';

  // Map: idEleve -> { 'present': bool, 'paye': bool, 'tarif': double }
  final Map<String, bool> _presenceMap = {};
  final Map<String, bool> _payeMap = {};

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay.fromDateTime(now);

    if (widget.profProfile != null && widget.profProfile!.matieres.isNotEmpty) {
      _matiereChoisie = widget.profProfile!.matieres.first;
    }

    for (final el in widget.groupe.eleves) {
      _presenceMap[el.idEleve] = true; // Tous présents par défaut
      _payeMap[el.idEleve] = true; // Payé maintenant par défaut
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Date de la séance de groupe',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Heure de début',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool get _estSeanceFuture {
    if (widget.estPlanification) return true;
    final dateComplete = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    return dateComplete.isAfter(DateTime.now());
  }

  int get _nbPresents {
    if (_estSeanceFuture) return widget.groupe.eleves.length;
    return _presenceMap.values.where((p) => p == true).length;
  }

  int get _nbPayes {
    if (_estSeanceFuture) return 0;
    return _presenceMap.entries
        .where((e) => e.value == true && (_payeMap[e.key] == true))
        .length;
  }

  double get _totalEstime {
    return _nbPresents * widget.groupe.tarifParDefaut;
  }

  double get _totalEncaisse {
    return _nbPayes * widget.groupe.tarifParDefaut;
  }

  double get _totalImpaye {
    return (_nbPresents - _nbPayes) * widget.groupe.tarifParDefaut;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    final eleves = widget.groupe.eleves;
    if (eleves.isEmpty) {
      setState(() {
        _errorMessage = 'Ce groupe ne contient aucun élève. Ajoutez d\'abord des élèves au groupe.';
      });
      return;
    }

    final dateComplete = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final isFuture = widget.estPlanification || dateComplete.isAfter(DateTime.now());

    final presences = <Map<String, dynamic>>[];
    final int tarifParEleve = widget.groupe.tarifParDefaut.round();

    if (isFuture) {
      // En planification future : tous les élèves du groupe sont inclus d'office
      for (final el in eleves) {
        presences.add({
          'id_eleve': el.idEleve,
          'present': true,
          'paye': false,
          'tarif': tarifParEleve,
          'montant': tarifParEleve,
        });
      }
    } else {
      // Séance effectuée : pointage réel des présences et du mode d'encaissement
      for (final el in eleves) {
        final isPresent = _presenceMap[el.idEleve] ?? false;
        if (isPresent) {
          presences.add({
            'id_eleve': el.idEleve,
            'present': true,
            'paye': _payeMap[el.idEleve] ?? false,
            'tarif': tarifParEleve,
            'montant': tarifParEleve,
          });
        } else {
          // Absent : statut Annulée, montant 0 DZD (ne génère pas d'impayé)
          presences.add({
            'id_eleve': el.idEleve,
            'present': false,
            'paye': false,
            'tarif': tarifParEleve,
            'montant': 0,
          });
        }
      }

      if (presences.isEmpty) {
        setState(() {
          _errorMessage = 'Aucun élève trouvé dans ce groupe.';
        });
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(dateComplete);
      final elevesVerifIds = presences
          .where((p) => p['present'] == true)
          .map((p) => p['id_eleve'].toString())
          .toList();

      if (elevesVerifIds.isNotEmpty) {
        try {
          final doublons = await ApiService.verifierDoublonsSeance(
            eleveIds: elevesVerifIds,
            dateSeance: dateStr,
            idGroupe: widget.groupe.id,
          );

          if (doublons.isNotEmpty && mounted) {
            final continuer = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Séance déjà enregistrée',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                content: Text(
                  'Attention : une ou plusieurs séances existent déjà le $dateStr pour :\n\n'
                  '• ${doublons.join('\n• ')}\n\n'
                  'Voulez-vous tout de même enregistrer cette séance de groupe ?',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Modifier'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Enregistrer quand même'),
                  ),
                ],
              ),
            );

            if (continuer != true) {
              setState(() {
                _isSaving = false;
              });
              return;
            }
          }
        } catch (errDoublon) {
          debugPrint('Erreur vérification doublon groupe: $errDoublon');
        }
      }

      final res = await ApiService.creerSeanceGroupe(
        idGroupe: widget.groupe.id,
        dateSeance: dateComplete,
        matiere: _matiereChoisie,
        presences: presences,
        dureeMinutes: _dureeMinutes,
        statutSeance: isFuture ? 'Planifiée' : 'Réalisée',
      );

      if (mounted) {
        Navigator.of(context).pop(res);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Erreur : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eleves = widget.groupe.eleves;
    final matieresDispos = widget.profProfile?.matieres ?? ['Mathématiques', 'Physique', 'Sciences'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF131D42) : Colors.white,
      child: Container(
        width: 560,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
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
                    child: Icon(
                      _estSeanceFuture ? Icons.event_note_rounded : Icons.how_to_reg_rounded,
                      color: const Color(0xFF006A61),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estSeanceFuture
                              ? 'Planifier : ${widget.groupe.nom}'
                              : 'Saisir séance : ${widget.groupe.nom}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _estSeanceFuture
                              ? 'Planification de séance groupée (${widget.groupe.niveau})'
                              : 'Pointage des présences & encaissement (${widget.groupe.niveau})',
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null)
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
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Heure
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_rounded, size: 16),
                              label: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time_rounded, size: 16),
                              label: Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Matière & Durée
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: matieresDispos.contains(_matiereChoisie)
                                  ? _matiereChoisie
                                  : (matieresDispos.isNotEmpty ? matieresDispos.first : null),
                              decoration: InputDecoration(
                                labelText: 'Matière',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: matieresDispos.map((m) {
                                return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _matiereChoisie = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              initialValue: _dureeMinutes,
                              decoration: InputDecoration(
                                labelText: 'Durée',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 60, child: Text('1h00', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 90, child: Text('1h30', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 120, child: Text('2h00', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 150, child: Text('2h30', style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: 180, child: Text('3h00', style: TextStyle(fontSize: 13))),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _dureeMinutes = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Récapitulatif Tarif & Total
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A61).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF006A61).withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tarif / élève :',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${widget.groupe.tarifParDefaut.toInt()} DZD',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006A61),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _estSeanceFuture ? 'Inscrits :' : 'Pointés :',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      _estSeanceFuture
                                          ? '${eleves.length} élève(s)'
                                          : '$_nbPresents / ${eleves.length}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006A61),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _estSeanceFuture ? 'Total prévisionnel :' : 'Total séance :',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      '${_totalEstime.toInt()} DZD',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF061449),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!_estSeanceFuture && _nbPresents > 0) ...[
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Encaissé : ${_totalEncaisse.toInt()} DZD',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Impayé : ${_totalImpaye.toInt()} DZD',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_estSeanceFuture) ...[
                        // En mode planification future : pas de sélection d'élèves, tous sont planifiés
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A61).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF006A61).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event_note_rounded, color: Color(0xFF006A61), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Planification automatique',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF006A61)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tous les élèves du groupe (${eleves.length} élèves) sont inclus dans la planification. Le pointage des présences et le choix d\'encaissement (Payé maintenant ou Payer plus tard) s\'effectueront une fois la séance terminée.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: eleves.map((el) => Chip(
                                  avatar: const CircleAvatar(
                                    backgroundColor: Color(0xFF006A61),
                                    child: Icon(Icons.person, size: 12, color: Colors.white),
                                  ),
                                  label: Text(el.nomEleve, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                  backgroundColor: isDark ? const Color(0xFF1A2652) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  side: BorderSide(color: isDark ? const Color(0xFF2E3E75) : const Color(0xFFE2E8F0)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Pointage des présences pour séance effectuée
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pointage des présences & Paiement :',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                              onPressed: () {
                                final allPresent = !_presenceMap.values.every((v) => v);
                                setState(() {
                                  for (final k in _presenceMap.keys) {
                                    _presenceMap[k] = allPresent;
                                  }
                                });
                              },
                              label: const Text('Basculer tous', style: TextStyle(fontSize: 11.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        if (eleves.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('Aucun élève affecté à ce groupe.', style: TextStyle(fontSize: 12)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: eleves.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final el = eleves[idx];
                              final isPresent = _presenceMap[el.idEleve] ?? false;
                              final isPaye = _payeMap[el.idEleve] ?? false;

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? (isDark ? const Color(0xFF1A2652) : Colors.white)
                                      : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isPresent
                                        ? const Color(0xFF006A61).withValues(alpha: 0.35)
                                        : (isDark ? const Color(0xFF233166) : const Color(0xFFE2E8F0)),
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
                                            el.nomEleve.isNotEmpty ? el.nomEleve[0].toUpperCase() : '?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: isPresent ? const Color(0xFF006A61) : Colors.grey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            el.nomEleve,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isPresent
                                                  ? (isDark ? Colors.white : const Color(0xFF061449))
                                                  : Colors.grey[500],
                                              decoration: isPresent ? null : TextDecoration.lineThrough,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                                onTap: () => setState(() => _presenceMap[el.idEleve] = true),
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
                                                onTap: () => setState(() => _presenceMap[el.idEleve] = false),
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

                                    // Ligne 2 : Encaissement (Payé maintenant vs Payer plus tard)
                                    if (isPresent) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Bouton Payé maintenant
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => _payeMap[el.idEleve] = true),
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
                                                    Flexible(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          'Payé mtn',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isPaye
                                                                ? Colors.white
                                                                : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Bouton Payer plus tard
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => setState(() => _payeMap[el.idEleve] = false),
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
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Text(
                                                          'Payer plus tard',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: !isPaye
                                                                ? Colors.white
                                                                : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                                          ),
                                                        ),
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
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Boutons d'action harmonisés
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Fermer'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF061449),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _enregistrer,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_rounded, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      _estSeanceFuture ? 'Planifier la séance' : 'Valider la séance',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
