import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEEF4FB),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 35,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_reset,
                    size: 70,
                    color: Color(0xff1976D2),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "إستعادة كلمة المرور",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0D47A1),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: emailController,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Email required" : null,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: const Color(0xffF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1976D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;

                              setState(() => loading = true);

                              try {
                                await ref
                                    .read(forgotPasswordProvider)
                                    .sendResetEmail(
                                      emailController.text.trim(),
                                    );

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("تم إرسال الرابط"),
                                    ),
                                  );

                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                final message = parseError(e);

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  AppPopupAlert.show(
                                    context,
                                    message: message,
                                    isError: true,
                                  );
                                });
                              }

                              setState(() => loading = false);
                            },
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "إرسال",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
