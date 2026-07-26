import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
            top: 20,
            left: 0,
            child: _svgBackgroundIcon(const Color(0xff1976D2)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _svgBackgroundIcon(const Color(0xff0D47A1)),
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

  Widget _svgBackgroundIcon(Color color) {
    return SizedBox(
      width: 120,
      height: 120,
      child: SvgPicture.asset(
        "assets/images/waterDropIcon.svg",
        colorFilter: ColorFilter.mode(color.withOpacity(0.10), BlendMode.srcIn),
      ),
    );
  }
}
