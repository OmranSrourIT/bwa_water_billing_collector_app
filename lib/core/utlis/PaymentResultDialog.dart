import 'package:bwa_water_billing_collector_app/core/utlis/payment_error_mapper.dart';
import 'package:flutter/material.dart';

class PaymentResultDialog extends StatelessWidget {
  final bool success;

  final Map<String, dynamic> data;

  const PaymentResultDialog({
    super.key,

    required this.success,

    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final code = data["rspCode"] ?? "";

    final msg = data["rspMsg"] ?? "";

final match = RegExp(r'Error\s+(-?\d+)')
    .firstMatch(msg);

final Resultcode = match?.group(1) ?? "";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,

              size: 80,

              color: success ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 15),

            Text(
              success ? "تم الدفع بنجاح" : "فشل الدفع",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (success) ...{
              _Info("رقم العملية", data["tranId"]),

              _Info("المبلغ", "${data["amount"]} د.ع"),

              _Info("البطاقة", data["maskedAccount"]),

              _Info("طريقة الدفع", data["paymentMethod"]),

              _Info("RRN", data["rrn"]),
            } else
              _Info(
                "السبب",

                PaymentErrorMapper.getMessage(Resultcode, data["rspMsg"]),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),

              child: Text("إغلاق"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _Info(String title, String? value) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),

      padding: EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Expanded(child: Text(title)),

          Expanded(child: Text(value ?? "-")),
        ],
      ),
    );
  }
}
