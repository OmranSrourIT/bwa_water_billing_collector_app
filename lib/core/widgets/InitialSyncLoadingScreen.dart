import 'package:flutter/material.dart';

class InitialSyncLoadingScreen extends StatefulWidget {
  final String message;

  const InitialSyncLoadingScreen({super.key, required this.message});

  @override
  State<InitialSyncLoadingScreen> createState() =>
      _InitialSyncLoadingScreenState();
}

class _InitialSyncLoadingScreenState extends State<InitialSyncLoadingScreen>
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
    return Scaffold(
      backgroundColor: const Color(0xffEEF4FB),

      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _circle(const Color(0xff1976D2)),
          ),

          Positioned(
            bottom: -140,
            right: -90,
            child: _circle(const Color(0xff0D47A1)),
          ),

          Center(
            child: Container(
              width: 350,

              padding: const EdgeInsets.all(35),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(28),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 35,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  RotationTransition(
                    turns: _controller,

                    child: Container(
                      width: 90,
                      height: 90,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        gradient: const LinearGradient(
                          colors: [Color(0xff3B82F6), Color(0xff0D47A1)],
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(.25),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),

                      child: const Icon(
                        Icons.cloud_sync_outlined,
                        color: Colors.white,
                        size: 45,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    widget.message,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff0D47A1),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const SizedBox(
                    width: 220,

                    child: LinearProgressIndicator(
                      minHeight: 6,

                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "يرجى الانتظار قليلاً",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
    child: CustomPaint(
      painter: _WaterDropPainter(color),
    ),
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


    path.moveTo(
      x(w * 0.5),
      y(h * 0.95),
    );


    path.quadraticBezierTo(
      x(w * 0.15),
      y(h * 0.65),
      x(w * 0.35),
      y(h * 0.30),
    );


    path.quadraticBezierTo(
      x(w * 0.5),
      y(h * 0.05),
      x(w * 0.65),
      y(h * 0.30),
    );


    path.quadraticBezierTo(
      x(w * 0.85),
      y(h * 0.65),
      x(w * 0.5),
      y(h * 0.95),
    );


    canvas.drawPath(path, paint);
  }


  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) => false;
}
