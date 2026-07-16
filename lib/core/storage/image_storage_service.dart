import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  Future<Directory> _imagesDirectory() async {
    final dir = await getApplicationDocumentsDirectory();

    final imagesDir = Directory("${dir.path}/images");

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  String _buildFileName({
    required String invoiceNo,
    required String type,
  }) {
    return "${type.toLowerCase()}_$invoiceNo.jpg";
  }

  Future<String?> saveInvoiceImage({
    required String invoiceNo,
    required String type,
    String? base64,
  }) async {
    if (base64 == null || base64.trim().isEmpty) {
      return null;
    }

    final folder = await _imagesDirectory();

    final fileName = _buildFileName(
      invoiceNo: invoiceNo,
      type: type,
    );

    final file = File("${folder.path}/$fileName");

    final bytes = base64Decode(base64);

    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  Future<String> saveBytes({
    required List<int> bytes,
    required String invoiceNo,
    required String type,
  }) async {
    final folder = await _imagesDirectory();

    final fileName = _buildFileName(
      invoiceNo: invoiceNo,
      type: type,
    );

    final file = File("${folder.path}/$fileName");

    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  Future<String?> imageToBase64(String? path) async {
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);

    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();

    return base64Encode(bytes);
  }

  Future<File?> getImage(String? path) async {
    if (path == null || path.isEmpty) {
      return null;
    }

    final file = File(path);

    if (!await file.exists()) {
      return null;
    }

    return file;
  }

  Future<bool> exists(String? path) async {
    if (path == null || path.isEmpty) {
      return false;
    }

    return File(path).exists();
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
