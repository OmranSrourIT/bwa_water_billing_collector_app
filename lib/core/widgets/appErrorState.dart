import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffEEF4FB),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Stack(
        children: [
          

          Center(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xffEF5350), Color(0xffC62828)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(.25),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "تعذر تحميل البيانات",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff0D47A1),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "إعادة المحاولة",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1976D2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "تحقق من اتصال الإنترنت ثم حاول مرة أخرى.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(Color color) {
    return SizedBox(
      width: 280,
      height: 280,
      child: CustomPaint(painter: _WaterDropPainter(color)),
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  final Color color;

  _WaterDropPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final path = Path();

    final w = size.width;
    final h = size.height;

    double x(double v) => v;
    double y(double v) => h - v;

    path.moveTo(x(w * 0.5), y(h * 0.95));

    path.quadraticBezierTo(x(w * 0.15), y(h * 0.65), x(w * 0.35), y(h * 0.30));

    path.quadraticBezierTo(x(w * 0.5), y(h * 0.05), x(w * 0.65), y(h * 0.30));

    path.quadraticBezierTo(x(w * 0.85), y(h * 0.65), x(w * 0.5), y(h * 0.95));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
