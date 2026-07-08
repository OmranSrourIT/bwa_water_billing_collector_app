import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPrintLayout extends StatelessWidget {
  final String invoiceNo;
  final String accountNo;
  final String customerName;
  final String address;
  final String collectorName;
  final double amount;
  final String today;
  final int cycleCode;
 final int paymentRefNo;
  const PaymentPrintLayout({
    super.key,
    required this.invoiceNo,
    required this.accountNo,
    required this.customerName,
    required this.address,
    required this.collectorName,
    required this.amount,
    required this.today,
    required this.cycleCode,
    required this.paymentRefNo
  });

  TextStyle get sectionTitleStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.black,
  );

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
                        "assets/images/BWA_Logo.png",
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
                            "هيئة مياه بغداد",
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
                            "نظام فوترة خدمات المياه",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "إشعار تسديد",
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
                _sectionTitle("بيانات المشترك"),
                // ================= INFO =================
                _row(
                  "رقم الفاتورة / الإصدارية :",
                  invoiceNo + " / ${cycleCode}",
                ),
                _row("رقم الحساب : ", accountNo),
                _row("أسم المشترك : ", customerName),
                _row("العنوان : ", address),
                _row("تاريخ الإشعار : ", today),
                _row("أسم الجابي : ", collectorName),

                const SizedBox(height: 10),
                const Divider(thickness: 2, color: Colors.black),

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
                        "المبلغ المترتب",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${NumberFormat('#,##0.000').format(amount)} د.ع",
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
                  "يرجى تسديد المبلغ خلال ثلاثة أيام من تاريخ هذا الإشعار , ونشكر تعاملكم معنا لخدمة الصالح العام ",
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
                  "أمسح الرمز للتحقق والدفع الألكتروني",
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
                      data: AppConstant.verofNumberPrintNotice(paymentRefNo.toString()),
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(thickness: 2, color: Colors.black),
                const Center(
                  child: Text(
                    "شكراً لكم",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(height: 5), // مساحة في النهاية لمنع القص
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
        child: Text(title, style: sectionTitleStyle),
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
