import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              
              SizedBox(height: 10),
              Text(
                'Effective Date: April 1st 2025',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '1. Introduction\nWelcome to Lunchbox. Your privacy is important to us. '
                'This Privacy Policy explains how we collect, use, disclose, and safeguard your '
                'information when you use our mobile application and related services.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '2. Information We Collect\n- Personal Information: Name, email address, profile picture, etc.\n'
                '- Usage Data: Information about app interactions.\n'
                '- Device Information: Device type, operating system, IP address.\n'
                '- Media Files: Images and videos uploaded by you.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '3. How We Use Your Information\n- Provide and improve services.\n'
                '- Authenticate users.\n'
                '- Process transactions.\n'
                '- Send updates and notifications.\n'
                '- Comply with legal requirements.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '4. Sharing Your Information\nWe do not sell your personal data, but may share it with:\n'
                '- Service Providers.\n'
                '- Legal Authorities.\n'
                '- Business Transfers (mergers, sales).',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '5. Data Security\nWe take reasonable steps to protect your data, but no online service is 100% secure.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '6. Your Choices\n- Update or delete your account.\n'
                '- Opt-out of promotional messages.\n'
                '- Restrict certain data collection.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '7. Third-Party Links\nWe are not responsible for external websites linked in our services.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '8. Children’s Privacy\nOur app is not for children under 13. We do not knowingly collect their data.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '9. Changes to This Policy\nWe may update this Privacy Policy. Continued use of the app after updates means acceptance.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '10. Contact Us\nIf you have any questions, please contact us at peacechampion@peacechampions.com.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
