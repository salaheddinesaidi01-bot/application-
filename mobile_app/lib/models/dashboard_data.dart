import 'seance.dart';

class CaChartPoint {
  final String mois;
  final int total;

  CaChartPoint({required this.mois, required this.total});

  factory CaChartPoint.fromJson(Map<String, dynamic> json) {
    return CaChartPoint(
      mois: json['mois']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class TarifsConfig {
  final int normale;
  final int privee;
  final int normale1;
  final int normale2;
  final int privee1;
  final int privee2;
  final List<int> tarifsNormale;
  final List<int> tarifsPrivee;

  TarifsConfig({
    required this.normale,
    required this.privee,
    required this.normale1,
    required this.normale2,
    required this.privee1,
    required this.privee2,
    required this.tarifsNormale,
    required this.tarifsPrivee,
  });

  factory TarifsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TarifsConfig(
        normale: 1000,
        privee: 2000,
        normale1: 1000,
        normale2: 1500,
        privee1: 2000,
        privee2: 2500,
        tarifsNormale: const [1000, 1500],
        tarifsPrivee: const [2000, 2500],
      );
    }
    final n1 = (json['normale_1'] as num?)?.toInt() ??
        (json['normale'] as num?)?.toInt() ??
        1000;
    final n2 = (json['normale_2'] as num?)?.toInt() ?? 1500;
    final p1 = (json['privee_1'] as num?)?.toInt() ??
        (json['privee'] as num?)?.toInt() ??
        2000;
    final p2 = (json['privee_2'] as num?)?.toInt() ?? 2500;

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

    return TarifsConfig(
      normale: n1,
      privee: p1,
      normale1: n1,
      normale2: n2,
      privee1: p1,
      privee2: p2,
      tarifsNormale: tn,
      tarifsPrivee: tp,
    );
  }
}

class DashboardKpi {
  final int totalPayeMois;
  final int nombreSeancesMois;
  final int totalImpaye;
  final int nombreEleves;

  DashboardKpi({
    required this.totalPayeMois,
    required this.nombreSeancesMois,
    required this.totalImpaye,
    this.nombreEleves = 0,
  });
}

class DashboardData {
  final int caTotal;
  final int totalImpaye;
  final int nombreEleves;
  final List<Seance> seancesJour;
  final List<Seance> seancesImpayees;
  final List<CaChartPoint> caChartData;
  final TarifsConfig tarifs;
  final String emailDestinataire;
  final String profNom;
  final int retards3JCount;
  final int retards3JMontant;

  DashboardData({
    required this.caTotal,
    required this.totalImpaye,
    required this.nombreEleves,
    required this.seancesJour,
    required this.seancesImpayees,
    required this.caChartData,
    required this.tarifs,
    required this.emailDestinataire,
    this.profNom = '',
    this.retards3JCount = 0,
    this.retards3JMontant = 0,
  });

  DashboardKpi get kpi => DashboardKpi(
        totalPayeMois: caTotal,
        nombreSeancesMois: seancesJour.length,
        totalImpaye: totalImpaye,
        nombreEleves: nombreEleves,
      );

  List<Seance> get seancesDuJour => seancesJour;
  List<Seance> get seancesImpayes => seancesImpayees;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      caTotal: (json['caTotal'] as num?)?.toInt() ?? 0,
      totalImpaye: (json['totalImpaye'] as num?)?.toInt() ?? 0,
      nombreEleves: (json['nombreEleves'] as num?)?.toInt() ?? 0,
      seancesJour: (json['seancesJour'] as List<dynamic>?)
              ?.map((item) => Seance.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      seancesImpayees: (json['seancesImpayees'] as List<dynamic>?)
              ?.map((item) => Seance.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      caChartData: (json['caChartData'] as List<dynamic>?)
              ?.map((item) => CaChartPoint.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      tarifs: TarifsConfig.fromJson(json['tarifs'] as Map<String, dynamic>?),
      emailDestinataire:
          json['emailDestinataire']?.toString() ?? '',
      profNom: json['profNom']?.toString() ?? '',
      retards3JCount: (json['retards3JCount'] as num?)?.toInt() ?? 0,
      retards3JMontant: (json['retards3JMontant'] as num?)?.toInt() ?? 0,
    );
  }
}
