import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/Serivces/minesec_service.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/ConnectionBanner.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/PaymentResultDialog.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart'
    show parseError;
import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/screen/payment_debug_screen.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/service/payment_debug_service.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/model/payment_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/providers/paymentProvider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/reading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final String Invoicenumber;
  final String paymentReference;
  final double amount;
  final String batchId;

  const PaymentDialog({
    super.key,
    required this.Invoicenumber,
    required this.paymentReference,
    required this.amount,
    required this.batchId,
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

  void _onPaymentResult(String status, dynamic data) async {
    PaymentDebugService.addEvent(
      title: "Payment Reponse ",
      description: data.toString(),
    );

    if (!mounted) return;

    setState(() {
      isProcessing = false;
      paymentResult = data;
    });

    if (status == "success") {
      try {
        final response = await ref.read(
          paymentProvider(
            PaymentRequest(
              invoiceNo: widget.Invoicenumber,
              tranId: data["tranId"],
              trace: data["trace"],
              rrn: data["rrn"],
              tranType: data["tranType"],
              tranStatus: data["tranStatus"],
              approvalCode: data["approvalCode"],
              paymentMethod: data["paymentMethod"],
              entryMode: data["entryMode"],
              maskedAccount: data["maskedAccount"],
              cvmPerformed: data["cvmPerformed"],
              acqMid: data["acqMid"],
              acqTid: data["acqTid"],
              posMessageId: data["posMessageId"],
              mchAddress: data["mchAddress"],
              mchName: data["mchName"],
              totalAmount: double.parse(data["totalAmount"].toString()),
              createByName: data["createByName"],
              createdAt: data["createdAt"],
              updatedAt: data["updatedAt"],
              amount: widget.amount,
              description: "Payment from POS",
            ),
          ).future,
        );

        if (!mounted) return;

         await ref.read(
          updateInvoiceStatusProvider((
            invoiceNo: widget.Invoicenumber,
            status: "COL",
          )).future,
        );

        


        AppPopupAlert.show(
          context,
          message: "تم إرسال بيانات الدفع بنجاح",
          isError: false,
        );

        
        ref.invalidate(invoicesProvider(widget.batchId.toString()));

        ref.invalidate(invoiceDetailProvider(widget.Invoicenumber.toString()));

      } catch (e) {
        final message = parseError(e);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppPopupAlert.show(context, message: message, isError: true);
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PaymentDebugService.finish(
        success: status == "success",
        response: Map<String, dynamic>.from(data),
      );

      showDialog(
        context: context,
        builder: (_) => PaymentResultDialog(
          success: status == "success",
          data: data,
          Invoicenumber: widget.Invoicenumber,
        ),
      );
    });
  }

  DateTime paymentDate = DateTime.now();

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

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
                        const Text(
                          "دفع الفاتورة",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 25),
                        IconButton(
                          icon: const Icon(Icons.bug_report),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaymentDebugScreen(),
                              ),
                            );
                          },
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
                                        title: "تاريخ وزمن الدفع",
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

                          isLoadingInvoice
                              ? const Center(child: CircularProgressIndicator())
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _InfoCard(
                                        title: "القراءة السابقة",
                                        value: (previousReading ?? 0)
                                            .toStringAsFixed(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoCard(
                                        title: "القراءة الحالية",
                                        value: (currentReading ?? 0)
                                            .toStringAsFixed(2),
                                      ),
                                    ),
                                  ],
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
                                    "يرجى التأكد من بيانات الدفع قبل تأكيد العملية",
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                            onPressed: () async {
                              final isOnline = ref.read(connectionProvider);

                              if (!isOnline) {
                                ConnectionStatusDialog.show(
                                  context: context,
                                  isOnline: false,
                                );
                                return;
                              }

                              setState(() => isProcessing = true);

                              PaymentDebugService.addEvent(
                                title: "========== PAYMENT REQUEST ==========",
                                description: "",
                              );

                              PaymentDebugService.addEvent(
                                title: "Invoice",
                                description: "${widget.Invoicenumber}",
                              );

                              PaymentDebugService.addEvent(
                                title: "Reference",
                                description: "${widget.paymentReference}",
                              );

                              PaymentDebugService.addEvent(
                                title: "Amount",
                                description: "${widget.amount}",
                              );

                              PaymentDebugService.addEvent(
                                title: "Amount Sent ",
                                description: "${widget.amount * 10}",
                              );

                              PaymentDebugService.addEvent(
                                title: "Batch",
                                description: "${widget.batchId}",
                              );

                              PaymentDebugService.start(
                                request: {
                                  "invoiceNumber": widget.Invoicenumber,
                                  "paymentReference": widget.paymentReference,
                                  "amount": widget.amount,
                                  "amountSent": widget.amount * 10,
                                  "batchId": widget.batchId,
                                  "paymentDate": paymentDate.toIso8601String(),
                                },
                              );

                              PaymentDebugService.addEvent(
                                title: "Sending request to TPay",
                              );

                              final referenceId =
                                  "${widget.paymentReference}_${DateTime.now().millisecondsSinceEpoch}";

                              await MineSecService.startPayment(
                                amount: widget.amount * 10,
                                referenceId: referenceId,
                              );
                            },
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
