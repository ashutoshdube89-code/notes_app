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
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _sortNotesNewestFirst(List<Note> list) {
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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

  @override
  Widget build(BuildContext context) {
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
              ? const Center(
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
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () => _openEditor(note: note),
                      onDelete: () => _deleteNote(note),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: 'New note',
        child: const Icon(Icons.add),
      ),
    );
  }
}