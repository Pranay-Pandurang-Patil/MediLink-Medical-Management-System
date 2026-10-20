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
  void initState() { super.initState(); _load(); }
  void _load() => _notes = NotesService.instance.searchNotes(_search.text);
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _refresh() async { setState(_load); await _notes; }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notes'), actions: [IconButton(tooltip: 'Regular customers', icon: const Icon(Icons.people_alt_outlined), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersScreen())); })]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNoteScreen())); await _refresh(); }, icon: const Icon(Icons.add), label: const Text('Add note')),
    body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onChanged: (_) => setState(_load), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search notes', border: OutlineInputBorder()))), Expanded(child: FutureBuilder<List<DailyNote>>(future: _notes, builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snapshot.hasError) return Center(child: Text('Could not load notes: ${snapshot.error}')); final notes = snapshot.data ?? []; if (notes.isEmpty) return const Center(child: Text('No notes yet. Add your first note.')); return ListView.builder(itemCount: notes.length, itemBuilder: (context, i) { final note = notes[i]; return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), child: ListTile(title: Text(note.title.isEmpty ? 'Untitled note' : note.title), subtitle: Text('${note.content}\n${note.updatedAt.toLocal()}'), isThreeLine: true, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddNoteScreen(note: note))); await _refresh(); }, trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete note?'), content: const Text('This note will be deleted from this device.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))])); if (ok == true) { await NotesService.instance.deleteNote(note.id); await _refresh(); } }))); }); }))]),
  );
}
