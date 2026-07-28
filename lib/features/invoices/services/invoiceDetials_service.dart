import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:dio/dio.dart';

class InvoiceDetailsService {
  final Dio dio;

  InvoiceDetailsService(this.dio);

  Future<InvoiceInformationModel> getInvoiceDeatils(
    String invoiceNumber,
  ) async {
    try {
      final response = await dio.get(
        ApiConstants.invoiceDetails(invoiceNumber),
      );

      return InvoiceInformationModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        throw Exception(
          data['message'] ??
              data['Message'] ??
              data['error'] ??
              'حدث خطأ أثناء جلب تفاصيل الفاتورة',
        );
      }

      throw Exception('حدث خطأ أثناء جلب تفاصيل الفاتورة');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> updateNoticePrint(String invoiceNo) async {
    try {
      final response = await dio.post(
        ApiConstants.updateNoticePrint,
        data: {"InvoiceNo": invoiceNo},
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
