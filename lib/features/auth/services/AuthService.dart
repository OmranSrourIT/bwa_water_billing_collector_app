import 'package:bwa_water_billing_collector_app/features/auth/models/auth_model.dart';

abstract class AuthService {
  Future<AuthUser> login({required String username, required String password});
  Future<void> logout();
}
