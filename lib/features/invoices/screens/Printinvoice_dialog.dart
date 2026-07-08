import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/printer_channel.dart';
import 'package:bwa_water_billing_collector_app/features/Printer%20VAN_GOLD/printer_service.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/InvoicePrintLayout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;

class PrintInvoiceDialog extends ConsumerStatefulWidget {
  final String invoiceNumber;
  final String Function(InvoiceInformationModel invoice, BuildContext context)
  getInvoiceStatusCode;

  const PrintInvoiceDialog({
    super.key,
    required this.invoiceNumber,
    required this.getInvoiceStatusCode,
  });

  @override
  ConsumerState<PrintInvoiceDialog> createState() => _PrintInvoiceDialogState();
}

class _PrintInvoiceDialogState extends ConsumerState<PrintInvoiceDialog> {
  bool isPrinting = false;
  final ScreenshotController controller = ScreenshotController();

  String formatDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd-MM-yyyy').format(d);

  String formatAmount(double value) {
    return NumberFormat('#,##0.000').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceNumber));
    return Stack(
      children: [
        buildDialog(context, invoiceAsync),
        BwaLoadingOverlay(isLoading: isPrinting),
      ],
    );
  }

  Dialog buildDialog(
    BuildContext context,
    AsyncValue<InvoiceInformationModel> invoiceAsync,
  ) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12), // 🔥 أصغر
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * .88, // 🔥 أصغر
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24), // 🔥 أخف
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.96),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildHeader(context),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: invoiceAsync.when(
                        data: (invoice) {
                          return Column(
                            children: [
                              _buildMainInvoiceCard(invoice),

                              const SizedBox(height: 10),

                              _buildCustomerSection(invoice),

                              const SizedBox(height: 10),

                              _buildCollectorSection(invoice),

                              const SizedBox(height: 10),

                              _buildSubscriptionSection(invoice),

                              const SizedBox(height: 10),

                              // _buildChargesTable(),
                              const SizedBox(height: 10),

                              _buildTotalAmount(invoice),

                              const SizedBox(height: 10),

                              _buildStatus(context, invoice),

                              const SizedBox(height: 10),

                              _buildQrSection(invoice),

                              const SizedBox(height: 12),

                              _buildFooter(context, invoice),
                            ],
                          );
                        },

                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: CircularProgressIndicator(),
                          ),
                        ),

                        error: (e, _) => Center(child: Text("Error: $e")),
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
    );
  }

  //================================================
  // HEADER
  //================================================
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
              child: const Text("إغلاق"),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text("طباعة الفاتورة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                setState(() => isPrinting = true);

                try {
                  final image = await controller.captureFromWidget(
                    Material(
                      color: Colors.white,
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: InvoicePrintLayout(invoice: infoDetials),
                      ),
                    ),
                    pixelRatio: 3,
                    targetSize: const Size(576, 3000),
                  );

                  final granted = await requestBluetoothPermissions();
                  if (!granted) return;

                  await PrinterChannel.printImage(
                    mac: "86:67:7A:02:70:92",
                    image: image,
                  );
                } catch (e) {
                  debugPrint("PRINT ERROR: $e");
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 62, // 🔥 أصغر
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff2F318B), Color(0xff27A9E1)],
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "فاتورة المياه",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18, // 🔥 أصغر
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "رقم الفاتورة ${widget.invoiceNumber}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  //================================================
  // MAIN CARD
  //================================================

  Widget _buildMainInvoiceCard(InvoiceInformationModel invoice) {
    String getLookupCodeValue(
      InvoiceInformationModel invoice,
      String lookupType,
      BuildContext context,
    ) {
      final item = invoice.lookup.firstWhere(
        (e) => e.lookupType == lookupType,
        orElse: () => LookupModel.empty(),
      );

      return item.code;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset("assets/images/BWA_Logo.png", width: 90, height: 90),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final collectionType = getLookupCodeValue(
                      invoice,
                      "CollectionType",
                      context,
                    );

                    final int? days = (collectionType == "EST")
                        ? (invoice.periodToDate != null &&
                                  invoice.periodFromDate != null)
                              ? invoice.periodToDate!
                                    .difference(invoice.periodFromDate!)
                                    .inDays
                              : null
                        : (invoice.previousReadingDateTime != null &&
                              invoice.currentReadDateTime != null)
                        ? invoice.currentReadDateTime!
                              .difference(invoice.previousReadingDateTime!)
                              .inDays
                        : null;

                    return Column(
                      children: [
                        const Text(
                          "هيئة مياه بغداد",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "فاتورة استهلاك المياه",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "رقم الاصدارية: ${invoice.cycleCode}",
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 2),
                        Text(
                          "رقم الفاتورة : ${widget.invoiceNumber}",
                          style: const TextStyle(fontSize: 14),
                        ),

                        Text(
                          "الفترة: من ${formatDate(invoice.periodFromDate)} - الى ${formatDate(invoice.periodToDate)}",
                          style: const TextStyle(fontSize: 14),
                        ),

                        Text(
                          "عدد أيام الاحتساب: ${days?.toString() ?? ""} يوم",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Image.asset(
                "assets/images/VerticalAsimati.png",
                width: 90,
                height: 90,
              ),
            ],
          ),
        ],
      ),
    );
  }

  //================================================
  // CUSTOMER
  //================================================

  Widget _buildTotalAmount(InvoiceInformationModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "قيمة الفاتورة المطلوبة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            "${formatAmount(invoice.totalInvoiceAmount)} د.ع",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(InvoiceInformationModel invoice) {
    return _SectionCard(
      title: "بيانات المشترك",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.person_outline,
                  label: "اسم المشترك",
                  value: invoice.customerName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoRow(
                  icon: Icons.badge_outlined,
                  label: "رقم الحساب",
                  value: invoice.accountNo,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.phone_outlined,
                  label: "رقم الهاتف",
                  value: invoice.customerMobileNo.isEmpty
                      ? "-"
                      : invoice.customerMobileNo.endsWith("+")
                      ? "+${invoice.customerMobileNo.substring(0, invoice.customerMobileNo.length - 1)}"
                      : invoice.customerMobileNo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoRow(
                  icon: Icons.home_work_outlined,
                  label: "نوع الإشغال",
                  value: invoice.usageTypeName,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _InfoRow(
            icon: Icons.location_on_outlined,
            label: "العنوان",
            value: invoice.propertyAddress,
            isLast: true,
          ),
        ],
      ),
    );
  }
  //================================================
  // COLLECTOR
  //================================================

  Widget _buildCollectorSection(InvoiceInformationModel invoice) {
    return _SectionCard(
      title: "معلومات الجابي",
      child: _InfoRow(
        icon: Icons.person_search_outlined,
        label: "اسم الجابي",
        value: invoice.collectorName,
        isLast: true,
      ),
    );
  }

  //================================================
  // SUBSCRIPTION
  //================================================

  Widget _buildSubscriptionSection(InvoiceInformationModel invoice) {
    return _SectionCard(
      title: "بيانات الاشتراك",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.assignment_outlined,
                  label: "نوع الاشتراك",
                  value: invoice.invoiceTypeName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoRow(
                  icon: Icons.show_chart_outlined,
                  label: "معدل الاستهلاك اليومي",
                  value: invoice.estimatedPotableWater.toStringAsFixed(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.water_drop_outlined,
                  label: "الاستهلاك الكلي",
                  value: invoice.consumptionQtyPotable.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoRow(
                  icon: Icons.speed_outlined,
                  label: "رقم المقياس",
                  value: invoice.accountNo,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              // Expanded(
              //   child: _InfoRow(
              //     icon: Icons.alt_route_outlined,
              //     label: "المسار",
              //     value: invoice.routeNo,
              //   ),
              // ),
              const SizedBox(width: 10),
              // Expanded(
              //   // child: _InfoRow(
              //   //   icon: Icons.repeat_outlined,
              //   //   label: "الدورة",
              //   //   value: invoice.cycleNo,
              //   //   isLast: true,
              //   // ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
  //================================================
  // CHARGES
  //================================================

  // Widget _buildChargesTable() {
  //   return _SectionCard(
  //     title: "بنود الرسوم والخدمات",
  //     child: Column(
  //       children: invoice.charges.map((charge) {
  //         return Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 8),
  //           child: Row(
  //             children: [
  //               Expanded(
  //                 child: Text(
  //                   charge.description,
  //                   textAlign: TextAlign.right,
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //               ),

  //               Text(
  //                 formatAmount(charge.amount),
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  //================================================
  // TOTAL
  //================================================

  //================================================
  // STATUS
  //================================================

  Widget _buildStatus(BuildContext contex, InvoiceInformationModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Text(
            "حالة الفاتورة",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.getInvoiceStatusCode(invoice, context),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  //================================================
  // QR
  //================================================

  Widget _buildQrSection(InvoiceInformationModel invoice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        textDirection: ui.TextDirection.ltr,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: AppConstant.verofNumberPrintNotice(
                invoice.payment!.paymentRefNo.toString(),
              ),

              size: 170,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 18),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "هيئة مياه بغداد",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text("شارع الخلفاء - بغداد - العراق"),
                SizedBox(height: 4),
                Text("+964 773 624 8535", textDirection: ui.TextDirection.ltr),
                SizedBox(height: 4),
                Text("info@water.mayorality.gov.iq"),
                SizedBox(height: 10),
                Text(
                  "امسح الرمز للتحقق والدفع الإلكتروني",
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //================================================
  // FOOTER
  //================================================

  Widget _buildFooter(BuildContext context, InvoiceInformationModel invoice) {
    return Column(
      children: [
        const Text(
          "شكراً لتعاملكم معنا",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xff27A9E1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff2F318B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5EAF3)),
      ),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xff2F318B).withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff2F318B), size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
