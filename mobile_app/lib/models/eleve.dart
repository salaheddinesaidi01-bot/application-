class Eleve {
  final String idEleve;
  final String nom;
  final String? niveau;
  final String? telephone;
  final String? telephoneParent;
  final String? email;
  final String statut; // 'Actif' ou 'Inactif'
  final DateTime? dateAjout;

  final String? idGroupe;
  final String? nomGroupe;

  Eleve({
    required this.idEleve,
    required this.nom,
    this.niveau,
    this.telephone,
    this.telephoneParent,
    this.email,
    required this.statut,
    this.dateAjout,
    this.idGroupe,
    this.nomGroupe,
  });

  bool get estActif => statut.toLowerCase() == 'actif';
  bool get isActif => estActif;
  String get id => idEleve;
  bool get aGroupe => idGroupe != null && idGroupe!.trim().isNotEmpty;
  bool get sansGroupe => !aGroupe;

  Eleve copyWith({
    String? idEleve,
    String? nom,
    String? niveau,
    String? telephone,
    String? telephoneParent,
    String? email,
    String? statut,
    DateTime? dateAjout,
    String? idGroupe,
    String? nomGroupe,
  }) {
    return Eleve(
      idEleve: idEleve ?? this.idEleve,
      nom: nom ?? this.nom,
      niveau: niveau ?? this.niveau,
      telephone: telephone ?? this.telephone,
      telephoneParent: telephoneParent ?? this.telephoneParent,
      email: email ?? this.email,
      statut: statut ?? this.statut,
      dateAjout: dateAjout ?? this.dateAjout,
      idGroupe: idGroupe ?? this.idGroupe,
      nomGroupe: nomGroupe ?? this.nomGroupe,
    );
  }

  factory Eleve.fromJson(Map<String, dynamic> json) {
    return Eleve(
      idEleve: json['id_eleve']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      niveau: json['niveau']?.toString(),
      telephone: json['telephone']?.toString(),
      telephoneParent: json['telephone_parent']?.toString(),
      email: json['email']?.toString(),
      statut: json['statut']?.toString() ?? 'Actif',
      dateAjout: json['date_ajout'] != null
          ? DateTime.tryParse(json['date_ajout'].toString())
          : null,
      idGroupe: json['id_groupe']?.toString(),
      nomGroupe: json['nom_groupe']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_eleve': idEleve,
      'nom': nom,
      'niveau': niveau,
      'telephone': telephone,
      'telephone_parent': telephoneParent,
      'email': email,
      'statut': statut,
      'id_groupe': idGroupe,
      'nom_groupe': nomGroupe,
    };
  }
}
