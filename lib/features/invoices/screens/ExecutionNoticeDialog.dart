import 'dart:ui' as ui;
import 'dart:ui';

import 'package:bwa_water_billing_collector_app/core/storage/PrinterStorage.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/request_AppPermissions.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/printer_channel.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/field_failure_lookup_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/field_failure_lookup_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import 'ExecutionPrintLayout.dart';

class ExecutionNoticeDialog extends ConsumerStatefulWidget {
  final String invoiceNumber;

  const ExecutionNoticeDialog({super.key, required this.invoiceNumber});

  @override
  ConsumerState<ExecutionNoticeDialog> createState() =>
      _ExecutionNoticeDialogState();
}

class _ExecutionNoticeDialogState extends ConsumerState<ExecutionNoticeDialog> {
  bool isPrinting = false;
  String selectedFailureReason = 'لم يتم تحديد السبب';
  String get printedAt =>
      DateFormat('yyyy-MM-dd / HH:mm').format(DateTime.now()); 

 String getFailureReasonLabel(
  InvoiceInformationModel invoice,
  List<FieldFailureLookupModel> failureReasons,
) {
  if (invoice.failureReasons.isEmpty) {
    return 'لم يتم تحديد السبب';
  }

  final failure = invoice.failureReasons.last;
  final reasonCode = failure.failureReasonCode.trim();

  for (final item in failureReasons) {
    if (item.code.trim() == reasonCode) {
      final arabicDescription = item.arDesc.trim();

      if (arabicDescription.isNotEmpty) {
        return arabicDescription;
      }

      final englishDescription = item.enDesc.trim();

      if (englishDescription.isNotEmpty) {
        return englishDescription;
      }
    }
  }

  final notes = failure.failureNotes.trim();

  return notes.isNotEmpty ? notes : 'لم يتم تحديد السبب';
}


  String cleanCollectorName(String value) =>
      value.replaceAll('null', '').trim();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildDialog(context),
        BwaLoadingOverlay(isLoading: isPrinting),
      ],
    );
  }

  Widget _buildDialog(BuildContext context) {
    final failureReasonsAsync = ref.watch(
      fieldFailureLookupProvider("FieldFailureReason"),
    );
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceNumber));
    final accountAsync = ref.watch(accountProvider);

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
                    _header(context),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: invoiceAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, _) =>
                              Center(child: Text(parseError(error))),
                          data: (invoice) => accountAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) =>
                                Center(child: Text(parseError(error))),
                            data: (account) => failureReasonsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, _) =>
                                  Center(child: Text(parseError(error))),
                              data: (failureReasons) =>
                                  _body(invoice, account.phone, failureReasons),
                            ),
                          ),
                        ),
                      ),
                    ),
                    invoiceAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (invoice) => _footer(context, invoice),
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

  Widget _header(BuildContext context) {
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
          const Text(
            'إشعار تعذر التنفيذ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _body(
    InvoiceInformationModel invoice,
    String phone,
   List<FieldFailureLookupModel> failureReasons,

  ) {
    final collector = cleanCollectorName(invoice.collectorName);
    selectedFailureReason = getFailureReasonLabel(invoice, failureReasons);

    final reason = selectedFailureReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _noticeCard(
          child: Row(
            children: [
              _logo('assets/images/Governerate2_logo.png'),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  children: [
                    Text(
                      'دائرة ماء بغداد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'نظام فوترة وجباية الماء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'إشعار تعذر تنفيذ القراءة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _logo('assets/images/VerticalAsimati.png'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _noticeCard(
          title: 'بيانات المشترك والحساب',
          child: Column(
            children: [
              _row('رقم الحساب :', invoice.accountNo),
              _row('اسم المشترك :', invoice.customerName),
              _row('اسم الجابي :', collector),
              _row('رقم هاتف الجابي :', phone),
              _printDateRow(printedAt),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6B84A), width: 1.4),
          ),
          child: Column(
            children: [
             
              Text(
                'يرجى العلم بأنه تعذّرت قراءة مقياس الماء الخاص بالحساب أعلاه، وذلك بسبب: $reason.\n\nوعليه، يرجى المبادرة بمراجعة دائرة الماء أو التواصل مع الجابي على رقم الهاتف الموضّح أعلاه، وذلك لتجنّب انقطاع الخدمة.\n\nشاكرين لكم حسن تعاونكم.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, InvoiceInformationModel invoice) {
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
                'إغلاق',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.print, size: 22),
              label: const Text(
                'طباعة الإشعار',
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
              onPressed: isPrinting ? null : () => _print(invoice),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _print(InvoiceInformationModel invoice) async {
    if (isPrinting) return;
    setState(() => isPrinting = true);

    try {
      final account = await ref.read(accountProvider.future);
      final controller = ScreenshotController();
      final printWidget = ExecutionPrintLayout(
        accountNo: invoice.accountNo,
        customerName: invoice.customerName,
        reason: selectedFailureReason,

        collectorName: cleanCollectorName(invoice.collectorName),
        collectorPhone: account.phone,
        printedAt: printedAt,
      );

      final image = await controller.captureFromWidget(
        Material(
          color: Colors.white,
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: printWidget,
          ),
        ),
        pixelRatio: 1.0,
        targetSize: const Size(576, 2600),
      );

      final granted = await requestBluetoothPermissions();
      if (!granted) return;

      final mac = await PrinterStorage.getMac();
      if (mac == null) {
        throw Exception('الطابعة غير متصلة، يرجى الاتصال بالطابعة أولاً.');
      }

      await PrinterChannel.printImage(mac: mac, image: image);
      if (!mounted) return;
      AppPopupAlert.show(
        context,
        message: 'تمت طباعة إشعار التنفيذ بنجاح',
        isError: false,
      );
    } catch (error) {
      if (mounted) {
        AppPopupAlert.show(context, message: parseError(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => isPrinting = false);
    }
  }

  Widget _logo(String path) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }

  Widget _noticeCard({String? title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: Text(
                value.trim().isEmpty ? '-' : value,
                textDirection: value.contains("+964")
                    ? ui.TextDirection.ltr
                    : ui.TextDirection.rtl,
                textAlign: TextAlign.left,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _printDateRow(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تاريخ ووقت الطباعة :',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
