import 'package:bwa_water_billing_collector_app/core/Serivces/AppInfoService.dart';
import 'package:bwa_water_billing_collector_app/core/lang/app_localizations.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/responsive.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/services/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onToggleLang;
  final Locale locale;

  const LoginScreen({
    super.key,
    required this.onToggleLang,
    required this.locale,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool rememberMe = false;

  bool _handledExpired = false;

  // late final WebViewController _webViewController;
  // String? _captchaToken;
  // bool _showCaptcha = false;

  @override
  void initState() {
    super.initState();
    // _webViewController = WebViewController()
    //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //   ..addJavaScriptChannel(
    //     'CaptchaChannel',
    //     onMessageReceived: (message) {
    //       setState(() {
    //         _captchaToken = message.message;
    //         _showCaptcha = false;
    //       });
    //       print("Captcha Token: $_captchaToken");
    //     },
    //   )
    //   ..loadHtmlString(_buildHtml() , baseUrl: ApiConstants.baseUrl);

    Future.microtask(() async {
      final storage = ref.read(tokenStorageProvider);

      rememberMe = await storage.getRememberMe();
      if (rememberMe) {
        _usernameController.text = await storage.getUsername() ?? "";

        _passwordController.text = await storage.getPassword() ?? "";
      }
     

      if (mounted) {
        setState(() {});
      }
    });

    final auth = ref.read(authProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.tokenExpired &&
          auth.user == null &&
          auth.initialized &&
          !_handledExpired) {
        _showSessionExpiredAlert();
      }
    });

    ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (next.tokenExpired &&
          next.successLogin == true &&
          auth.user == null &&
          !_handledExpired) {
        _showSessionExpiredAlert();
      }
      
      if (next.error != null && next.error != prev?.error) {
        Future.microtask(() {
          if (mounted) {
            AppPopupAlert.show(
              context,
              message:
                  next.error?.toString().replaceFirst("Exception: ", "") ??
                  "Unknown error",
              isError: true,
            );
          }
        });
      }
    });
  }

  // String _buildHtml() {
  //   return """
  //   <html>
  //     <head>
  //       <meta name="viewport" content="width=device-width, initial-scale=1.0">
  //       <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  //       <script>
  //         function onResult(token ) {
  //           CaptchaChannel.postMessage(token);
  //         }
  //       </script>
  //       <style>
  //         body { display: flex; justify-content: center; align-items: center; background: transparent; margin: 0; padding: 0; }
  //       </style>
  //     </head>
  //     <body>
  //       <div class="g-recaptcha"
  //            data-sitekey="6LdYa1AtAAAAAGF-PqV2EXHToACnZdAKfKfkH-_A"
  //            data-callback="onResult"></div>
  //     </body>
  //   </html>
  // """;
  // }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSessionExpiredAlert() {
    _handledExpired = true;
    AppPopupAlert.show(
      context,
      message: "انتهت الجلسة، الرجاء تسجيل الدخول مرة أخرى",
      isError: true,
    );
  }

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = Responsive.isTablet(context);
    final cardWidth = isTablet ? size.width * 0.90 : size.width * 0.90;

    return Scaffold(
      backgroundColor: const Color(0xffEEF4FB),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _circle(const Color(0xff1976D2)),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: _circle(const Color(0xff0D47A1)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  right: 10,
                  left: 10,
                  top: 0,
                  bottom: 50,
                ),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 10,
                  ),
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
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LanguageArEn(widget: widget),
                            Container(
                              padding: EdgeInsets.only(top: 8),
                              width: 65,
                              height: 65,
                              child: Image.asset(
                                "assets/images/VerticalAsimati.png",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _logo(),
                        const SizedBox(height: 18),
                        Text(
                          t.t("title"),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0D47A1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.t("subtitle"),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _input(
                          controller: _usernameController,
                          icon: Icons.person_outline,
                          label: t.t("username"),
                          hint: t.t("enter_username"),
                          validatorText: t.t("username_required"),
                        ),
                        const SizedBox(height: 16),
                        _input(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          label: t.t("password"),
                          hint: t.t("enter_password"),
                          obscure: obscurePassword,
                          suffix: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          validatorText: t.t("password_required"),
                        ),

                        // Align(
                        //   alignment: AppLocalizations.of(context).locale.languageCode == 'en'
                        //       ? Alignment.centerLeft
                        //       : Alignment.centerRight,
                        //   child: TextButton(
                        //     onPressed: () {
                        //       _showForgotPasswordDialog(context);
                        //     },
                        //     child: Text(
                        //       t.t("password_forgot"),
                        //       style: TextStyle(
                        //         fontSize: 12,
                        //         color: const Color(0xff1976D2),
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 20),

                        // 🛡️ reCAPTCHA Widget
                        // if (_captchaToken == null)
                        //   Container(
                        //     height: 100,
                        //     width: double.infinity,
                        //     margin: const EdgeInsets.only(bottom: 10),
                        //     child: WebViewWidget(
                        //       controller: _webViewController,
                        //     ),
                        //   )
                        // else
                        // Padding(
                        //   padding: const EdgeInsets.only(bottom: 10),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       const Icon(Icons.check_circle, color: Colors.green),
                        //       const SizedBox(width: 8),
                        //       const Text(
                        //         "تم التحقق بنجاح",
                        //         style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (v) {
                                setState(() {
                                  rememberMe = v ?? false;
                                });
                              },
                            ),
                            const Text(
                              "تذكرني ؟",
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xff1976D2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        _button(t),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffEEF4FB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xff1976D2).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 16,
                                color: Color(0xff1976D2),
                              ),

                              const SizedBox(width: 6),
                              Text(
                                "${t.t("version")}  ${AppInfoService.version}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff0D47A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (ref.watch(authProvider).isLoading)
            const BwaLoadingOverlay(isLoading: true),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool loading = false;
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xff1976D2), Color(0xff0D47A1)],
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "إستعادة كلمة المرور",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff0D47A1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: emailController,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Email required" : null,
                        decoration: InputDecoration(
                          labelText: "البريد الإلكتروني",
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: const BorderSide(
                                  color: Color(0xff1976D2),
                                ),
                              ),
                              child: const Text("إلغاء"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: loading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;
                                      setState(() => loading = true);
                                      try {
                                        // logic for reset email
                                        Navigator.pop(context);
                                        AppPopupAlert.show(
                                          context,
                                          message:
                                              "تم إرسال رابط إعادة التعيين",
                                          isError: false,
                                        );
                                      } catch (e) {
                                        AppPopupAlert.show(
                                          context,
                                          message: e.toString(),
                                          isError: true,
                                        );
                                      }
                                      setState(() => loading = false);
                                    },
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _logo() {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Image.asset("assets/images/BWA_Logo.png"),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    String? validatorText,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return validatorText;
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        labelStyle: const TextStyle(
          color: Color(0xff0D47A1),
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button(AppLocalizations t) {
    return Consumer(
      builder: (context, ref, _) {
        final authState = ref.watch(authProvider);
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xff3B82F6), Color.fromARGB(166, 30, 59, 138)],
              ),
            ),
            child: ElevatedButton(
              onPressed:
                  (authState.isLoading) //|| _captchaToken == null
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      FocusScope.of(context).unfocus();
                      try {
                        await ref
                            .read(authProvider.notifier)
                            .login(
                              username: _usernameController.text,
                              password: _passwordController.text,
                              rememberMe: rememberMe,
                            );
                      } catch (e) {
                        final message = parseError(e);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          AppPopupAlert.show(
                            context,
                            message: message,
                            isError: true,
                          );
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t.t("login"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class LanguageArEn extends StatelessWidget {
  const LanguageArEn({super.key, required this.widget});
  final LoginScreen widget;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AppLocalizations.of(context).locale.languageCode == 'ar'
          ? Alignment.topLeft
          : Alignment.topRight,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffEEF4FB),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xff1976D2).withOpacity(0.25)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {}, // Language toggle logic
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    size: 20,
                    color: Color(0xff1976D2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).locale.languageCode == 'en'
                        ? 'العربية'
                        : 'العربية',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xff0D47A1),
                      fontSize: 16,
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

Widget _circle(Color color) {
  return SizedBox(
    width: 280,
    height: 280,
    child: CustomPaint(painter: _WaterDropPainter(color)),
  );
}

class _WaterDropPainter extends CustomPainter {
  final Color color;
  _WaterDropPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.10)
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h * 0.05);
    path.quadraticBezierTo(w * 0.15, h * 0.35, w * 0.35, h * 0.70);
    path.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.65, h * 0.70);
    path.quadraticBezierTo(w * 0.85, h * 0.35, w * 0.5, h * 0.05);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
