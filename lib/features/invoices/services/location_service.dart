import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/location_response_model.dart';

class LocationService {
  final Dio dio;

  LocationService({
    required this.dio,
  });

  Future<LocationResponse> insertLocation(
    LocationRequest request,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.insertLocation,
        data: request.toJson(),
      );

      return _parseResponse(response.data);
    } on DioException catch (e) {
      // API ممكن ترجع 404/400 ومعها JSON error
      final data = e.response?.data;

      if (data != null) {
        return _parseResponse(data);
      }

      // ما في response من السيرفر
      return LocationResponse(
        isSuccess: false,
        errorCode: e.response?.statusCode?.toString(),
        errorMessage: e.message ?? "حدث خطأ أثناء إرسال الموقع",
      );
    } catch (e) {
      return LocationResponse(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  LocationResponse _parseResponse(dynamic data) {
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return LocationResponse(
          isSuccess: false,
          errorMessage: data,
        );
      }
    }

    if (data is Map<String, dynamic>) {
      return LocationResponse.fromJson(data);
    }

    if (data is List && data.isNotEmpty) {
      final first = data.first;

      if (first is Map<String, dynamic>) {
        return LocationResponse.fromJson(first);
      }
    }

    return const LocationResponse(
      isSuccess: false,
      errorMessage: "Unexpected location response",
    );
  }
}
