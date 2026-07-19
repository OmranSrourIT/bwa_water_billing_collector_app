import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:dio/dio.dart';
 
class InvoiceDetailsService {
  final Dio dio;

  InvoiceDetailsService(this.dio);

  Future<InvoiceInformationModel> getInvoiceDeatils(String invoiceNumber) async {
    final response = await dio.get(ApiConstants.invoiceDetails(invoiceNumber));

    return InvoiceInformationModel.fromJson(response.data);
  }

  Future<String> updateNoticePrint(String invoiceNo) async {
  try {
    final response = await dio.post(
      ApiConstants.updateNoticePrint,data: {"InvoiceNo":invoiceNo}
    );

    final data = response.data;

    if (data is Map && data['Invoice'] != null) {
      final invoice = data['Invoice'];
      return invoice['NoticePrintedDateTime'].toString();
    }

    return data.toString();
  } catch (e) {
    throw Exception(e.toString());
  }
}
}
