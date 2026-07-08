import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateScreen extends StatefulWidget {
  final String apkUrl;

  const UpdateScreen({super.key, required this.apkUrl});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  double progress = 0;

  bool isDownloading = false;

  Future<void> downloadAndInstallApk() async {
    await Permission.requestInstallPackages.request();

    await Permission.notification.request();

    setState(() {
      isDownloading = true;

      progress = 0;
    });

    try {
      final directory = await getExternalStorageDirectory();

      final filePath = "${directory!.path}/bwa_update.apk";

      Dio dio = Dio();

      await dio.download(
        "https://bwa.infinite-tek.com:8443/rest/v1/NewReleaseDownload/newRelease.apk",

        filePath,

        options: Options(
          headers: {"Accept": "application/vnd.android.package-archive"},

          responseType: ResponseType.bytes,
        ),

        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (mounted) {
              setState(() {
                progress = received / total;
              });
            }
          }
        },
      );

      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint("Download Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("فشل التحميل: تأكد من اتصالك بالإنترنت"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
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

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,

                    vertical: 30,
                  ),

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
                        width: 90,

                        height: 90,

                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,

                          gradient: LinearGradient(
                            colors: [Color(0xff1976D2), Color(0xff0D47A1)],
                          ),
                        ),

                        child: const Icon(
                          Icons.system_update,

                          size: 45,

                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "تحديث جديد متوفر",

                        style: TextStyle(
                          fontSize: 20,

                          fontWeight: FontWeight.w800,

                          color: Color(0xff0D47A1),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        "يوجد إصدار جديد من التطبيق يحتوي على تحسينات مهمة\nيرجى التحديث للمتابعة",

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 13,

                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 25),

                      if (isDownloading)
                        _downloadProgress()
                      else
                        _downloadButton(),

                      const SizedBox(height: 15),

                      Text(
                        'نظام تحصيل فواتير المياه',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      width: double.infinity,

      height: 50,

      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),

          gradient: const LinearGradient(
            colors: [Color(0xff3B82F6), Color(0xff1E3A8A)],
          ),
        ),

        child: ElevatedButton.icon(
          onPressed: downloadAndInstallApk,

          icon: const Icon(Icons.download, color: Colors.white),

          label: const Text(
            "تحميل التحديث",

            style: TextStyle(
              color: Colors.white,

              fontSize: 16,

              fontWeight: FontWeight.w600,
            ),
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,

            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _downloadProgress() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xffEEF4FB),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.downloading_rounded,

            size: 38,

            color: Color(0xff1976D2),
          ),

          const SizedBox(height: 12),

          const Text(
            "جاري تحميل التحديث",

            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              value: progress,

              minHeight: 14,

              backgroundColor: Colors.grey.shade300,

              valueColor: const AlwaysStoppedAnimation(Color(0xff1976D2)),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "${(progress * 100).toStringAsFixed(0)} %",

            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
    final paint = Paint()..color = color.withOpacity(.10);

    final path = Path();

    path.moveTo(size.width * .5, size.height * .95);

    path.quadraticBezierTo(
      size.width * .15,
      size.height * .65,

      size.width * .35,
      size.height * .30,
    );

    path.quadraticBezierTo(
      size.width * .5,
      size.height * .05,

      size.width * .65,
      size.height * .30,
    );

    path.quadraticBezierTo(
      size.width * .85,
      size.height * .65,

      size.width * .5,
      size.height * .95,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
