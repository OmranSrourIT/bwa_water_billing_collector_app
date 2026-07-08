import 'dart:ui';
import 'package:flutter/material.dart';

class BwaLoadingOverlay extends StatefulWidget {
  final bool isLoading;

  const BwaLoadingOverlay({super.key, required this.isLoading});

  @override
  State<BwaLoadingOverlay> createState() => _BwaLoadingOverlayState();
}

class _BwaLoadingOverlayState extends State<BwaLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    return Stack(
      children: [
        // 🔒 Blocking + blur background
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.45),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // 🔄 Rotating logo only
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.1416,
                child: child,
              );
            },
            child: Container(
              width: 190,
              height: 190,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.white, // إذا بدك شفافية خففها أو خليها Colors.transparent
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/images/BWA_Logo.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
