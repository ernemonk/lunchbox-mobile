import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class TweakTheAIPage extends StatefulWidget {
  const TweakTheAIPage({super.key});

  @override
  State<TweakTheAIPage> createState() => _TweakTheAIPageState();
}

class _TweakTheAIPageState extends State<TweakTheAIPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  String? _editingDocId;

  bool _editorFullscreen = false;

  CollectionReference get _promptRef =>
      FirebaseFirestore.instance.collection('prompts');

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleController.clear();
    _promptController.clear();
    setState(() => _editingDocId = null);
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'promptTitle': _titleController.text.trim(),
      'prompt': _promptController.text.trim(),
    };

    try {
      if (_editingDocId != null) {
        await _promptRef.doc(_editingDocId).update(data);
        _showSnack('Prompt updated');
      } else {
        await _promptRef.add(data);
        _showSnack('Prompt created');
      }
      _clearForm();
    } catch (e) {
      _showSnack('Error saving prompt: $e', isError: true);
    }
  }

  Future<void> _deletePrompt(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete prompt?'),
        content: const Text(
            'This will permanently remove the prompt. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _promptRef.doc(id).delete();
      if (_editingDocId == id) _clearForm();
      _showSnack('Prompt deleted');
    } catch (e) {
      _showSnack('Error deleting prompt: $e', isError: true);
    }
  }

  void _editPrompt(DocumentSnapshot doc) {
    _titleController.text = (doc['promptTitle'] ?? '').toString();
    _promptController.text = (doc['prompt'] ?? '').toString();
    setState(() {
      _editingDocId = doc.id;
      _editorFullscreen = true; // jump straight into big edit mode
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  InputBorder get _thickBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      );

  @override
  Widget build(BuildContext context) {
    final editor = Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Prompt Title',
              border: _thickBorder,
              enabledBorder: _thickBorder,
              focusedBorder: _thickBorder,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
            ),
            style: const TextStyle(fontSize: 18),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),

          // The BIG prompt input
          Expanded(
            child: TextFormField(
              controller: _promptController,
              decoration: InputDecoration(
                labelText: 'Prompt',
                hintText: 'Type your prompt here…',
                alignLabelWithHint: true,
                border: _thickBorder,
                enabledBorder: _thickBorder,
                focusedBorder: _thickBorder,
                contentPadding: const EdgeInsets.all(24), // more padding
              ),
              keyboardType: TextInputType.multiline,
              expands: true,
              maxLines: null,
              minLines: null,
              style: const TextStyle(fontSize: 18, height: 1.4),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a prompt' : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _savePrompt,
                icon: const Icon(Icons.save),
                label: Text(_editingDocId != null ? 'Update' : 'Create'),
              ),
              const SizedBox(width: 12),
              if (_editingDocId != null)
                OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                ),
              const Spacer(),
              // Fullscreen toggle
              IconButton.filledTonal(
                tooltip: _editorFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                onPressed: () =>
                    setState(() => _editorFullscreen = !_editorFullscreen),
                icon: Icon(_editorFullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tweak the AI'),
        actions: [
          IconButton(
            tooltip: _editorFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
            onPressed: () =>
                setState(() => _editorFullscreen = !_editorFullscreen),
            icon: Icon(
              _editorFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          // Layout:
          // - Fullscreen ON: only the editor (fills screen)
          // - Fullscreen OFF: editor (2/3 height) + list (1/3 height)
          child: _editorFullscreen
              ? Column(
                  children: [
                    Expanded(child: editor),
                  ],
                )
              : Column(
                  children: [
                    // Editor gets more space by default
                    Expanded(flex: 2, child: editor),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Text(
                          'Your Prompts',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // List area
                    Expanded(
                      flex: 1,
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            _promptRef.orderBy('promptTitle').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text('No prompts found.'));
                          }

                          final docs = snapshot.data!.docs;
                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final title =
                                  (doc['promptTitle'] ?? '').toString().trim();
                              final prompt =
                                  (doc['prompt'] ?? '').toString().trim();

                              return ListTile(
                                title: Text(
                                  title.isEmpty ? '(Untitled)' : title,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                subtitle: Text(
                                  prompt,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _editPrompt(doc),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editPrompt(doc),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deletePrompt(doc.id),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
