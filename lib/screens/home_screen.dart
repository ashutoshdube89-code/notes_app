import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_storage.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotesStorage _storage = NotesStorage();
  final TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sortNotesNewestFirst(List<Note> list) {
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<Note> get _filteredNotes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes
        .where((note) => note.title.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _loadNotes() async {
    final loaded = await _storage.loadNotes();
    _sortNotesNewestFirst(loaded);
    if (!mounted) return;
    setState(() {
      _notes = loaded;
      _isLoading = false;
    });
  }

  Future<void> _openEditor({Note? note}) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(existingNote: note),
      ),
    );

    if (result == null) return;

    final updated = List<Note>.from(_notes);
    final existingIndex = updated.indexWhere((item) => item.id == result.id);

    if (existingIndex != -1) {
      updated[existingIndex] = result;
    } else {
      updated.add(result);
    }

    _sortNotesNewestFirst(updated);

    if (!mounted) return;
    setState(() {
      _notes = updated;
    });

    await _storage.saveNotes(updated);
  }

  Future<void> _deleteNote(Note note) async {
    final updated = _notes.where((item) => item.id != note.id).toList();
    setState(() {
      _notes = updated;
    });
    await _storage.saveNotes(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );
  }

  void _cycleThemeMode() {
    final nextMode = switch (widget.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    widget.onThemeModeChanged(nextMode);
  }

  IconData _themeIcon() {
    return switch (widget.themeMode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined, size: 56),
            SizedBox(height: 12),
            Text(
              'No notes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Tap + to create your first note.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search notes by title...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 10),
            Text(
              'No notes matching "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _filteredNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_themeIcon()),
            tooltip: 'Switch theme',
            onPressed: _cycleThemeMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: visibleNotes.isEmpty
                          ? _buildNoSearchResults()
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 4, bottom: 80),
                              itemCount: visibleNotes.length,
                              itemBuilder: (context, index) {
                                final note = visibleNotes[index];
                                return NoteCard(
                                  note: note,
                                  onTap: () => _openEditor(note: note),
                                  onDelete: () => _deleteNote(note),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }
}