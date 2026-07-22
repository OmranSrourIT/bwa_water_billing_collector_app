import 'package:bwa_water_billing_collector_app/features/Printer%20VAN_GOLD/printer_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestAppPermissions() async {
  await Permission.camera.request();
  await Permission.location.request();
  await requestBluetoothPermissions();
}

Future<bool> requestBluetoothPermissions() async {
  final bluetooth = await Permission.bluetooth.request();
  final connect = await Permission.bluetoothConnect.request();
  final scan = await Permission.bluetoothScan.request();

  return bluetooth.isGranted && connect.isGranted && scan.isGranted;
}

