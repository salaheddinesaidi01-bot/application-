import 'package:flutter/material.dart';

class ProfProfile {
  static const List<String> titresDisponibles = [
    'Prof.',
    'M.',
    'Mme',
    'Dr.',
    'Ing.',
  ];

  static const List<Map<String, dynamic>> avatarsDisponibles = [
    {'id': 'school', 'label': 'École & Général', 'icon': Icons.school_rounded},
    {'id': 'calculate', 'label': 'Maths & Calcul', 'icon': Icons.calculate_rounded},
    {'id': 'science', 'label': 'Physique & Sciences', 'icon': Icons.science_rounded},
    {'id': 'book', 'label': 'Langues & Lettres', 'icon': Icons.menu_book_rounded},
    {'id': 'tech', 'label': 'Informatique & Tech', 'icon': Icons.computer_rounded},
    {'id': 'person', 'label': 'Enseignant Particulier', 'icon': Icons.person_rounded},
  ];

  final String titre;
  final String nom;
  final String specialite;
  final String telephone;
  final String email;
  final List<String> matieres;
  final int prixNormale1;
  final int prixNormale2;
  final int prixPrivee1;
  final int prixPrivee2;
  final List<int> tarifsNormale;
  final List<int> tarifsPrivee;
  final String devise;
  final String pinCode;
  final String avatar;
  final bool isConfigured;

  ProfProfile({
    this.titre = 'Prof.',
    required this.nom,
    this.specialite = '',
    this.telephone = '',
    this.email = '',
    required this.matieres,
    int? prixNormale1,
    int? prixNormale2,
    int? prixPrivee1,
    int? prixPrivee2,
    List<int>? tarifsNormale,
    List<int>? tarifsPrivee,
    this.devise = 'DZD',
    this.pinCode = '',
    this.avatar = 'school',
    this.isConfigured = false,
  })  : tarifsNormale = (tarifsNormale != null && tarifsNormale.isNotEmpty)
            ? tarifsNormale
            : [prixNormale1 ?? 1000, if (prixNormale2 != null) prixNormale2 else 1500],
        tarifsPrivee = (tarifsPrivee != null && tarifsPrivee.isNotEmpty)
            ? tarifsPrivee
            : [prixPrivee1 ?? 2000, if (prixPrivee2 != null) prixPrivee2 else 2500],
        prixNormale1 = (tarifsNormale != null && tarifsNormale.isNotEmpty)
            ? tarifsNormale.first
            : (prixNormale1 ?? 1000),
        prixNormale2 = (tarifsNormale != null && tarifsNormale.length > 1)
            ? tarifsNormale[1]
            : (prixNormale2 ?? (prixNormale1 ?? 1000)),
        prixPrivee1 = (tarifsPrivee != null && tarifsPrivee.isNotEmpty)
            ? tarifsPrivee.first
            : (prixPrivee1 ?? 2000),
        prixPrivee2 = (tarifsPrivee != null && tarifsPrivee.length > 1)
            ? tarifsPrivee[1]
            : (prixPrivee2 ?? (prixPrivee1 ?? 2000));

  String get nomComplet =>
      titre.isNotEmpty && nom.isNotEmpty ? '$titre $nom' : (nom.isNotEmpty ? nom : 'Enseignant');

  bool get hasPin => pinCode.trim().length >= 4;

  IconData get avatarIcon {
    switch (avatar) {
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

  factory ProfProfile.initial() {
    return ProfProfile(
      titre: 'Prof.',
      nom: '',
      specialite: '',
      telephone: '',
      email: '',
      matieres: const ['Mathématiques', 'Physique-Chimie'],
      prixNormale1: 1000,
      prixNormale2: 1500,
      prixPrivee1: 2000,
      prixPrivee2: 2500,
      tarifsNormale: const [1000, 1500],
      tarifsPrivee: const [2000, 2500],
      devise: 'DZD',
      pinCode: '',
      avatar: 'school',
      isConfigured: false,
    );
  }

  factory ProfProfile.empty() => ProfProfile.initial();

  factory ProfProfile.fromJson(Map<String, dynamic> json) {
    List<String> mats = [];
    if (json['matieres'] is List) {
      mats = (json['matieres'] as List).map((e) => e.toString()).toList();
    }
    final nomVal = json['nom']?.toString() ?? '';
    final isConfVal = json['isConfigured'] == true || (json['isConfigured']?.toString() == 'true');
    final isTrulyConfigured = isConfVal && nomVal.trim().isNotEmpty;

    final n1 = (json['prix_normale_1'] as num?)?.toInt() ?? 1000;
    final n2 = (json['prix_normale_2'] as num?)?.toInt() ?? 1500;
    final p1 = (json['prix_privee_1'] as num?)?.toInt() ?? 2000;
    final p2 = (json['prix_privee_2'] as num?)?.toInt() ?? 2500;

    List<int> tn = [];
    if (json['tarifs_normale'] is List) {
      tn = (json['tarifs_normale'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (tn.isEmpty) tn = [n1, n2];

    List<int> tp = [];
    if (json['tarifs_privee'] is List) {
      tp = (json['tarifs_privee'] as List).map((e) => (e as num).toInt()).toList();
    }
    if (tp.isEmpty) tp = [p1, p2];

    return ProfProfile(
      titre: json['titre']?.toString() ?? 'Prof.',
      nom: nomVal,
      specialite: json['specialite']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      matieres: mats.isNotEmpty ? mats : const ['Mathématiques', 'Physique-Chimie'],
      prixNormale1: n1,
      prixNormale2: n2,
      prixPrivee1: p1,
      prixPrivee2: p2,
      tarifsNormale: tn,
      tarifsPrivee: tp,
      devise: json['devise']?.toString() ?? 'DZD',
      pinCode: json['pin_code']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? 'school',
      isConfigured: isTrulyConfigured,
    );
  }

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'nom': nom,
        'specialite': specialite,
        'telephone': telephone,
        'email': email,
        'matieres': matieres,
        'prix_normale_1': prixNormale1,
        'prix_normale_2': prixNormale2,
        'prix_privee_1': prixPrivee1,
        'prix_privee_2': prixPrivee2,
        'tarifs_normale': tarifsNormale,
        'tarifs_privee': tarifsPrivee,
        'devise': devise,
        'pin_code': pinCode,
        'avatar': avatar,
        'isConfigured': isConfigured,
      };

  ProfProfile copyWith({
    String? titre,
    String? nom,
    String? specialite,
    String? telephone,
    String? email,
    List<String>? matieres,
    int? prixNormale1,
    int? prixNormale2,
    int? prixPrivee1,
    int? prixPrivee2,
    List<int>? tarifsNormale,
    List<int>? tarifsPrivee,
    String? devise,
    String? pinCode,
    String? avatar,
    bool? isConfigured,
  }) {
    return ProfProfile(
      titre: titre ?? this.titre,
      nom: nom ?? this.nom,
      specialite: specialite ?? this.specialite,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      matieres: matieres ?? this.matieres,
      prixNormale1: prixNormale1 ?? this.prixNormale1,
      prixNormale2: prixNormale2 ?? this.prixNormale2,
      prixPrivee1: prixPrivee1 ?? this.prixPrivee1,
      prixPrivee2: prixPrivee2 ?? this.prixPrivee2,
      tarifsNormale: tarifsNormale ?? this.tarifsNormale,
      tarifsPrivee: tarifsPrivee ?? this.tarifsPrivee,
      devise: devise ?? this.devise,
      pinCode: pinCode ?? this.pinCode,
      avatar: avatar ?? this.avatar,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}
