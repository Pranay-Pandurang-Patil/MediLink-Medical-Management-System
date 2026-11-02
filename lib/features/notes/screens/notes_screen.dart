import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  final TextEditingController _search = TextEditingController();
  late Future<Box<DailyNote>> _boxFuture;

  @override
  void initState() {
    super.initState();
    _boxFuture = NotesService.instance.openBox();
  }

  void _reopenBox() {
    if (!mounted) return;
    setState(() {
      _boxFuture = NotesService.instance.openBox();
    });
  }

  Future<void> _openAddNote() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AddNoteScreen(),
      ),
    );
    // The Hive listenable updates the list automatically. Reopen the box
    // future as a safe fallback if the owner session changed while navigating.
    _reopenBox();
  }

  Future<void> _openNote(DailyNote note) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddNoteScreen(note: note),
      ),
    );
    _reopenBox();
  }

  Future<void> _deleteNote(DailyNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.title}” will be permanently deleted from this device.'),
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

    if (confirmed != true || !mounted) return;

    try {
      await NotesService.instance.deleteNote(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted.')),
      );
      // No setState is needed here. ValueListenableBuilder receives the
      // Hive box change and rebuilds the list automatically.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete note: $error')),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily notes'),
        actions: [
          IconButton(
            tooltip: 'Regular customers',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () {
              Navigator.push<void>(
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title or note content',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                // ValueListenableBuilder filters the current Hive values
                // using the latest query; no asynchronous reload is required.
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<Box<DailyNote>>(
              future: _boxFuture,
              builder: (context, boxSnapshot) {
                if (boxSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (boxSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Could not open notes: ${boxSnapshot.error}'),
                    ),
                  );
                }

                final box = boxSnapshot.data;
                if (box == null || !box.isOpen) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Notes storage is not available.'),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _reopenBox,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }

                return ValueListenableBuilder<Box<DailyNote>>(
                  valueListenable: box.listenable(),
                  builder: (context, listenableBox, _) {
                    final query = _search.text.trim().toLowerCase();
                    final notes = listenableBox.values.where((note) {
                      if (query.isEmpty) return true;
                      return note.title.toLowerCase().contains(query) ||
                          note.content.toLowerCase().contains(query);
                    }).toList()
                      ..sort(
                            (a, b) => b.updatedAt.compareTo(a.updatedAt),
                      );

                    if (notes.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No notes yet. Tap “Add note” to create one.'
                              : 'No notes match “${_search.text.trim()}”.',
                          textAlign: TextAlign.center,
                        ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
