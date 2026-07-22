import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart';
import 'package:bwa_water_billing_collector_app/core/storage/PrinterStorage.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/requestAppPermissions.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/Printer%20VAN_GOLD/printer_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/printer_channel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/PaymentPrintLayout.dart';
import 'dart:ui' as ui;

class PaymentNoticeDialog extends ConsumerStatefulWidget {
  final String invoiceNumber;

  PaymentNoticeDialog({super.key, required this.invoiceNumber});

  @override
  ConsumerState<PaymentNoticeDialog> createState() =>
      _PaymentNoticeDialogState();
}

class _PaymentNoticeDialogState extends ConsumerState<PaymentNoticeDialog> {
  bool isPrinting = false;

  TextStyle get sectionTitleStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.black,
  );
  final ScreenshotController screenshotController = ScreenshotController();
  String get today {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildDialog(context),
        BwaLoadingOverlay(isLoading: isPrinting),
      ],
    );
  }

  Dialog buildDialog(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceNumber));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    HraderPopup(context),

                    /// ================= BODY (FIXED)
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            /// ================= HEADER CARD
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: Image.asset(
                                      "assets/images/BWA_Logo.png",
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  const Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          "هيئة مياه بغداد",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "نظام فوترة خدمات المياه",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          "إشعار تسديد",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: Image.asset(
                                      "assets/images/VerticalAsimati.png",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            /// ================= INFO
                            ///
                            invoiceAsync.when(
                              data: (invoice) {
                                return Column(
                                  children: [
                                    _NoticeCard(
                                      title: "بيانات المشترك",
                                      child: Column(
                                        children: [
                                          _NoticeRow(
                                            "رقم الفاتورة / الإصدارية :",
                                            invoice.invoiceNumber +
                                                " / ${invoice.cycleCode}",
                                          ),
                                          _NoticeRow(
                                            "رقم الحساب :",
                                            invoice.accountNo,
                                          ),
                                          _NoticeRow(
                                            "أسم المشترك :",
                                            invoice.customerName,
                                          ),
                                          _NoticeRow(
                                            "العنوان",
                                            invoice.propertyAddress,
                                          ),
                                          _NoticeRow("تاريخ الإشعار : ", today),
                                          _NoticeRow(
                                            "أسم الجابي : ",
                                            invoice.collectorName,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    /// ================= AMOUNT
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black12,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text("المبلغ المترتب"),
                                          const SizedBox(height: 8),
                                          Text(
                                            "${NumberFormat('#,##0.000').format(invoice.totalInvoiceAmount)} د.ع",

                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    /// ================= NOTICE
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Text(
                                        "يرجى تسديد المبلغ خلال ثلاثة أيام من تاريخ هذا الإشعار , ونشكر تعاملكم معنا ",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    /// ================= QR
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            "أمسح الرمز للتحقق والدفع الألكتروني",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.black12,
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: QrImageView(
                                              data:
                                                  AppConstant.verofNumberPrintNotice(
                                                    invoice
                                                        .payment!
                                                        .paymentRefNo
                                                        .toString(),
                                                  ),

                                              size: 142,
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },

                              loading: () {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              error: (e, s) {
                                return const SizedBox();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    invoiceAsync.when(
                      data: (invoice) {
                        return FooterPopup(context, invoice);
                      },
                      loading: () {
                        return const SizedBox();
                      },
                      error: (e, s) {
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER
  Container HraderPopup(BuildContext context) {
    return Container(
      height: 55,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff2F318B), Color(0xff27A9E1)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text("إشعار الدفع", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ================= FOOTER
  Container FooterPopup(
    BuildContext context,
    InvoiceInformationModel infoDetials,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color.fromARGB(162, 158, 158, 158)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "إغلاق",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 22),
              label: Text(
                "طباعة الإشعار",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),

              onPressed: () async {
                setState(() => isPrinting = true);

                // 👇 اجبر Flutter يرسم الـ loading قبل أي عمل ثقيل
                await Future.delayed(const Duration(milliseconds: 100));

                try {
                  final controller = ScreenshotController();

                  final printWidget = PaymentPrintLayout(
                    invoiceNo: infoDetials.invoiceNumber,
                    accountNo: infoDetials.accountNo,
                    customerName: infoDetials.customerName,
                    address: infoDetials.propertyAddress,
                    collectorName: infoDetials.collectorName,
                    amount: infoDetials.totalInvoiceAmount,
                    today: today,
                    cycleCode: infoDetials.cycleCode,
                    paymentRefNo: infoDetials.payment!.paymentRefNo,
                  );

                  final image = await controller.captureFromWidget(
                    Material(
                      color: Colors.white,
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: printWidget,
                      ),
                    ),
                    pixelRatio: 3,
                    // 🔥 إضافة targetSize بارتفاع كبير جداً لمنع الـ Overflow نهائياً
                    targetSize: const Size(
                      576,
                      3000,
                    ), // القيمة الأصلية الخاصة بك
                  );

                  final granted = await requestBluetoothPermissions();
                  if (!granted) return;

                  final mac = await PrinterStorage.getMac();

                  if (mac == null) {
                    AppPopupAlert.show(
                      context,
                      message:
                          "الطابعة غير متصلة، يرجى الاتصال بالطابعة أولاً.",
                      isError: true,
                    );
                    return;
                  }

                  if (image != null) {
                    await PrinterChannel.printImage(mac: mac, image: image);

                    final result = await ref.read(
                      updateNoticePrintProvider(
                        infoDetials.invoiceNumber,
                      ).future,
                    );

                    AppPopupAlert.show(
                      context,
                      message: "تم الطباعة وتحديث الإشعار بنجاح",
                      isError: false,
                    );
                  }
                } catch (e) {
                  final message = parseError(e);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppPopupAlert.show(
                      context,
                      message: message,
                      isError: true,
                    );
                  });
                } finally {
                  setState(() => isPrinting = false);
                }
              },
            ),
          ),
        ],
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
}

/// ================= CARD
class _NoticeCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _NoticeCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// ================= ROW
class _NoticeRow extends StatelessWidget {
  final String label;
  final String value;

  const _NoticeRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
