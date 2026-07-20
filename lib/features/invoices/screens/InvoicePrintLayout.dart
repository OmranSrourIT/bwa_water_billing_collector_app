import 'dart:ui' as ui;
import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoicePrintLayout extends StatelessWidget {
  final InvoiceInformationModel invoice;

  const InvoicePrintLayout({super.key, required this.invoice});

  String money(double v) => NumberFormat('#,##0.000').format(v);

  String formatDate(DateTime? d) =>
      d == null ? '-' : DateFormat('dd-MM-yyyy').format(d);

  // ================= STYLES =================
  TextStyle get headerStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w900,
    fontSize: 30,
    color: Colors.black,
    height: 1.1,
  );

  TextStyle get subHeaderStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w700,
    fontSize: 25,
    color: Colors.black,
  );

  TextStyle get sectionTitleStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.black,
  );

  TextStyle get labelStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 24,
    color: Colors.black,
  );

  TextStyle get valueStyle => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w600,
    fontSize: 23,
    color: Colors.black,
  );

  TextStyle get labelStyleFees => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.black,
  );

  TextStyle get valueStyleFees => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w600,
    fontSize: 19,
    color: Colors.black,
  );

  TextStyle get valueStyleFeesValue => const TextStyle(
    fontFamily: "Cairo",
    fontWeight: FontWeight.w600,
    fontSize: 21,
    color: Colors.black,
  );

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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          width: 576,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: RepaintBoundary(child: _buildContent(context)),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ================= HEADER =================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset("assets/images/BWA_Logo.png", width: 100),
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
                      Text("هيئة مياه بغداد", style: headerStyle),
                      Text("فاتورة استهلاك المياه", style: subHeaderStyle),
                      const SizedBox(height: 3),

                      Text(
                        "رقم الاصدارية: ${invoice.cycleCode}",
                        style: valueStyle.copyWith(fontSize: 20),
                      ),

                      Text(
                        "رقم الفاتورة: ${invoice.invoiceNumber}",
                        style: valueStyle.copyWith(fontSize: 20),
                      ),

                      Text(
                        getLookupCodeValue(
                                  invoice,
                                  "CollectionType",
                                  context,
                                ) ==
                                "EST"
                            ? "الفترة: من ${formatDate(invoice.periodFromDate)} - الى ${formatDate(invoice.periodToDate)}"
                            : "من ${formatDate(invoice.previousReadingDateTime)} - الى ${formatDate(invoice.currentReadDateTime)}",
                        style: valueStyle.copyWith(fontSize: 18),
                      ),

                      Text(
                        "عدد أيام الاحتساب: ${invoice.activeCollectionPeriod} يوم",
                        style: valueStyle.copyWith(fontSize: 18),
                      ),
                    ],
                  );
                },
              ),
            ),
            Image.asset("assets/images/VerticalAsimati.png", width: 100),
          ],
        ),
        const SizedBox(height: 5),
        _blackDivider(),

        // ================= بيانات المشترك =================
        _sectionTitle("بيانات المشترك"),
        _rowItem("اسم المشترك :", invoice.customerName),
        _rowItem("رقم الحساب :", invoice.accountNo),
        _rowItem("رقم الهاتف :", invoice.customerMobileNo),
        _rowItem("نوع الإشغال :", invoice.usageTypeName),
        _rowItem("العنوان :", invoice.propertyAddress),

        _blackDivider(), // سطر فاصل صلب
        // ================= معلومات الجابي =================
        _sectionTitle("معلومات الجابي"),
        _rowItem("اسم الجابي :", invoice.collectorName),

        _blackDivider(), // سطر فاصل صلب
        // ================= بيانات الاشتراك =================
        _sectionTitle("بيانات الاشتراك"),

        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.black),
          ),
          child: Column(
            children: [
              _rowItem("نوع الاشتراك :", invoice.invoiceTypeName),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(invoice, "CollectionType", context) ==
                  "EST")
                _rowItem(
                  "معدل الاستهلاك اليومي :",
                  "${invoice.estimatedPotableWater.toInt().toString()} م³",
                ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(invoice, "CollectionType", context) ==
                  "ACT")
                _rowItem(
                  "القراءة السابقة :",
                  "${invoice.previousReading.toInt().toString()} م³",
                ),

              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(invoice, "CollectionType", context) ==
                  "ACT")
                _rowItem(
                  "القراءة الحالية :",
                  "${invoice.currentReading.toInt().toString()} م³",
                ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              _rowItem(
                "الاستهلاك الكلي :",
                "${invoice.consumptionQtyPotable.toInt().toString()} م³",
              ),
            ],
          ),
        ),

        // ================= بنود الرسوم والخدمات =================
        _sectionTitle("بنود الرسوم والخدمات"),
        _blackDivider(), // سطر فاصل صلب
        if (invoice.invoiceDetails.isNotEmpty)
          ...invoice.invoiceDetails.map((item) {
            return _rowItemFees(item.description, money(item.amount));
          }).toList(),

        // ================= TOTAL BOX =================
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.black),
          ),
          child: Column(
            children: [
              _rowItem(
                "قيمة الفاتورة  :",
                "${money(invoice.totalInvoiceAmount)} د.ع",
                isTotal: true,
              ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              _rowItem("حالة الفاتورة:", "محصلة", isTotal: true),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // المعلومات في أقصى اليمين
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10,
                ), // إنزال البيانات لأسفل قليلاً لتوازي الـ QR
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // يمين في نظام RTL
                  children: const [
                    Text(
                      "هيئة مياه بغداد",
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontWeight: FontWeight.bold,
                        fontSize: 22, // تكبير الخط
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "شارع الخلفاء - بغداد - العراق",
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ), // تكبير الخط
                    ),
                    Text(
                      "+964 773 624 8535",
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ), // تكبير الخط
                    ),
                    Text(
                      "info@water.mayorality.gov.iq",
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ), // تكبير الخط
                    ),
                    SizedBox(height: 12),
                    Text(
                      "امسح الرمز للتحقق",
                      style: TextStyle(
                        fontFamily: "Cairo",
                        fontSize: 18, // تكبير الخط
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 15),

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
              child: QrImageView(
                data: AppConstant.verofNumberPrintNotice(
                  invoice.payment!.paymentRefNo.toString(),
                ),
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),
        _blackDivider(), // السطر الأخير قبل الخاتمة
        const SizedBox(height: 2),
        Center(
          child: Text(
            "شكراً لتعاملكم معنا",
            style: subHeaderStyle.copyWith(fontSize: 18),
          ),
        ),
      ],
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

  Widget _rowItem(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      child: Row(
        textDirection: ui.TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // القيمة (يسار)
          isTotal
              ? Text(value, style: labelStyle.copyWith(fontSize: 24))
              : Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.left,
                    style: valueStyle,
                  ),
                ),

          const SizedBox(width: 10),

          // الليبل (يمين)
          Text(label, style: labelStyle),
        ],
      ),
    );
  }

  Widget _rowItemFees(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      child: Row(
        textDirection: ui.TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // القيمة (يسار)
          isTotal
              ? Text(value, style: labelStyle.copyWith(fontSize: 24))
              : Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.left,
                    style: valueStyleFeesValue, //omran
                  ),
                ),

          const SizedBox(width: 10),

          // الليبل (يمين)
          Text(label, style: labelStyleFees),
        ],
      ),
    );
  }

  // ويدجت للخط الأسود الصلب والواضح للطباعة
  Widget _blackDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        thickness: 2.5, // سماكة الخط لضمان ظهوره
        color: Colors.black, // لون أسود صلب
        height: 2,
      ),
    );
  }
}
