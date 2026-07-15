import 'package:bwa_water_billing_collector_app/core/offlineMode/database/dao/AccountLocalService.dart';
import 'package:bwa_water_billing_collector_app/features/Account/model/account_model.dart';
import 'package:bwa_water_billing_collector_app/features/Account/services/account_service.dart';
 

class AccountRepository {
  final AccountService api;
  final AccountLocalService local;
  final bool isOnline;

  AccountRepository({
    required this.api,
    required this.local,
    required this.isOnline,
  });

  Future<AccountModel> getAccount() async {
    if (isOnline) {
      final account = await api.getAccount();

      await local.saveAccount(account);

      return account;
    }

    return await local.getAccount();
  }
}
