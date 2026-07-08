import 'dart:io';
import 'package:safe_device/safe_device.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SecurityService {
  static Future<bool> isRooted() async {
    try {
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;
      final isMockLocation = await SafeDevice.isMockLocation; 
      return isJailBroken || !isRealDevice || isMockLocation;
    } catch (e) {
       
      return true;
    }
  }

  static Future<bool> isEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;

      return !android.isPhysicalDevice ||
          android.model.toLowerCase().contains("sdk") ||
          android.fingerprint.toLowerCase().contains("generic") ||
          android.brand.toLowerCase().contains("generic");
    }

    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return !ios.isPhysicalDevice;
    }

    return false;
  }

  static Future<bool> isVpnActive() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        final name = interface.name.toLowerCase();

      
        if (name.contains("tun") ||
            name.contains("ppp") ||
            name.contains("pptp") ||
            name.contains("l2tp") ||
            name.contains("ipsec") ||
            name.contains("vpn")) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
