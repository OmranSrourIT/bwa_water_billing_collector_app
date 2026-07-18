import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/batch_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/batch_model.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';

class BatchRepository {
  final BatchApiService api;
  final BatchLocalService local;

  final bool isOnline;

  BatchRepository({
    required this.api,
    required this.local,
    required this.isOnline,
  });

  Future<List<BatchModel>> getBatches() async {
    if (isOnline) {
      final batches = await api.getBatches();

    //  batches.sort((a, b) => a.assignedDate.compareTo(b.assignedDate));

      batches.sort((a, b) => a.batchNumber.compareTo(b.batchNumber));

      return batches;
    }

    return await local.getAllBatches();
  }
}
