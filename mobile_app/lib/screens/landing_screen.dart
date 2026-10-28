import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prof_profile.dart';
import '../services/api_service.dart';
import '../main.dart';

class LandingScreen extends StatefulWidget {
  final bool isReviewMode;

  const LandingScreen({super.key, this.isReviewMode = false});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  // Mode : Présentation héroïque ou Assistant de création de compte
  bool _isWizardActive = false;
  int _currentStep = 0;
  final int _totalSteps = 4;
  late PageController _pageController;

  // Contrôleurs d'animations
  late AnimationController _entryController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _headerFade;
  late Animation<Offset> _bottomSlide;
  late Animation<double> _bottomFade;

  // Données du formulaire Enseignant
  String _selectedTitre = 'Prof.';
  String _selectedAvatar = 'school';
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  // Matières
  final List<String> _matieresSelectionnees = ['Mathématiques', 'Physique-Chimie'];
  final List<String> _matieresSuggerees = [
    'Mathématiques',
    'Physique-Chimie',
    'Sciences Naturelles (SVT)',
    'Français',
    'Arabe',
    'Anglais',
    'Philosophie',
    'Histoire-Géo',
    'Économie & Gestion',
    'Informatique',
    'Génie Mécanique',
    'Génie Électrique',
    'Génie Civil',
    'Sciences Islamiques',
    'Allemand',
    'Espagnol',
  ];
  final TextEditingController _customMatiereController = TextEditingController();

  // Tarifs dynamiques en DZD (saisie directe au clavier)
  final List<TextEditingController> _tarifsNormaleControllers = [
    TextEditingController(text: '1000'),
  ];
  final List<TextEditingController> _tarifsPriveeControllers = [
    TextEditingController(text: '2000'),
  ];

  bool _isSaving = false;
  String? _stepError;

  final List<String> _stepTitles = [
    'Identité & Contact',
    'Matières Enseignées',
    'Grille Tarifaire (DZD)',
    'Confirmation & Lancement',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 1. Animation d'entrée
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeIn),
      ),
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Animation flottante
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // 3. Animation de pulsation du bouton CTA
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 4. Animation de célébration
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _entryController.forward();

    // Charger les informations existantes si disponibles
    _prechargerProfilExistant();
  }

  Future<void> _prechargerProfilExistant() async {
    try {
      final prof = await ApiService.getProfProfile();
      if (prof.nom.isNotEmpty) {
        setState(() {
          _selectedTitre = prof.titre.isNotEmpty ? prof.titre : 'Prof.';
          _selectedAvatar = prof.avatar.isNotEmpty ? prof.avatar : 'school';
          _nomController.text = prof.nom;
          _telephoneController.text = prof.telephone;
          
          for (final c in _tarifsNormaleControllers) {
            c.dispose();
          }
          _tarifsNormaleControllers.clear();
          if (prof.tarifsNormale.isNotEmpty) {
            for (final t in prof.tarifsNormale) {
              _tarifsNormaleControllers.add(TextEditingController(text: '$t'));
            }
          } else {
            _tarifsNormaleControllers.add(TextEditingController(text: '1000'));
          }

          for (final c in _tarifsPriveeControllers) {
            c.dispose();
          }
          _tarifsPriveeControllers.clear();
          if (prof.tarifsPrivee.isNotEmpty) {
            for (final t in prof.tarifsPrivee) {
              _tarifsPriveeControllers.add(TextEditingController(text: '$t'));
            }
          } else {
            _tarifsPriveeControllers.add(TextEditingController(text: '2000'));
          }

          if (prof.matieres.isNotEmpty) {
            _matieresSelectionnees.clear();
            _matieresSelectionnees.addAll(prof.matieres);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _entryController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _pageController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _customMatiereController.dispose();
    for (final c in _tarifsNormaleControllers) {
      c.dispose();
    }
    for (final c in _tarifsPriveeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _demarrerAssistant() {
    setState(() {
      _isWizardActive = true;
      _currentStep = 0;
      _stepError = null;
    });
  }

  void _annulerAssistant() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() {
        _isWizardActive = false;
      });
    }
  }

  void _etapeSuivante() {
    setState(() => _stepError = null);

    // Validation par étape
    if (_currentStep == 0) {
      if (_nomController.text.trim().isEmpty) {
        setState(() => _stepError = 'Veuillez saisir votre nom complet.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_matieresSelectionnees.isEmpty) {
        setState(() => _stepError = 'Veuillez sélectionner au moins une matière.');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finaliserEtLancer() async {
    setState(() => _isSaving = true);

    final List<int> tarifsNormale = _tarifsNormaleControllers
        .map((c) => int.tryParse(c.text.trim()) ?? 0)
        .where((t) => t > 0)
        .toList();
    final List<int> tarifsPrivee = _tarifsPriveeControllers
        .map((c) => int.tryParse(c.text.trim()) ?? 0)
        .where((t) => t > 0)
        .toList();

    final prof = ProfProfile(
      titre: _selectedTitre,
      nom: _nomController.text.trim(),
      specialite: '',
      telephone: _telephoneController.text.trim(),
      email: '',
      matieres: List<String>.from(_matieresSelectionnees),
      tarifsNormale: tarifsNormale.isNotEmpty ? tarifsNormale : [1000],
      tarifsPrivee: tarifsPrivee.isNotEmpty ? tarifsPrivee : [2000],
      devise: 'DZD',
      pinCode: '',
      avatar: _selectedAvatar,
      isConfigured: true,
    );

    try {
      await ApiService.saveProfProfile(prof);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bienvenue, ${prof.nomComplet} ! Votre espace est prêt.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      if (widget.isReviewMode) {
        Navigator.of(context).pop(prof);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _stepError = 'Erreur lors de la sauvegarde : $e';
        });
      }
    }
  }

  void _ajouterMatierePersonnalisee() {
    final nouvelle = _customMatiereController.text.trim();
    if (nouvelle.isEmpty) return;
    setState(() {
      if (!_matieresSuggerees.contains(nouvelle)) {
        _matieresSuggerees.add(nouvelle);
      }
      if (!_matieresSelectionnees.contains(nouvelle)) {
        _matieresSelectionnees.add(nouvelle);
      }
      _customMatiereController.clear();
      _stepError = null;
    });
  }

  IconData _getIconForAvatar(String id) {
    switch (id) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'tech':
        return Icons.computer_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'school':
      default:
        return Icons.school_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // CARTE ENSEIGNANT ANIMÉE EN DIRECT (LIVE PREVIEW)
  // ---------------------------------------------------------------------------
  Widget _buildLiveTeacherCard(bool isDark) {
    final nomAffiche = _nomController.text.trim().isNotEmpty
        ? '$_selectedTitre ${_nomController.text.trim()}'
        : '$_selectedTitre Votre Nom Ici';
    final specialiteAffichee = _matieresSelectionnees.isNotEmpty
        ? _matieresSelectionnees.join(', ')
        : 'Cours de soutien & Suivi pédagogique';
    final telAffiche = _telephoneController.text.trim().isNotEmpty
        ? _telephoneController.text.trim()
        : '05 / 06 / 07 XX XX XX';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF86F2E4).withValues(alpha: 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061449).withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF86F2E4).withValues(alpha: 0.20),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar avec lueur
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF86F2E4), width: 2),
                ),
                child: Icon(
                  _getIconForAvatar(_selectedAvatar),
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomAffiche,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      specialiteAffichee,
                      style: const TextStyle(
                        color: Color(0xFF86F2E4),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A61),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86F2E4), width: 1),
                ),
                child: const Text(
                  'DZD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  telAffiche,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉCRAN PRÉSENTATION HERO (SI PAS DANS L'ASSISTANT)
  // ---------------------------------------------------------------------------
  Widget _buildPresentationView(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          if (widget.isReviewMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Présentation de l\'Application',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo flottant
                  AnimatedBuilder(
                    animation: Listenable.merge([_entryController, _floatController]),
                    builder: (context, child) {
                      final floatOffset = -7 * math.sin(_floatController.value * math.pi);
                      return Transform.translate(
                        offset: Offset(0, floatOffset),
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoFade.value,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF061449), Color(0xFF1E2A5E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF86F2E4).withValues(alpha: 0.6),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF061449).withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: const Color(0xFF86F2E4).withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 54,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Titre & description
                  SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: Column(
                        children: [
                          Text(
                            'Gestion Soutien Scolaire',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : const Color(0xFF061449),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Application professionnelle et autonome conçue pour les enseignants en Algérie. Créez votre compte en quelques étapes et gérez vos élèves, groupes et finances en toute sérénité.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: isDark ? Colors.grey[300] : const Color(0xFF556080),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Aperçu des fonctionnalités
                  _buildFeatureCard(
                    isDark: isDark,
                    icon: Icons.person_add_alt_1_rounded,
                    color: const Color(0xFF006A61),
                    badgeText: 'NOUVEAU',
                    title: 'Création de Compte Enseignant de A à Z',
                    description:
                        'Personnalisez votre titre, votre nom, vos coordonnées WhatsApp, vos matières et votre grille tarifaire en DZD.',
                  ),
                  _buildFeatureCard(
                    isDark: isDark,
                    icon: Icons.groups_2_rounded,
                    color: const Color(0xFF1E2A5E),
                    title: 'Groupes de Soutien & Paiements Groupés',
                    description:
                        'Regroupez vos élèves par niveau (Primaire, CEM, Lycée BAC). Planifiez des séances collectives et encaissez tous les élèves en 1 clic.',
                  ),
                  _buildFeatureCard(
                    isDark: isDark,
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF10B981),
                    badgeText: 'PRIVÉ & LOCAL',
                    title: 'Données Privées & Sécurisées',
                    description:
                        'Fonctionnement 100% autonome et local sur votre appareil sans dépendance',
                  ),
                  _buildFeatureCard(
                    isDark: isDark,
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFFFB95F),
                    title: 'Finances & Historique en Dinars Algériens (DZD)',
                    description:
                        'Suivi automatique des paiements, gestion des impayés, reçus et clôtures mensuelles pour une comptabilité irréprochable.',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Barre inférieure CTA
          SlideTransition(
            position: _bottomSlide,
            child: FadeTransition(
              opacity: _bottomFade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D42) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (0.025 * _pulseController.value);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF061449),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF061449).withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          onPressed: _demarrerAssistant,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isReviewMode
                                    ? 'MODIFIER MON COMPTE ENSEIGNANT'
                                    : 'CRÉER MON COMPTE ENSEIGNANT',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isReviewMode
                          ? 'Vous pouvez reconfigurer votre nom, vos tarifs et vos matières.'
                          : 'Configuration simple et intuitive en 4 étapes rapides.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    String? badgeText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeText != null
              ? color.withValues(alpha: isDark ? 0.6 : 0.4)
              : (isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF)),
          width: badgeText != null ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF061449),
                        ),
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, const Color(0xFF86F2E4)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : const Color(0xFF556080),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ASSISTANT DE CRÉATION DE COMPTE (WIZARD 5 ÉTAPES)
  // ---------------------------------------------------------------------------
  Widget _buildWizardView(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          // Barre de navigation supérieure de l'assistant
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D42) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: _annulerAssistant,
                      tooltip: 'Étape précédente',
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Étape ${_currentStep + 1} sur $_totalSteps',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006A61),
                            ),
                          ),
                          Text(
                            _stepTitles[_currentStep],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF061449),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A61).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006A61),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Barre de progression fluide
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF006A61)),
                  ),
                ),
              ],
            ),
          ),

          // Message d'erreur s'il y en a
          if (_stepError != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _stepError!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // PageView des 4 étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) {
                setState(() {
                  _currentStep = idx;
                  _stepError = null;
                });
                if (idx == 3) {
                  _celebrationController.forward(from: 0.0);
                }
              },
              children: [
                _buildStep1Identite(isDark),
                _buildStep2Matieres(isDark),
                _buildStep3Tarifs(isDark),
                _buildStep5Confirmation(isDark),
              ],
            ),
          ),

          // Barre d'actions inférieure (Précédent / Suivant / Terminer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D42) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                        ),
                        onPressed: _annulerAssistant,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Précédent'),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF061449),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _currentStep == _totalSteps - 1
                          ? (_isSaving ? null : _finaliserEtLancer)
                          : _etapeSuivante,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep == _totalSteps - 1
                                        ? 'OUVRIR MON ESPACE 🚀'
                                        : 'Continuer',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep == _totalSteps - 1
                                        ? Icons.rocket_launch_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉTAPE 1 : IDENTITÉ & CONTACT
  // ---------------------------------------------------------------------------
  Widget _buildStep1Identite(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte live preview
          _buildLiveTeacherCard(isDark),
          const SizedBox(height: 20),

          // Civilité
          Text(
            'Civilité / Titre :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF061449),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProfProfile.titresDisponibles.map((titre) {
                final isSelected = _selectedTitre == titre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(titre),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTitre = titre);
                    },
                    selectedColor: const Color(0xFF006A61),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Choix Avatar
          Text(
            'Icône de profil :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF061449),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ProfProfile.avatarsDisponibles.map((av) {
                final id = av['id'] as String;
                final isSelected = _selectedAvatar == id;
                final icon = av['icon'] as IconData;
                final label = av['label'] as String;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatar = id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF006A61).withValues(alpha: 0.15)
                          : (isDark ? const Color(0xFF131D42) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF006A61) : (isDark ? Colors.white24 : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: isSelected ? const Color(0xFF006A61) : Colors.grey, size: 26),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF006A61) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Nom & Prénom
          TextFormField(
            controller: _nomController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nom et Prénom *',
              hintText: 'Ex: Mohamed Salah, Amine Kaci...',
              prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF006A61)),
              filled: true,
              fillColor: isDark ? const Color(0xFF131D42) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          // Téléphone
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Numéro de Téléphone / WhatsApp',
              hintText: 'Ex: 0555 12 34 56',
              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF006A61)),
              filled: true,
              fillColor: isDark ? const Color(0xFF131D42) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ÉTAPE 2 : MATIÈRES ENSEIGNÉES
  // ---------------------------------------------------------------------------
  Widget _buildStep2Matieres(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Matières dispensées :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF061449),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A61).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_matieresSelectionnees.length} sélectionnée(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A61),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les matières que vous enseignez dans vos cours de soutien :',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : const Color(0xFF556080),
            ),
          ),
          const SizedBox(height: 14),

          // Liste des puces de matières
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _matieresSuggerees.map((matiere) {
              final isSelected = _matieresSelectionnees.contains(matiere);
              return FilterChip(
                label: Text(matiere),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _matieresSelectionnees.add(matiere);
                    } else {
                      _matieresSelectionnees.remove(matiere);
                    }
                    _stepError = null;
                  });
                },
                selectedColor: const Color(0xFF006A61),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: isDark ? const Color(0xFF131D42) : const Color(0xFFF1F5F9),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Ajouter une matière sur mesure
          Text(
            'Ajouter une autre matière personnalisée :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF061449),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _customMatiereController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Comptabilité, Droit, Robotique...',
                    prefixIcon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF006A61)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF131D42) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onFieldSubmitted: (_) => _ajouterMatierePersonnalisee(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _ajouterMatierePersonnalisee,
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // ÉTAPE 3 : TARIFS EN DINARS ALGÉRIENS (DZD)
  // ---------------------------------------------------------------------------
  Widget _buildStep3Tarifs(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF006A61).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006A61).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on_rounded, color: Color(0xFF006A61), size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grille Tarifaire par Défaut en DZD',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Définissez vos tarifs de groupe et privés avec saisie directe. Vous pouvez ajouter autant de tarifs que nécessaire.',
                        style: TextStyle(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 1. Tarif Standard (Séances de groupe)
          _buildTarifsSection(
            title: 'Tarif Standard (Séances de groupe)',
            subtitle: 'Tarif appliqué par défaut pour les groupes',
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
          const SizedBox(height: 18),

          // 2. Tarif Privé (Séances particulières)
          _buildTarifsSection(
            title: 'Tarif Privé (Séances particulières)',
            subtitle: 'Tarif pour les cours individuels / privés',
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTarifsSection({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D42) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Choix du mode: 1 tarif unique vs Plusieurs tarifs
          Row(
            children: [
              ChoiceChip(
                label: const Text('1 tarif unique'),
                selected: !isMultiple,
                selectedColor: color.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
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
                  fontSize: 12,
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
          const SizedBox(height: 12),

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
                prefixIcon: Icon(Icons.payments_outlined, color: color, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controllers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ctrl = controllers[index];
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Tarif ${index + 1}',
                          suffixText: 'DZD',
                          suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: color),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (controllers.length > 1) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        tooltip: 'Supprimer ce tarif',
                        onPressed: () => onRemove(index),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter un tarif'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: color.withValues(alpha: 0.5)),
              ),
              onPressed: onAdd,
            ),
          ],
        ],
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // ÉTAPE 5 : CONFIRMATION & LANCEMENT
  // ---------------------------------------------------------------------------
  Widget _buildStep5Confirmation(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Animation de succès
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _celebrationController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF10B981), width: 3),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 58,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Votre Profil est Prêt !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF061449),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Voici le récapitulatif de votre compte enseignant :',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : const Color(0xFF556080),
            ),
          ),
          const SizedBox(height: 20),

          // Carte finale récapitulative
          _buildLiveTeacherCard(isDark),
          const SizedBox(height: 16),

          // Récapitulatif des matières
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D42) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matières enregistrées :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _matieresSelectionnees.map((m) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A61).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006A61),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Récapitulatif des tarifs
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D42) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarifs configurés :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._tarifsNormaleControllers.asMap().entries.map(
                      (e) => _buildMiniTarif(
                        _tarifsNormaleControllers.length == 1 ? 'Standard' : 'Standard ${e.key + 1}',
                        '${e.value.text.isEmpty ? "0" : e.value.text} DZD',
                      ),
                    ),
                    ..._tarifsPriveeControllers.asMap().entries.map(
                      (e) => _buildMiniTarif(
                        _tarifsPriveeControllers.length == 1 ? 'Privé' : 'Privé ${e.key + 1}',
                        '${e.value.text.isEmpty ? "0" : e.value.text} DZD',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMiniTarif(String label, String montant) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF061449).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            montant,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006A61)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan dégradé
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF061449),
                          const Color(0xFF0A1128),
                          const Color(0xFF0A1128),
                        ]
                      : [
                          const Color(0xFFE5EEFF),
                          const Color(0xFFF8F9FF),
                          Colors.white,
                        ],
                ),
              ),
            ),
          ),

          // Sphères décoratives en arrière-plan
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, _) {
              final val = _floatController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -40 + (15 * math.sin(val * math.pi)),
                    right: -50 + (10 * math.cos(val * math.pi)),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (isDark ? const Color(0xFF1E2A5E) : const Color(0xFF86F2E4))
                                .withValues(alpha: isDark ? 0.35 : 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 240 + (12 * math.cos(val * math.pi)),
                    left: -60 + (8 * math.sin(val * math.pi)),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF006A61).withValues(alpha: isDark ? 0.25 : 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Basculement entre la Vue Présentation et le Wizard de Création
          _isWizardActive ? _buildWizardView(isDark) : _buildPresentationView(isDark),
        ],
      ),
    );
  }
}
