import 'dart:io';

import 'package:bwa_water_billing_collector_app/features/AppGate/Screen/appGate.dart';
import 'package:bwa_water_billing_collector_app/features/security/Services/SecurityService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class SecurityGate extends StatefulWidget {
  final VoidCallback onToggleLang;

  const SecurityGate({super.key, required this.onToggleLang});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  bool loading = true;
  bool blocked = false;
  String reason = "";

  @override
  void initState() {
    super.initState();
    checkDevice();
  }

  Future<void> checkDevice() async {
    final root = await SecurityService.isRooted();
    final emulator = await SecurityService.isEmulator();
    final vpn = await SecurityService.isVpnActive();

    if (!mounted) return;

    if (root) {
      blocked = true;
      reason = "لا يمكن تشغيل التطبيق على جهاز Root";
    } else if (emulator) {
      blocked = true;
      reason = "لا يمكن تشغيل التطبيق على حهاز محاكي";
    } else if (vpn) {
      blocked = true;
      reason = "VPN غير مسموح أثناء استخدام التطبيق";
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!loading && !blocked) {
      return AppGate(onToggleLang: widget.onToggleLang);
    }

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
                  child: loading ? _loadingWidget() : _blockedWidget(),
                ),
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
        colorFilter: ColorFilter.mode(
          color.withOpacity(0.10),
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _loadingWidget() {
    return Column(
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
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          "جاري التحقق من أمان الجهاز",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xff0D47A1),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "يرجى الانتظار قليلاً...",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _blockedWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xffE53935), Color(0xffB71C1C)],
            ),
          ),
          child: const Icon(Icons.security, color: Colors.white, size: 46),
        ),

        const SizedBox(height: 18),

        const Text(
          "تعذر تشغيل التطبيق",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xff0D47A1),
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "تم اكتشاف إعدادات أو بيئة تشغيل غير مسموح بها لحماية بيانات النظام.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffFCEAEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
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
              onPressed: () async {
                if (Platform.isAndroid) {
                  await SystemNavigator.pop();
                } else {
                  exit(0);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text(
                "إغلاق التطبيق",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
