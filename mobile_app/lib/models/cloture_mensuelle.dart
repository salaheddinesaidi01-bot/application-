import 'dart:convert';

class RecapEleveCloture {
  final String nom;
  final int nombreSeances;
  final int montantTotal;

  RecapEleveCloture({
    required this.nom,
    required this.nombreSeances,
    required this.montantTotal,
  });

  factory RecapEleveCloture.fromJson(Map<String, dynamic> json) {
    return RecapEleveCloture(
      nom: json['nom'] as String? ?? 'Élève',
      nombreSeances: (json['nombreSeances'] as num?)?.toInt() ?? 0,
      montantTotal: (json['montantTotal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'nombreSeances': nombreSeances,
        'montantTotal': montantTotal,
      };
}

class ClotureMensuelle {
  final String idCloture;
  final DateTime dateCloture;
  final String moisNom;
  final int annee;
  final int mois;
  final int caTotal;
  final int totalSeances;
  final int totalEleves;
  final List<RecapEleveCloture> recapEleves;
  final List<dynamic> seancesDetails;

  int get totalCaRealise => caTotal;
  int get totalCaEncaisse => caTotal;
  double get tauxEncaissement => 100.0;

  ClotureMensuelle({
    required this.idCloture,
    required this.dateCloture,
    required this.moisNom,
    required this.annee,
    required this.mois,
    required this.caTotal,
    required this.totalSeances,
    required this.totalEleves,
    this.recapEleves = const [],
    this.seancesDetails = const [],
  });

  factory ClotureMensuelle.fromJson(Map<String, dynamic> json) {
    var rawRecap = json['recap_eleves'];
    if (rawRecap is String && rawRecap.trim().isNotEmpty) {
      try {
        rawRecap = jsonDecode(rawRecap);
      } catch (_) {}
    }

    List<RecapEleveCloture> parsedRecap = [];
    if (rawRecap is List) {
      for (final item in rawRecap) {
        if (item is Map) {
          parsedRecap.add(RecapEleveCloture.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    var rawDetails = json['seances_details'];
    if (rawDetails is String && rawDetails.trim().isNotEmpty) {
      try {
        rawDetails = jsonDecode(rawDetails);
      } catch (_) {}
    }

    List<dynamic> parsedDetails = [];
    if (rawDetails is List) {
      parsedDetails = rawDetails;
    }

    return ClotureMensuelle(
      idCloture: json['id_cloture'] as String? ?? '',
      dateCloture: json['date_cloture'] != null
          ? DateTime.tryParse(json['date_cloture'].toString()) ?? DateTime.now()
          : DateTime.now(),
      moisNom: json['mois_nom'] as String? ?? 'Clôture mensuelle',
      annee: (json['annee'] as num?)?.toInt() ?? DateTime.now().year,
      mois: (json['mois'] as num?)?.toInt() ?? DateTime.now().month,
      caTotal: (json['ca_total'] as num?)?.toInt() ?? 0,
      totalSeances: (json['total_seances'] as num?)?.toInt() ?? 0,
      totalEleves: (json['total_eleves'] as num?)?.toInt() ?? 0,
      recapEleves: parsedRecap,
      seancesDetails: parsedDetails,
    );
  }
}
