import 'package:hive/hive.dart';

import '../models/daily_note.dart';
import 'owner_data_service.dart';

/// Offline-first CRUD service for the authenticated owner's daily notes.
class NotesService {
  NotesService._();

  static final NotesService instance = NotesService._();

  Box<DailyNote>? _box;
  String? _openedBoxName;

  Future<Box<DailyNote>> openBox() async {
    final name = OwnerDataService.instance.notesBoxName;

    if (_box != null &&
        _box!.isOpen &&
        _openedBoxName == name &&
        _box!.name == name) {
      return _box!;
    }

    // Do not reuse a previously cached box after the authenticated owner changes.
    _box = await Hive.openBox<DailyNote>(name);
    _openedBoxName = name;
    return _box!;
  }

  Future<List<DailyNote>> getAllNotes() async {
    final box = await openBox();
    final notes = box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<List<DailyNote>> searchNotes(String query) async {
    final notes = await getAllNotes();
    final term = query.trim().toLowerCase();

    if (term.isEmpty) return notes;

    return notes
        .where(
          (note) =>
      note.title.toLowerCase().contains(term) ||
          note.content.toLowerCase().contains(term),
    )
        .toList();
  }

  Future<void> addNote(DailyNote note) async {
    final box = await openBox();

    if (box.containsKey(note.id)) {
      throw StateError('A note with this ID already exists.');
    }

    await box.put(note.id, note);
    await box.flush();
  }

  Future<void> updateNote(DailyNote note) async {
    final box = await openBox();

    if (!box.containsKey(note.id)) {
      throw StateError('Note not found. Refresh the notes list and try again.');
    }

    await box.put(note.id, note);
    await box.flush();
  }

  Future<void> deleteNote(String id) async {
    final box = await openBox();

    if (!box.containsKey(id)) {
      throw StateError('This note no longer exists. Refresh the notes list.');
    }

    await box.delete(id);
    await box.flush();
  }

  Future<DailyNote?> getNoteById(String id) async {
    return (await openBox()).get(id);
  }
}
