import 'package:bwa_water_billing_collector_app/features/Account/model/account_model.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_api_service.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_service.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  final dio = ref.read(dioProvider);

  return AccountApiService(dio);
});


final accountProvider = FutureProvider<AccountModel>((ref) async {
  final service = ref.read(accountServiceProvider);
  return service.getAccount();
});
