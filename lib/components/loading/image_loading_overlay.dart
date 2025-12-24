import 'package:flutter/material.dart';

/// A loading overlay that displays an image with text.
/// 
/// Used to show a loading state with a message while
/// content is being generated or fetched.
class ImageLoadingOverlay extends StatelessWidget {
  /// The asset path for the image
  final String imagePath;

  /// The message to display below the image
  final String message;

  /// Width of the image
  final double imageWidth;

  /// Height of the image
  final double imageHeight;

  const ImageLoadingOverlay({
    super.key,
    this.imagePath = 'assets/avatar.png',
    this.message = 'Your recipes are being generated...',
    this.imageWidth = 200,
    this.imageHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text('Image not found');
              },
            ),
            const SizedBox(height: 30),
            Text(
              message,
              style: const TextStyle(
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
