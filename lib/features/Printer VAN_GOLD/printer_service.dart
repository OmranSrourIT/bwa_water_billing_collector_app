
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBluetoothPermissions() async {
  final bluetooth = await Permission.bluetooth.request();
  final connect = await Permission.bluetoothConnect.request();
  final scan = await Permission.bluetoothScan.request();

  return bluetooth.isGranted && connect.isGranted && scan.isGranted;
}


