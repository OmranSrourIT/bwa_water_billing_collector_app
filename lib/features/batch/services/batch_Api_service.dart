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

      dynamic data = response.data;

      // إذا كانت الاستجابة نصًا
      if (data is String) {
        final text = data.trim();

        // استجابة فارغة تعني لا توجد سجلات
        if (text.isEmpty) {
          return [];
        }

        // محاولة تحويل النص إلى JSON
        try {
          data = jsonDecode(text);
        } catch (_) {
          // النص العادي من الـ API يعني عدم وجود سجلات
          return [];
        }
      }

      // إذا كانت الاستجابة قائمة
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => BatchModel.fromJson(item))
            .toList();
      }

      // إذا كان الـ API يرجع Object يحتوي على قائمة
      if (data is Map<String, dynamic>) {
        final listData =
            data["Data"] ??
            data["data"] ??
            data["Batches"] ??
            data["batches"] ??
            data["Result"];

        if (listData is List) {
          return listData
              .whereType<Map<String, dynamic>>()
              .map((item) => BatchModel.fromJson(item))
              .toList();
        }

        // Object بدون قائمة يعني لا توجد سجلات
        return [];
      }

      // أي تنسيق غير متوقع نعتبره بدون سجلات
      return [];
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
      throw Exception(handleDioError(e));
    } catch (e) {
      return BatchEndResponse.error(
        "حدث خطأ أثناء معالجة البيانات",
        "Error processing data",
      );
    }
  }
}
