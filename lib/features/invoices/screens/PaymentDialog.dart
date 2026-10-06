import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/Serivces/minesec_service.dart';
import 'package:bwa_water_billing_collector_app/core/constants/api_constants.dart';

import 'package:bwa_water_billing_collector_app/features/Payment/model/pos_payment_models.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/providers/pos_payment_provider.dart';

import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart'
    show parseError;
import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/screen/payment_debug_screen.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/service/payment_debug_service.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/payment_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/providers/paymentProvider.dart';

import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum PaymentTestScenario {
  realPayment,
  success,
  insufficientBalance,
  expiredCard,
  cancelled,
  noResponse,
  deviceError,
}

class PaymentDialog extends ConsumerStatefulWidget {
  final String Invoicenumber;
  final String paymentReference;
  final double amount;
  final String batchId;
  final void Function(
    bool success,
    Map<String, dynamic> data,
    String invoiceStatus,
  )?
  onPaymentFinished;

  const PaymentDialog({
    super.key,
    required this.Invoicenumber,
    required this.paymentReference,
    required this.amount,
    required this.batchId,
    this.onPaymentFinished,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  bool isProcessing = false;
  Map<String, dynamic>? paymentResult;

  double? previousReading;
  double? currentReading;
  bool isLoadingInvoice = false;
  bool _paymentResultHandled = false;

  PaymentTestScenario _selectedTestScenario = PaymentTestScenario.realPayment;

  bool get _isTestEnvironment {
    return ApiConstants.environment == "TEST";
  }

  bool get _isGTAGEEnvironment {
    return ApiConstants.environment == "STAGE";
  }

  @override
  void initState() {
    super.initState();
    MineSecService.init(_onPaymentResult);
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() => isLoadingInvoice = true);

    try {
      final invoiceDetails = await ref.read(
        invoiceDetailProvider(widget.Invoicenumber).future,
      );

      if (!mounted) return;

      setState(() {
        previousReading = invoiceDetails.previousReading;
        currentReading = invoiceDetails.currentReading;
        isLoadingInvoice = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingInvoice = false);
    }
  }

  Future<void> _onPaymentResult(String status, dynamic data) async {
    // منع استقبال نفس callback أكثر من مرة
    if (_paymentResultHandled) {
      debugPrint('[PAYMENT] Duplicate payment result ignored');
      return;
    }

    _paymentResultHandled = true;

    final resultData = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{"raw": data?.toString() ?? ""};

    final normalizedStatus = status.toLowerCase();

    PaymentDebugService.addEvent(
      title: "Payment Response",
      description: resultData.toString(),
    );

    PaymentDebugService.finish(
      success: normalizedStatus == "success",
      response: resultData,
    );

    // =====================================================
    // أولًا: الدفع مرفوض أو فشل من جهاز POS
    // =====================================================
    if (normalizedStatus != "success") {
      await _releaseInvoiceSafely();

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      Navigator.of(context).pop();

      widget.onPaymentFinished?.call(false, resultData, "");

      return;
    }

    // =====================================================
    // ثانيًا: الدفع نجح من جهاز POS
    // =====================================================
    try {
      final paymentResponse = await ref.read(
        paymentProvider(
          PaymentRequest(
            invoiceNo: widget.Invoicenumber,
            tranId: resultData["tranId"]?.toString() ?? "",
            trace: resultData["trace"]?.toString() ?? "",
            rrn: resultData["rrn"]?.toString() ?? "",
            tranType: resultData["tranType"]?.toString() ?? "",
            tranStatus: resultData["tranStatus"]?.toString() ?? "",
            approvalCode: resultData["approvalCode"]?.toString() ?? "",
            paymentMethod: resultData["paymentMethod"]?.toString() ?? "",
            entryMode: resultData["entryMode"]?.toString() ?? "",
            maskedAccount: resultData["maskedAccount"]?.toString() ?? "",
            cvmPerformed: resultData["cvmPerformed"]?.toString() ?? "",
            acqMid: resultData["acqMid"]?.toString() ?? "",
            acqTid: resultData["acqTid"]?.toString() ?? "",
            posMessageId: resultData["posMessageId"]?.toString() ?? "",
            mchAddress: resultData["mchAddress"]?.toString() ?? "",
            mchName: resultData["mchName"]?.toString() ?? "",
            totalAmount:
                double.tryParse(resultData["totalAmount"]?.toString() ?? "") ??
                widget.amount,
            createByName: resultData["createByName"]?.toString() ?? "",
            createdAt:
                resultData["createdAt"]?.toString() ??
                paymentDate.toIso8601String(),
            updatedAt:
                resultData["updatedAt"]?.toString() ??
                paymentDate.toIso8601String(),
            amount: widget.amount,
            description: "Payment from POS",
          ),
        ).future,
      );

      if (!paymentResponse.isSuccess) {
        throw Exception(
          paymentResponse.arMessage.isNotEmpty
              ? paymentResponse.arMessage
              : "تعذر حفظ عملية الدفع",
        );
      }
 

      if (!mounted) {
        return;
      }

      // تحديث الحالة المحلية بدون انتظار
      ref.invalidate(invoiceDetailProvider(widget.Invoicenumber));

      ref.invalidate(invoicesProvider(widget.batchId));

      setState(() {
        isProcessing = false;
      });

      // حفظ callback قبل إغلاق النافذة
      final onPaymentFinished = widget.onPaymentFinished;

      // إغلاق نافذة تأكيد الدفع فوراً
      Navigator.of(context).pop();

      // فتح PaymentResultDialog مباشرة
      onPaymentFinished?.call(true, resultData, "COL");

      // عكس IsSentToPOS في الخلفية بدون تعطيل الواجهة
      _releaseInvoiceSafely();
    } catch (e, stack) {
      debugPrint("[PAYMENT SAVE ERROR] $e");
      debugPrint("$stack");

      // حصل نجاح من جهاز POS، لكن حفظ العملية لم يتأكد.
      // لذلك نسأل الـbackend عن الحالة قبل عرض النتيجة النهائية.
      final statusResponse = await _checkUnknownPayment();

      // حسب التدفق المطلوب، نعكس الحجز في جميع الحالات.
      await _releaseInvoiceSafely();

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      final bool isPaid = statusResponse?.isPaid == true;

      if (statusResponse == null) {
        AppPopupAlert.show(
          context,
          message: "تعذر الاتصال بخدمة التحقق من حالة الدفع.",
          isError: true,
        );

        _paymentResultHandled = false;
        return;
      }

      final message = statusResponse.arMessage;

      AppPopupAlert.show(context, message: message, isError: !isPaid);

      _paymentResultHandled = false;

      // السماح بإعادة المحاولة إذا لم نستطع تثبيت النتيجة.
      _paymentResultHandled = false;
    }
  }

  Future<void> _releaseInvoiceSafely() async {
    try {
      final response = await ref
          .read(posPaymentRepositoryProvider)
          .releaseInvoice(invoiceNo: widget.Invoicenumber);

      if (!response.isSuccess) {
        debugPrint(
          '[POS] Failed to release invoice. '
          'Status: ${response.statusCode}, '
          'Message: ${response.message}',
        );
      }
    } catch (e, stack) {
      // لا نغيّر نتيجة الدفع بسبب فشل عكس الفلاج.
      debugPrint('[POS] Release invoice exception: $e');
      debugPrint('$stack');
    }
  }

  Future<PaymentStatusCheckResponse?> _checkUnknownPayment() async {
    try {
      return await ref
          .read(posPaymentRepositoryProvider)
          .checkPayment(invoiceNo: widget.Invoicenumber);
    } catch (e, stack) {
      debugPrint('[PAYMENT] Check payment status exception: $e');
      debugPrint('$stack');

      return null;
    }
  }

  Map<String, dynamic> _buildTestPaymentData() {
    final now = DateTime.now().toIso8601String();

    return {
      "tranId": "TEST-TRAN-ID",
      "trace": "TEST-TRACE",
      "rrn": "TEST-RRN",
      "tranType": "SALE",
      "tranStatus": "APPROVED",
      "approvalCode": "TEST-APPROVAL",
      "paymentMethod": "CARD",
      "entryMode": "TEST",
      "maskedAccount": "**** **** **** 1111",
      "cvmPerformed": "TEST",
      "acqMid": "TEST-MID",
      "acqTid": "TEST-TID",
      "posMessageId": "TEST-MESSAGE-ID",
      "mchAddress": "TEST ADDRESS",
      "mchName": "BWA TEST POS",
      "totalAmount": widget.amount,
      "createByName": "TEST USER",
      "createdAt": now,
      "updatedAt": now,
    };
  }

  // Future<void> _runSelectedTestScenario() async {
  //   switch (_selectedTestScenario) {
  //     case PaymentTestScenario.success:
  //       await _onPaymentResult("success", _buildTestPaymentData());
  //       return;

  //     case PaymentTestScenario.insufficientBalance:
  //       await _onPaymentResult("insufficient_balance", {
  //         "responseCode": "51",
  //         "message": "Insufficient funds",
  //         "AR_message": "الرصيد غير كافٍ",
  //         "EN_message": "Insufficient balance",
  //       });
  //       return;

  //     case PaymentTestScenario.expiredCard:
  //       await _onPaymentResult("expired_card", {
  //         "responseCode": "54",
  //         "message": "Expired card",
  //         "AR_message": "البطاقة منتهية الصلاحية",
  //         "EN_message": "The card has expired",
  //       });
  //       return;

  //     case PaymentTestScenario.cancelled:
  //       await _onPaymentResult("cancelled", {
  //         "responseCode": "CANCELLED",
  //         "message": "Payment cancelled by user",
  //         "AR_message": "تم إلغاء عملية الدفع",
  //         "EN_message": "Payment was cancelled",
  //       });
  //       return;

  //     case PaymentTestScenario.deviceError:
  //       await _onPaymentResult("device_error", {
  //         "responseCode": "DEVICE_ERROR",
  //         "message": "POS device error",
  //         "AR_message": "حدث خطأ في جهاز الدفع",
  //         "EN_message": "Payment device error",
  //       });
  //       return;

  //     case PaymentTestScenario.noResponse:
  //       await _runNoResponseTest();
  //       return;

  //     case PaymentTestScenario.realPayment:
  //       // هذا الخيار لا يدخل هنا؛ لأنه يعالج في _startReservedPayment.
  //       return;
  //   }
  // }

  // Future<void> _runNoResponseTest() async {
  //   PaymentDebugService.addEvent(
  //     title: "TEST: No payment response",
  //     description: "Simulating network interruption / missing POS response",
  //   );

  //   final statusResponse = await _checkUnknownPayment();

  //   await _releaseInvoiceSafely();

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     isProcessing = false;
  //   });

  //   if (statusResponse == null) {
  //     AppPopupAlert.show(
  //       context,
  //       message: "تعذر الاتصال بخدمة التحقق من حالة الدفع.",
  //       isError: true,
  //     );

  //     _paymentResultHandled = false;
  //     return;
  //   }

  //   final isPaid = statusResponse.isPaid;

  //   final message = statusResponse.arMessage;

  //   AppPopupAlert.show(context, message: message, isError: !isPaid);

  //   _paymentResultHandled = false;
  // }

  Future<void> _startReservedPayment() async {
    if (isProcessing || _paymentResultHandled) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isProcessing = true;
      _paymentResultHandled = false;
    });

    bool reservedByCurrentAttempt = false;

    try {
      // =====================================================
      // 1. فحص حالة الفاتورة قبل إنشاء حجز جديد
      // =====================================================
      final invoiceDetails = await ref.refresh(
        invoiceDetailProvider(widget.Invoicenumber).future,
      );

      final isAlreadySentToPos = invoiceDetails.payment?.isSentToPos == true;

      PaymentDebugService.addEvent(
        title: 'Checking existing POS payment state',
        description: 'IsSentToPOS: $isAlreadySentToPos',
      );

      // =====================================================
      // 2. توجد عملية دفع سابقة قيد المعالجة
      // =====================================================
      if (isAlreadySentToPos) {
        final statusResponse = await _checkUnknownPayment();

        if (statusResponse == null) {
          if (!mounted) return;

          setState(() {
            isProcessing = false;
          });

          // لا يوجد API response حتى نعرض رسالته
          AppPopupAlert.show(
            context,
            message: parseError(
              Exception('CheckPaymentStatus returned no response'),
            ),
            isError: true,
          );

          return;
        }

        final apiMessage = statusResponse.arMessage.trim().isNotEmpty
            ? statusResponse.arMessage.trim()
            : statusResponse.enMessage.trim();

        PaymentDebugService.addEvent(
          title: 'Previous POS payment status',
          description:
              'IsPaid: ${statusResponse.isPaid}, '
              'IsVerified: ${statusResponse.isVerified}, '
              'Message: $apiMessage',
        );

        // =====================================================
        // 3. العملية السابقة ناجحة
        // =====================================================
        if (statusResponse.isVerified && statusResponse.isPaid) {
          if (!mounted) return;

          setState(() {
            isProcessing = false;
          });

          ref.invalidate(invoiceDetailProvider(widget.Invoicenumber));

          ref.invalidate(invoicesProvider(widget.batchId));

          AppPopupAlert.show(context, message: apiMessage, isError: false);

          return;
        }

        // =====================================================
        // 4. العملية السابقة مرفوضة
        // =====================================================
        if (statusResponse.isVerified && !statusResponse.isPaid) {
          PaymentDebugService.addEvent(
            title: 'Previous POS payment rejected',
            description: apiMessage,
          );

          if (!mounted) return;

          setState(() {
            isProcessing = false;
          });

          AppPopupAlert.show(context, message: apiMessage, isError: true);

          return;
        }
      }

      // =====================================================
      // 5. لا توجد عملية سابقة فعالة، ننشئ حجزاً جديداً
      // =====================================================
      final referenceId = 'BWA-${DateTime.now().millisecondsSinceEpoch}';

      final reserveResponse = await ref
          .read(posPaymentRepositoryProvider)
          .reserveInvoice(
            invoiceNo: widget.Invoicenumber,
            posReference: referenceId,
          );

      if (!reserveResponse.isSuccess || reserveResponse.isSentToPos != true) {
        throw Exception(reserveResponse.message.trim());
      }

      reservedByCurrentAttempt = true;

      PaymentDebugService.addEvent(
        title: 'POS invoice reserved',
        description:
            'Invoice: ${widget.Invoicenumber}, '
            'Reference: $referenceId',
      );

      // if ((_isTestEnvironment || _isGTAGEEnvironment) &&
      //     _selectedTestScenario != PaymentTestScenario.realPayment) {
      //   await _runSelectedTestScenario();
      //   return;
      // }

      PaymentDebugService.start(
        request: {
          'invoiceNumber': widget.Invoicenumber,
          'paymentReference': widget.paymentReference,
          'posReference': referenceId,
          'amount': widget.amount,
          'amountSent': widget.amount * 10,
          'batchId': widget.batchId,
          'paymentDate': paymentDate.toIso8601String(),
        },
      );

      await MineSecService.startPayment(
        amount: widget.amount * 10,
        referenceId: referenceId,
      );
    } catch (e, stack) {
      debugPrint('[PAYMENT START ERROR] $e');
      debugPrint('[PAYMENT START STACK] $stack');

      // لا تحرر إلا الحجز الذي أنشأته هذه المحاولة
      if (reservedByCurrentAttempt) {
        await _releaseInvoiceSafely();
      }

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      AppPopupAlert.show(context, message: parseError(e), isError: true);
    }
  }

  DateTime paymentDate = DateTime.now();

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // Widget _buildTestScenarioSelector() {
  //   if (!_isTestEnvironment || !_isGTAGEEnvironment) {
  //     return const SizedBox.shrink();
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         "وضع الاختبار - TEST فقط",
  //         style: TextStyle(
  //           color: Colors.red,
  //           fontSize: 15,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),

  //       const SizedBox(height: 8),

  //       DropdownButtonFormField<PaymentTestScenario>(
  //         value: _selectedTestScenario,
  //         decoration: InputDecoration(
  //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //           prefixIcon: const Icon(Icons.science_outlined),
  //         ),
  //         items: const [
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.realPayment,
  //             child: Text("الدفع الحقيقي"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.success,
  //             child: Text("نجاح الدفع"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.insufficientBalance,
  //             child: Text("لا يوجد رصيد كافٍ"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.expiredCard,
  //             child: Text("البطاقة منتهية"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.cancelled,
  //             child: Text("إلغاء العملية"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.noResponse,
  //             child: Text("انقطاع / لا يوجد Response"),
  //           ),
  //           DropdownMenuItem(
  //             value: PaymentTestScenario.deviceError,
  //             child: Text("خطأ من جهاز الدفع"),
  //           ),
  //         ],
  //         onChanged: isProcessing
  //             ? null
  //             : (value) {
  //                 if (value == null) return;

  //                 setState(() {
  //                   _selectedTestScenario = value;
  //                 });
  //               },
  //       ),

  //       const SizedBox(height: 12),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(Icons.bug_report, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PaymentDebugScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                        const Text(
                          "دفع الفاتورة",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= BODY (FIXED LAYOUT) =================
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          isLoadingInvoice
                              ? const Center(child: CircularProgressIndicator())
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _InfoCard(
                                        title: "رقم الدفع المرجعي",
                                        value: widget.paymentReference,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoCard(
                                        title: "تاريخ الدفع",
                                        value: formatDate(paymentDate),
                                      ),
                                    ),
                                  ],
                                ),

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade700,
                                  Colors.green.shade500,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "المبلغ المطلوب دفعه",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  NumberFormat(
                                    '#,##0.000',
                                  ).format(widget.amount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    " يرجى التاكد من مبلغ الفاتورة قبل تأكيد عملية الدفع",
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // _buildTestScenarioSelector(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ================= FOOTER =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("إلغاء"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : _startReservedPayment,

                            icon: const Icon(Icons.payments),
                            label: const Text("تأكيد الدفع"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0F9D58),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
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
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
