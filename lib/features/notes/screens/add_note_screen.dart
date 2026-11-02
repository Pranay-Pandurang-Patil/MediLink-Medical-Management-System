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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final existingNote = widget.note;

      final note = existingNote == null
          ? DailyNote(
        id: now.microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: now,
        updatedAt: now,
      )
          : existingNote.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        updatedAt: now,
      );

      if (existingNote == null) {
        await NotesService.instance.addNote(note);
      } else {
        await NotesService.instance.updateNote(note);
      }

      // Do not call setState after popping this route. The route may be
      // disposed as soon as Navigator.pop completes.
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not save note: $error')),
        );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit note' : 'Add note'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Enter a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              minLines: 6,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty
                  ? 'Enter note content'
                  : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save note'),
            ),
          ],
        ),
      ),
    );
  }
}
