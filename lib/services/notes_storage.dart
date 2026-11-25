import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NotesStorage {
  static const String _storageKey = 'saved_notes_v1';

  Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final rawString = prefs.getString(_storageKey);
    if (rawString == null || rawString.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(rawString) as List<dynamic>;
    return decoded
        .map((item) => Note.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}