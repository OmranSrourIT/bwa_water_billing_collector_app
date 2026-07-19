 import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/AccountLocalService.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/batch_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/lookup_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_api_service.dart';
import 'package:bwa_water_billing_collector_app/features/batch/services/batch_Api_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/FieldFailureLookupService.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoice_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

import '../database/dao/invoice_local_service.dart';

class InitialSyncRepository {
  final BatchApiService batchApi;
  final InvoiceService invoiceApi;
  final InvoiceDetailsService detailsApi;
  final FieldFailureLookupService lookupApi;
  final AccountApiService accountApi;
  final BatchLocalService batchLocal;
  final InvoiceLocalService invoiceLocal;
  final InvoiceDetailsLocalService detailsLocal;
  final LookupLocalService lookupLocal;
  final AccountLocalService accountLocal;

  InitialSyncRepository({
    required this.batchApi,
    required this.invoiceApi,
    required this.detailsApi,
    required this.lookupApi,
    required this.accountApi,
    required this.batchLocal,
    required this.invoiceLocal,
    required this.detailsLocal,
    required this.lookupLocal,
    required this.accountLocal,
  });

  Future<void> downloadInitialData({
    Function(String message)? onProgress,
  }) async {
    try {
      onProgress?.call("جاري تجهيز البيانات محليا...");

      //تحميل بيانات الحساب

      final account = await accountApi.getAccount();

      await accountLocal.saveAccount(account);

      // تحميل الدفعات

      final batches = await batchApi.getBatches();

      await batchLocal.insertBatches(batches);

     // تحميل حالة الفاتورة ، تحميل اسباب التعذر 

      const lookupTypes = ["FieldFailureReason", "InvoiceStatus"];

      for (final type in lookupTypes) {
        final lookups = await lookupApi.getLookupStatus(type);

        await lookupLocal.insertLookups(type, lookups);
      }
    
      onProgress?.call("تم تحميل جميع البيانات بنجاح");
    } catch (e) {
      onProgress?.call("حدث خطأ أثناء تحميل البيانات");

      rethrow;
    }
  }

  
}
