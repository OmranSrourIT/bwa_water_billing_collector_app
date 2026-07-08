import 'dart:convert';
import 'dart:ui';

import 'package:bwa_water_billing_collector_app/core/Serivces/AppInfoService.dart';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Model/AppUpdate.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Storage/AppUpdateStorage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appUpdateStorageProvider = Provider<AppUpdateStorage>((ref) {
  return AppUpdateStorage();
});

final appUpdateProvider = FutureProvider<AppUpdate>((ref) async {
  final dio = Dio();
  final storage = ref.read(appUpdateStorageProvider);

  try {
    final res = await dio.get(
      "${ApiConstants.baseUrl}${ApiConstants.updateAppVersion(AppInfoService.version)}",
    );

    // 🔥 FIX: parse string -> json
    final data = res.data is String
        ? jsonDecode(res.data)
        : res.data;

    final model = AppUpdate.fromJson(data);

    // 🔥 خزّن محلياً
    await storage.saveUpdateData(
      needUpdate: model.needUpdate,
      apkUrl: model.apkURL,
    );

    return model;
  } catch (e) {
    final cachedNeedUpdate = await storage.getNeedUpdate();
    final cachedUrl = await storage.getApkUrl() ?? "";

    if (cachedUrl.isEmpty) {
      return AppUpdate(needUpdate: false, apkURL: "");
    }

    return AppUpdate(
      needUpdate: cachedNeedUpdate,
      apkURL: cachedUrl,
    );
  }
});

final localeProvider = StateProvider<Locale>((ref) => const Locale('ar'));

final forceUpdateProvider = Provider<bool>((ref) {
  final update = ref.watch(appUpdateProvider);

  return update.when(
    data: (value) => value.needUpdate,
    loading: () => false,
    error: (_, __) => false,
  );
});
