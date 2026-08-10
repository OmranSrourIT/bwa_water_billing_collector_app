import 'dart:ui' as ui; 
import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPrintLayout extends ConsumerStatefulWidget {
  final String invoiceNo;
  final String accountNo;
  final String customerName;
  final String customerMobileNo;
  final String address;
  final String collectorName;
  final double amount;
  final String today;
  final String cycleCode;
  final int paymentRefNo;
  final String phone;
  const PaymentPrintLayout({
    super.key,
    required this.invoiceNo,
    required this.accountNo,
    required this.customerName,
    required this.customerMobileNo,
    required this.address,
    required this.collectorName,
    required this.amount,
    required this.today,
    required this.cycleCode,
    required this.paymentRefNo,
    required this.phone,
  });

  TextStyle get sectionTitleStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.black,
  );

  @override
  ConsumerState<PaymentPrintLayout> createState() => _InvoicePrintLayout();
}

class _InvoicePrintLayout extends ConsumerState<PaymentPrintLayout> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          height: 1.2,
          color: Colors.black,
        ),
        child: SizedBox(
          width: 576,
          child: Padding(
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              left: 12,
              right: 12,
            ), // 🔥 إضافة Padding علوي لمنع القص
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // 🔥 مهم جداً لأخذ الطول الفعلي فقط
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ================= HEADER =================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      color: Colors.white,
                      child: Image.asset(
                        "assets/images/Governerate2_logo.png",
                        width: 120,
                        height: 120,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: const [
                          Text(
                            "دائرة ماء بغداد",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34, // خط كبير وواضح
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "نظام فوترة وجباية الماء",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "إشعار تسديد الأجور",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        "assets/images/VerticalAsimati.png",
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(thickness: 2, color: Colors.black),
                _sectionTitle("بيانات المشترك والفاتورة"),
                // ================= INFO =================
                _row(
                  "رقم الفاتورة / الإصدارية :",
                  widget.invoiceNo + " / ${widget.cycleCode}",
                ),
                _row("رقم الحساب : ", widget.accountNo),
                _row("اسم المشترك : ", widget.customerName),
                _row("رقم الهاتف : ", widget.customerMobileNo),
                _row("العنوان : ", widget.address),
                _row("تاريخ الإشعار : ", widget.today),
                _row("اسم الجابي : ", widget.collectorName),
                _row("رقم هاتف الجابي : ", widget.phone),

                const SizedBox(height: 5),
                const Divider(thickness: 2, color: Colors.black),
                const SizedBox(height: 5),

                // ================= AMOUNT =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "مبلغ الفاتورة المستحق",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${NumberFormat('#,##0.000').format(widget.amount)} د.ع",
                        style: const TextStyle(
                          fontSize: 48, // خط ضخم وواضح للمبلغ
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                const Text(
                  "يرجى تسديد المبلغ خلال ثلاثة أيام من تاريخ هذا الإشعار لخدمة الصالح العام , شاكرين تعاونكم معنا ",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                // ... (باقي الأقسام كـ QR وغيرها تبقى كما هي مع التأكد من MainAxisSize.min)
                const SizedBox(height: 20),
                // ================= QR =================
                const Text(
                  "امسح الرمز للتحقق والدفع الإلكتروني",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 15),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black87, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: AppConstant.verofNumberPrintNotice(
                        widget.paymentRefNo.toString(),
                      ),
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "دائرة ماء بغداد",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                // const Divider(thickness: 2, color: Colors.black),

                // const Center(
                //   child: Text(
                //     "يمكنك أيضاً دفع الفاتورة إلكترونياً من خلال زيارة الرابط التالي:",
                //     textAlign: TextAlign.center,
                //     style: TextStyle(
                //       fontSize: 20,
                //       fontWeight: FontWeight.bold,
                //       fontFamily: 'Cairo',
                //     ),
                //   ),
                // ),

                // const SizedBox(height: 6),

                // const Center(
                //   child: Text(
                //     "https://bwa.asimti.iq",
                //     textAlign: TextAlign.center,
                //     style: TextStyle(
                //       fontSize: 22,
                //       fontWeight: FontWeight.bold,
                //       fontFamily: 'Cairo',
                //       decoration: TextDecoration.underline,
                //     ),
                //   ),
                // ),
                const Divider(thickness: 2, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 1, bottom: 2),
        child: Text(title, style: widget.sectionTitleStyle),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Text(
            value,
            textDirection: value.contains("+964")
                ? ui.TextDirection.ltr
                : ui.TextDirection.rtl,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
