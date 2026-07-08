import '../model/account_model.dart';

abstract class AccountService {
  Future<AccountModel> getAccount();
}
