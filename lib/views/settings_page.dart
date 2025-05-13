import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:lunchbox/views/privacy_policy.dart';
import 'package:lunchbox/views/tweak_the_ai.dart'; // Make sure this path is correct

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userRole;

  bool get isAdmin => userRole == 'admin';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userRole = doc.data()?['role'];
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showDeleteAccountDialog() {
    final user = _auth.currentUser;
    if (user == null) return;

    String enteredEmail = '';
    bool isEmailValid = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Confirm Account Deletion"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "⚠ Warning: This action is irreversible!\n"
                      "All your data, including account details and associated files, "
                      "will be permanently erased.",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Enter your email to confirm",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          enteredEmail = value;
                          isEmailValid = enteredEmail == user.email;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isEmailValid
                      ? () {
                          Navigator.pop(context); // Close the dialog
                          deleteAccount();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade200,
                  ),
                  child: const Text("Delete Permanently"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? idToken = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse('https://delete-account-43109921054.us-central1.run.app'),
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"uid": user.uid}),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/');
        await _auth.signOut();
      } else {
        print("Failed to delete account: ${response.body}");
      }
    } catch (e) {
      print("Error deleting account: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Delete Account"),
            onTap: _showDeleteAccountDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Privacy Policy"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          const Divider(),
          if (isAdmin)
  ListTile(
    leading: const Icon(Icons.settings_suggest),
    title: const Text("Tweak the ai"),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TweakTheAIPage()),
      );
    },
  ),

        ],
      ),
    );
  }
}
