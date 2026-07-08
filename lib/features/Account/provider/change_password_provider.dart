import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';

import '../services/change_password_api_service.dart';
import '../services/change_password_service.dart';

final changePasswordServiceProvider =
    Provider<ChangePasswordService>((ref) {
  final dio = ref.read(dioProvider); 
  return ChangePasswordApiService(dio);
});

