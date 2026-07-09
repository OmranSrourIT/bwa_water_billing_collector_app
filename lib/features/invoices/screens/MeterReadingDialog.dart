import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/reading_request_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/reading_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class ReadingDialog extends ConsumerStatefulWidget {
  final String invoiceNumber;
  final String batchId;

  const ReadingDialog({
    super.key,
    required this.invoiceNumber,
    required this.batchId,
  });

  @override
  ConsumerState<ReadingDialog> createState() => _ReadingDialogState();
}

class _ReadingDialogState extends ConsumerState<ReadingDialog> {
  final TextEditingController currentReadingController =
      TextEditingController();

  DateTime readingDate = DateTime.now();

  bool resetMeter = false;

  File? imageFile;

  String? base64Image = "";
  bool isLoading = false;
  final FocusNode currentReadingFocusNode = FocusNode();

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);

        final bytes = await File(file.path).readAsBytes();

        setState(() {
          imageFile = file;
          base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      final message = parseError(e);
      AppPopupAlert.show(context, message: message, isError: true);
    }
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: readingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        readingDate = selected;
      });
    }
  }

  Future<Position?> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> saveReading(InvoiceInformationModel invoice) async {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    // 🔥 1. قراءة إلزامية
    if (currentReadingController.text.trim().isEmpty) {
      AppPopupAlert.show(
        context,
        message: "يجب إدخال القراءة الحالية",
        isError: true,
      );
      return;
    }

    final text = currentReadingController.text.trim();

    final current = double.tryParse(text);

    if (current == null) {
      AppPopupAlert.show(
        context,
        message: "الرجاء إدخال قراءة صحيحة",
        isError: true,
      );
      return;
    }

    final previous = invoice.previousReading.toDouble();

    if (!resetMeter) {
      // القراءة العادية
      if (current < previous) {
        AppPopupAlert.show(
          context,
          message:
              "القراءة الحالية يجب أن تكون أكبر من أو تساوي القراءة السابقة",
          isError: true,
        );
        return;
      }
    } else {
      // إعادة تسلسل العداد
      if (current >= previous) {
        AppPopupAlert.show(
          context,
          message:
              "عند إعادة تسلسل العداد يجب أن تكون القراءة الحالية أقل من القراءة السابقة",
          isError: true,
        );
        return;
      }
    }

    // 🔥 2. صورة إلزامية
    if (imageFile == null || base64Image == null || base64Image!.isEmpty) {
      AppPopupAlert.show(
        context,
        message: "يجب التقاط صورة للقراءة",
        isError: true,
      );
      FocusScope.of(context).unfocus();
      return;
    }

    final position = await getLocation();

    if (position == null) {
      final message = "تعذر تحديد الموقع";
      AppPopupAlert.show(context, message: message, isError: true);

      return;
    }

    final request = ReadingRequest(
      invoiceNumber: widget.invoiceNumber,

      previousReading: invoice.previousReading.toDouble(),

      currentReading: current,

      currentReadDateTime: readingDate.toUtc().toIso8601String(),

      previousReadingDateTime:  invoice.previousReadingDateTime?.toUtc().toIso8601String() ?? "",

      isMeterRollover: resetMeter,

      latitude: position.latitude.toString(),

      longitude: position.longitude.toString(),

      base64: base64Image,
    );

    try {
      final response = await ref.read(insertReadingProvider(request).future);

      try {
        if (!response.isSuccess) {
          AppPopupAlert.show(
            context,
            message: response.arMessage,
            isError: true,
          );

          ref.invalidate(invoicesProvider(widget.batchId.toString()));

          ref.invalidate(
            invoiceDetailProvider(widget.invoiceNumber.toString()),
          );

          return;
        }

        // await ref.read(
        //   updateInvoiceStatusProvider((
        //     invoiceNo: widget.invoiceNumber,
        //     status: "RDY",
        //   )).future,
        // );

        AppPopupAlert.show(
          context,
          message: response.arMessage,
          isError: false,
          onOk: () {
            Navigator.pop(context, true);
          },
        );

        ref.invalidate(invoicesProvider(widget.batchId.toString()));

        ref.invalidate(invoiceDetailProvider(widget.invoiceNumber.toString()));
      } catch (e) {
        final errorMessage = "حدث خطأ أثناء تحديث حالة الفاتورة";

        if (context.mounted) {
          AppPopupAlert.show(context, message: errorMessage, isError: true);
        }

        debugPrint("updateInvoiceStatus error: $e");
      }
    } catch (e) {
      final message = parseError(e);
      AppPopupAlert.show(context, message: message, isError: true);
    }
  }

  String formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  String formatApiDate(DateTime? d) {
    if (d == null) return "-";

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  void dispose() {
    currentReadingController.dispose();
    currentReadingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceAsync = ref.watch(invoiceDetailProvider(widget.invoiceNumber));
    return invoiceAsync.when(
      loading: () => Dialog(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),

      error: (e, _) {
        final message = parseError(e);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppPopupAlert.show(context, message: message, isError: true);
        });

        return const Center(child: CircularProgressIndicator());
      },

      data: (invoice) {
        return Stack(
          children: [
            Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .92,
                  maxWidth: 750,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(.4)),
                      ),
                      child: Column(
                        children: [
                          // HEADER
                          Container(
                            height: 72,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xff2F318B), Color(0xff27A9E1)],
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
                                  "إدخال القراءة الحالية",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),

                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  _SectionCard(
                                    title: "معلومات القراءة السابقة",
                                    child: Column(
                                      children: [
                                        _InfoRow(
                                          label: "القراءة السابقة",
                                          value: invoice.previousReading
                                              .toString(),
                                        ),
                                        _InfoRow(
                                          label: "تاريخ القراءة السابقة",
                                          value: formatApiDate(
                                            invoice.previousReadingDateTime,
                                          ),
                                        ),
                                        // _InfoRow(
                                        //   label: "آخر جابي",
                                        //   value: "أحمد علي",
                                        // ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  _SectionCard(
                                    title: "إدخال القراءة الحالية",
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: pickDate,
                                          child: Container(
                                            height: 54,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_month,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(formatDate(readingDate)),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 14),

                                        TextField(
                                          controller: currentReadingController,
                                          focusNode: currentReadingFocusNode,

                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),

                                          textInputAction: TextInputAction.done,

                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d{0,2}$'),
                                            ),
                                          ],

                                          onSubmitted: (value) {
                                            currentReadingFocusNode.unfocus();
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },

                                          decoration: InputDecoration(
                                            labelText: "القراءة الحالية",
                                            prefixIcon: const Icon(Icons.speed),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  _SectionCard(
                                    title: "إعادة تسلسل العداد",
                                    child:
                                        CupertinoSlidingSegmentedControl<bool>(
                                          groupValue: resetMeter,
                                          children: const {
                                            true: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text("نعم"),
                                            ),
                                            false: Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text("لا"),
                                            ),
                                          },
                                          onValueChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                resetMeter = value;
                                              });
                                            }
                                          },
                                        ),
                                  ),

                                  const SizedBox(height: 16),

                                  _SectionCard(
                                    title: "صورة القراءة",
                                    child: Column(
                                      children: [
                                        Stack(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: imageFile == null
                                                    ? SizedBox(
                                                        height: 350,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .photo_camera_outlined,
                                                              size: 70,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              "لم يتم التقاط صورة",
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Image.file(
                                                        imageFile!,
                                                        fit: BoxFit.fitWidth,
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 12,
                                              left: 12,
                                              child: FloatingActionButton.small(
                                                heroTag: "camera_btn",
                                                backgroundColor: const Color(
                                                  0xff2F318B,
                                                ),
                                                foregroundColor: Colors.white,
                                                onPressed: pickImage,
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                ),
                                              ),
                                            ),

                                            if (imageFile != null)
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child:
                                                    FloatingActionButton.small(
                                                      heroTag:
                                                          "remove_image_btn",
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                      onPressed: () {
                                                        setState(() {
                                                          imageFile = null;
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close,
                                                      ),
                                                    ),
                                              ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),

                                        SizedBox(
                                          width: 220,
                                          height: 52,
                                          child: ElevatedButton.icon(
                                            onPressed: pickImage,
                                            icon: const Icon(Icons.camera_alt),
                                            label: const Text("التقاط صورة"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xff2F318B,
                                              ),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
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

                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("إلغاء"),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      SystemChannels.textInput.invokeMethod(
                                        'TextInput.hide',
                                      );

                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );

                                      if (!mounted) return;

                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await saveReading(invoice);

                                        ref.invalidate(
                                          invoiceDetailProvider(
                                            widget.invoiceNumber,
                                          ),
                                        );

                                        await ref.read(
                                          invoiceDetailProvider(
                                            widget.invoiceNumber,
                                          ).future,
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.save),
                                    label: const Text("حفظ القراءة"),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      backgroundColor: const Color(0xff0F9D58),
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

            if (isLoading)
              const Positioned.fill(child: BwaLoadingOverlay(isLoading: true)),
          ],
        );
      },
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xff2F318B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
