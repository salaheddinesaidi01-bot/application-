class PaiementHistorique {
  final String idSeance;
  final String? idEleve;
  final String nomEleve;
  final DateTime? dateSeance;
  final String? heure;
  final String typeSeance;
  final int montant;
  final String? modePaiement;
  final DateTime? datePaiement;
  final String? idGroupe;
  final String? idSeanceGroupe;
  final String? nomGroupe;
  final String? notes;
  final String? niveau;

  PaiementHistorique({
    required this.idSeance,
    this.idEleve,
    required this.nomEleve,
    this.dateSeance,
    this.heure,
    required this.typeSeance,
    required this.montant,
    this.modePaiement,
    this.datePaiement,
    this.idGroupe,
    this.idSeanceGroupe,
    this.nomGroupe,
    this.notes,
    this.niveau,
  });

  bool get estGroupe => idGroupe != null && idGroupe!.isNotEmpty;
  bool get isGroupe => estGroupe;
  String get matiere => typeSeance;
  int get dureeMinutes => 120;

  String get nomEleveEtNiveau => (niveau != null && niveau!.trim().isNotEmpty)
      ? '$nomEleve ($niveau)'
      : nomEleve;

  factory PaiementHistorique.fromJson(Map<String, dynamic> json) {
    return PaiementHistorique(
      idSeance: json['id_seance']?.toString() ?? '',
      idEleve: json['id_eleve']?.toString(),
      nomEleve: json['nom_eleve']?.toString() ?? 'Élève',
      dateSeance: json['date_seance'] != null
          ? DateTime.tryParse(json['date_seance'].toString())
          : null,
      heure: json['heure']?.toString(),
      typeSeance: json['type_seance']?.toString() ?? 'Normale',
      montant: int.tryParse(json['montant']?.toString() ?? '0') ?? 0,
      modePaiement: json['mode_paiement']?.toString() ?? 'Espèces',
      datePaiement: json['date_paiement'] != null
          ? DateTime.tryParse(json['date_paiement'].toString())
          : null,
      idGroupe: json['id_groupe']?.toString(),
      idSeanceGroupe: json['id_seance_groupe']?.toString(),
      nomGroupe: json['nom_groupe']?.toString(),
      notes: json['notes']?.toString(),
      niveau: json['niveau']?.toString(),
    );
  }
}

class HistoriquePaiementsResponse {
  final int count;
  final int totalMontant;
  final List<PaiementHistorique> paiements;

  int get totalCount => count;

  HistoriquePaiementsResponse({
    required this.count,
    required this.totalMontant,
    required this.paiements,
  });

  factory HistoriquePaiementsResponse.fromJson(Map<String, dynamic> json) {
    List<PaiementHistorique> list = [];
    if (json['paiements'] is List) {
      list = (json['paiements'] as List)
          .map((item) => PaiementHistorique.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return HistoriquePaiementsResponse(
      count: int.tryParse(json['count']?.toString() ?? '0') ?? list.length,
      totalMontant: int.tryParse(json['totalMontant']?.toString() ?? '0') ?? 0,
      paiements: list,
    );
  }
}
