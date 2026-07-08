import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart' show InvoiceModel;

abstract class InvoiceService {

Future<List<InvoiceModel>> getInvoices(String batchId);

  Future<InvoiceModel> getInvoiceDetails(
        String batchId,
    String invoiceNo,
  
  );
}
