import 'package:bwa_water_billing_collector_app/core/constants/AppColors.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/HandelError.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/change_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  bool loading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "كلمة المرور مطلوبة";
    }

    if (value.length < 8) {
      return "يجب أن تكون كلمة المرور 8 أحرف على الأقل";
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "يجب أن تحتوي على حرف كبير (A-Z)";
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "يجب أن تحتوي على حرف صغير (a-z)";
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "يجب أن تحتوي على رقم";
    }

    if (!RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(value)) {
      return "يجب أن تحتوي على رمز خاص";
    }

    return null;
  }

  InputDecoration decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xff1976D2)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xffF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff1976D2), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xffEAF3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Color(0xff1976D2),
                  size: 42,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "تعديل كلمة المرور",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0D47A1),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "يجب أن تتكون كلمة المرور من 8 خانات على الأقل , وأن تحتوي على أرقام وأحرف كبيرة و صغيرة ,رموز خاصة مثل !@#\$%^&*()_+",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color.fromARGB(255, 230, 5, 5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _newPasswordController,
                obscureText: _hidePassword,
                validator: validatePassword,
                decoration: decoration(
                  label: "كلمة المرور الجديدة",
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "كلمة المرور مطلوبة";
                  }

                  if (value != _newPasswordController.text) {
                    return "كلمة المرور غير متطابقة";
                  }

                  return null;
                },
                decoration: decoration(
                  label: "تأكيد كلمة المرور",
                  icon: Icons.lock,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => loading = true);

                          try {
                            final result = await ref
                                .read(changePasswordServiceProvider)
                                .changePassword(
                                  newPassword: _newPasswordController.text
                                      .trim(),
                                  confirmPassword: _confirmPasswordController
                                      .text
                                      .trim(),
                                );

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            AppPopupAlert.show(
                              context,
                              message: result,
                              isError: false,
                            );
                          } catch (e) {
                            final errorMessage = e!.toString().replaceAll(
                              "Exception: ",
                              "",
                            );

                            AppPopupAlert.show(
                              context,
                              message: errorMessage,
                              isError: true,
                            );
                          }

                          setState(() => loading = false);
                        },

                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xff1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "حفظ التغيرات",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryDark.withOpacity(0.15),
                  ),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      "إلغاء",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
