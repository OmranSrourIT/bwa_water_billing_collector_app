import 'package:flutter/material.dart';

class AnimatedMeterNumber extends StatefulWidget {
  final String value;

  const AnimatedMeterNumber({super.key, required this.value});

  @override
  State<AnimatedMeterNumber> createState() => _AnimatedMeterNumberState();
}

class _AnimatedMeterNumberState extends State<AnimatedMeterNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xffE8F5E9),
              border: Border.all(color: const Color(0xff2E7D32), width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.15 + (_controller.value * 0.20),
                  ),
                  blurRadius: 8 + (_controller.value * 10),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    return Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xff2E7D32),
                          const Color(0xff81C784),
                          _controller.value,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(
                              0.3 + (_controller.value * 0.4),
                            ),
                            blurRadius: 8 + (_controller.value * 6),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.speed,
                        color: Colors.white,
                        size: 15,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff1B5E20),
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
