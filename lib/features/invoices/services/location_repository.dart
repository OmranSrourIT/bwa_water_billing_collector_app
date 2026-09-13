import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/sync_queue_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_response_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/location_service.dart';

class LocationRepository {
  final LocationService api;
  final SyncQueueLocalService queue;
  final bool isOnline;

  LocationRepository({
    required this.api,
    required this.queue,
    required this.isOnline,
  });

  Future<LocationResponse> saveLocation(
    LocationRequest request,
  ) async {
    if (isOnline) {
      return await api.insertLocation(request);
    }

    await queue.addQueue(
      type: "LOCATION",
      referenceNo: request.invoiceNumber,
      payload: {
        "invoiceNumber": request.invoiceNumber,
        "latitude": request.latitude,
        "longitude": request.longitude,
      },
    );

    return const LocationResponse(
  isSuccess: true,
  result: "PENDING",
);
  }
}
