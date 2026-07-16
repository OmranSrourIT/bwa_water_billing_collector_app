import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bwa_water_billing_collector_app/core/storage/image_storage_service.dart';

final imageStorageProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});
