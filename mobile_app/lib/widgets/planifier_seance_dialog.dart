import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/eleve.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class PlanifierSeanceDialog extends StatefulWidget {
  final List<Eleve> eleves;
  final TarifsConfig tarifs;
  final VoidCallback onSuccess;

  const PlanifierSeanceDialog({
    super.key,
    required this.eleves,
    required this.tarifs,
    required this.onSuccess,
  });

  @override
  State<PlanifierSeanceDialog> createState() => _PlanifierSeanceDialogState();
}

class _PlanifierSeanceDialogState extends State<PlanifierSeanceDialog> {
  final Set<String> _selectedEleveIds = {};
  DateTime _dateSeance = DateTime.now();
  TimeOfDay _heureSeance = const TimeOfDay(hour: 14, minute: 0);
  String _typeSeance = 'Normale';
  int? _selectedTarif;
  late final TextEditingController _customMontantController;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  List<int> get _activeTarifs {
    final list = _typeSeance == 'Privée'
        ? widget.tarifs.tarifsPrivee
        : widget.tarifs.tarifsNormale;
    if (list.isNotEmpty) return list;
    final fallback = _typeSeance == 'Privée'
        ? widget.tarifs.privee1
        : widget.tarifs.normale1;
    return [fallback > 0 ? fallback : 800];
  }

  @override
  void initState() {
    super.initState();
    final initialTarif = _activeTarifs.isNotEmpty ? _activeTarifs.first : 800;
    _selectedTarif = initialTarif;
    _customMontantController =
        TextEditingController(text: initialTarif.toString());
  }

  @override
  void dispose() {
    _customMontantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _montantEffectif {
    if (_selectedTarif != null) {
      return _selectedTarif!;
    }
    return int.tryParse(_customMontantController.text.trim()) ??
        (_activeTarifs.isNotEmpty ? _activeTarifs.first : 800);
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedEleveIds.length == widget.eleves.length) {
        _selectedEleveIds.clear();
      } else {
        _selectedEleveIds.clear();
        for (final el in widget.eleves) {
          _selectedEleveIds.add(el.idEleve);
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSeance,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
      helpText: 'Date de la séance planifiée',
      cancelText: 'Annuler',
      confirmText: 'Sélectionner',
    );

    if (picked != null) {
      setState(() {
        _dateSeance = picked;
      });
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return _dateSeance.year == now.year &&
        _dateSeance.month == now.month &&
        _dateSeance.day == now.day;
  }

  bool get _isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _dateSeance.year == tomorrow.year &&
        _dateSeance.month == tomorrow.month &&
        _dateSeance.day == tomorrow.day;
  }

  void _setDateToday() {
    setState(() {
      _dateSeance = DateTime.now();
    });
  }

  void _setDateTomorrow() {
    setState(() {
      _dateSeance = DateTime.now().add(const Duration(days: 1));
    });
  }


  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heureSeance,
      helpText: 'Heure de la séance',
    );

    if (picked != null) {
      setState(() {
        _heureSeance = picked;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedEleveIds.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner au moins un élève.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final selectedEleves = widget.eleves
          .where((e) => _selectedEleveIds.contains(e.idEleve))
          .toList();
      final dateStr = DateFormat('yyyy-MM-dd').format(_dateSeance);
      final heureStr =
          '${_heureSeance.hour.toString().padLeft(2, '0')}:${_heureSeance.minute.toString().padLeft(2, '0')}';

      // Vérification anti-doublon (même élève, même date)
      try {
        final doublons = await ApiService.verifierDoublonsSeance(
          eleveIds: _selectedEleveIds.toList(),
          dateSeance: dateStr,
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
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: Text(
                'Attention : une ou plusieurs séances existent déjà le $dateStr pour :\n\n'
                '• ${doublons.join('\n• ')}\n\n'
                'Voulez-vous tout de même planifier cette séance ?',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Modifier'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Planifier quand même'),
                ),
              ],
            ),
          );

          if (continuer != true) {
            setState(() {
              _isSubmitting = false;
            });
            return;
          }
        }
      } catch (errDoublon) {
        debugPrint('Erreur vérification doublon: $errDoublon');
      }

      // Vérification des conflits d'horaires
      try {
        final conflits = await ApiService.verifierConflitHoraire(
          dateSeance: dateStr,
          heure: heureStr,
        );
        if (conflits.isNotEmpty && mounted) {
          final premierConflit = conflits.first;
          final descConflit = premierConflit;
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
                  Text('Conflit d\'horaire',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'Une séance existe déjà le $dateStr à $heureStr avec $descConflit (${conflits.length} séance(s) en conflit).\n\nSouhaitez-vous quand même planifier cette séance sur ce même créneau ?',
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Modifier l\'horaire'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Continuer quand même'),
                ),
              ],
            ),
          );

          if (continuer != true) {
            setState(() {
              _isSubmitting = false;
            });
            return;
          }
        }
      } catch (errCheck) {
        debugPrint('Erreur vérification conflit: $errCheck');
      }

      final result = await ApiService.planifierSeancesMultiple(
        eleves: selectedEleves,
        dateSeance: dateStr,
        heure: heureStr,
        typeSeance: _typeSeance,
        montant: _montantEffectif,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Planifier les rappels natifs système 30 minutes avant l'heure de la séance
      try {
        final seancesList = result['seances'] as List<dynamic>? ?? [];
        final fullDateTime = DateTime(
          _dateSeance.year,
          _dateSeance.month,
          _dateSeance.day,
          _heureSeance.hour,
          _heureSeance.minute,
        );

        if (seancesList.isNotEmpty) {
          for (final s in seancesList) {
            final idSeance = s['id_seance']?.toString() ?? '';
            final nomEleve = s['nom_eleve']?.toString() ?? 'Élève';
            await NotificationService().planifierRappelSeance(
              idSeance: idSeance,
              nomEleve: nomEleve,
              matiere: 'Soutien Scolaire',
              dateHeureSeance: fullDateTime,
            );
          }
        } else {
          for (int i = 0; i < selectedEleves.length; i++) {
            final el = selectedEleves[i];
            final pseudoId = '${el.idEleve}_$i';
            await NotificationService().planifierRappelSeance(
              idSeance: pseudoId,
              nomEleve: el.nom,
              matiere: 'Soutien Scolaire',
              dateHeureSeance: fullDateTime,
            );
          }
        }
      } catch (errNotif) {
        debugPrint('Erreur planif rappel notif: $errNotif');
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedEleves.length} séance(s) planifiée(s) avec succès ! Rappels configurés à -30 min et -15 min (${_heureSeance.hour.toString().padLeft(2, '0')}:${_heureSeance.minute.toString().padLeft(2, '0')}).',
            ),
            backgroundColor: const Color(0xFF006A61),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  Widget _buildDarkChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2CE5A7) : const Color(0xFF0B0D1B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2CE5A7) : const Color(0xFF252A4A),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0B0D1B) : const Color(0xFF8E95B3),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = widget.eleves.isNotEmpty &&
        _selectedEleveIds.length == widget.eleves.length;

    return Dialog(
      backgroundColor: const Color(0xFF16192E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF252A4A), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF16192E),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2CE5A7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF2CE5A7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Planifier une Séance Future',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8E95B3)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF252A4A)),

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
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Contenu défilable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Choix de date rapide
                    const Text(
                      'Date de la séance (planifiée)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: 'Aujourd\'hui',
                            selected: _isToday,
                            onSelected: (val) {
                              if (val) _setDateToday();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: 'Demain',
                            selected: _isTomorrow,
                            onSelected: (val) {
                              if (val) _setDateTomorrow();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: !_isToday && !_isTomorrow
                                ? DateFormat('dd/MM').format(_dateSeance)
                                : 'Autre date',
                            selected: !_isToday && !_isTomorrow,
                            onSelected: (val) => _pickDate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date & Heure
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  color: Color(0xFF8E95B3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B0D1B),
                                    border: Border.all(
                                      color: const Color(0xFF252A4A),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 18, color: Color(0xFF2CE5A7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(_dateSeance),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Heure',
                                style: TextStyle(
                                  color: Color(0xFF8E95B3),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B0D1B),
                                    border: Border.all(
                                      color: const Color(0xFF252A4A),
                                      width: 1.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 18, color: Color(0xFF2CE5A7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_heureSeance.hour.toString().padLeft(2, '0')}:${_heureSeance.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Type
                    const Text(
                      'Type de séance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: 'Normale (${widget.tarifs.normale1} DZD)',
                            selected: _typeSeance == 'Normale',
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _typeSeance = 'Normale';
                                  final firstTarif = _activeTarifs.isNotEmpty
                                      ? _activeTarifs.first
                                      : 800;
                                  _selectedTarif = firstTarif;
                                  _customMontantController.text =
                                      firstTarif.toString();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: 'Privée (${widget.tarifs.privee1} DZD)',
                            selected: _typeSeance == 'Privée',
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _typeSeance = 'Privée';
                                  final firstTarif = _activeTarifs.isNotEmpty
                                      ? _activeTarifs.first
                                      : 800;
                                  _selectedTarif = firstTarif;
                                  _customMontantController.text =
                                      firstTarif.toString();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarification
                    Text(
                      'Tarification ($_typeSeance)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._activeTarifs.map((tarif) => _buildDarkChoiceChip(
                              label: '$tarif DZD',
                              selected: _selectedTarif == tarif,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedTarif = tarif;
                                    _customMontantController.text =
                                        tarif.toString();
                                  });
                                }
                              },
                            )),
                        _buildDarkChoiceChip(
                          label: 'Autre montant...',
                          selected: _selectedTarif == null,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedTarif = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (_selectedTarif == null) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customMontantController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Prix libre par élève (DZD)',
                          labelStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          prefixIcon: const Icon(Icons.payments_outlined,
                              size: 20, color: Color(0xFF2CE5A7)),
                          suffixText: 'DZD',
                          suffixStyle: const TextStyle(color: Color(0xFF2CE5A7)),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF0B0D1B),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF252A4A),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2CE5A7),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Montant appliqué : $_montantEffectif DZD par élève',
                        style: const TextStyle(
                          color: Color(0xFF2CE5A7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information statut paiement
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202646).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF252A4A),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF2CE5A7), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Les séances planifiées sont automatiquement enregistrées comme "Impayé" jusqu\'au règlement.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E95B3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text(
                      'Notes / Objectifs (Optionnel)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Objectifs ou thèmes de la séance...',
                        hintStyle: const TextStyle(color: Color(0xFF8E95B3)),
                        filled: true,
                        fillColor: const Color(0xFF0B0D1B),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF252A4A),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2CE5A7),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Élèves
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Élèves (${_selectedEleveIds.length}/${widget.eleves.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _toggleSelectAll,
                          icon: Icon(
                            allSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: const Color(0xFF2CE5A7),
                          ),
                          label: Text(
                            allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
                            style: const TextStyle(
                                color: Color(0xFF2CE5A7), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (widget.eleves.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Aucun élève actif trouvé.',
                            style: TextStyle(color: Color(0xFF8E95B3)),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0D1B),
                          border: Border.all(
                            color: const Color(0xFF252A4A),
                            width: 1.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.eleves.length,
                          itemBuilder: (context, index) {
                            final eleve = widget.eleves[index];
                            final isSelected =
                                _selectedEleveIds.contains(eleve.idEleve);
                            return CheckboxListTile(
                              dense: true,
                              activeColor: const Color(0xFF2CE5A7),
                              checkColor: const Color(0xFF0B0D1B),
                              title: Text(
                                eleve.nom,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: eleve.niveau != null
                                  ? Text(eleve.niveau!,
                                      style: const TextStyle(
                                          color: Color(0xFF8E95B3),
                                          fontSize: 11))
                                  : null,
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedEleveIds.add(eleve.idEleve);
                                  } else {
                                    _selectedEleveIds.remove(eleve.idEleve);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8E95B3),
                        side: const BorderSide(
                          color: Color(0xFF252A4A),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Fermer',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2CE5A7),
                        foregroundColor: const Color(0xFF0B0D1B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0B0D1B),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Planifier (${_selectedEleveIds.length} élève${_selectedEleveIds.length > 1 ? 's' : ''})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF0B0D1B),
                                ),
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
    );
  }
}
