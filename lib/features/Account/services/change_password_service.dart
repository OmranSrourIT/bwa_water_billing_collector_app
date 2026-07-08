abstract class ChangePasswordService {
  Future<String> changePassword({
    required String newPassword,
    required String confirmPassword,
  });
}
