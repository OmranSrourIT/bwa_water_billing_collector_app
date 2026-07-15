import 'package:bwa_water_billing_collector_app/core/constants/AppColors.dart';
import 'package:bwa_water_billing_collector_app/core/lang/app_localizations.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_sync_provider.dart';
import 'package:bwa_water_billing_collector_app/core/storage/PrinterStorage.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/ConnectionBanner.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/responsive.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/InitialSyncLoadingScreen.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/appErrorState.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/showEndBatchConfirmDialog.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/Account/screen/AccountDetailsDialog.dart';
import 'package:bwa_water_billing_collector_app/features/Account/screen/ChangePasswordDialog.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/printer_channel.dart';
import 'package:bwa_water_billing_collector_app/features/Printer%20VAN_GOLD/printer_service.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/batch_model.dart';
import 'package:bwa_water_billing_collector_app/features/batch/providers/batch_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/InvoiceSummary.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoiceDetails_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/MeterReadingDialog.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/PaymentDialog.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/PaymentNoticeDialog.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/Printinvoice_dialog.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/UnreachableDialog.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/screens/invoice_details_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? selectedInvoiceNo;
  BatchModel? selectedBatch;
  String? selectedCollectionType;
  String? selectedInvoiceStatus;
  String? searchAccountValue;
  bool isEndBatchLoading = false;
  bool isInitialBatchSelectionDone = false;

  @override
  void initState() {
    super.initState();

    initPrinter();
  }

  Future<void> initPrinter() async {
    final granted = await requestBluetoothPermissions();
    if (!granted) return;

    final printers = await PrinterChannel.getPairedPrinters();
    if (!mounted) return;

    if (printers.isEmpty) return;

    final savedMac = await PrinterStorage.getMac();

    if (savedMac != null) {
      final exists = printers.any((p) => p["mac"] == savedMac);

      if (exists) {
        return;
      }
    }
    await PrinterStorage.saveMac(printers.first["mac"]);
  }

  void _endBatch(BatchModel batch) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() => isEndBatchLoading = true);

    try {
      final response = await ref.read(
        endBatchProvider(batch.batchNumber).future,
      );

      AppPopupAlert.show(
        context,
        message: isArabic ? response.arMessage : response.enMessage,
        isError: !response.isSuccess,
      );

      if (response.isSuccess) {
        ref.invalidate(batchProvider);
        setState(() {
          selectedBatch = null;
          selectedCollectionType = null;
          selectedInvoiceNo = null;
          selectedInvoiceStatus = null;
          searchAccountValue = null;
        });
      }
    } catch (e) {
      final message = parseError(e);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppPopupAlert.show(context, message: message, isError: true);
      });
    } finally {
      if (mounted) setState(() => isEndBatchLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(initialSyncStateProvider);
    final batchAsync = ref.watch(batchProvider);
    final isTablet = Responsive.isTablet(context);
  

    if (syncState.loading) {
      return InitialSyncLoadingScreen(message: syncState.message);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      if (selectedBatch != null) {
                        ref.refresh(
                          invoicesProvider(selectedBatch!.batchNumber),
                        );

                        ref.refresh(
                          invoiceDetailProvider(selectedInvoiceNo!).future,
                        );
                      } else {
                        ref.refresh(batchProvider);
                      }
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isTablet ? 12 : 20),
                      child: Column(
                        children: [
                          /// ================= INVOICES LIST =================
                          batchAsync.when(
                            data: (batches) {
                              if (batches.isEmpty) {
                                return const SizedBox();
                              }

                              if (!isInitialBatchSelectionDone &&
                                  batches.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;

                                  setState(() {
                                    selectedBatch = batches.last;
                                    isInitialBatchSelectionDone = true;
                                  });
                                });
                              }

                              final activeBatch = selectedBatch;
                              if (activeBatch == null) {
                                return Column(
                                  children: [
                                    ActiveBatchBar(
                                      batchesDrop: batches,
                                      selectedBatch: selectedBatch,
                                      onBatchSelected: (batch) {
                                        setState(() {
                                          selectedBatch = batch;

                                          selectedCollectionType = null;
                                          selectedInvoiceNo = null;
                                          selectedInvoiceStatus = null;
                                          searchAccountValue = null;
                                        });
                                      },
                                      onResetFilters: () {
                                        setState(() {
                                          selectedCollectionType = null;
                                          selectedInvoiceNo = null;
                                          selectedInvoiceStatus = null;
                                          searchAccountValue = null;
                                        });
                                      },
                                      onStartEndBatchLoading: () {
                                        final batch = selectedBatch;
                                        if (batch == null) return;

                                        _endBatch(batch);
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    MessageSelectedBacth(),
                                  ],
                                );
                              }

                              /// ================= SAFE INVOICES CALL =================
                              final invoicesAsync = ref.watch(
                                invoicesProvider(activeBatch.batchNumber),
                              );
                              return invoicesAsync.when(
                                data: (invoices) {
                                  final invoicesRaw = invoices
                                      .cast<InvoiceModel>();

                                  final summary = calculateSummary(invoicesRaw);

                                  final collectionTypes = invoicesRaw
                                      .expand<LookupModelParent>(
                                        (inv) => inv.lookup,
                                      )
                                      .where(
                                        (l) => l.lookupType == "CollectionType",
                                      )
                                      .fold<List<LookupModelParent>>([], (
                                        list,
                                        item,
                                      ) {
                                        if (!list.any(
                                          (e) => e.code == item.code,
                                        )) {
                                          list.add(item);
                                        }
                                        return list;
                                      });

                                  final invoiceStatuses = invoicesRaw
                                      .expand<LookupModelParent>(
                                        (inv) => inv.lookup,
                                      )
                                      .where(
                                        (l) => l.lookupType == "InvoiceStatus",
                                      )
                                      .fold<List<LookupModelParent>>([], (
                                        list,
                                        item,
                                      ) {
                                        if (!list.any(
                                          (e) => e.code == item.code,
                                        )) {
                                          list.add(item);
                                        }
                                        return list;
                                      });

                                  final filteredInvoices = invoicesRaw.where((
                                    inv,
                                  ) {
                                    final collectionMatch =
                                        selectedCollectionType == null ||
                                        inv.lookup.any(
                                          (l) =>
                                              l.lookupType ==
                                                  "CollectionType" &&
                                              l.code == selectedCollectionType,
                                        );

                                    final statusMatch =
                                        selectedInvoiceStatus == null ||
                                        inv.lookup.any(
                                          (l) =>
                                              l.lookupType == "InvoiceStatus" &&
                                              l.code == selectedInvoiceStatus,
                                        );

                                    final searchByAccountMatch =
                                        searchAccountValue == null ||
                                        searchAccountValue!.isEmpty ||
                                        inv.invoiceNo.toLowerCase().contains(
                                          searchAccountValue!.toLowerCase(),
                                        );

                                    return collectionMatch &&
                                        statusMatch &&
                                        searchByAccountMatch;
                                  }).toList();
                                  return Column(
                                    children: [
                                      ActiveBatchBar(
                                        batchesDrop: batches,
                                        selectedBatch: selectedBatch,
                                        onBatchSelected: (batch) {
                                          setState(() {
                                            selectedBatch = batch;
                                            selectedCollectionType = null;
                                            selectedInvoiceNo = null;
                                            selectedInvoiceStatus = null;
                                          });
                                        },
                                        onResetFilters: () {
                                          setState(() {
                                            selectedCollectionType = null;
                                            selectedInvoiceNo = null;
                                            selectedInvoiceStatus = null;
                                            searchAccountValue = null;
                                          });
                                        },
                                        onStartEndBatchLoading: () {
                                          final batch = selectedBatch;
                                          if (batch == null) return;

                                          _endBatch(batch);
                                        },
                                      ),

                                      SizedBox(height: isTablet ? 8 : 16),

                                      _BatchSummary(
                                        summary: summary,
                                        batch: activeBatch,
                                        invoicesCount: invoicesRaw.length,
                                      ),

                                      SizedBox(height: isTablet ? 8 : 16),

                                      _SearchSection(
                                        collectionTypes: collectionTypes,
                                        selectedCollectionType:
                                            selectedCollectionType,

                                        invoiceStatuses: invoiceStatuses,
                                        selectedInvoiceStatus:
                                            selectedInvoiceStatus,

                                        onSearchChanged: (value) {
                                          setState(() {
                                            searchAccountValue = value;
                                          });
                                        },

                                        onCollectionChanged: (value) {
                                          setState(() {
                                            selectedCollectionType =
                                                value?.code;
                                          });
                                        },

                                        onStatusChanged: (value) {
                                          setState(() {
                                            selectedInvoiceStatus = value?.code;
                                          });
                                        },
                                      ),

                                      SizedBox(height: isTablet ? 5 : 15),

                                      ...filteredInvoices.map((invoice) {
                                        final id = invoice.invoiceNo;

                                        return _InvoiceCard(
                                          invoice,
                                          isSelected: selectedInvoiceNo == id,
                                          batchId: selectedBatch!.batchNumber,
                                          onSelect: () {
                                            setState(() {
                                              selectedInvoiceNo = id;
                                            });
                                          },
                                        );
                                      }),
                                    ],
                                  );
                                },
                                loading: () => CircularProgressIndicator(),
                                error: (error, stack) {
                                  final message = parseError(error);

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    AppPopupAlert.show(
                                      context,
                                      message: message,
                                      isError: true,
                                    );
                                  });

                                  return const SizedBox();
                                },
                              );
                            },
                            loading: () => CircularProgressIndicator(),
                            error: (error, stack) {
                              return AppErrorState(
                                message: parseError(error).replaceAll("Exception:", ""),
                                onRetry: () {
                                  ref.invalidate(batchProvider);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (batchAsync.isLoading ||
                (selectedBatch != null &&
                    ref
                        .watch(invoicesProvider(selectedBatch!.batchNumber))
                        .isLoading))
              const BwaLoadingOverlay(isLoading: true),

            if (isEndBatchLoading) const BwaLoadingOverlay(isLoading: true),
          ],
        ),
      ),
    );
  }
}

class MessageSelectedBacth extends StatelessWidget {
  const MessageSelectedBacth({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined, size: 60, color: Colors.blue.shade400),

            const SizedBox(height: 12),

            const Text(
              "الرحاء إختيار السجل من القائمة أعلاه",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "يرجى اختيار السجل من القائمة المنسدلة لتحميل الفواتير",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff2DAAE2), Color(0xff38B6FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "ابدأ باختيار  السجل",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = Responsive.isTablet(context);
    final tr = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isOnlineMODE = ref.watch(connectionProvider);
    final accountAsync = ref.watch(accountProvider);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.primaryDark,
      child: Row(
        textDirection: isArabic ? ui.TextDirection.ltr : ui.TextDirection.rtl,
        children: [
          /// USER SECTION
          Expanded(
            flex: 6,
            child: Align(
              alignment: isArabic
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: PopupMenuButton<String>(
                offset: const Offset(0, 50),
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      showDialog(
                        context: context,
                        builder: (_) => const AccountDetailsDialog(),
                      );
                      break;

                    case 'changePassword':
                      showDialog(
                        context: context,
                        builder: (_) => ChangePasswordDialog(),
                      );
                      break;

                    case 'logout':
                      await ref
                          .read(authProvider.notifier)
                          .logout(); // 👈 مهم جداً

                      break;
                  }
                },

                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline),
                        const SizedBox(width: 10),
                        Text(tr.t('account_info')),
                      ],
                    ),
                  ),

                  PopupMenuItem(
                    value: 'changePassword',
                    child: Row(
                      children: [
                        const Icon(Icons.lock_reset),
                        const SizedBox(width: 10),
                        Text(tr.t('change_password')),
                      ],
                    ),
                  ),

                  const PopupMenuDivider(),

                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 10),
                        Text(tr.t('logout')),
                      ],
                    ),
                  ),
                ],

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: isArabic
                      ? ui.TextDirection.ltr
                      : ui.TextDirection.rtl,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),

                    const SizedBox(width: 8),
                    accountAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) {
                        final message = parseError(error);

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          AppPopupAlert.show(
                            context,
                            message: message,
                            isError: true,
                          );
                        });

                        return const SizedBox();
                      },
                      data: (account) {
                        final NameArabic =
                            account.firstNameAr +
                            " " +
                            account.fatherNameAr +
                            " " +
                            account.grandfatherNameAr +
                            " " +
                            account.familyNameAr;
                        final NameEnglish =
                            account.firstNameEn +
                            " " +
                            account.fatherNameEn +
                            " " +
                            account.grandfatherNameEn +
                            " " +
                            account.familyNameEn;
                        return Flexible(
                          child: Text(
                            isArabic ? NameArabic : NameEnglish,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          /// CLOUD INDICATOR
          Expanded(
            child: CloudIndicator(isTablet: isTablet, isOnline: isOnlineMODE),
          ),

          /// TITLE + LOGO
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/BWA_Logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 10),

                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: isArabic
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        tr.t('home_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        textDirection: ui.TextDirection.rtl,
                        tr.t('home_subtitle'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 15 : 12,
                        ),
                      ),
                    ],
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

class _BatchSummary extends StatelessWidget {
  final InvoiceSummary summary;
  final BatchModel batch;
  final int invoicesCount;

  const _BatchSummary({
    required this.summary,
    required this.batch,
    required this.invoicesCount,
  });
  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: tr.t('collected_amount'),
                value: NumberFormat(
                  '#,##0.000',
                ).format(summary.collectedAmount),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _SummaryCard(
                title: tr.t('completed'),
                value: summary.completed.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: _SummaryCard(
                title: tr.t('remaining'),
                value: summary.remaining.toString(),
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: _SummaryCard(
                title: tr.t('pending'),
                value: summary.pending.toString(),
                icon: Icons.report_problem_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        logs(context, batch, invoicesCount),
      ],
    );
  }

  Container logs(BuildContext context, BatchModel batch, int invoicesCount) {
    final tr = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xff2DAAE2), Color(0xff38B6FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// date
          Expanded(
            flex: 3,
            child: _BatchInfoItem(
              title: tr.t('assigned_date'),
              value: DateFormat('yyyy-MM-dd').format(batch.assignedDate),
            ),
          ),

          Container(width: 1, height: 40, color: Colors.white24),

          /// invoices
          Expanded(
            flex: 2,
            child: _BatchInfoItem(
              title: tr.t('total_invoices'),
              value: invoicesCount.toString(),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),

          const SizedBox(width: 10),

          /// due date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr.t('due_date'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('yyyy-MM-dd').format(batch.collectionDueDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Container(
      height: isTablet ? 72 : 68,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.02), blurRadius: 4),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 2),
          Icon(icon, color: color, size: isTablet ? 25 : 18),

          const SizedBox(height: 6),

          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 13,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15, // 🔥 ثابت أصغر
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatefulWidget {
  final List<LookupModelParent> collectionTypes;
  final String? selectedCollectionType;
  final Function(LookupModelParent?) onCollectionChanged;

  final List<LookupModelParent> invoiceStatuses;
  final String? selectedInvoiceStatus;
  final Function(LookupModelParent?) onStatusChanged;

  final String? searchAccountValue;
  final Function(String) onSearchChanged;

  const _SearchSection({
    super.key,
    required this.collectionTypes,
    required this.selectedCollectionType,
    required this.onCollectionChanged,

    required this.invoiceStatuses,
    required this.selectedInvoiceStatus,
    required this.onStatusChanged,
    this.searchAccountValue,
    required this.onSearchChanged,
  });

  @override
  State<_SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<_SearchSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isTablet = Responsive.isTablet(context);

    return Column(
      children: [
        /// ================= SEARCH =================
        Container(
          height: isTablet ? 48 : 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isTablet ? 15 : 14),
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: tr.t('search_invoice'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: isTablet ? 15 : 13,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 20,
                  vertical: 12,
                ),
                suffixIcon: Icon(
                  Icons.search_rounded,
                  size: isTablet ? 20 : 22,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        /// ================= FILTERS =================
        Row(
          children: [
            Expanded(
              child: _FilterDropdownsubscriptionType(
                title: tr.t('search_by_status'),
                items: widget.invoiceStatuses,
                selected: widget.selectedInvoiceStatus,
                onChanged: widget.onStatusChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FilterDropdownsubscriptionType(
                title: tr.t('subscription_type'),
                items: widget.collectionTypes,
                selected: widget.selectedCollectionType,
                onChanged: widget.onCollectionChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterDropdownsubscriptionType extends StatefulWidget {
  final String title;
  final List<LookupModelParent> items;
  final String? selected;
  final Function(LookupModelParent?) onChanged;

  const _FilterDropdownsubscriptionType({
    required this.title,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_FilterDropdownsubscriptionType> createState() =>
      _FilterDropdownsubscriptionTypeState();
}

class _FilterDropdownsubscriptionTypeState
    extends State<_FilterDropdownsubscriptionType> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showDropdown() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _hideDropdown,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 6),
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: IntrinsicWidth(
                    child: Material(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // يرجى الاختيار
                          InkWell(
                            onTap: () {
                              widget.onChanged(null);
                              _hideDropdown();
                            },
                            child: Container(
                              width: 280,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                isArabic ? "يرجى الاختيار" : "Please Select",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          Divider(height: 1, color: Colors.grey.shade200),

                          ...widget.items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    widget.onChanged(item);
                                    _hideDropdown();
                                  },
                                  child: Container(
                                    width: 280,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      isArabic ? item.arDesc : item.enDesc,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (index != widget.items.length - 1)
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                              ],
                            );
                          }),
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: () {
          if (_overlayEntry == null) {
            _showDropdown();
          } else {
            _hideDropdown();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.keyboard_arrow_down),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (_) {
                    final selectedItem =
                        widget.items
                            .where((e) => e.code == widget.selected)
                            .isNotEmpty
                        ? widget.items.firstWhere(
                            (e) => e.code == widget.selected,
                          )
                        : null;

                    final isArabic =
                        Localizations.localeOf(context).languageCode == 'ar';
                    return Text(
                      selectedItem == null
                          ? widget.title
                          : (isArabic
                                ? selectedItem.arDesc
                                : selectedItem.enDesc),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends ConsumerStatefulWidget {
  final InvoiceModel invoice;
  final bool isSelected;
  final String batchId;
  final VoidCallback? onSelect;

  const _InvoiceCard(
    this.invoice, {
    this.isSelected = false,
    this.batchId = "",
    this.onSelect,
  });

  @override
  ConsumerState<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends ConsumerState<_InvoiceCard> {
  bool _pressed = false;
  bool _loadingPayment = false;
 

  String getInvoiceStatus(InvoiceModel invoice, BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final status = invoice.lookup.firstWhere(
      (e) => e.lookupType == "InvoiceStatus",
      orElse: () => invoice.lookup.first,
    );

    return isArabic ? status.arDesc : status.enDesc;
  }

  String getInvoiceStatusForPrint(
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

  Color getInvoiceStatusColor(InvoiceModel invoice, BuildContext context) {
    final status = invoice.lookup.firstWhere(
      (e) => e.lookupType == "InvoicSetatus",
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

  String getInvoiceStatusCode(InvoiceModel invoice, BuildContext context) {
    final status = invoice.lookup.firstWhere(
      (e) => e.lookupType == "InvoiceStatus",
      orElse: () => invoice.lookup.first,
    );

    return status.code;
  }

  String getLookupValue(
    InvoiceModel invoice,
    String lookupType,
    BuildContext context,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final item = invoice.lookup.firstWhere(
      (e) => e.lookupType == lookupType,
      orElse: () => LookupModelParent.empty(),
    );

    return isArabic ? item.arDesc : item.enDesc;
  }

  Color getStatusColor(InvoiceModel invoice) {
    final status = invoice.lookup.firstWhere(
      (e) => e.lookupType == "InvoiceStatus",
      orElse: () => invoice.lookup.first,
    );

    switch (status.code) {
      case "RDY":
        return Colors.orange;
      case "ISS":
        return Colors.blue;
      case "COL":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getInvoiceStatusIcon(InvoiceModel invoice) {
    final status = invoice.lookup.firstWhere(
      (e) => e.lookupType == "InvoiceStatus",
      orElse: () => invoice.lookup.first,
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

  void _setPressed(bool value) {
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final tr = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
     final isOnline = ref.watch(connectionProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onSelect?.call();
      },
      onTapCancel: () => _setPressed(false),

      child: Stack(
        children: [
          /// ================= SELECTED GLOW =================
          if (widget.isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff0D47A1).withOpacity(0.08),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          /// ================= CARD =================
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,

            margin: const EdgeInsets.only(bottom: 6),

            transform: Matrix4.identity()
              ..translate(0.0, widget.isSelected ? -2 : (_pressed ? -4 : 0))
              ..scale(widget.isSelected ? 1.01 : (_pressed ? 0.99 : 1.0)),

            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.primary.withOpacity(0.03)
                  : Colors.white,

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),

              /// ⭐ ONLY SHADOW (clean)
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(_pressed ? 0.10 : 0.05),
                  blurRadius: widget.isSelected ? 25 : (_pressed ? 18 : 10),
                  spreadRadius: 0,
                  offset: Offset(
                    0,
                    widget.isSelected ? 10 : (_pressed ? 6 : 2),
                  ),
                ),
              ],

              border: Border.all(
                color: widget.isSelected
                    ? AppColors.primary.withOpacity(0.9)
                    : Colors.transparent,
                width: widget.isSelected ? 2 : 1,
              ),
            ),

            child: Column(
              children: [
                /// ================= HEADER =================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),

                  child: Row(
                    textDirection: isArabic
                        ? ui.TextDirection.ltr
                        : ui.TextDirection.rtl,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _HeaderCell(
                          title: tr.t('invoice_no'),
                          value: widget.invoice.invoiceNo,
                        ),
                      ),
                      _HeaderDivider(),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell(
                          title: tr.t('account_no'),
                          value: widget.invoice.accountNo,
                        ),
                      ),
                      _HeaderDivider(),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell(
                          title: tr.t('occupancy_type'),
                          value: widget.invoice.usageType,
                        ),
                      ),
                      _HeaderDivider(),
                      Expanded(
                        flex: 4,
                        child: _HeaderCell(
                          title: tr.t('customer_name'),
                          value: widget.invoice.customerName,
                        ),
                      ),
                    ],
                  ),
                ),

                /// ================= AMOUNT =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    textDirection: isArabic
                        ? ui.TextDirection.ltr
                        : ui.TextDirection.rtl,
                    children: [
                      // ================= STATUS =================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: getInvoiceStatusColor(
                            widget.invoice,
                            context,
                          ).withOpacity(0.12),

                          borderRadius: BorderRadius.circular(24),

                          border: Border.all(
                            color: getInvoiceStatusColor(
                              widget.invoice,
                              context,
                            ).withOpacity(0.35),
                          ),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getInvoiceStatusIcon(widget.invoice),
                              color: getInvoiceStatusColor(
                                widget.invoice,
                                context,
                              ),
                              size: 17,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              getInvoiceStatus(widget.invoice, context),

                              style: TextStyle(
                                color: getInvoiceStatusColor(
                                  widget.invoice,
                                  context,
                                ),

                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ================= AMOUNT =================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,

                          borderRadius: BorderRadius.circular(10),

                          border: Border.all(color: Colors.grey.shade200),
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 17,
                              color: AppColors.primaryDark,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              "${tr.t('invoice_amount')} : ",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Text(
                              NumberFormat(
                                '#,##0.000',
                              ).format(widget.invoice.totalAmount),

                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: isTablet ? 15 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                /// ================= DETAILS =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InlineItem(
                        title: tr.t('service_address'),
                        value: widget.invoice.address,
                      ),
                      const SizedBox(width: 16),
                      _InlineItem(
                        title: tr.t('subscription_type'),
                        value: getLookupValue(
                          widget.invoice,
                          "CollectionType",
                          context,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _InlineItem(
                        title: tr.t('consumption'),
                        value: NumberFormat(
                          '#,##0.000',
                        ).format(widget.invoice.consumptionQtyPotable),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                /// ================= ACTIONS =================
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      _ActionButton(
                        title: Text(tr.t('view')),
                        icon: Icons.visibility_outlined,
                        color: Colors.grey.shade500,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => InvoiceDetailsDialog(
                              invoiceNumber: widget.invoice.invoiceNo,
                            ),
                          );
                        },
                      ),
                      if (getInvoiceStatusCode(widget.invoice, context) ==
                          "RDY")
                        _ActionButton(
                          title: Text(tr.t('print_notice')),
                          icon: Icons.print_outlined,
                          color: AppColors.warning,
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (_) => PaymentNoticeDialog(
                                invoiceNumber: widget.invoice.invoiceNo,
                              ),
                            );
                          },
                        ),
                      if (getInvoiceStatusCode(widget.invoice, context) == "COL")
                        _ActionButton(
                          title: Text(tr.t('print_invoice')),
                          icon: Icons.receipt_long,
                          color: AppColors.warning,
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) {
                                return PrintInvoiceDialog(
                                  invoiceNumber: widget.invoice.invoiceNo,
                                  getInvoiceStatusCode:
                                      getInvoiceStatusForPrint,
                                );
                              },
                            );
                          },
                        ),
                      if (getInvoiceStatusCode(widget.invoice, context) ==
                              "ISS" ||
                          getInvoiceStatusCode(widget.invoice, context) ==
                              "UEX")
                        _ActionButton(
                          title: Text(tr.t('enter_reading')),
                          icon: Icons.speed,
                          color: AppColors.primary,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ReadingDialog(
                                invoiceNumber: widget.invoice.invoiceNo,
                                batchId: widget.batchId,
                              ),
                            );
                          },
                        ),
                      if ((getInvoiceStatusCode(widget.invoice, context) ==  "RDY" ||  getInvoiceStatusCode(widget.invoice, context) ==  "UNC") && isOnline)
                        _ActionButton(
                          title: _loadingPayment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  tr.t('pay_invoice'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          icon: Icons.payments_outlined,
                          color: Colors.green,
                          onPressed: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => PaymentDialog(
                                Invoicenumber: widget.invoice.invoiceNo,
                                batchId: widget.batchId,
                                paymentReference: widget
                                    .invoice
                                    .payment!
                                    .paymentRefNo
                                    .toString(),
                                amount: widget.invoice.totalAmount,
                              ),
                            );
                          },
                        ),
                      if (getInvoiceStatusCode(widget.invoice, context) ==
                              "ISS" ||
                          getInvoiceStatusCode(widget.invoice, context) ==
                              "RDY" ||
                          getInvoiceStatusCode(widget.invoice, context) ==
                              "UNC" ||
                          getInvoiceStatusCode(widget.invoice, context) ==
                              "UEX")
                        _ActionButton(
                          title: Text(tr.t('unreachable')),
                          icon: Icons.report_problem_outlined,
                          color: AppColors.danger,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => UnreachableDialog(
                                invoiceNumber: widget.invoice.invoiceNo,
                                batchId: widget.batchId,
                              ),
                            );
                          },
                        ),
                    ],
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

class _InlineItem extends StatelessWidget {
  final String title;
  final String value;

  const _InlineItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$title : ",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String title;
  final String value;

  const _HeaderCell({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget title;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [Icon(icon, size: 20), const SizedBox(width: 8), title],
        ),
      ),
    );
  }
}

class _BatchInfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _BatchInfoItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class ActiveBatchBar extends ConsumerStatefulWidget {
  final List<BatchModel> batchesDrop;
  final BatchModel? selectedBatch;
  final Function(BatchModel?) onBatchSelected;
  final VoidCallback onResetFilters;
  final VoidCallback onStartEndBatchLoading;

  const ActiveBatchBar({
    required this.batchesDrop,
    required this.selectedBatch,
    required this.onBatchSelected,
    required this.onResetFilters,
    required this.onStartEndBatchLoading,
  });

  @override
  ConsumerState<ActiveBatchBar> createState() => _ActiveBatchBarState();
}

class _ActiveBatchBarState extends ConsumerState<ActiveBatchBar> {
  BatchModel? selectedBatch;
  late final List<BatchModel> batches;
  bool isEndBatchLoading = false;

  @override
  void initState() {
    super.initState();
    batches = widget.batchesDrop;
  }

  @override
  Widget build(BuildContext context) {
    final List<BatchModel> batches = widget.batchesDrop;
    final tr = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          /// ACTIVE BADGE (compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr.t('active_batch'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          /// SEARCH BOX (compact)
          Expanded(
            child: _BatchDropdown(
              batches: batches,
              selected: widget.selectedBatch?.batchNumber ?? "",
              onSelected: (value) {
                if (value == null || value.isEmpty) {
                  widget.onBatchSelected(null);

                  return;
                }

                final selected = batches.firstWhere(
                  (b) => b.batchNumber == value,
                );

                widget.onBatchSelected(selected);
              },
            ),
          ),
          const SizedBox(width: 10),

          /// END BUTTON (compact)
          _ActionButton(
            title: Text(tr.t('end_batch')),
            icon: Icons.close_outlined,
            color: const Color.fromARGB(193, 211, 13, 13),
            onPressed: () async {
              final batch = widget.selectedBatch;
              if (batch == null) return;

              final confirm = await showEndBatchConfirmDialog(
                context,
                batch.batchNumber,
              );

              if (confirm != true) return;

              widget.onStartEndBatchLoading(); // 👈 مهم
            },
          ),
        ],
      ),
    );
  }
}

class _BatchDropdown extends StatefulWidget {
  final List<BatchModel> batches;
  final String selected;
  final Function(String?) onSelected;

  const _BatchDropdown({
    required this.batches,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_BatchDropdown> createState() => _BatchDropdownState();
}

class _BatchDropdownState extends State<_BatchDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _controller = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDropdown() {
    _controller.clear();

    _overlayEntry = _createOverlay();

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        final filtered = widget.batches
            .where(
              (e) => e.batchNumber.toLowerCase().contains(
                _controller.text.toLowerCase(),
              ),
            )
            .toList();

        return Positioned.fill(
          child: GestureDetector(
            onTap: _hideDropdown,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomCenter,
                    followerAnchor: Alignment.topCenter,
                    offset: const Offset(0, 6),

                    child: Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(14),

                      child: Container(
                        width: 300,
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),

                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),

                          itemBuilder: (context, index) {
                            final item = filtered[index];

                            return InkWell(
                              onTap: () {
                                widget.onSelected(item.batchNumber);

                                _controller.clear();

                                setState(() {
                                  isSearching = false;
                                });

                                _hideDropdown();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.folder_open_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.batchNumber,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            isSearching = true;
          });

          _showDropdown();
        },

        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xffF8FAFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Row(
            children: [
              /// 🔍 search icon (left side)
              Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade500),

              const SizedBox(width: 8),

              Expanded(
                child: isSearching
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        onChanged: (_) {
                          if (_overlayEntry == null) {
                            _showDropdown();
                          }
                        },

                        decoration: InputDecoration(
                          hintText: tr.t('search_batch'),
                          border: InputBorder.none,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),

                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.selected.isEmpty
                              ? tr.t('search_batch')
                              : widget.selected,

                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,

                            color: widget.selected.isEmpty
                                ? Colors.grey.shade400
                                : Colors.black87,
                          ),
                        ),
                      ),
              ),

              if (widget.selected.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    widget.onSelected(null);
                    setState(() {
                      isSearching = true;
                    });
                    if (_overlayEntry != null) {
                      _hideDropdown();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),

              Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: Colors.white.withOpacity(.25),
    );
  }
}

class CloudIndicator extends StatefulWidget {
  final bool isTablet;
  final bool isOnline;
  const CloudIndicator({
    super.key,
    required this.isTablet,
    required this.isOnline,
  });

  @override
  State<CloudIndicator> createState() => _CloudIndicatorState();
}

class _CloudIndicatorState extends State<CloudIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool? _lastStatus;
  @override
  void initState() {
    super.initState();
    _lastStatus = widget.isOnline;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CloudIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_lastStatus != widget.isOnline) {
      _lastStatus = widget.isOnline;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ConnectionStatusDialog.show(context: context, isOnline: _lastStatus!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Tooltip(
        message: widget.isOnline ? "Connected to Server" : "Disconnected",
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            /// CLOUD ICON
            Icon(
              Icons.cloud_rounded,
              color: Colors.white70,
              size: widget.isTablet ? 35 : 24,
            ),

            /// ================= GLOW =================
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final glow = widget.isOnline
                      ? 0.3 + (_controller.value * 0.7)
                      : 0.2 + (_controller.value * 0.4); // أقل شوي offline

                  return Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15 * glow),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6 * glow),
                          blurRadius: 10,
                          spreadRadius: 1.5,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            /// ================= DOT / ICON =================
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final anim = _controller.value;

                  if (widget.isOnline) {
                    /// 🟢 ONLINE (breathing dot)
                    final brightness = 0.6 + (anim * 0.4);

                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(brightness),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.7 * brightness),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  } else {
                    ///   OFFLINE (flicker + icon)
                    final flicker = anim > 0.5 ? 1.0 : 0.3;

                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(flicker),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6 * flicker),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_off,
                        size: 10,
                        color: Colors.white,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
