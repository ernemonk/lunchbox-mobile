import 'package:flutter/material.dart';

class BouncingImageOverlay extends StatefulWidget {
  const BouncingImageOverlay({super.key});

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
    return Positioned.fill( // ✅ Ensures it covers full screen
      child: Container(
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
              'assets/avatar.png',
              width:200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
