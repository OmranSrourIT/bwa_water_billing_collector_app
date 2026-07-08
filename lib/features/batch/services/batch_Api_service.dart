import 'dart:convert';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/HandelError.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/BatchEndResponse.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/batch_model.dart';
import 'package:dio/dio.dart';

class BatchApiService {
  final Dio dio;
  BatchApiService(this.dio);

  Future<List<BatchModel>> getBatches() async {
    try {
      final response = await dio.get(ApiConstants.batches);

      final data = response.data as List;
      return data.map((e) => BatchModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    }
  }

  Future<BatchEndResponse> endBatch(String batchId) async {
    try {
      final response = await dio.post(
        ApiConstants.endBatch,
        data: {"BatchNumber": batchId},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          responseType: ResponseType.plain,
        ),
      );
      // تحويل البيانات إلى Map
      Map<String, dynamic> jsonData;
      if (response.data is String) {
        if (response.data.toString().trim().isEmpty) {
          return BatchEndResponse.error("استجابة فارغة", "Empty response");
        }
        jsonData = jsonDecode(response.data);
      } else if (response.data is Map) {
        jsonData = response.data;
      } else {
        return BatchEndResponse.error("تنسيق غير مدعوم", "Unsupported format");
      }

      return BatchEndResponse.fromJson(jsonData);
    } on DioException catch (e) {
      // التعامل مع أخطاء الـ Timeout أو انقطاع الاتصال
      print("Dio Error: ${e.type} - ${e.message}");
      return BatchEndResponse.networkError();
    } catch (e) {
      // التعامل مع أي خطأ غير متوقع في الكود
      print("Unexpected Error: $e");
      return BatchEndResponse.error(
        "حدث خطأ أثناء معالجة البيانات",
        "Error processing data",
      );
    }
  }
}
