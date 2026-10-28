class Seance {
  final String idSeance;
  final String? idEleve;
  final String nomEleve;
  final String dateSeance; // YYYY-MM-DD
  final String? heure;
  final String typeSeance; // 'Normale' ou 'Privée'
  final int montant;
  final String statutSeance; // 'Réalisée', 'Planifiée', 'Annulée'
  final String statutPaiement; // 'Payé', 'Impayé'
  final String? modePaiement;
  final String? datePaiement;
  final String? notes;
  final bool cloturee;
  final int joursRetard;
  final String? idGroupe;
  final String? idSeanceGroupe;
  final String? nomGroupe;
  final String? niveau;

  Seance({
    required this.idSeance,
    this.idEleve,
    required this.nomEleve,
    required this.dateSeance,
    this.heure,
    required this.typeSeance,
    required this.montant,
    required this.statutSeance,
    required this.statutPaiement,
    this.modePaiement,
    this.datePaiement,
    this.notes,
    required this.cloturee,
    this.joursRetard = 0,
    this.idGroupe,
    this.idSeanceGroupe,
    this.nomGroupe,
    this.niveau,
  });

  bool get estPaye => statutPaiement.toLowerCase() == 'payé';
  bool get estImpaye => statutPaiement.toLowerCase() == 'impayé';
  bool get estAnnulee => statutSeance.toLowerCase() == 'annulée';
  bool get estPlanifiee => statutSeance.toLowerCase() == 'planifiée';
  bool get estRealisee => statutSeance.toLowerCase() == 'réalisée';

  String get nomEleveEtNiveau => (niveau != null && niveau!.trim().isNotEmpty)
      ? '$nomEleve ($niveau)'
      : nomEleve;

  bool get estArrivee {
    if (!estPlanifiee) return true;
    final parts = dateSeance.split('-');
    if (parts.length != 3) return true;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final day = int.tryParse(parts[2]) ?? DateTime.now().day;
    int hour = 0;
    int minute = 0;
    if (heure != null && heure!.contains(':')) {
      final hParts = heure!.split(':');
      hour = int.tryParse(hParts[0]) ?? 0;
      minute = int.tryParse(hParts[1]) ?? 0;
    }
    final dt = DateTime(year, month, day, hour, minute);
    return !DateTime.now().isBefore(dt);
  }

  bool get estPayable => !estPlanifiee || estArrivee;

  factory Seance.fromJson(Map<String, dynamic> json) {
    // Parser la date au format lisible sans l'heure si c'est un ISO string
    String rawDate = json['date_seance']?.toString() ?? '';
    if (rawDate.contains('T')) {
      rawDate = rawDate.split('T')[0];
    }

    final rawCloturee = json['cloturee'];
    final isCloturee = rawCloturee == true ||
        rawCloturee == 1 ||
        rawCloturee?.toString() == 'true' ||
        rawCloturee?.toString() == '1';

    return Seance(
      idSeance: json['id_seance']?.toString() ?? '',
      idEleve: json['id_eleve']?.toString(),
      nomEleve: json['nom_eleve']?.toString() ?? 'Élève',
      dateSeance: rawDate,
      heure: json['heure']?.toString(),
      typeSeance: json['type_seance']?.toString() ?? 'Normale',
      montant: (json['montant'] as num?)?.toInt() ?? 0,
      statutSeance: json['statut_seance']?.toString() ?? 'Réalisée',
      statutPaiement: json['statut_paiement']?.toString() ?? 'Impayé',
      modePaiement: json['mode_paiement']?.toString(),
      datePaiement: json['date_paiement']?.toString(),
      notes: json['notes']?.toString(),
      cloturee: isCloturee,
      joursRetard: (json['joursRetard'] as num?)?.toInt() ?? 0,
      idGroupe: json['id_groupe']?.toString(),
      idSeanceGroupe: json['id_seance_groupe']?.toString(),
      nomGroupe: json['nom_groupe']?.toString(),
      niveau: json['niveau']?.toString(),
    );
  }
}
