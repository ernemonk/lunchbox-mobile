import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyFridgePage extends StatefulWidget {
  const MyFridgePage({super.key});

  @override
  State<MyFridgePage> createState() => _MyFridgePageState();
}

class _MyFridgePageState extends State<MyFridgePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> fridgeItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFridgeContents();
  }

  Future<void> _fetchFridgeContents() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['fridge'] != null) {
        setState(() {
          fridgeItems = List<Map<String, dynamic>>.from(data['fridge']);
        });
      }
    }
  }

void _showFridgeItemDialog({Map<String, dynamic>? item, int? index}) {
  TextEditingController itemController =
      TextEditingController(text: item?['name'] ?? '');
  TextEditingController quantityController =
      TextEditingController(text: item?['quantity']?.toString() ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item == null ? 'Add Item' : 'Edit Item'),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cancel',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: itemController,
              decoration: const InputDecoration(labelText: 'Fridge Item'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          if (item != null)
            TextButton(
              onPressed: () {
                _deleteItem(index!);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () {
              final String name = itemController.text.trim();
              final String quantity = quantityController.text.trim();

              if (name.isNotEmpty && quantity.isNotEmpty) {
                if (item == null) {
                  _addItem(name, quantity);
                } else {
                  _editItem(index!, name, quantity);
                }
                Navigator.pop(context);
              }
            },
            child: Text(item == null ? 'Add' : 'Save'),
          ),
        ],
      );
    },
  );
}


  Future<void> _addItem(String name, String quantity) async {
    final user = _auth.currentUser;
    if (user != null) {
      final newItem = {'name': name, 'quantity': quantity};
      setState(() {
        fridgeItems.add(newItem);
      });
      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });
    }
  }

  Future<void> _editItem(int index, String name, String quantity) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems[index] = {'name': name, 'quantity': quantity};
      });
      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });
    }
  }

  Future<void> _deleteItem(int index) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems.removeAt(index);
      });
      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      body: fridgeItems.isEmpty
          ? const Center(
              child: Text(
                'Your fridge is empty!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: fridgeItems.length,
              itemBuilder: (context, index) {
                final item = fridgeItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  color: Colors.indigo.shade50,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.indigo,
                      ),
                    ),
                    subtitle: Text(
                      'Quantity: ${item['quantity']}',
                      style: TextStyle(color: Colors.indigo.shade400),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.indigo),
                    onTap: () =>
                        _showFridgeItemDialog(item: item, index: index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFridgeItemDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
