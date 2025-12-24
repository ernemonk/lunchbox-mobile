import 'package:flutter/material.dart';

class ImageWithTextOverlay extends StatelessWidget {
  const ImageWithTextOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white, // Optional background color
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/avatar.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text('Image not found');
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Your recipes are being generated...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
