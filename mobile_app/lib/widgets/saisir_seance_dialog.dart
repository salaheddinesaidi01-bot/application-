import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/eleve.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class SaisirSeanceDialog extends StatefulWidget {
  final List<Eleve> eleves;
  final TarifsConfig tarifs;
  final VoidCallback onSuccess;

  const SaisirSeanceDialog({
    super.key,
    required this.eleves,
    required this.tarifs,
    required this.onSuccess,
  });

  @override
  State<SaisirSeanceDialog> createState() => _SaisirSeanceDialogState();
}

class _SaisirSeanceDialogState extends State<SaisirSeanceDialog> {
  final Set<String> _selectedEleveIds = {};
  DateTime _dateSeance = DateTime.now();
  String _typeSeance = 'Normale'; // 'Normale' ou 'Privée'
  int? _selectedTarif; // null signifie montant personnalisé
  late final TextEditingController _customMontantController;
  String _statutPaiement = 'Payé'; // 'Payé' (maintenant) ou 'Impayé' (plus tard)
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSeance.isAfter(now) ? now : _dateSeance,
      firstDate: DateTime(2023),
      lastDate: now, // Interdiction stricte de choisir une date future
      helpText: 'Date de la séance réalisée',
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

  bool get _isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _dateSeance.year == yesterday.year &&
        _dateSeance.month == yesterday.month &&
        _dateSeance.day == yesterday.day;
  }

  void _setDateToday() {
    setState(() {
      _dateSeance = DateTime.now();
    });
  }

  void _setDateYesterday() {
    setState(() {
      _dateSeance = DateTime.now().subtract(const Duration(days: 1));
    });
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

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (_dateSeance.isAfter(todayMidnight)) {
      setState(() {
        _errorMessage = 'Impossible de saisir une séance réalisée dans le futur.';
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

      // Vérification anti-doublon
      final doublons = await ApiService.verifierDoublonsSeance(
        eleveIds: _selectedEleveIds.toList(),
        dateSeance: dateStr,
      );

      if (doublons.isNotEmpty && mounted) {
        final confirmation = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
                SizedBox(width: 8),
                Expanded(child: Text('Séance déjà enregistrée')),
              ],
            ),
            content: Text(
              'Attention : une ou plusieurs séances existent déjà le $dateStr pour :\n\n'
              '• ${doublons.join('\n• ')}\n\n'
              'Voulez-vous tout de même enregistrer ce doublon ?',
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Modifier'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Enregistrer quand même'),
              ),
            ],
          ),
        );

        if (confirmation != true) {
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      await ApiService.saisirSeancesMultiple(
        eleves: selectedEleves,
        dateSeance: dateStr,
        typeSeance: _typeSeance,
        montant: _montantEffectif,
        statutPaiement: _statutPaiement,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedEleves.length} séance(s) enregistrée(s) avec succès !',
            ),
            backgroundColor: const Color(0xFF10B981),
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
                    Icons.add_task_rounded,
                    color: Color(0xFF2CE5A7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Saisir une Séance (Réalisée)',
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
                    // Date
                    const Text(
                      'Date de la séance (réalisée)',
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
                            label: 'Hier',
                            selected: _isYesterday,
                            onSelected: (val) {
                              if (val) _setDateYesterday();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDarkChoiceChip(
                            label: !_isToday && !_isYesterday
                                ? DateFormat('dd/MM').format(_dateSeance)
                                : 'Autre date',
                            selected: !_isToday && !_isYesterday,
                            onSelected: (val) => _pickDate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
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
                            const Icon(Icons.event_note_rounded,
                                size: 18, color: Color(0xFF2CE5A7)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isToday
                                    ? 'Aujourd\'hui (${DateFormat('dd/MM/yyyy').format(_dateSeance)})'
                                    : _isYesterday
                                        ? 'Hier (${DateFormat('dd/MM/yyyy').format(_dateSeance)})'
                                        : () {
                                            try {
                                              return DateFormat('EEEE dd/MM/yyyy', 'fr_FR').format(_dateSeance);
                                            } catch (_) {
                                              return DateFormat('dd/MM/yyyy').format(_dateSeance);
                                            }
                                          }(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Text(
                              'Changer',
                              style: TextStyle(
                                color: Color(0xFF2CE5A7),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type de séance
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
                                  final firstTarif = _activeTarifs.isNotEmpty ? _activeTarifs.first : 800;
                                  _selectedTarif = firstTarif;
                                  _customMontantController.text = firstTarif.toString();
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
                                  final firstTarif = _activeTarifs.isNotEmpty ? _activeTarifs.first : 1500;
                                  _selectedTarif = firstTarif;
                                  _customMontantController.text = firstTarif.toString();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarification dynamique
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
                                    _customMontantController.text = tarif.toString();
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
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF2CE5A7)),
                          suffixText: 'DZD',
                          suffixStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF0B0D1B),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2CE5A7), width: 1.5),
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

                    // Statut de paiement
                    const Text(
                      'Règlement',
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
                          child: InkWell(
                            onTap: () => setState(() => _statutPaiement = 'Payé'),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: _statutPaiement == 'Payé'
                                    ? const Color(0xFF2CE5A7).withValues(alpha: 0.15)
                                    : const Color(0xFF0B0D1B),
                                border: Border.all(
                                  color: _statutPaiement == 'Payé'
                                      ? const Color(0xFF2CE5A7)
                                      : const Color(0xFF252A4A),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 18,
                                    color: _statutPaiement == 'Payé'
                                        ? const Color(0xFF2CE5A7)
                                        : const Color(0xFF8E95B3),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payé maintenant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _statutPaiement == 'Payé'
                                          ? const Color(0xFF2CE5A7)
                                          : const Color(0xFF8E95B3),
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
                            onTap: () => setState(() => _statutPaiement = 'Impayé'),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: _statutPaiement == 'Impayé'
                                    ? Colors.orange.withValues(alpha: 0.15)
                                    : const Color(0xFF0B0D1B),
                                border: Border.all(
                                  color: _statutPaiement == 'Impayé'
                                      ? Colors.orange
                                      : const Color(0xFF252A4A),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 18,
                                    color: _statutPaiement == 'Impayé'
                                        ? Colors.orange
                                        : const Color(0xFF8E95B3),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Payer plus tard',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _statutPaiement == 'Impayé'
                                          ? Colors.orange
                                          : const Color(0xFF8E95B3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sélection des élèves
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
                                color: Color(0xFF2CE5A7), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (widget.eleves.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Aucun élève actif trouvé. Veuillez ajouter des élèves d\'abord.',
                            style: TextStyle(color: Color(0xFF8E95B3)),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0D1B),
                          border: Border.all(color: const Color(0xFF252A4A), width: 1.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.eleves.length,
                          separatorBuilder: (context, i) => const Divider(
                            height: 1,
                            color: Color(0xFF252A4A),
                          ),
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
                                  ? Text(
                                      eleve.niveau!,
                                      style: const TextStyle(
                                        color: Color(0xFF8E95B3),
                                        fontSize: 11,
                                      ),
                                    )
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
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF252A4A), width: 1.2),
                      foregroundColor: const Color(0xFF8E95B3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                                'Valider (${_selectedEleveIds.length * _montantEffectif} DZD)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
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
