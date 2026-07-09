import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/invoice_details_local_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/services/invoiceDetials_service.dart';

class InvoiceDetailsRepository {
  final InvoiceDetailsService api;

  final InvoiceDetailsLocalService local;

  final bool isOnline;

  InvoiceDetailsRepository({
    required this.api,
    required this.local,
    required this.isOnline,
  });

 
  Future<InvoiceInformationModel> getInvoice(String invoiceNo) async {
    if (isOnline) {
      final result = await api.getInvoice(invoiceNo); 
      return result;
    }

    print("Offline => Invoice Details");

    final localData = await local.getInvoiceDetails(invoiceNo);

    if (localData == null) {
      throw Exception("No offline data");
    }

    return localData;
  }
}
