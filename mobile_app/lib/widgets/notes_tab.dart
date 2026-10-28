import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prof_note.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => NotesTabState();
}

class NotesTabState extends State<NotesTab> {
  static const String _prefNotesKey = 'prof_notes_list';

  List<ProfNote> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTag = 'Tout';

  static const List<Color> _accentColors = [
    Color(0xFF061449), // Deep Royal Navy
    Color(0xFF006A61), // Deep Teal
    Color(0xFF1E2A5E), // Indigo Navy
    Color(0xFFFFB95F), // Amber Gold
    Color(0xFF006F66), // Dark Teal
    Color(0xFF4F5B92), // Slate Blue
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Permet au parent de recharger l'onglet si besoin
  void recharger() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefNotesKey);

    if (jsonList != null && jsonList.isNotEmpty) {
      try {
        final loaded = jsonList
            .map((str) => ProfNote.fromJson(jsonDecode(str) as Map<String, dynamic>))
            .toList();
        // Trier par date décroissante, avec épinglées en premier
        loaded.sort((a, b) {
          if (a.isPinned != b.isPinned) {
            return a.isPinned ? -1 : 1;
          }
          return b.date.compareTo(a.date);
        });

        if (mounted) {
          setState(() {
            _notes = loaded;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }

    // Initialisation avec une liste propre et vide pour un état 100% neuf
    final defaultNotes = <ProfNote>[];

    if (mounted) {
      setState(() {
        _notes = defaultNotes;
        _isLoading = false;
      });
      _saveNotes(defaultNotes);
    }
  }

  Future<void> _saveNotes(List<ProfNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_prefNotesKey, jsonList);
  }

  void _addOrUpdateNote(ProfNote note, {bool isEdit = false}) {
    setState(() {
      if (isEdit) {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = note;
        }
      } else {
        _notes.insert(0, note);
      }

      // Re-trier
      _notes.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.date.compareTo(a.date);
      });
    });

    _saveNotes(_notes);
  }

  void _togglePin(ProfNote note) {
    final updated = note.copyWith(isPinned: !note.isPinned);
    _addOrUpdateNote(updated, isEdit: true);
  }

  void _deleteNote(ProfNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: Text('Voulez-vous vraiment supprimer "${note.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      _saveNotes(_notes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note supprimée.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showNoteDialog([ProfNote? existing]) async {
    final isEdit = existing != null;
    final titreController = TextEditingController(text: existing?.titre ?? '');
    final contenuController = TextEditingController(text: existing?.contenu ?? '');
    String tag = existing?.tag ?? 'Général';
    bool isPinned = existing?.isPinned ?? false;
    int couleurIndex = existing?.couleurIndex ?? 0;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final accent = _accentColors[couleurIndex % _accentColors.length];

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 540,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre du Dialog
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.note_alt_rounded, color: accent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isEdit ? 'Modifier la Note' : 'Nouvelle Note',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Champ Titre
                        TextFormField(
                          controller: titreController,
                          decoration: InputDecoration(
                            labelText: 'Titre de la note *',
                            hintText: 'Titre de la note ou devoir...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Veuillez saisir un titre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Catégorie / Tag
                        const Text(
                          'Catégorie :',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: ProfNote.availableTags().map((t) {
                            final isSel = tag == t;
                            return ChoiceChip(
                              label: Text(t, style: const TextStyle(fontSize: 12)),
                              selected: isSel,
                              selectedColor: accent.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() => tag = t);
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Contenu
                        TextFormField(
                          controller: contenuController,
                          maxLines: 6,
                          minLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Contenu / Remarques *',
                            hintText: 'Notez ici vos remarques, points à aborder, devoirs...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Veuillez saisir du contenu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Épingler
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Épingler cette note en haut',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Elle apparaîtra toujours en tête de liste',
                              style: TextStyle(fontSize: 12)),
                          secondary: Icon(
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            color: isPinned ? const Color(0xFFF59E0B) : Colors.grey,
                          ),
                          value: isPinned,
                          onChanged: (val) => setDialogState(() => isPinned = val),
                        ),
                        const SizedBox(height: 8),

                        // Couleur d'accent
                        Row(
                          children: [
                            const Text('Couleur : ',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Wrap(
                              spacing: 8,
                              children: List.generate(_accentColors.length, (idx) {
                                final c = _accentColors[idx];
                                final isSelected = couleurIndex == idx;
                                return InkWell(
                                  onTap: () => setDialogState(() => couleurIndex = idx),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: c.withValues(alpha: 0.5),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Boutons Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  final n = isEdit
                                      ? existing.copyWith(
                                          titre: titreController.text.trim(),
                                          contenu: contenuController.text.trim(),
                                          date: DateTime.now(),
                                          tag: tag,
                                          isPinned: isPinned,
                                          couleurIndex: couleurIndex,
                                        )
                                      : ProfNote.create(
                                          titre: titreController.text.trim(),
                                          contenu: contenuController.text.trim(),
                                          tag: tag,
                                          isPinned: isPinned,
                                          couleurIndex: couleurIndex,
                                        );
                                  _addOrUpdateNote(n, isEdit: isEdit);
                                  Navigator.of(ctx).pop();
                                }
                              },
                              child: Text(isEdit ? 'Mettre à jour' : 'Enregistrer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filtrer les notes
    final filtered = _notes.where((note) {
      final matchesQuery = _searchQuery.isEmpty ||
          note.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.contenu.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTag = _selectedTag == 'Tout' || note.tag == _selectedTag;
      return matchesQuery && matchesTag;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête avec bouton Ajouter
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131D42) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B1C30).withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF061449).withValues(alpha: isDark ? 0.35 : 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: isDark ? const Color(0xFF9EA8E0) : const Color(0xFF061449),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Carnet de Notes',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: isDark ? Colors.white : const Color(0xFF0B1C30),
                                      ),
                                    ),
                                    Text(
                                      '${_notes.length} note(s) • ${_notes.where((n) => n.isPinned).length} épinglée(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF9EA8E0) : const Color(0xFF45464F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF061449),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                ),
                                onPressed: () => _showNoteDialog(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Nouvelle Note',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Barre de recherche capsule
                          TextField(
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une note (titre, contenu)...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF9EA8E0).withValues(alpha: 0.6) : const Color(0xFF767680),
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0A1128) : const Color(0xFFEFF4FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9999),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filtres par Tags (Capsule pills)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: const Text('Tout'),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedTag == 'Tout'
                                        ? Colors.white
                                        : (isDark ? const Color(0xFF9EA8E0) : const Color(0xFF45464F)),
                                  ),
                                  selected: _selectedTag == 'Tout',
                                  showCheckmark: false,
                                  backgroundColor: isDark ? const Color(0xFF1E2A5E).withValues(alpha: 0.4) : const Color(0xFFEFF4FF),
                                  selectedColor: const Color(0xFF061449),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                    side: BorderSide.none,
                                  ),
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedTag = 'Tout');
                                  },
                                ),
                                const SizedBox(width: 8),
                                ...ProfNote.availableTags().map((tag) {
                                  final isSel = _selectedTag == tag;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(tag),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSel
                                            ? Colors.white
                                            : (isDark ? const Color(0xFF9EA8E0) : const Color(0xFF45464F)),
                                      ),
                                      selected: isSel,
                                      showCheckmark: false,
                                      backgroundColor: isDark ? const Color(0xFF1E2A5E).withValues(alpha: 0.4) : const Color(0xFFEFF4FF),
                                      selectedColor: const Color(0xFF061449),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9999),
                                        side: BorderSide.none,
                                      ),
                                      onSelected: (val) {
                                        if (val) setState(() => _selectedTag = tag);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Liste des notes
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.note_outlined,
                                size: 64,
                                color: isDark ? const Color(0xFF233166) : const Color(0xFFC6C5D1),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _notes.isEmpty
                                    ? 'Aucune note pour le moment'
                                    : 'Aucune note ne correspond à votre recherche',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0B1C30),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Notez vos devoirs, remarques pédagogiques et idées en un clic.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF9EA8E0) : const Color(0xFF767680),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF061449),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                ),
                                onPressed: () => _showNoteDialog(),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Créer une note', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final note = filtered[index];
                          final accent =
                              _accentColors[note.couleurIndex % _accentColors.length];
                          final formattedDate =
                              DateFormat('dd MMM yyyy à HH:mm').format(note.date);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF131D42) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: note.isPinned
                                    ? const Color(0xFFFFB95F).withValues(alpha: 0.7)
                                    : (isDark ? const Color(0xFF233166) : const Color(0xFFE5EEFF)),
                                width: note.isPinned ? 1.5 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0B1C30).withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Spine verticale à gauche
                                    Container(
                                      width: 5,
                                      color: note.isPinned ? const Color(0xFFFFB95F) : accent,
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _showNoteDialog(note),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Header de la carte
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  // Tag badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 9, vertical: 3.5),
                                                    decoration: BoxDecoration(
                                                      color: accent.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(9999),
                                                    ),
                                                    child: Text(
                                                      note.tag,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: accent,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (note.isPinned)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFFDDB8),
                                                        borderRadius: BorderRadius.circular(9999),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.push_pin,
                                                              size: 11, color: Color(0xFF281600)),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Épinglé',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                              color: Color(0xFF281600),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  const Spacer(),
                                                  // Actions rapides
                                                  IconButton(
                                                    icon: Icon(
                                                      note.isPinned
                                                          ? Icons.push_pin
                                                          : Icons.push_pin_outlined,
                                                      size: 18,
                                                      color: note.isPinned
                                                          ? const Color(0xFFFFB95F)
                                                          : (isDark ? const Color(0xFF9EA8E0) : const Color(0xFF767680)),
                                                    ),
                                                    tooltip: note.isPinned
                                                        ? 'Désépingler'
                                                        : 'Épingler en haut',
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _togglePin(note),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: Icon(Icons.copy_rounded,
                                                        size: 16, color: isDark ? const Color(0xFF9EA8E0) : const Color(0xFF767680)),
                                                    tooltip: 'Copier le contenu',
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                          ClipboardData(text: '${note.titre}\n\n${note.contenu}'));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Note copiée dans le presse-papier'),
                                                          duration: Duration(seconds: 1),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline_rounded,
                                                        size: 18, color: Color(0xFFBA1A1A)),
                                                    tooltip: 'Supprimer',
                                                    visualDensity: VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _deleteNote(note),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              // Titre
                                              Text(
                                                note.titre,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark ? Colors.white : const Color(0xFF0B1C30),
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),

                                              // Contenu
                                              Text(
                                                note.contenu,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  height: 1.45,
                                                  color: isDark ? const Color(0xFFEFF4FF) : const Color(0xFF45464F),
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // Date
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? const Color(0xFF9EA8E0) : const Color(0xFF767680),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
