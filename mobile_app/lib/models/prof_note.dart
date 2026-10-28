class ProfNote {
  final String id;
  final String titre;
  final String contenu;
  final DateTime date;
  final String tag;
  final bool isPinned;
  final int couleurIndex;

  ProfNote({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.date,
    this.tag = 'Général',
    this.isPinned = false,
    this.couleurIndex = 0,
  });

  factory ProfNote.create({
    required String titre,
    required String contenu,
    String tag = 'Général',
    bool isPinned = false,
    int couleurIndex = 0,
  }) {
    return ProfNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titre: titre,
      contenu: contenu,
      date: DateTime.now(),
      tag: tag,
      isPinned: isPinned,
      couleurIndex: couleurIndex,
    );
  }

  factory ProfNote.fromJson(Map<String, dynamic> json) {
    return ProfNote(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titre: json['titre']?.toString() ?? '',
      contenu: json['contenu']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tag: json['tag']?.toString() ?? 'Général',
      isPinned: json['isPinned'] == true,
      couleurIndex: (json['couleurIndex'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'contenu': contenu,
        'date': date.toIso8601String(),
        'tag': tag,
        'isPinned': isPinned,
        'couleurIndex': couleurIndex,
      };

  ProfNote copyWith({
    String? id,
    String? titre,
    String? contenu,
    DateTime? date,
    String? tag,
    bool? isPinned,
    int? couleurIndex,
  }) {
    return ProfNote(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      date: date ?? this.date,
      tag: tag ?? this.tag,
      isPinned: isPinned ?? this.isPinned,
      couleurIndex: couleurIndex ?? this.couleurIndex,
    );
  }

  static List<String> availableTags() => const [
        'Général',
        'Pédagogique',
        'Élèves',
        'Devoirs & Quiz',
        'Rappels',
        'Idées',
      ];
}
