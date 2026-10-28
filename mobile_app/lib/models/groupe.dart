class GroupeEleveMembre {
  final String idEleve;
  final String nom;
  final String? niveau;
  final String? telephone;

  GroupeEleveMembre({
    required this.idEleve,
    required this.nom,
    this.niveau,
    this.telephone,
  });

  String get id => idEleve;
  String get nomEleve => nom;

  factory GroupeEleveMembre.fromJson(Map<String, dynamic> json) {
    return GroupeEleveMembre(
      idEleve: json['id_eleve']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      niveau: json['niveau']?.toString(),
      telephone: json['telephone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_eleve': idEleve,
      'nom': nom,
      'niveau': niveau,
      'telephone': telephone,
    };
  }
}

class Groupe {
  final String idGroupe;
  final String nom;
  final String? niveau;
  final int tarifParEleve;
  final String? description;
  final DateTime? dateCreation;
  final int totalEleves;
  final List<GroupeEleveMembre> eleves;
  final int countImpayes;
  final int totalImpaye;
  final String? derniereSeanceDate;
  final String? derniereSeanceHeure;
  final int? derniereSeancePresents;

  String get id => idGroupe;
  double get tarifParDefaut => tarifParEleve.toDouble();
  double get tarifSuggere => tarifParEleve.toDouble();
  int get seancesImpayeesCount => countImpayes;

  Groupe({
    required this.idGroupe,
    required this.nom,
    this.niveau,
    required this.tarifParEleve,
    this.description,
    this.dateCreation,
    this.totalEleves = 0,
    this.eleves = const [],
    this.countImpayes = 0,
    this.totalImpaye = 0,
    this.derniereSeanceDate,
    this.derniereSeanceHeure,
    this.derniereSeancePresents,
  });

  factory Groupe.fromJson(Map<String, dynamic> json) {
    List<GroupeEleveMembre> members = [];
    if (json['eleves'] is List) {
      members = (json['eleves'] as List)
          .map((e) => GroupeEleveMembre.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    String? dsDate;
    String? dsHeure;
    int? dsPresents;
    if (json['derniereSeance'] is Map) {
      final ds = json['derniereSeance'] as Map;
      dsDate = ds['date_seance']?.toString();
      dsHeure = ds['heure']?.toString();
      dsPresents = ds['presents'] != null ? int.tryParse(ds['presents'].toString()) : null;
    }

    return Groupe(
      idGroupe: json['id_groupe']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      niveau: json['niveau']?.toString(),
      tarifParEleve: int.tryParse(json['tarif_par_eleve']?.toString() ?? '1000') ?? 1000,
      description: json['description']?.toString(),
      dateCreation: json['date_creation'] != null
          ? DateTime.tryParse(json['date_creation'].toString())
          : null,
      totalEleves: int.tryParse(json['total_eleves']?.toString() ?? '0') ?? members.length,
      eleves: members,
      countImpayes: int.tryParse(json['countImpayes']?.toString() ?? '0') ?? 0,
      totalImpaye: int.tryParse(json['totalImpaye']?.toString() ?? '0') ?? 0,
      derniereSeanceDate: dsDate,
      derniereSeanceHeure: dsHeure,
      derniereSeancePresents: dsPresents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_groupe': idGroupe,
      'nom': nom,
      'niveau': niveau,
      'tarif_par_eleve': tarifParEleve,
      'description': description,
      'eleves_ids': eleves.map((e) => e.idEleve).toList(),
    };
  }
}
