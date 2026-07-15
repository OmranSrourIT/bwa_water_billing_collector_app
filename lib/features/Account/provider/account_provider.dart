import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/repositories/AccountRepository.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/Account/model/account_model.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_api_service.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_service.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  final dio = ref.read(dioProvider);

  return AccountApiService(dio);
});

 

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    api: ref.read(accountServiceProvider),
    local: ref.read(accountLocalServiceProvider),
    isOnline: ref.watch(connectionProvider),
  );
});

final accountProvider = FutureProvider<AccountModel>((ref) async {
  final repository = ref.watch(accountRepositoryProvider);

  return repository.getAccount();
});
