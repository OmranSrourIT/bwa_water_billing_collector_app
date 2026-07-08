import 'package:dio/dio.dart';
import '../models/invoice_model.dart';
import 'invoice_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/HandelError.dart';

class InvoiceApiService implements InvoiceService {
  final Dio dio;

  InvoiceApiService(this.dio);

  @override
  Future<List<InvoiceModel>> getInvoices(String batchId) async {
    try {
      final response = await dio.get(ApiConstants.invoices(batchId),);

      return (response.data as List)
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
    } catch (e) {
      if (e is DioException) {
        throw Exception(handleDioError(e));
      }

      throw Exception(e.toString());
    }
  }

  @override
  Future<InvoiceModel> getInvoiceDetails(String batchId, String invoiceNo) async {
    final list = await getInvoices(batchId);
    return list.firstWhere((e) => e.invoiceNo == invoiceNo);
  }


}
