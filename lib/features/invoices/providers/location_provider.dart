import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_response_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/location_service.dart';
 

final locationServiceProvider = Provider<LocationService>((ref) {
  final dio = ref.read(dioProvider);

  return LocationService(
    dio: dio,
  );
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(
    api: ref.read(locationServiceProvider),
    queue: ref.read(syncQueueLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final insertLocationProvider =
    FutureProvider.family<LocationResponse, LocationRequest>(
  (ref, request) async {
    final repository = ref.read(locationRepositoryProvider);

    return repository.saveLocation(request);
  },
);
