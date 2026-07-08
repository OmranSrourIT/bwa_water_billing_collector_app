import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/field_failure_lookup_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:flutter/material.dart';
import 'package:bwa_water_billing_collector_app/core/constants/AppColors.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

class InvoiceDetailsDialog extends ConsumerWidget {
  final String invoiceNumber;

  const InvoiceDetailsDialog({super.key, required this.invoiceNumber});

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  }

  String getLookupValue(
    InvoiceInformationModel invoice,
    String lookupType,
    BuildContext context,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final item = invoice.lookup.firstWhere(
      (e) => e.lookupType == lookupType,
      orElse: () => LookupModel.empty(),
    );

    return isArabic ? item.arDesc : item.enDesc;
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = Responsive.isTablet(context);
    final invoiceAsync = ref.watch(invoiceDetailProvider(invoiceNumber));

    return invoiceAsync.when(
      loading: () => BwaLoadingOverlay(isLoading: true),
      error: (error, stack) {
        final message = parseError(error);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppPopupAlert.show(context, message: message, isError: true);
        });

        return const SizedBox();
      },

      data: (invoice) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // ================= BACKGROUND =================
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.4,
                    colors: [
                      const Color(0xff27A9E1).withOpacity(0.18),
                      const Color(0xff2F318B).withOpacity(0.10),
                      Colors.white.withOpacity(0.96),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),

              // ================= MAIN =================
              Container(
                width: isTablet ? 900 : double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          // ================= HEADER =================
                          Container(
                            height: 70,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xff2F318B).withOpacity(0.95),
                                  const Color(0xff27A9E1).withOpacity(0.95),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  "تفاصيل الفاتورة",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),

                          // ================= BODY =================
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  const SizedBox(height: 6),

                                  // ================= TITLE =================
                                  _Card(
                                    child: Row(
                                      children: [
                                        const Text(
                                          "فاتورة استهلاك المياه",
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        _Badge(invoice: invoice),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // ================= SECTION 1 =================
                                  _Section(
                                    title: "معلومات الفاتورة",
                                    children: [
                                      _Row(
                                        "رقم الفاتورة",
                                        invoice.invoiceNumber,
                                        "فترة الخدمة",
                                        invoice.collectionPeriodDescription,
                                      ),
                                      _Row(
                                        "رقم الحساب",
                                        invoice.accountNo,
                                        "أيام الاحتساب",
                                        getLookupCodeValue(
                                                  invoice,
                                                  "CollectionType",
                                                  context,
                                                ) ==
                                                "EST"
                                            ? (invoice.periodToDate != null &&
                                                      invoice.periodFromDate !=
                                                          null)
                                                  ? "${invoice.periodToDate!.difference(invoice.periodFromDate!).inDays}"
                                                  : ""
                                            : (invoice.previousReadingDateTime !=
                                                      null &&
                                                  invoice.currentReadDateTime !=
                                                      null)
                                            ? "${invoice.currentReadDateTime!.difference(invoice.previousReadingDateTime!).inDays}"
                                            : "",
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // ================= SECTION 2 =================
                                  _Section(
                                    title: "بيانات المشترك",
                                    children: [
                                      _Row(
                                        "اسم المشترك",
                                        invoice.customerName,
                                        "رقم المشترك",
                                        invoice.customerID.toString(),
                                      ),
                                      _Row(
                                        "رقم الهاتف",
                                        invoice.customerMobileNo,
                                        "صفة الاستعمال",
                                        invoice.usageTypeName,
                                      ),
                                      _Row(
                                        "العنوان",
                                        invoice.propertyAddress,
                                        "المنطقة",
                                        invoice.region,
                                      ),

                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // ================= SECTION 3 =================
                                  _Section(
                                    title: "بيانات الاشتراك",
                                    children: [
                                      _Row(
                                        "نوع الاشتراك",
                                        getLookupValue(
                                          invoice,
                                          "CollectionType",
                                          context,
                                        ),
                                        "صافي الاستهلاك",
                                        getLookupCodeValue(
                                                  invoice,
                                                  "CollectionType",
                                                  context,
                                                ) ==
                                                "EST"
                                            ? "${invoice.estimatedPotableWater}"
                                            : "${invoice.consumptionQtyPotable}",
                                      ),
                                      if (getLookupCodeValue(
                                            invoice,
                                            "CollectionType",
                                            context,
                                          ) ==
                                          "ACT")
                                        _Row(
                                          "تاريخ التنصيب",
                                          _formatDate(invoice.installationDate),
                                          "الدفعة",
                                          _formatDate(invoice.installationDate),
                                        ),
                                      if (getLookupCodeValue(
                                            invoice,
                                            "CollectionType",
                                            context,
                                          ) ==
                                          "ACT")
                                        _Row(
                                          "حجم المنفذ",
                                          invoice.consumptionQtyRow.toString(),
                                          "",
                                          "",
                                          // "الإجمالي",
                                          // NumberFormat(
                                          //   '#,##0.000',
                                          // ).format(invoice.totalInvoiceAmount),
                                        ),
                                      if (getLookupCodeValue(
                                            invoice,
                                            "CollectionType",
                                            context,
                                          ) ==
                                          "ACT")
                                        _Row(
                                          "القراءة السابقة",
                                          "${invoice.previousReading}",
                                          "القراءة الحالية",
                                          "${invoice.currentReading}",
                                        ),
                                      if (invoice.attachment != null &&
                                          invoice.attachment!.isNotEmpty)
                                        _AttachmentImageInline(
                                          base64: invoice.attachment!,
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ================= TOTAL =================
                                  _TotalCard(
                                    amount: NumberFormat(
                                      '#,##0.000',
                                    ).format(invoice.totalInvoiceAmount),
                                  ),

                                  const SizedBox(height: 16),

                                  // ================= CHARGES =================
                                  _ChargesTable(
                                    charges: invoice.invoiceDetails,
                                  ),

                                  const SizedBox(height: 16),

                                  _FailureReasonsTable(
                                    reasons: invoice.failureReasons,
                                    invoice: invoice,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ================= FOOTER =================
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "إغلاق",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentImageInline extends StatelessWidget {
  final String base64;

  const _AttachmentImageInline({required this.base64});

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    try {
      var cleanBase64 = base64.trim();

      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      imageBytes = base64Decode(cleanBase64);
    } catch (e) {
      return const SizedBox();
    }

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.6),
          builder: (_) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Image.memory(imageBytes!, fit: BoxFit.contain),
                      ),
                    ),

                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xff2F318B).withOpacity(0.95),
                            const Color(0xff27A9E1).withOpacity(0.95),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "صورة المقياس",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
            );
          },
        );
      },
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(33, 47, 49, 139).withOpacity(0.70),
              const Color.fromARGB(144, 39, 169, 225).withOpacity(0.95),
            ],
          ),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, color: Colors.lightGreen),
            SizedBox(width: 8),
            Text(
              "عرض صورة المقياس",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargesTable extends StatefulWidget {
  final List<InvoiceDetailModel> charges;

  const _ChargesTable({required this.charges});

  @override
  State<_ChargesTable> createState() => _ChargesTableState();
}

class _ChargesTableState extends State<_ChargesTable> {
  String query = "";
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.charges.where((e) {
      return e.description.toLowerCase().contains(query.toLowerCase()) ||
          e.amount.toString().contains(query);
    }).toList();

    double total = filtered.fold(0, (p, e) => p + e.amount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Row(
            children: [
              Text(
                "بنود الرسوم والخدمات",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                "${filtered.length} بنود",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ===== SEARCH =====
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: "ابحث عن البند او القيمة",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ===== HEADER ROW =====
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withOpacity(0.08),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    "البند",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "القيمة",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ===== ROWS =====
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final originalIndex = widget.charges.indexOf(filtered[i]);

              return _ChargeRowItem(
                item: filtered[i],
                selected: selectedIndex == originalIndex,
                onTap: () {
                  setState(() {
                    selectedIndex = selectedIndex == originalIndex
                        ? null
                        : originalIndex;
                  });
                },
              );
            },
          ),

          const SizedBox(height: 10),

          // ===== TOTAL =====
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          //   decoration: BoxDecoration(
          //     color: Colors.green.withOpacity(0.08),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Row(
          //     children: [
          //       const Text(
          //         "الإجمالي",
          //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          //       ),
          //       const Spacer(),
          //       Text(
          //         NumberFormat('#,##0.000').format(total),
          //         style: const TextStyle(fontWeight: FontWeight.bold),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ChargeRowItem extends StatefulWidget {
  final InvoiceDetailModel item;
  final bool selected;
  final VoidCallback onTap;

  const _ChargeRowItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_ChargeRowItem> createState() => _ChargeRowItemState();
}

class _ChargeRowItemState extends State<_ChargeRowItem> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    // final active = widget.selected || hover;
    String money(double v) => NumberFormat('#,##0.000').format(v);
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),

          // 🔥 نفس الحجم القديم (مهم)
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),

            color: widget.selected
                ? AppColors.primary.withOpacity(0.06)
                : hover
                ? Colors.white.withOpacity(0.70)
                : Colors.white.withOpacity(0.45),

            border: Border.all(
              color: widget.selected
                  ? AppColors.primary.withOpacity(0.35)
                  : Colors.white.withOpacity(0.35),
            ),

            boxShadow: [
              if (widget.selected)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),

          child: Row(
            children: [
              // 🔥 مؤشر صغير جدًا (بدون ما يكبر UI)
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: widget.selected
                      ? AppColors.primary
                      : Colors.transparent,
                ),
              ),

              const SizedBox(width: 8),

              // ITEM
              Expanded(
                flex: 5,
                child: Text(
                  widget.item.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // VALUE
              Expanded(
                flex: 2,
                child: Text(
                  money(widget.item.amount),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: widget.selected
                        ? Colors.green.shade700
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FailureReasonsTable extends ConsumerWidget {
  final List<FieldFailureReasonModel> reasons;
  final InvoiceInformationModel invoice;

  const _FailureReasonsTable({required this.reasons, required this.invoice});

  String getReasonName(
    FieldFailureReasonModel item,
    List<FieldFailureLookupModel> lookup,
    BuildContext context,
  ) {
    final result = lookup.firstWhere(
      (e) => e.code == item.failureReasonCode,
      orElse: () => FieldFailureLookupModel.empty(),
    );

    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return isArabic ? result.arDesc : result.enDesc;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reasons.isEmpty) {
      return const SizedBox();
    }

    final lookupAsync = ref.watch(
      fieldFailureLookupProvider("FieldFailureReason"),
    );

    return lookupAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),

      error: (_, __) => const SizedBox(),

      data: (lookup) {
        return Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: Colors.white.withOpacity(0.4)),

            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16),
            ],
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Text(
                    "أسباب التعذر",

                    style: TextStyle(
                      fontSize: 14,

                      fontWeight: FontWeight.w700,

                      color: AppColors.primary,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    "${reasons.length} أسباب",

                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: reasons.length,
                itemBuilder: (context, index) {
                  final item = reasons[index];

                  Uint8List? imageBytes;
                  if (item.attachment != null && item.attachment!.isNotEmpty) {
                    try {
                      imageBytes = base64Decode(item.attachment!.trim());
                    } catch (e) {
                      imageBytes = null;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= HEADER =================
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                getReasonName(item, lookup, context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "الملاحظة",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          item.failureNotes.isEmpty
                              ? "لا يوجد"
                              : item.failureNotes,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // ================= IMAGE BUTTON =================
                        const SizedBox(height: 12),

                        if (imageBytes != null)
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(0.6),
                                builder: (_) {
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Dialog(
                                        backgroundColor: Colors.white,
                                        insetPadding: const EdgeInsets.all(10),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Stack(
                                            children: [
                                              // ================= IMAGE =================
                                              Center(
                                                child: InteractiveViewer(
                                                  minScale: 1.0,
                                                  maxScale: 5.0,
                                                  child: Image.memory(
                                                    imageBytes!,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),

                                              // ================= HEADER (YOUR COLORS) =================
                                              Container(
                                                height: 60,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      const Color(
                                                        0xff2F318B,
                                                      ).withOpacity(0.95),
                                                      const Color(
                                                        0xff27A9E1,
                                                      ).withOpacity(0.95),
                                                    ],
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // CLOSE
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                    // TITLE
                                                    Expanded(
                                                      child: Center(
                                                        child: Text(
                                                          getReasonName(
                                                            item,
                                                            lookup,
                                                            context,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // ================= BOTTOM HINT =================
                                              Positioned(
                                                bottom: 12,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.7),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "قرّب بإصبعين للتكبير • اسحب للتحريك",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              height: 55,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(
                                      33,
                                      47,
                                      49,
                                      139,
                                    ).withOpacity(0.70),
                                    const Color.fromARGB(
                                      144,
                                      39,
                                      169,
                                      225,
                                    ).withOpacity(0.95),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, color: Colors.lightGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    "عرض الصورة",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18),
        ],
      ),
      child: child,
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String l1, v1, l2, v2;

  const _Row(this.l1, this.v1, this.l2, this.v2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: _item(l1, v1)),
          const SizedBox(width: 16),
          Expanded(child: _item(l2, v2)),
        ],
      ),
    );
  }

  Widget _item(String l, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          v,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final InvoiceInformationModel invoice;

  _Badge({required this.invoice});

  @override
  Widget build(BuildContext context) {
    IconData getInvoiceStatusIcon(InvoiceInformationModel invoice) {
      final status = invoice.lookup.firstWhere(
        (e) => e.lookupType == "InvoiceStatus",
        orElse: () => LookupModel.empty(),
      );
      return switch (status.code) {
        // محصلة
        "COL" => Icons.check_circle_outline,

        // قيد التحصيل
        "RDY" => Icons.account_balance_wallet_outlined,

        // تعذر التحصيل
        "UNC" => Icons.error_outline,

        // قيد التنفيذ
        "ISS" => Icons.pending_actions,

        _ => Icons.info_outline,
      };
    }

    Color getInvoiceStatusColor(
      InvoiceInformationModel invoice,
      BuildContext context,
    ) {
      final status = invoice.lookup.firstWhere(
        (e) => e.lookupType == "InvoiceStatus",
        orElse: () => invoice.lookup.first,
      );

      return switch (status.code) {
        // محصلة
        "COL" => Colors.green.shade700,

        // قيد التحصيل
        "RDY" => Colors.blue.shade700,

        // تعذر التحصيل
        "UNC" => Colors.red.shade700,

        // تعذر القراءه او التنفيذ
        "UEX" => Colors.red.shade700,

        // قيد التنفيذ
        "ISS" => Colors.orange.shade700,

        // Default
        _ => Colors.grey.shade600,
      };
    }

    String getInvoiceStatus(
      InvoiceInformationModel invoice,
      BuildContext context,
    ) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      final status = invoice.lookup.firstWhere(
        (e) => e.lookupType == "InvoiceStatus",
        orElse: () => invoice.lookup.first,
      );

      return isArabic ? status.arDesc : status.enDesc;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: getInvoiceStatusColor(invoice, context).withOpacity(0.12),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: getInvoiceStatusColor(invoice, context).withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getInvoiceStatusIcon(invoice),
            color: getInvoiceStatusColor(invoice, context),
            size: 17,
          ),

          const SizedBox(width: 6),

          Text(
            getInvoiceStatus(invoice, context),

            style: TextStyle(
              color: getInvoiceStatusColor(invoice, context),

              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final String amount;

  const _TotalCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1B5E20), Color(0xff43A047)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            "قيمة الفاتورة الحالية (د.ع)",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
