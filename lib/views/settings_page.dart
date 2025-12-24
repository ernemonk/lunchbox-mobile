import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_colors.dart';
import 'package:lunchbox/views/privacy_policy.dart';
import 'package:lunchbox/views/tweak_the_ai.dart';
import 'package:lunchbox/views/subscription_page.dart';

/// Settings page for user account management.
/// 
/// Features:
/// - Logout functionality
/// - Account deletion
/// - Privacy policy access
/// - Admin: AI prompt management (visible only to admin users)
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
              backgroundColor: AppColors.surface,
              title: const Text(
                "Confirm Account Deletion",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "⚠ Warning: This action is irreversible!\n"
                      "All your data, including account details and associated files, "
                      "will be permanently erased.",
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Enter your email to confirm",
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isEmailValid
                      ? () {
                          Navigator.pop(context);
                          deleteAccount();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    disabledBackgroundColor: AppColors.error.withOpacity(0.5),
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
            leading: const Icon(Icons.star, color: AppColors.primary),
            title: const Text(
              "My Subscription",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              "Manage your plan & free trial",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionPage()),
              );
            },
          ),
          Divider(color: AppColors.primary.withOpacity(0.1)),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.primary),
            title: const Text(
              "Logout",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            onTap: () => _logout(context),
          ),
          Divider(color: AppColors.primary.withOpacity(0.1)),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              "Delete Account",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            onTap: _showDeleteAccountDialog,
          ),
          Divider(color: AppColors.primary.withOpacity(0.1)),
          ListTile(
            leading: const Icon(Icons.event, color: AppColors.secondary),
            title: const Text(
              "Privacy Policy",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          Divider(color: AppColors.primary.withOpacity(0.1)),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.settings_suggest, color: AppColors.accent),
              title: const Text(
                "Tweak the ai",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
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
