import 'package:flutter/material.dart';

import '../../../models/daily_note.dart';
import '../../../services/notes_service.dart';
import 'add_note_screen.dart';
import 'customers_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _search = TextEditingController();
  late Future<List<DailyNote>> _notes;

  @override
  void initState() {
    super.initState();
    _notes = _loadNotes();
  }

  Future<List<DailyNote>> _loadNotes() =>
      NotesService.instance.searchNotes(_search.text);

  void _reload() {
    if (mounted) setState(() => _notes = _loadNotes());
  }

  Future<void> _openAddNote() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddNoteScreen()),
    );
    _reload();
  }

  Future<void> _openNote(DailyNote note) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => AddNoteScreen(note: note)),
    );
    _reload();
  }

  Future<void> _deleteNote(DailyNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.title}” will be deleted from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await NotesService.instance.deleteNote(note.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete note: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Daily notes'),
      actions: [
        IconButton(
          tooltip: 'Regular customers',
          icon: const Icon(Icons.people_alt_outlined),
          onPressed: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CustomersScreen(),
              ),
            );
          },
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _openAddNote,
      icon: const Icon(Icons.add),
      label: const Text('Add note'),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            onChanged: (_) => _reload(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search title or note content',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DailyNote>>(
            future: _notes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load notes: ${snapshot.error}'),
                );
              }
              final notes = snapshot.data ?? [];
              if (notes.isEmpty) {
                return const Center(
                  child: Text('No notes found. Tap “Add note” to create one.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final updated = note.updatedAt.toLocal();
                  final date =
                      '${updated.day.toString().padLeft(2, '0')}/'
                      '${updated.month.toString().padLeft(2, '0')}/'
                      '${updated.year}  '
                      '${updated.hour.toString().padLeft(2, '0')}:'
                      '${updated.minute.toString().padLeft(2, '0')}';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.sticky_note_2_outlined),
                      title: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${note.content}\nUpdated $date',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      onTap: () => _openNote(note),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Note actions',
                        onSelected: (action) {
                          if (action == 'edit') _openNote(note);
                          if (action == 'delete') _deleteNote(note);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.delete_outline),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
