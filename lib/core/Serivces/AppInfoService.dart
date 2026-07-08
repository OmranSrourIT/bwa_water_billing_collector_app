import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  AppInfoService._();

  static String? _version;
  static String? _buildNumber;

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform(); 
    _version = info.version;
    _buildNumber = info.buildNumber;
  }

  static String get version => _version ?? "1.0.0"; 
  static String get buildNumber => _buildNumber ?? "0";
}
