class NotificationsSummary {
  final int total;
  final int countRetard3j;
  final int countImpayees;
  final int countSeances30min;
  final List<AppNotification> notifications;

  NotificationsSummary get summary => this;
  int get countImpayes => countImpayees;

  NotificationsSummary({
    required this.total,
    required this.countRetard3j,
    required this.countImpayees,
    required this.countSeances30min,
    required this.notifications,
  });

  factory NotificationsSummary.fromJson(Map<String, dynamic> json) {
    var rawList = json['notifications'];
    List<AppNotification> notifs = [];
    if (rawList is List) {
      notifs = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => AppNotification.fromJson(item))
          .toList();
    }
    return NotificationsSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      countRetard3j: (json['countRetard3j'] as num?)?.toInt() ?? 0,
      countImpayees: (json['countImpayees'] as num?)?.toInt() ?? 0,
      countSeances30min: (json['countSeances30min'] as num?)?.toInt() ?? 0,
      notifications: notifs,
    );
  }
}

class AppNotification {
  final String id;
  final String? idSeance;
  final String type;
  final String severite;
  final String titre;
  final String message;
  final String? nomEleve;
  final int? montant;
  final int? retardJours;
  final String? heure;
  final String? dateSeance;
  final String? notes;
  final String? telephone;

  String? get referenceId => idSeance;

  DateTime get dateReference {
    if (dateSeance != null) {
      try {
        final d = DateTime.parse(dateSeance!);
        if (heure != null && heure!.contains(':')) {
          final p = heure!.split(':');
          return DateTime(d.year, d.month, d.day, int.tryParse(p[0]) ?? 0, int.tryParse(p[1]) ?? 0);
        }
        return d;
      } catch (_) {}
    }
    return DateTime.now();
  }

  AppNotification({
    required this.id,
    this.idSeance,
    required this.type,
    required this.severite,
    required this.titre,
    required this.message,
    this.nomEleve,
    this.montant,
    this.retardJours,
    this.heure,
    this.dateSeance,
    this.notes,
    this.telephone,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      idSeance: json['id_seance'] as String?,
      type: json['type'] as String? ?? 'info',
      severite: json['severite'] as String? ?? 'info',
      titre: json['titre'] as String? ?? '',
      message: json['message'] as String? ?? '',
      nomEleve: json['nom_eleve'] as String?,
      montant: (json['montant'] as num?)?.toInt(),
      retardJours: (json['retard_jours'] as num?)?.toInt(),
      heure: json['heure'] as String?,
      dateSeance: json['date_seance']?.toString(),
      notes: json['notes'] as String?,
      telephone: json['telephone'] as String? ?? json['telephone_parent'] as String?,
    );
  }
}
