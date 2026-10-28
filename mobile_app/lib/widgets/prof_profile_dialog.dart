import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prof_profile.dart';
import '../services/api_service.dart';

class ProfProfileDialog extends StatefulWidget {
  final ProfProfile? currentProfile;
  final bool isInitialSetup;

  const ProfProfileDialog({
    super.key,
    this.currentProfile,
    this.isInitialSetup = false,
  });

  @override
  State<ProfProfileDialog> createState() => _ProfProfileDialogState();
}

class _ProfProfileDialogState extends State<ProfProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _titre;
  late String _avatar;
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;

  late List<TextEditingController> _tarifsNormaleControllers;
  late List<TextEditingController> _tarifsPriveeControllers;
  final TextEditingController _nouvelleMatiereController = TextEditingController();

  final List<String> _matieresSelectionnees = [];
  final List<String> _matieresDisponibles = [
    'Mathématiques',
    'Physique-Chimie',
    'Sciences Naturelles',
    'Français',
    'Arabe',
    'Anglais',
    'Philosophie',
    'Histoire-Géo',
    'Économie & Gestion',
    'Informatique',
  ];

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.currentProfile;
    _titre = (p != null && p.titre.isNotEmpty) ? p.titre : 'Prof.';
    _avatar = (p != null && p.avatar.isNotEmpty) ? p.avatar : 'school';

    _nomController = TextEditingController(text: p?.nom ?? '');
    _telephoneController = TextEditingController(text: p?.telephone ?? '');

    final tNormale = p?.tarifsNormale ?? [];
    if (tNormale.isNotEmpty) {
      _tarifsNormaleControllers = tNormale
          .map((val) => TextEditingController(text: val.toString()))
          .toList();
    } else {
      _tarifsNormaleControllers = [
        TextEditingController(
            text: (p != null && p.prixNormale1 > 0) ? p.prixNormale1.toString() : '1000')
      ];
      if (p != null && p.prixNormale2 > 0) {
        _tarifsNormaleControllers.add(TextEditingController(text: p.prixNormale2.toString()));
      }
    }

    final tPrivee = p?.tarifsPrivee ?? [];
    if (tPrivee.isNotEmpty) {
      _tarifsPriveeControllers = tPrivee
          .map((val) => TextEditingController(text: val.toString()))
          .toList();
    } else {
      _tarifsPriveeControllers = [
        TextEditingController(
            text: (p != null && p.prixPrivee1 > 0) ? p.prixPrivee1.toString() : '2000')
      ];
      if (p != null && p.prixPrivee2 > 0) {
        _tarifsPriveeControllers.add(TextEditingController(text: p.prixPrivee2.toString()));
      }
    }

    if (p != null && p.matieres.isNotEmpty) {
      _matieresSelectionnees.addAll(p.matieres);
      for (final m in p.matieres) {
        if (!_matieresDisponibles.contains(m)) {
          _matieresDisponibles.add(m);
        }
      }
    } else {
      _matieresSelectionnees.addAll(['Mathématiques', 'Physique-Chimie']);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    for (final c in _tarifsNormaleControllers) {
      c.dispose();
    }
    for (final c in _tarifsPriveeControllers) {
      c.dispose();
    }
    _nouvelleMatiereController.dispose();
    super.dispose();
  }

  void _ajouterMatiereManuelle() {
    final nouvelle = _nouvelleMatiereController.text.trim();
    if (nouvelle.isEmpty) return;

    setState(() {
      if (!_matieresDisponibles.contains(nouvelle)) {
        _matieresDisponibles.add(nouvelle);
      }
      if (!_matieresSelectionnees.contains(nouvelle)) {
        _matieresSelectionnees.add(nouvelle);
      }
      _nouvelleMatiereController.clear();
    });
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_matieresSelectionnees.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner au moins une matière.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final tarifsNormale = _tarifsNormaleControllers
          .map((c) => int.tryParse(c.text.trim()) ?? 0)
          .where((v) => v > 0)
          .toList();
      final tarifsPrivee = _tarifsPriveeControllers
          .map((c) => int.tryParse(c.text.trim()) ?? 0)
          .where((v) => v > 0)
          .toList();

      final updatedProfile = ProfProfile(
        titre: _titre,
        nom: _nomController.text.trim(),
        specialite: '',
        telephone: _telephoneController.text.trim(),
        email: '',
        avatar: _avatar,
        pinCode: '',
        matieres: List<String>.from(_matieresSelectionnees),
        prixNormale1: tarifsNormale.isNotEmpty ? tarifsNormale.first : 1000,
        prixNormale2: tarifsNormale.length > 1 ? tarifsNormale[1] : 0,
        prixPrivee1: tarifsPrivee.isNotEmpty ? tarifsPrivee.first : 2000,
        prixPrivee2: tarifsPrivee.length > 1 ? tarifsPrivee[1] : 0,
        tarifsNormale: tarifsNormale,
        tarifsPrivee: tarifsPrivee,
        devise: 'DZD',
        isConfigured: true,
      );

      await ApiService.saveProfProfile(updatedProfile);

      if (mounted) {
        Navigator.of(context).pop(updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Erreur lors de la sauvegarde : $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xFF061449);
    const tealColor = Color(0xFF006A61);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF131D42) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.badge_rounded, color: primaryColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isInitialSetup
                                  ? 'Configuration Enseignant'
                                  : 'Modifier mon Profil Enseignant',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              'Identité, contact, matières & tarifs en DZD',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isInitialSetup)
                        IconButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Avatar selector
                  Text(
                    'Icône de profil & Avatar',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ProfProfile.avatarsDisponibles.map((av) {
                      final isSelected = _avatar == av['id'];
                      return InkWell(
                        onTap: () => setState(() => _avatar = av['id'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? const Color(0xFF2D2B55) : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? tealColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                av['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? const Color(0xFF86F2E4)
                                    : (isDark ? Colors.white70 : const Color(0xFF1E2A5E)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                av['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.grey[300] : const Color(0xFF374151)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // 2. Titre & Nom
                  Text(
                    'Civilité & Titre d\'enseignant',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ProfProfile.titresDisponibles.map((t) {
                      final isSelected = _titre == t;
                      return ChoiceChip(
                        label: Text(t),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        backgroundColor: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF3F4F6),
                        onSelected: (val) {
                          if (val) setState(() => _titre = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Nom & Prénom *',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nomController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Ex: Benali Mohamed',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 1.8),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Veuillez saisir votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Contact (Téléphone / WhatsApp)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Téléphone / WhatsApp',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '0550 12 34 56',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Matières enseignées
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Matières enseignées *',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                        ),
                      ),
                      Text(
                        '${_matieresSelectionnees.length} sélectionnée(s)',
                        style: const TextStyle(fontSize: 11, color: tealColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _matieresDisponibles.map((matiere) {
                      final isSelected = _matieresSelectionnees.contains(matiere);
                      return FilterChip(
                        label: Text(
                          matiere,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[300] : const Color(0xFF374151)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        checkmarkColor: Colors.white,
                        backgroundColor:
                            isDark ? const Color(0xFF2D2B55) : const Color(0xFFF3F4F6),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _matieresSelectionnees.add(matiere);
                            } else {
                              _matieresSelectionnees.remove(matiere);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Ajouter une matière personnalisée manuellement
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nouvelleMatiereController,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Autre matière...',
                            prefixIcon: const Icon(Icons.add_circle_outline, size: 18),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2D2B55) : const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                          ),
                          onSubmitted: (_) => _ajouterMatiereManuelle(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _ajouterMatiereManuelle,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 6. Définition des Prix par l'enseignant
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Grille Tarifaire (DZD)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Séances Normales (Standard)
                        _buildDynamicTarifSection(
                          title: 'Tarif Standard (Séances de groupe)',
                          subtitle: 'Tarif appliqué par défaut pour les cours en groupe',
                          icon: Icons.groups_rounded,
                          controllers: _tarifsNormaleControllers,
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                          onAdd: () {
                            setState(() {
                              _tarifsNormaleControllers.add(TextEditingController(text: '1000'));
                            });
                          },
                          onRemove: (index) {
                            setState(() {
                              _tarifsNormaleControllers[index].dispose();
                              _tarifsNormaleControllers.removeAt(index);
                            });
                          },
                          onSetSingle: () {
                            if (_tarifsNormaleControllers.length > 1) {
                              setState(() {
                                for (int i = 1; i < _tarifsNormaleControllers.length; i++) {
                                  _tarifsNormaleControllers[i].dispose();
                                }
                                _tarifsNormaleControllers.removeRange(1, _tarifsNormaleControllers.length);
                              });
                            }
                          },
                          onSetMultiple: () {
                            if (_tarifsNormaleControllers.length == 1) {
                              setState(() {
                                _tarifsNormaleControllers.add(TextEditingController(text: '1200'));
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Séances Privées (Individuel)
                        _buildDynamicTarifSection(
                          title: 'Tarif Privé (Séances particulières)',
                          subtitle: 'Tarif pour les cours individuels / particuliers',
                          icon: Icons.person_rounded,
                          controllers: _tarifsPriveeControllers,
                          color: const Color(0xFF006A61),
                          isDark: isDark,
                          onAdd: () {
                            setState(() {
                              _tarifsPriveeControllers.add(TextEditingController(text: '2000'));
                            });
                          },
                          onRemove: (index) {
                            setState(() {
                              _tarifsPriveeControllers[index].dispose();
                              _tarifsPriveeControllers.removeAt(index);
                            });
                          },
                          onSetSingle: () {
                            if (_tarifsPriveeControllers.length > 1) {
                              setState(() {
                                for (int i = 1; i < _tarifsPriveeControllers.length; i++) {
                                  _tarifsPriveeControllers[i].dispose();
                                }
                                _tarifsPriveeControllers.removeRange(1, _tarifsPriveeControllers.length);
                              });
                            }
                          },
                          onSetMultiple: () {
                            if (_tarifsPriveeControllers.length == 1) {
                              setState(() {
                                _tarifsPriveeControllers.add(TextEditingController(text: '2500'));
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action harmonisés (Fermer & Enregistrer)
                  if (widget.isInitialSetup)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _sauvegarder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Enregistrer & Démarrer l\'Espace',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Fermer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _sauvegarder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Enregistrer',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTarifSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<TextEditingController> controllers,
    required Color color,
    required bool isDark,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
    required VoidCallback onSetSingle,
    required VoidCallback onSetMultiple,
  }) {
    final isMultiple = controllers.length > 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1128) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Choix du mode: 1 tarif unique vs Plusieurs tarifs
          Row(
            children: [
              ChoiceChip(
                label: const Text('1 tarif unique'),
                selected: !isMultiple,
                selectedColor: color.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: !isMultiple ? FontWeight.bold : FontWeight.normal,
                  color: !isMultiple ? color : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
                onSelected: (selected) {
                  if (selected && isMultiple) {
                    onSetSingle();
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Plusieurs tarifs'),
                selected: isMultiple,
                selectedColor: color.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isMultiple ? FontWeight.bold : FontWeight.normal,
                  color: isMultiple ? color : (isDark ? Colors.grey[300] : Colors.grey[700]),
                ),
                onSelected: (selected) {
                  if (selected && !isMultiple) {
                    onSetMultiple();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Saisie directe
          if (!isMultiple && controllers.isNotEmpty)
            TextFormField(
              controller: controllers[0],
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Montant en DZD',
                hintText: 'Ex: 1000',
                suffixText: 'DZD',
                suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: color),
                prefixIcon: Icon(Icons.payments_outlined, color: color, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Requis';
                }
                if (int.tryParse(val.trim()) == null) {
                  return 'Invalide';
                }
                return null;
              },
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controllers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ctrl = controllers[index];
                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Tarif ${index + 1}',
                          suffixText: 'DZD',
                          suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: color),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Requis';
                          }
                          if (int.tryParse(val.trim()) == null) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (controllers.length > 1) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        tooltip: 'Supprimer ce tarif',
                        onPressed: () => onRemove(index),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ajouter un tarif'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide(color: color.withValues(alpha: 0.5)),
              ),
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}
