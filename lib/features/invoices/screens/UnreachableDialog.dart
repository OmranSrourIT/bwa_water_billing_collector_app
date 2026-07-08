import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/image_helper.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/FailureReasonRequestModel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/failure_reason_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/field_failure_lookup_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/reading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnreachableDialog extends ConsumerStatefulWidget {
  final String invoiceNumber;
  final String batchId;

  const UnreachableDialog({
    super.key,
    required this.invoiceNumber,
    required this.batchId,
  });

  @override
  ConsumerState<UnreachableDialog> createState() => _UnreachableDialogState();
}

class _UnreachableDialogState extends ConsumerState<UnreachableDialog> {
  final notesController = TextEditingController();

  String? selectedReasonCode;
  String? base64Image;
  String? invoiceStatus;
  bool isSaving = false;
  String getLookupValue(
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
    final lookupReasons = ref.watch(
      fieldFailureLookupProvider("FieldFailureReason"),
    );
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceNumber.toString()));

    final showCamera =
        selectedReasonCode == "DAM" || selectedReasonCode == "LCK";

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 650,
              maxHeight: MediaQuery.of(context).size.height * .82,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.96),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // ================= HEADER =================
                      Container(
                        height: 62,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xff2F318B), Color(0xff27A9E1)],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Text(
                              "تعذر التنفيذ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ================= INFO CARD =================
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "سيتم تسجيل حالة تعذر التنفيذ للفاتورة رقم ${widget.invoiceNumber} وإرسالها للمراجعة",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ================= REASON =================
                              const Text(
                                "سبب التعذر *",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 8),
                              lookupReasons.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),

                                error: (error, _) => Text(error.toString()),

                                data: (data) {
                                  return invoiceAsync.when(
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (e, _) => Text(e.toString()),
                                    data: (invoice) {
                                      final invoiceStatus = getLookupValue(
                                        invoice,
                                        "InvoiceStatus",
                                        context,
                                      );

                                      // فلترة الأسباب حسب حالة الفاتورة
                                      final filteredData = data.where((item) {
                                        final invoiceStatusValue = invoiceStatus
                                            .trim();

                                        switch (invoiceStatusValue) {
                                          case "ISS":
                                            return item.code == "CNA" ||
                                                item.code == "NTM" ||
                                                item.code == "DAM" ||
                                                item.code == "MST" ||
                                                item.code == "OTH";

                                          case "RDY":
                                            return item.code == "CNA" ||
                                                item.code == "CNP" ||
                                                item.code == "OTH";

                                          default:
                                            return true;
                                        }
                                      }).toList();

                                      // ترتيب حسب Order
                                      filteredData.sort(
                                        (a, b) => a.order!.compareTo(b.order!),
                                      );

                                      return DropdownButtonFormField<String>(
                                        value: selectedReasonCode,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        items: filteredData.map((item) {
                                          return DropdownMenuItem<String>(
                                            value: item.code,
                                            child: Text(
                                              isArabic
                                                  ? item.arDesc
                                                  : item.enDesc,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedReasonCode = value;
                                            base64Image = null;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 22),

                              // ================= NOTES =================
                              const Text(
                                "الملاحظات",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 8),

                              TextField(
                                controller: notesController,
                                maxLines: 6,
                                decoration: InputDecoration(
                                  hintText: "اكتب تفاصيل إضافية...",
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 22),

                              // ================= ATTACH IMAGE =================
                              if (showCamera)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(.06),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(.15),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(height: 10),

                                      const Text("التقاط صورة إلزامي"),

                                      const SizedBox(height: 10),

                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final img =
                                              await ImageHelper.pickImageBase64();
                                          if (img != null) {
                                            setState(() {
                                              base64Image = img;
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.camera),
                                        label: const Text("فتح الكاميرا"),
                                      ),

                                      if (base64Image != null)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text("✓ تم التقاط الصورة"),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // ================= FOOTER =================
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: const Text("إلغاء"),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (selectedReasonCode == null) {
                                          AppPopupAlert.show(
                                            context,
                                            message: "يجب اختيار سبب التعذر",
                                            isError: true,
                                          );
                                          return;
                                        }

                                        if(notesController.text.trim().isEmpty){
                                          AppPopupAlert.show(
                                            context,
                                            message: "يجب كتابة ملاحظات",
                                            isError: true,
                                          );
                                          return;
                                        }

                                        if (showCamera && base64Image == null) {
                                          AppPopupAlert.show(
                                            context,
                                            message: "يجب التقاط صورة",
                                            isError: true,
                                          );
                                          return;
                                        }

                                        setState(() {
                                          isSaving = true;
                                        });

                                        try {
                                          final invoice = await ref.read(
                                            invoiceDetailProvider(
                                              widget.invoiceNumber.toString(),
                                            ).future,
                                          );

                                          final currentStatus = getLookupValue(
                                            invoice,
                                            "InvoiceStatus",
                                            context,
                                          );

                                          // 🔥 تحويل الحالة إلى status جديد
                                          String newStatus;

                                          if (currentStatus == "ISS") {
                                            newStatus =
                                                "UEX"; // تعذر القراءة أو التنفيذ
                                          } else if (currentStatus == "RDY") {
                                            newStatus = "UNC"; // تعذر التحصيل
                                          } else {
                                            throw Exception(
                                              "حالة الفاتورة غير قابلة للتعذر",
                                            );
                                          }

                                          // 🔄 حفظ سبب التعذر (زي كودك الحالي)
                                          final result = await ref.read(
                                            failureReasonProvider(
                                              FailureReasonRequest(
                                                invoiceNo: widget.invoiceNumber,
                                                code: selectedReasonCode!,
                                                failureReason:
                                                    selectedReasonCode!,
                                                notes: notesController.text,
                                                base64: base64Image,
                                              ),
                                            ).future,
                                          );

                                          // 🔥 تحديث الحالة
                                          await ref.read(
                                            updateInvoiceStatusProvider((
                                              invoiceNo: widget.invoiceNumber.toString(),
                                              status: newStatus,
                                            )).future,
                                          );

                                          // إعادة تحميل الفواتير
                                          ref.invalidate(
                                            invoicesProvider(widget.batchId.toString()),
                                          );

                                          ref.invalidate(
                                            invoiceDetailProvider(
                                              widget.invoiceNumber.toString(),
                                            ),
                                          );

                                          AppPopupAlert.show(
                                            context,
                                            message: isArabic ? result.arMessage : result.enMessage,
                                            isError: false,
                                            onOk: () {
                                              Navigator.pop(context, result);
                                            },
                                          );
                                        } catch (e) {
                                          final message = parseError(e);

                                          AppPopupAlert.show(
                                            context,
                                            message: message,
                                            isError: true,
                                          );
                                        } finally {
                                          setState(() {
                                            isSaving = false;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.save),
                                label: const Text("حفظ التعذر"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
        ),
        BwaLoadingOverlay(isLoading: isSaving),
      ],
    );
  }
}
