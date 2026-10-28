import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NouvelEleveDialog extends StatefulWidget {
  const NouvelEleveDialog({super.key});

  @override
  State<NouvelEleveDialog> createState() => _NouvelEleveDialogState();
}

class _NouvelEleveDialogState extends State<NouvelEleveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _niveauController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _telephoneParentController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  String _domaineChoisi = 'Lycée';

  final Map<String, List<String>> _niveauxParDomaine = {
    'Primaire': ['Primaire', '1ère AP', '2ème AP', '3ème AP', '4ème AP', '5ème AP'],
    'CEM': ['1ère année', '2ème année', '3ème année', '4ème année'],
    'Lycée': ['1AS', '2AS', '2M', '2TM', '3AS', '3M', '3TM'],
  };

  @override
  void dispose() {
    _nomController.dispose();
    _niveauController.dispose();
    _telephoneController.dispose();
    _telephoneParentController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final eleve = await ApiService.ajouterEleve(
        nom: _nomController.text.trim(),
        niveau: _niveauController.text.trim().isEmpty ? null : _niveauController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        telephoneParent: _telephoneParentController.text.trim().isEmpty ? null : _telephoneParentController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(eleve);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkSurface = Color(0xFF16192E);
    const darkInputBg = Color(0xFF0B0D1B);
    const darkBorder = Color(0xFF252A4A);
    const neonMint = Color(0xFF2CE5A7);
    const darkNavyText = Color(0xFF0B0D1B);
    const mutedText = Color(0xFF8E95B3);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: darkBorder, width: 1.2),
      ),
      backgroundColor: darkSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                          color: neonMint.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: neonMint, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Ajouter un élève',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Création du profil élève',
                              style: TextStyle(
                                fontSize: 13,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: mutedText),
                        tooltip: 'Fermer',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Champ Nom
                  const Text(
                    'Nom et Prénom *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nomController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nom et prénom de l\'élève',
                      hintStyle: const TextStyle(color: mutedText, fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline, color: neonMint, size: 20),
                      filled: true,
                      fillColor: darkInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: neonMint, width: 1.5),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Le nom de l\'élève est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Domaine d'enseignement (Primaire, CEM, Lycée)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Domaine & Niveau scolaire *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (_niveauController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: neonMint.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: neonMint.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Text(
                            _niveauController.text,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: neonMint,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Sélecteur de domaine (Primaire, CEM, Lycée)
                  Container(
                    decoration: BoxDecoration(
                      color: darkInputBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: darkBorder, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['Primaire', 'CEM', 'Lycée'].map((domaine) {
                        final isSelected = _domaineChoisi == domaine;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _domaineChoisi = domaine;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? neonMint : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                domaine,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? darkNavyText : mutedText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Liste des niveaux pour le domaine choisi
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: (_niveauxParDomaine[_domaineChoisi] ?? []).map((niv) {
                        final isCurrent = _niveauController.text == niv;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(niv, style: const TextStyle(fontSize: 11)),
                            selected: isCurrent,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            selectedColor: neonMint,
                            labelStyle: TextStyle(
                              color: isCurrent ? darkNavyText : mutedText,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            ),
                            backgroundColor: darkInputBg,
                            side: BorderSide(
                              color: isCurrent ? neonMint : darkBorder,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            showCheckmark: false,
                            onSelected: (selected) {
                              setState(() {
                                _niveauController.text = selected ? niv : '';
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Champ texte du niveau (modifiable)
                  TextFormField(
                    controller: _niveauController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Sélectionnez ou saisissez le niveau',
                      hintStyle: const TextStyle(color: mutedText, fontSize: 13),
                      prefixIcon: const Icon(Icons.school_outlined, color: neonMint, size: 20),
                      filled: true,
                      fillColor: darkInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: neonMint, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ Téléphone
                  const Text(
                    'Numéro de téléphone',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '0555 12 34 56',
                      hintStyle: const TextStyle(color: mutedText, fontSize: 13),
                      prefixIcon: const Icon(Icons.phone_outlined, color: neonMint, size: 20),
                      filled: true,
                      fillColor: darkInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: neonMint, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ Téléphone Parents
                  const Text(
                    'Numéro de téléphone des parents',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _telephoneParentController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '0661 12 34 56 (Père / Mère)',
                      hintStyle: const TextStyle(color: mutedText, fontSize: 13),
                      prefixIcon: const Icon(Icons.contact_phone_outlined, color: neonMint, size: 20),
                      filled: true,
                      fillColor: darkInputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: darkBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: neonMint, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action harmonisés (Fermer & Ajouter)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mutedText,
                              side: const BorderSide(color: darkBorder, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
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
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _sauvegarder,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: darkNavyText),
                                  )
                                : const Icon(Icons.check_rounded, size: 18, color: darkNavyText),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isSaving ? 'Enregistrement...' : 'Ajouter l\'élève',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkNavyText),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonMint,
                              foregroundColor: darkNavyText,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              elevation: 0,
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
}
