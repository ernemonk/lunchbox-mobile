import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  CollectionReference get _promptRef => FirebaseFirestore.instance.collection('prompts');

  void _clearForm() {
    _titleController.clear();
    _promptController.clear();
    setState(() => _editingDocId = null);
  }

  Future<void> _savePrompt() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'promptTitle': _titleController.text.trim(),
        'prompt': _promptController.text.trim(),
      };

      if (_editingDocId != null) {
        await _promptRef.doc(_editingDocId).update(data);
      } else {
        await _promptRef.add(data);
      }

      _clearForm();
    }
  }

  Future<void> _deletePrompt(String id) async {
    await _promptRef.doc(id).delete();
    if (_editingDocId == id) _clearForm();
  }

  void _editPrompt(DocumentSnapshot doc) {
    _titleController.text = doc['promptTitle'];
    _promptController.text = doc['prompt'];
    setState(() => _editingDocId = doc.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tweak the AI')),
      body:  Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Prompt Title'),
                      validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _promptController,
                      decoration: const InputDecoration(labelText: 'Prompt'),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty ? 'Enter a prompt' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _savePrompt,
                          child: Text(_editingDocId != null ? 'Update' : 'Create'),
                        ),
                        const SizedBox(width: 10),
                        if (_editingDocId != null)
                          OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const Text('Your Prompts', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _promptRef.orderBy('promptTitle').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No prompts found.'));
            }

            return ListView(
              children: snapshot.data!.docs.map((doc) {
                return ListTile(
                  title: Text(doc['promptTitle']),
                  subtitle: Text(doc['prompt']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editPrompt(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePrompt(doc.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ],
  ),
),

    );
  }
}
