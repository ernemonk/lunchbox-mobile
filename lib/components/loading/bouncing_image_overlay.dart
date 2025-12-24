import 'package:flutter/material.dart';

/// A bouncing image overlay used during loading states.
/// 
/// Displays an animated avatar that bounces up and down
/// to indicate that content is being generated.
class BouncingImageOverlay extends StatefulWidget {
  /// The asset path for the image to display
  final String imagePath;

  /// Width of the image
  final double width;

  /// Height of the image
  final double height;

  const BouncingImageOverlay({
    super.key,
    this.imagePath = 'assets/avatar.png',
    this.width = 200,
    this.height = 200,
  });

  @override
  State<BouncingImageOverlay> createState() => _BouncingImageOverlayState();
}

class _BouncingImageOverlayState extends State<BouncingImageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 30)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animation.value),
              child: child,
            );
          },
          child: Image.asset(
            widget.imagePath,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
