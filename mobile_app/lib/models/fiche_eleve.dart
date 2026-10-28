import 'eleve.dart';
import 'seance.dart';

class FicheKpis {
  final int totalPaye;
  final int totalImpaye;
  final int totalSeances;

  FicheKpis({
    required this.totalPaye,
    required this.totalImpaye,
    required this.totalSeances,
  });

  factory FicheKpis.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FicheKpis(totalPaye: 0, totalImpaye: 0, totalSeances: 0);
    }
    return FicheKpis(
      totalPaye: (json['totalPaye'] as num?)?.toInt() ?? 0,
      totalImpaye: (json['totalImpaye'] as num?)?.toInt() ?? 0,
      totalSeances: (json['totalSeances'] as num?)?.toInt() ?? 0,
    );
  }
}

class FicheEleveData {
  final Eleve? eleve;
  final FicheKpis kpis;
  final List<Seance> seances;

  FicheEleveData({
    this.eleve,
    required this.kpis,
    required this.seances,
  });

  factory FicheEleveData.fromJson(Map<String, dynamic> json) {
    return FicheEleveData(
      eleve: json['eleve'] != null
          ? Eleve.fromJson(json['eleve'] as Map<String, dynamic>)
          : null,
      kpis: FicheKpis.fromJson(json['kpis'] as Map<String, dynamic>?),
      seances: (json['seances'] as List<dynamic>?)
              ?.map((item) => Seance.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
