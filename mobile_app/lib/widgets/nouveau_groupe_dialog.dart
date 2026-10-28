import 'package:flutter/material.dart';
import '../models/eleve.dart';
import '../models/groupe.dart';
import '../services/api_service.dart';

class NouveauGroupeDialog extends StatefulWidget {
  final Groupe? groupeInitial;

  const NouveauGroupeDialog({super.key, this.groupeInitial});

  @override
  State<NouveauGroupeDialog> createState() => _NouveauGroupeDialogState();
}

class _NouveauGroupeDialogState extends State<NouveauGroupeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _tarifController = TextEditingController();
  final _rechercheController = TextEditingController();

  String _domaineChoisi = 'Lycée';
  String _niveauChoisi = '3AS';
  final Set<String> _elevesSelectionnes = {};

  List<Eleve> _tousLesEleves = [];
  bool _isLoadingEleves = true;
  bool _isSaving = false;
  String? _errorMessage;

  final Map<String, List<String>> _niveauxParDomaine = {
    'Primaire': ['Primaire', '1ère AP', '2ème AP', '3ème AP', '4ème AP', '5ème AP'],
    'CEM': ['1ère année', '2ème année', '3ème année', '4ème année'],
    'Lycée': ['1AS', '2AS', '2M', '2TM', '3AS', '3M', '3TM'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.groupeInitial != null) {
      final g = widget.groupeInitial!;
      _nomController.text = g.nom;
      _tarifController.text = g.tarifParDefaut.toInt().toString();

      // Rechercher le domaine correspondant au niveau
      for (final entry in _niveauxParDomaine.entries) {
        if (entry.value.contains(g.niveau)) {
          _domaineChoisi = entry.key;
          _niveauChoisi = g.niveau ?? '3AS';
          break;
        }
      }
      if (g.eleves.isNotEmpty) {
        _elevesSelectionnes.addAll(g.eleves.map((e) => e.idEleve));
      }
    } else {
      _tarifController.text = '1000';
    }
    _chargerEleves();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _tarifController.dispose();
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerEleves() async {
    try {
      final list = await ApiService.getEleves();
      if (mounted) {
        setState(() {
          _tousLesEleves = list;
          _isLoadingEleves = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des élèves : $e';
          _isLoadingEleves = false;
        });
      }
    }
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    final tarif = double.tryParse(_tarifController.text.trim()) ?? 1000.0;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      Groupe resultat;
      if (widget.groupeInitial != null) {
        resultat = await ApiService.modifierGroupe(
          id: widget.groupeInitial!.id,
          nom: _nomController.text.trim(),
          niveau: _niveauChoisi,
          tarifParDefaut: tarif,
          eleveIds: _elevesSelectionnes.toList(),
        );
      } else {
        resultat = await ApiService.creerGroupe(
          nom: _nomController.text.trim(),
          niveau: _niveauChoisi,
          tarifParDefaut: tarif,
          eleveIds: _elevesSelectionnes.toList(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(resultat);
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
    final isEditing = widget.groupeInitial != null;

    final query = _rechercheController.text.trim().toLowerCase();
    final elevesFiltres = _tousLesEleves.where((e) {
      if (query.isEmpty) return true;
      return e.nom.toLowerCase().contains(query) ||
          (e.niveau ?? '').toLowerCase().contains(query);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF252A4A), width: 1.2),
      ),
      backgroundColor: const Color(0xFF16192E),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                      color: const Color(0xFF2CE5A7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: Color(0xFF2CE5A7),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Modifier le Groupe' : 'Nouveau Groupe',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Affectez plusieurs élèves pour faciliter les séances et paiements',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8E95B3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8E95B3)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              // Contenu défilable
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du groupe
                      TextFormField(
                        controller: _nomController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Nom du groupe *',
                          labelStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          hintText: 'Ex: Terminale S - Groupe Maths A',
                          hintStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          prefixIcon: const Icon(Icons.title_rounded, size: 20, color: Color(0xFF2CE5A7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2CE5A7), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0B0D1B),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir un nom de groupe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Sélection Domaine & Niveau
                      const Text(
                        'Cycle & Niveau Scolaire :',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Primaire', label: Text('Primaire')),
                          ButtonSegment(value: 'CEM', label: Text('CEM')),
                          ButtonSegment(value: 'Lycée', label: Text('Lycée')),
                        ],
                        selected: {_domaineChoisi},
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF2CE5A7);
                            }
                            return const Color(0xFF0B0D1B);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF0B0D1B);
                            }
                            return const Color(0xFF8E95B3);
                          }),
                          side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFF252A4A))),
                        ),
                        onSelectionChanged: (val) {
                          setState(() {
                            _domaineChoisi = val.first;
                            _niveauChoisi = _niveauxParDomaine[_domaineChoisi]!.first;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _niveauxParDomaine[_domaineChoisi]!.map((niv) {
                          final isSel = _niveauChoisi == niv;
                          return ChoiceChip(
                            label: Text(niv),
                            selected: isSel,
                            selectedColor: const Color(0xFF2CE5A7),
                            backgroundColor: const Color(0xFF0B0D1B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSel ? const Color(0xFF2CE5A7) : const Color(0xFF252A4A),
                              ),
                            ),
                            labelStyle: TextStyle(
                              color: isSel ? const Color(0xFF0B0D1B) : const Color(0xFF8E95B3),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _niveauChoisi = niv;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Tarif par élève et par séance
                      TextFormField(
                        controller: _tarifController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Tarif par élève et par séance (DZD) *',
                          labelStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          hintText: 'Ex: 500',
                          hintStyle: const TextStyle(color: Color(0xFF8E95B3)),
                          helperText: 'Chaque élève pointé présent est facturé ce tarif. La séance cumule les élèves présents (ex: 2 élèves × 500 DZD = 1 000 DZD)',
                          helperStyle: const TextStyle(color: Color(0xFF8E95B3), fontSize: 11),
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: Color(0xFF2CE5A7)),
                          suffixText: 'DZD / élève',
                          suffixStyle: const TextStyle(color: Color(0xFF2CE5A7), fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2CE5A7), width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0B0D1B),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Tarif requis';
                          if (double.tryParse(v.trim()) == null) return 'Nombre invalide';
                          return null;
                        },
                      ),
                      if (_elevesSelectionnes.isNotEmpty && (double.tryParse(_tarifController.text.trim()) ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF202646),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF252A4A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF2CE5A7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Total estimé séance : ${((double.tryParse(_tarifController.text.trim()) ?? 0) * _elevesSelectionnes.length).toInt()} DZD (${_elevesSelectionnes.length} élève(s) × ${(double.tryParse(_tarifController.text.trim()) ?? 0).toInt()} DZD)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2CE5A7)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Élèves du groupe
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Élèves membres (${_elevesSelectionnes.length} sélectionné(s)) :',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          if (_tousLesEleves.isNotEmpty)
                            TextButton(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () {
                                setState(() {
                                  if (_elevesSelectionnes.length == _tousLesEleves.length) {
                                    _elevesSelectionnes.clear();
                                  } else {
                                    _elevesSelectionnes.addAll(_tousLesEleves.map((e) => e.id));
                                  }
                                });
                              },
                              child: Text(
                                _elevesSelectionnes.length == _tousLesEleves.length
                                    ? 'Tout désélectionner'
                                    : 'Tout sélectionner',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF2CE5A7)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Barre de recherche élève
                      TextField(
                        controller: _rechercheController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un élève...',
                          hintStyle: const TextStyle(color: Color(0xFF8E95B3), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF8E95B3)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: const Color(0xFF0B0D1B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF252A4A)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF2CE5A7)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingEleves)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2CE5A7)),
                          ),
                        )
                      else if (_tousLesEleves.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0D1B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF252A4A)),
                          ),
                          child: const Center(
                            child: Text(
                              'Aucun élève enregistré pour le moment.\nAjoutez d\'abord des élèves dans le répertoire.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E95B3)),
                            ),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0D1B),
                            border: Border.all(color: const Color(0xFF252A4A)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: elevesFiltres.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFF252A4A)),
                            itemBuilder: (context, idx) {
                              final el = elevesFiltres[idx];
                              final isSelected = _elevesSelectionnes.contains(el.id);
                              return CheckboxListTile(
                                dense: true,
                                value: isSelected,
                                activeColor: const Color(0xFF2CE5A7),
                                checkColor: const Color(0xFF0B0D1B),
                                title: Text(
                                  el.nom,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  el.niveau ?? 'Niveau non défini',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E95B3)),
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _elevesSelectionnes.add(el.id);
                                    } else {
                                      _elevesSelectionnes.remove(el.id);
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
              // Boutons d'action harmonisés (Fermer & Enregistrer/Créer)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          side: const BorderSide(color: Color(0xFF252A4A)),
                          foregroundColor: const Color(0xFF8E95B3),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Fermer',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2CE5A7),
                          foregroundColor: const Color(0xFF0B0D1B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          elevation: 0,
                        ),
                        onPressed: _isSaving ? null : _sauvegarder,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0D1B)),
                              )
                            : const Icon(Icons.check_rounded, size: 18, color: Color(0xFF0B0D1B)),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isEditing ? 'Enregistrer' : 'Créer le groupe',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B0D1B)),
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
