import 'dart:ui' as ui;
import 'package:bwa_water_billing_collector_app/core/constants/AppConstant.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InvoicePrintLayout extends ConsumerStatefulWidget {
  final InvoiceInformationModel invoice;
  final String phone;
 final String status;
  const InvoicePrintLayout({
    super.key,
    required this.invoice,
    required this.phone,
    required this.status
  });

  @override
  ConsumerState<InvoicePrintLayout> createState() => _InvoicePrintLayout();
}

class _InvoicePrintLayout extends ConsumerState<InvoicePrintLayout> {
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
    fontSize: 22,
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
            Image.asset("assets/images/Governerate2_logo.png", width: 100),
            Expanded(
              child: Builder(
                builder: (context) {
                  final collectionType = getLookupCodeValue(
                    widget.invoice,
                    "CollectionType",
                    context,
                  );

                  final int? days = (collectionType == "EST")
                      ? (widget.invoice.periodToDate != null &&
                                widget.invoice.periodFromDate != null)
                            ? widget.invoice.periodToDate!
                                  .difference(widget.invoice.periodFromDate!)
                                  .inDays
                            : null
                      : (widget.invoice.previousReadingDateTime != null &&
                            widget.invoice.currentReadDateTime != null)
                      ? widget.invoice.currentReadDateTime!
                            .difference(widget.invoice.previousReadingDateTime!)
                            .inDays
                      : null;

                  return Column(
                    children: [
                      Text("دائرة ماء بغداد", style: headerStyle),
                      Text("فاتورة استهلاك المياه", style: subHeaderStyle),
                      const SizedBox(height: 3),

                      Text(
                        "رقم الاصدارية: ${widget.invoice.cycleCode}",
                        style: valueStyle.copyWith(fontSize: 20),
                      ),

                      Text(
                        "رقم الفاتورة: ${widget.invoice.invoiceNumber}",
                        style: valueStyle.copyWith(fontSize: 20),
                      ),

                      Text.rich(
                        getLookupCodeValue(
                                  widget.invoice,
                                  "CollectionType",
                                  context,
                                ) ==
                                "EST"
                            ? TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "الفترة: من ",
                                    style: TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatDate(
                                      widget.invoice.periodFromDate,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " - إلى ",
                                    style: TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatDate(
                                      widget.invoice.periodToDate,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              )
                            : TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "من ",
                                    style: TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatDate(
                                      widget.invoice.previousReadingDateTime,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " - إلى ",
                                    style: TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatDate(
                                      widget.invoice.currentReadDateTime,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: "Cairo",
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "عدد أيام الاحتساب: ",
                              style: const TextStyle(
                                fontFamily: "Cairo",
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.invoice.activeCollectionPeriod} يوم",
                              style: const TextStyle(
                                fontFamily: "Cairo",
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
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
        _rowItem("اسم المشترك :", widget.invoice.customerName),
        _rowItem("رقم الحساب :", widget.invoice.accountNo),
        _rowItem("رقم الهاتف :", widget.invoice.customerMobileNo),
        _rowItem("نوع الإشغال :", widget.invoice.usageTypeName),
        _rowItem("العنوان :", widget.invoice.propertyAddress),

        _blackDivider(), // سطر فاصل صلب
        // ================= معلومات الجابي =================
        _sectionTitle("معلومات الجابي"),
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.black),
          ),
          child: Column(
            children: [
              _rowItem("اسم الجابي :", widget.invoice.collectorName),
              const Divider(height: 1, thickness: 3, color: Colors.black),

              _rowItem("رقم هاتف الجابي:", "${widget.phone}"),
            ],
          ),
        ),

        // ================= بيانات الاشتراك =================
        _sectionTitle("بيانات الإشتراك والإستهلاك",),

        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 3, color: Colors.black),
          ),
          child: Column(
            children: [
              _rowItem("نوع الاشتراك :", widget.invoice.invoiceTypeName),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(
                    widget.invoice,
                    "CollectionType",
                    context,
                  ) ==
                  "EST")
                _rowItem(
                  "معدل الاستهلاك اليومي :",
                  "${widget.invoice.estimatedPotableWater.toInt().toString()} م³",
                ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(
                    widget.invoice,
                    "CollectionType",
                    context,
                  ) ==
                  "ACT")
                _rowItem(
                  "القراءة السابقة :",
                  "${widget.invoice.previousReading.toInt().toString()} م³",
                ),

              const Divider(height: 1, thickness: 3, color: Colors.black),
              if (getLookupCodeValue(
                    widget.invoice,
                    "CollectionType",
                    context,
                  ) ==
                  "ACT")
                _rowItem(
                  "القراءة الحالية :",
                  "${widget.invoice.currentReading.toInt().toString()} م³",
                ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              _rowItem(
                "الاستهلاك الكلي :",
                "${widget.invoice.consumptionQtyPotable.toInt().toString()} م³",
              ),
            ],
          ),
        ),

        // ================= بنود الرسوم والخدمات =================
        _sectionTitle("بنود الرسوم والخدمات"),
        _blackDivider(), // سطر فاصل صلب
        if (widget.invoice.invoiceDetails.isNotEmpty)
          ...widget.invoice.invoiceDetails.map((item) {
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
                "مبلغ الفاتورة المستحق :",
                "${money(widget.invoice.totalInvoiceAmount)} د.ع",
                isTotal: true,
              ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              _rowItem(
                "مجموع الديون السابقة :",
                "${money(widget.invoice!.totalDebt!)} د.ع",
                isTotal: true,
              ),
              const Divider(height: 1, thickness: 3, color: Colors.black),
              _rowItem("حالة الفاتورة :", widget.status, isTotal: true),
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
                      "دائرة ماء بغداد",
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
                  widget.invoice.payment!.paymentRefNo.toString(),
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
        // Center(
        //   child: Text(
        //     "دائرة ماء بغداد",
        //     style: subHeaderStyle.copyWith(fontSize: 25),
        //   ),
        // ),
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
                    textDirection: value.contains("+964")
                        ? ui.TextDirection.ltr
                        : ui.TextDirection.rtl,
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
