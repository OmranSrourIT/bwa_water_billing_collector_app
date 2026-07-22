import 'package:bwa_water_billing_collector_app/features/Payment/utils/payment_error_mapper.dart';
import 'package:flutter/material.dart';

class PaymentResultDialog extends StatelessWidget {
  final bool success;
  final Map<String, dynamic> data;
  final String Invoicenumber;
  final VoidCallback? onClose;

  const PaymentResultDialog({
    super.key,
    required this.success,
    required this.data,
    required this.Invoicenumber,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final msg = data["rspMsg"] ?? "";

    final match = RegExp(r'Error\s+(-?\d+)').firstMatch(msg);

    final resultCode = match?.group(1) ?? "";

    final primaryColor = success
        ? const Color(0xff0F9D58)
        : const Color(0xffD93025);

    final secondaryColor = success
        ? const Color(0xff34A853)
        : const Color(0xffEA4335);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      tween: Tween(begin: .85, end: 1),
      curve: Curves.easeOutBack,
      builder: (_, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //================ HEADER =======================
                  Container(
                    height: 165,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: success
                            ? const [Color(0xff2F318B), Color(0xff27A9E1)]
                            : const [Color(0xff93291E), Color(0xffED213A)],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -40,
                          right: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -50,
                          left: -20,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.06),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 105,
                              height: 105,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [primaryColor, secondaryColor],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                success
                                    ? Icons.verified_rounded
                                    : Icons.cancel_rounded,
                                color: Colors.white,
                                size: 58,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              success ? "تم الدفع بنجاح" : "فشل عملية الدفع",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: success
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          // child: Text(
                          //   success ? "Payment Completed" : "Payment Failed",
                          //   style: TextStyle(
                          //     color: primaryColor,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ),

                        const SizedBox(height: 24),

                        if (success)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                _infoRow(
                                  Icons.receipt_long,
                                  "رقم الفاتورة",
                                  Invoicenumber,
                                ),
                                Divider(height: 1),
                                _infoRow(
                                  Icons.payments_rounded,
                                  "المبلغ",
                                  "${data["totalAmount"]} د.ع",
                                ),
                                Divider(height: 1),
                                _infoRow(
                                  Icons.credit_card,
                                  "طريقة الدفع",
                                  data["paymentMethod"] ?? "-",
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    PaymentErrorMapper.getMessage(
                                      resultCode,
                                      data["rspMsg"],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 22),

                        Text(
                          success
                              ? "تمت عملية الدفع وإرسال بيانات العملية بنجاح."
                              : "تعذر إتمام عملية الدفع، يرجى مراجعة سبب الخطأ ثم إعادة المحاولة.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);

                              if (onClose != null) {
                                onClose!();
                              }
                            },
                            icon: Icon(
                              success
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_back_rounded,
                            ),
                            label: Text(
                              success ? "إنهاء" : "إغلاق",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xff2F318B).withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xff2F318B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
