import 'package:bwa_water_billing_collector_app/features/AppGate/Screen/appGate.dart';
import 'package:bwa_water_billing_collector_app/features/security/Services/SecurityService.dart';
import 'package:flutter/material.dart';
 

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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (blocked) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppGate(onToggleLang: widget.onToggleLang);
  }
}
