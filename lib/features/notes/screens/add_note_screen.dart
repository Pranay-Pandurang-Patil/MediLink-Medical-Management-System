import 'package:flutter/material.dart';

import '../../../models/daily_note.dart';
import '../../../services/notes_service.dart';

class AddNoteScreen extends StatefulWidget {
  final DailyNote? note;
  const AddNoteScreen({super.key, this.note});
  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}
class _AddNoteScreenState extends State<AddNoteScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  bool _saving = false;
  @override
  void initState() { super.initState(); _title = TextEditingController(text: widget.note?.title ?? ''); _content = TextEditingController(text: widget.note?.content ?? ''); }
  @override
  void dispose() { _title.dispose(); _content.dispose(); super.dispose(); }
  Future<void> _save() async { if (!_form.currentState!.validate()) return; setState(() => _saving = true); try { final now = DateTime.now(); final old = widget.note; final note = old == null ? DailyNote(id: '${now.microsecondsSinceEpoch}', title: _title.text.trim(), content: _content.text.trim(), createdAt: now, updatedAt: now) : old.copyWith(title: _title.text.trim(), content: _content.text.trim(), updatedAt: now); if (old == null) { await NotesService.instance.addNote(note); } else { await NotesService.instance.updateNote(note); } if (mounted) Navigator.pop(context); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save note: $e'))); } finally { if (mounted) setState(() => _saving = false); } }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.note == null ? 'Add note' : 'Edit note')), body: Form(key: _form, child: ListView(padding: const EdgeInsets.all(16), children: [TextFormField(controller: _title, maxLength: 100, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Enter a title' : null), const SizedBox(height: 12), TextFormField(controller: _content, minLines: 6, maxLines: 12, decoration: const InputDecoration(labelText: 'Note', alignLabelWithHint: true, border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Enter note content' : null), const SizedBox(height: 20), FilledButton.icon(onPressed: _saving ? null : _save, icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: Text(_saving ? 'Saving...' : 'Save note'))])));
}
