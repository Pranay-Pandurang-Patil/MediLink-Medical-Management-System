import 'package:hive/hive.dart';

import '../models/daily_note.dart';
import 'owner_data_service.dart';

/// Offline-first CRUD service for the authenticated owner's daily notes.
class NotesService {
  NotesService._();
  static final NotesService instance = NotesService._();

  Box<DailyNote>? _box;
  Future<Box<DailyNote>> openBox() async {
    final name = OwnerDataService.instance.notesBoxName;
    if (_box != null && _box!.isOpen && _box!.name == name) return _box!;
    _box = await Hive.openBox<DailyNote>(name);
    return _box!;
  }

  Future<List<DailyNote>> getAllNotes() async {
    final box = await openBox();
    final notes = box.values.toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<List<DailyNote>> searchNotes(String query) async {
    final notes = await getAllNotes();
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return notes;
    return notes.where((n) => n.title.toLowerCase().contains(term) || n.content.toLowerCase().contains(term)).toList();
  }

  Future<void> addNote(DailyNote note) async {
    final box = await openBox();
    if (box.containsKey(note.id)) throw StateError('A note with this ID already exists.');
    await box.put(note.id, note);
  }

  Future<void> updateNote(DailyNote note) async {
    final box = await openBox();
    if (!box.containsKey(note.id)) throw StateError('Note not found.');
    await box.put(note.id, note);
  }

  Future<void> deleteNote(String id) async => (await openBox()).delete(id);

  Future<DailyNote?> getNoteById(String id) async => (await openBox()).get(id);
}
