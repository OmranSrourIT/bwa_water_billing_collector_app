import 'dart:async';

import 'package:bwa_water_billing_collector_app/core/constants/AppColors.dart';
import 'package:bwa_water_billing_collector_app/core/lang/app_localizations.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_sync_provider.dart';
import 'package:bwa_water_billing_collector_app/core/storage/PrinterStorage.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/ConnectionBanner.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/request_AppPermissions.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/responsive.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/InitialSyncLoadingScreen.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/appErrorState.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/showEndBatchConfirmDialog.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:bwa_water_billing_collector_app/features/Account/screen/AccountDetailsDialog.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/printer_channel.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/utils/PaymentResultDialog.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Set<String> selectedInvoiceStatuses = {};
  String? _lastInvoiceStatusKey;
  Map<String, String> _lastInvoiceStatusesByInvoice = {};

  String? searchAccountValue;
  String? searchAddressValue;

  bool isEndBatchLoading = false;
  bool isInitialBatchSelectionDone = false;
  bool isInvoiceStatusFilterInitialized = false;

  Timer? _searchDebounce;

  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 300;

    if (shouldShow != _showScrollToTopButton && mounted) {
      setState(() {
        _showScrollToTopButton = shouldShow;
      });
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    initPrinter();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> initPrinter() async {
    await requestAppPermissions();

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

  void _selectAllInvoiceStatusesExceptCollected(
    List<LookupModelParent> invoiceStatuses,
  ) {
    final newSelectedStatuses = invoiceStatuses
        .where((status) => status.code != 'COL')
        .map((status) => status.code)
        .toSet();

    if (!mounted) return;

    setState(() {
      selectedInvoiceStatuses = newSelectedStatuses;
      isInvoiceStatusFilterInitialized = true;
    });
  }

  void _addCollectedInvoiceStatus(List<LookupModelParent> invoiceStatuses) {
    final collectedStatus = invoiceStatuses
        .where((status) => status.code == 'COL')
        .map((status) => status.code)
        .toSet();

    if (!mounted || collectedStatus.isEmpty) return;

    setState(() {
      selectedInvoiceStatuses = {
        ...selectedInvoiceStatuses,
        ...collectedStatus,
      };
    });
  }

  Future<void> _endBatch(BatchModel batch) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (!mounted) return;

    setState(() {
      isEndBatchLoading = true;
    });

    try {
      final response = await ref.read(
        endBatchProvider(batch.batchNumber).future,
      );

      if (!mounted) return;

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
          selectedInvoiceStatuses.clear();
          isInvoiceStatusFilterInitialized = false;
          searchAccountValue = null;
          searchAddressValue = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      final message = parseError(e);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        AppPopupAlert.show(context, message: message, isError: true);
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isEndBatchLoading = false;
      });
    }
  }

  void _selectBatch(BatchModel? batch) {
    if (!mounted) return;

    setState(() {
      selectedBatch = batch;
      selectedCollectionType = null;
      selectedInvoiceNo = null;
      selectedInvoiceStatuses.clear();
      isInvoiceStatusFilterInitialized = false;

      _lastInvoiceStatusKey = null;
      _lastInvoiceStatusesByInvoice.clear();

      searchAccountValue = null;
      searchAddressValue = null;
    });
  }

  void _resetFilters() {
    if (!mounted) return;

    setState(() {
      selectedCollectionType = null;
      selectedInvoiceNo = null;
      selectedInvoiceStatuses.clear();
      isInvoiceStatusFilterInitialized = false;

      _lastInvoiceStatusKey = null;
      _lastInvoiceStatusesByInvoice.clear();

      searchAccountValue = null;
      searchAddressValue = null;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        searchAccountValue = value;
      });
    });
  }

  void _onAddressSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      setState(() {
        searchAddressValue = value;
      });
    });
  }

  List<LookupModelParent> _getCollectionTypes(List<InvoiceModel> invoices) {
    return invoices
        .expand<LookupModelParent>((invoice) => invoice.lookup)
        .where((item) => item.lookupType == 'CollectionType')
        .fold<List<LookupModelParent>>([], (list, item) {
          if (!list.any((existing) => existing.code == item.code)) {
            list.add(item);
          }

          return list;
        });
  }

  List<LookupModelParent> _getInvoiceStatuses(List<InvoiceModel> invoices) {
    return invoices
        .expand<LookupModelParent>((invoice) => invoice.lookup)
        .where((item) => item.lookupType == 'InvoiceStatus')
        .fold<List<LookupModelParent>>([], (list, item) {
          if (!list.any((existing) => existing.code == item.code)) {
            list.add(item);
          }

          return list;
        });
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    final accountSearch = searchAccountValue?.trim().toLowerCase() ?? '';

    final addressSearch = searchAddressValue?.trim().toLowerCase() ?? '';

    return invoices
        .where((invoice) {
          final collectionMatch =
              selectedCollectionType == null ||
              invoice.lookup.any(
                (lookup) =>
                    lookup.lookupType == 'CollectionType' &&
                    lookup.code == selectedCollectionType,
              );

          final statusMatch =
              selectedInvoiceStatuses.isEmpty ||
              invoice.lookup.any(
                (lookup) =>
                    lookup.lookupType == 'InvoiceStatus' &&
                    selectedInvoiceStatuses.contains(lookup.code),
              );

          final accountMatch =
              accountSearch.isEmpty ||
              invoice.accountNo.toLowerCase().contains(accountSearch) ||
              invoice.customerName.toLowerCase().contains(accountSearch);

          final addressMatch =
              addressSearch.isEmpty ||
              invoice.address.toLowerCase().contains(addressSearch);

          return collectionMatch && statusMatch && accountMatch && addressMatch;
        })
        .toList(growable: false);
  }

  Widget _buildActiveBatchBar(List<BatchModel> batches) {
    return ActiveBatchBar(
      batchesDrop: batches,
      selectedBatch: selectedBatch,
      onBatchSelected: _selectBatch,
      onResetFilters: _resetFilters,
      onStartEndBatchLoading: () {
        final batch = selectedBatch;

        if (batch != null) {
          _endBatch(batch);
        }
      },
    );
  }

  Widget _buildEmptyInvoicesView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 50,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد فواتير لهذا السجل',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك اختيار سجل آخر من القائمة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(
    List<LookupModelParent> collectionTypes,
    List<LookupModelParent> invoiceStatuses,
  ) {
    return _SearchSection(
      collectionTypes: collectionTypes,
      selectedCollectionType: selectedCollectionType,
      invoiceStatuses: invoiceStatuses,
      selectedInvoiceStatuses: selectedInvoiceStatuses,
      searchAccountValue: searchAccountValue,
      searchAddressValue: searchAddressValue,
      onAddressSearchChanged: _onAddressSearchChanged,
      onSearchChanged: _onSearchChanged,
      onCollectionChanged: (value) {
        if (!mounted) return;

        setState(() {
          selectedCollectionType = value?.code;
        });
      },
      onStatusesChanged: (values) {
        if (!mounted) return;

        setState(() {
          selectedInvoiceStatuses = values;
        });
      },
    );
  }

  List<Widget> _buildBatchSlivers(List<BatchModel> batches, bool isTablet) {
    if (batches.isEmpty) {
      return [const SliverToBoxAdapter(child: SizedBox())];
    }

    if (!isInitialBatchSelectionDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || isInitialBatchSelectionDone) return;

        setState(() {
          selectedBatch = batches.last;
          isInitialBatchSelectionDone = true;
        });
      });
    }

    final activeBatch = selectedBatch;

    if (activeBatch == null) {
      return [
        SliverPadding(
          padding: EdgeInsets.all(isTablet ? 12 : 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildActiveBatchBar(batches),
              const SizedBox(height: 20),
              const MessageSelectedBacth(),
            ]),
          ),
        ),
      ];
    }

    final invoicesAsync = ref.watch(invoicesProvider(activeBatch.batchNumber));

    return invoicesAsync.when(
      loading: () {
        return [
          SliverPadding(
            padding: EdgeInsets.all(isTablet ? 12 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActiveBatchBar(batches),
                SizedBox(height: isTablet ? 8 : 16),
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ]),
            ),
          ),
        ];
      },
      error: (error, stack) {
        final isUnauthorized =
            error is DioException &&
            (error.response?.statusCode == 401 ||
                error.response?.statusCode == 403);

        return [
          SliverPadding(
            padding: EdgeInsets.all(isTablet ? 12 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActiveBatchBar(batches),
                SizedBox(height: isTablet ? 8 : 16),
                AppErrorState(
                  message: isUnauthorized
                      ? 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى'
                      : parseError(error),
                  onRetry: () {
                    ref.invalidate(invoicesProvider(activeBatch.batchNumber));
                  },
                ),
              ]),
            ),
          ),
        ];
      },
      data: (invoices) {
        final invoicesRaw = invoices.cast<InvoiceModel>();

        if (invoicesRaw.isEmpty) {
          return [
            SliverPadding(
              padding: EdgeInsets.all(isTablet ? 12 : 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildActiveBatchBar(batches),
                  SizedBox(height: isTablet ? 8 : 16),
                  _buildEmptyInvoicesView(),
                ]),
              ),
            ),
          ];
        }

        final summary = calculateSummary(invoicesRaw);

        final collectionTypes = _getCollectionTypes(invoicesRaw);

        final invoiceStatuses = _getInvoiceStatuses(invoicesRaw);

        final currentInvoiceStatuses = <String, String>{};

        for (final invoice in invoicesRaw) {
          final status = invoice.lookup.firstWhere(
            (lookup) => lookup.lookupType == 'InvoiceStatus',
            orElse: () => LookupModelParent.empty(),
          );

          currentInvoiceStatuses[invoice.invoiceNo] = status.code;
        }

        final invoiceStatusKey =
            currentInvoiceStatuses.entries
                .map((entry) => '${entry.key}:${entry.value}')
                .toList()
              ..sort();

        final currentStatusKey = invoiceStatusKey.join('|');

        if (_lastInvoiceStatusKey != currentStatusKey &&
            invoiceStatuses.isNotEmpty) {
          final isFirstInitialization = _lastInvoiceStatusKey == null;

          final previousInvoiceStatuses = Map<String, String>.from(
            _lastInvoiceStatusesByInvoice,
          );

          final changedStatusCodes = <String>{};

          if (!isFirstInitialization) {
            currentInvoiceStatuses.forEach((invoiceNo, newStatus) {
              final oldStatus = previousInvoiceStatuses[invoiceNo];

              if (oldStatus != null && oldStatus != newStatus) {
                changedStatusCodes.add(newStatus);
              }
            });
          }

          _lastInvoiceStatusKey = currentStatusKey;
          _lastInvoiceStatusesByInvoice = currentInvoiceStatuses;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            if (isFirstInitialization) {
              // أول تحميل:
              // كل الحالات ما عدا COL
              _selectAllInvoiceStatusesExceptCollected(invoiceStatuses);
              return;
            }

            if (changedStatusCodes.isEmpty) return;

            // بعد أي إجراء على فاتورة:
            // تفعيل الحالة الجديدة فقط
            setState(() {
              selectedInvoiceStatuses = {
                ...selectedInvoiceStatuses,
                ...changedStatusCodes,
              };
            });
          });
        }

        final filteredInvoices = _filterInvoices(invoicesRaw);

        return [
          SliverPadding(
            padding: EdgeInsets.only(
              left: isTablet ? 12 : 20,
              right: isTablet ? 12 : 20,
              top: isTablet ? 12 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActiveBatchBar(batches),
                SizedBox(height: isTablet ? 8 : 16),
                _BatchSummary(
                  summary: summary,
                  batch: activeBatch,
                  invoicesCount: invoicesRaw.length,
                ),
                SizedBox(height: isTablet ? 8 : 16),
              ]),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFiltersDelegate(
              minHeight: isTablet ? 120 : 130,
              maxHeight: isTablet ? 120 : 130,
              child: Container(
                color: AppColors.background,
                padding: EdgeInsets.only(
                  left: isTablet ? 12 : 20,
                  right: isTablet ? 12 : 20,
                  bottom: isTablet ? 12 : 20,
                ),
                child: _buildSearchSection(collectionTypes, invoiceStatuses),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.only(
              left: isTablet ? 12 : 20,
              right: isTablet ? 12 : 20,
              bottom: isTablet ? 12 : 20,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final invoice = filteredInvoices[index];

                return RepaintBoundary(
                  key: ValueKey(invoice.invoiceNo),
                  child: _InvoiceCard(
                    invoice,
                    isSelected: selectedInvoiceNo == invoice.invoiceNo,
                    batchId: activeBatch.batchNumber,
                    onSelect: () {
                      if (!mounted) return;

                      setState(() {
                        selectedInvoiceNo = invoice.invoiceNo;
                      });
                    },
                  ),
                );
              }, childCount: filteredInvoices.length),
            ),
          ),
        ];
      },
    );
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
                const _Header(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      final batch = selectedBatch;

                      if (batch != null) {
                        await ref.refresh(
                          invoicesProvider(batch.batchNumber).future,
                        );

                        if (selectedInvoiceNo != null) {
                          await ref.refresh(
                            invoiceDetailProvider(selectedInvoiceNo!).future,
                          );
                        }
                      } else {
                        await ref.refresh(batchProvider.future);
                      }
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: batchAsync.when(
                        data: (batches) {
                          if (batches.isEmpty) {
                            return [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "لا توجد سجلات مسندة حاليًا",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "لم يتم إسناد أي سجلات لك في الوقت الحالي.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            ref.invalidate(batchProvider);
                                          },
                                          icon: const Icon(Icons.refresh),
                                          label: const Text("إعادة المحاولة"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          }

                          return _buildBatchSlivers(batches, isTablet);
                        },
                        loading: () {
                          return [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ];
                        },
                        error: (error, stack) {
                          final message = parseError(error);

                          return [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: AppErrorState(
                                message: message,
                                onRetry: () {
                                  ref.invalidate(batchProvider);
                                },
                              ),
                            ),
                          ];
                        },
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

            Positioned(
              right: 16,
              bottom: 30,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  final offsetAnimation =
                      Tween<Offset>(
                        begin: const Offset(1, 0), // يبدأ من اليمين
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      );

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: _showScrollToTopButton
                    ? FloatingActionButton(
                        key: const ValueKey('scroll-to-top'),
                        heroTag: 'scroll-to-top',
                        onPressed: _scrollToTop,
                        tooltip: 'العودة إلى الأعلى',
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 30,
                        ),
                      )
                    : const SizedBox(key: ValueKey('scroll-to-top-hidden')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _StickyFiltersDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.background,
      elevation: overlapsContent ? 2 : 0,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFiltersDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
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

class _Header extends ConsumerStatefulWidget {
  const _Header();

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;

  bool isMenuOpen = false;

  void showAccountMenu() {
    if (_overlayEntry != null) {
      hideAccountMenu();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                onTap: hideAccountMenu,
                child: Container(color: Colors.transparent),
              ),

              CompositedTransformFollower(
                link: _layerLink,

                showWhenUnlinked: false,

                offset: const Offset(0, 60),

                child: Material(
                  color: Colors.transparent,

                  child: Directionality(
                    textDirection:
                        Localizations.localeOf(context).languageCode == 'ar'
                        ? ui.TextDirection.rtl
                        : ui.TextDirection.ltr,

                    child: Container(
                      width: 240,

                      padding: const EdgeInsets.all(8),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(16),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),

                            blurRadius: 20,

                            offset: const Offset(0, 8),
                          ),
                        ],

                        border: Border.all(
                          color: Colors.grey.withOpacity(0.15),
                        ),
                      ),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          _AccountMenuItem(
                            icon: Icons.person_outline,
                            title: AppLocalizations.of(
                              context,
                            ).t('account_info'),
                            color: AppColors.primary,

                            onTap: () {
                              hideAccountMenu();

                              showDialog(
                                context: context,
                                builder: (_) => const AccountDetailsDialog(),
                              );
                            },
                          ),

                          const Divider(height: 15),

                          _AccountMenuItem(
                            icon: Icons.logout,
                            title: AppLocalizations.of(context).t('logout'),
                            color: Colors.redAccent,

                            onTap: () async {
                              hideAccountMenu();

                              await ref.read(authProvider.notifier).logout();
                            },
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

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void hideAccountMenu() {
    _overlayEntry?.remove();

    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
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
              child: CompositedTransformTarget(
                link: _layerLink,

                child: GestureDetector(
                  onTap: showAccountMenu,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),

                      borderRadius: BorderRadius.circular(30),

                      border: Border.all(color: Colors.white.withOpacity(0.25)),
                    ),

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
                          loading: () => const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),

                          error: (_, __) => const SizedBox(),

                          data: (account) {
                            final name = isArabic
                                ? "${account.firstNameAr} ${account.fatherNameAr} ${account.familyNameAr}"
                                : "${account.firstNameEn} ${account.fatherNameEn} ${account.familyNameEn}";

                            return Flexible(
                              child: Text(
                                name,
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

                        const SizedBox(width: 5),

                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
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
                    'assets/images/VerticalAsimati.png',
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

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),

      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,

              decoration: BoxDecoration(
                color: color.withOpacity(0.12),

                borderRadius: BorderRadius.circular(10),
              ),

              child: Icon(icon, color: color, size: 20),
            ),

            const SizedBox(width: 12),

            Text(
              title,

              style: const TextStyle(
                color: Colors.black87,

                fontSize: 14,

                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                value: summary.unrechable.toString(),
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
  final Set<String> selectedInvoiceStatuses;
  final Function(Set<String>) onStatusesChanged;

  final String? searchAccountValue;
  final Function(String) onSearchChanged;

  final String? searchAddressValue;
  final Function(String) onAddressSearchChanged;

  const _SearchSection({
    super.key,
    required this.collectionTypes,
    required this.selectedCollectionType,
    required this.onCollectionChanged,

    required this.invoiceStatuses,
    required this.selectedInvoiceStatuses,
    required this.onStatusesChanged,

    this.searchAccountValue,
    required this.onSearchChanged,

    this.searchAddressValue,
    required this.onAddressSearchChanged,
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
    final isTablet = Responsive.isTablet(context);

    return Column(
      children: [
        /// ================= SEARCH =================
        /// ================= SEARCH =================
        Row(
          children: [
            Expanded(
              child: Container(
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
                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  inputFormatters: [NoArabicDigitsFormatter()],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isTablet ? 15 : 14),
                  onChanged: widget.onSearchChanged,
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

            const SizedBox(width: 8),

            Expanded(
              child: Container(
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
                child: TextField(
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isTablet ? 15 : 14),
                  onChanged: widget.onAddressSearchChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: tr.t('search_address'),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isTablet ? 15 : 13,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 20,
                      vertical: 12,
                    ),
                    suffixIcon: Icon(
                      Icons.location_on_outlined,
                      size: isTablet ? 20 : 22,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        /// ================= FILTERS =================
        Row(
          children: [
            Expanded(
              child: _InvoiceStatusChecklist(
                title: tr.t('search_by_status'),
                items: widget.invoiceStatuses,
                selectedCodes: widget.selectedInvoiceStatuses,
                onChanged: widget.onStatusesChanged,
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

class _InvoiceStatusChecklist extends StatelessWidget {
  final String title;
  final List<LookupModelParent> items;
  final Set<String> selectedCodes;
  final Function(Set<String>) onChanged;

  const _InvoiceStatusChecklist({
    required this.title,
    required this.items,
    required this.selectedCodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final selectedCount = selectedCodes.length;

    String displayText;

    if (selectedCount == 0) {
      displayText = 'لم يتم تحديد حالة الفاتورة';
    } else if (selectedCount == items.length) {
      displayText = 'الكل';
    } else {
      final locale = Localizations.localeOf(context).languageCode;

      final selectedNames = items
          .where((item) => selectedCodes.contains(item.code))
          .map((item) => locale == 'ar' ? item.arDesc : item.enDesc)
          .where((name) => name.trim().isNotEmpty)
          .toList();

      displayText = selectedNames.join('، ');
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          _showChecklist(context);
        },
        child: Container(
          height: isTablet ? 48 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: isTablet ? 20 : 21,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    color: selectedCount == 0
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChecklist(BuildContext context) {
    final tempSelected = Set<String>.from(selectedCodes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isTablet = Responsive.isTablet(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                if (tempSelected.length == items.length) {
                                  tempSelected.clear();
                                } else {
                                  tempSelected
                                    ..clear()
                                    ..addAll(items.map((item) => item.code));
                                }
                              });
                            },
                            child: Text(
                              tempSelected.length == items.length
                                  ? 'إلغاء الكل'
                                  : 'تحديد الكل',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) {
                          return const Divider(
                            height: 1,
                            indent: 20,
                            endIndent: 20,
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];

                          final isSelected = tempSelected.contains(item.code);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  tempSelected.add(item.code);
                                } else {
                                  tempSelected.remove(item.code);
                                }
                              });
                            },
                            title: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? item.arDesc
                                  : item.enDesc,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
                    ),

                    const Divider(height: 1),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            onChanged(Set<String>.from(tempSelected));

                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'تطبيق',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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
  }
}

class NoArabicDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[٠-٩]'), '');

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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

  OverlayEntry? _paymentTransitionOverlay;

  void _showPaymentTransitionLoading(BuildContext context) {
    if (_paymentTransitionOverlay != null) return;

    final overlay = Overlay.of(context, rootOverlay: true);

    _paymentTransitionOverlay = OverlayEntry(
      builder: (_) =>
          const Positioned.fill(child: BwaLoadingOverlay(isLoading: true)),
    );

    overlay.insert(_paymentTransitionOverlay!);
  }

  void _hidePaymentTransitionLoading() {
    _paymentTransitionOverlay?.remove();
    _paymentTransitionOverlay = null;
  }

  @override
  void dispose() {
    _hidePaymentTransitionLoading();
    super.dispose();
  }

  Future<void> _openInvoiceAction({
    required String invoiceNo,
    required Widget Function(BuildContext context) dialogBuilder,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await ref
          .read(invoiceDetailsRepositoryProvider)
          .ensureInvoiceDetails(invoiceNo);

      if (!mounted) return;

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (dialogContext) => dialogBuilder(dialogContext),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      AppPopupAlert.show(
        context,
        message: parseError(e).toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _openPrintInvoice({
    required String invoiceNo,
    required String batchId,
    required BuildContext dialogContext,
  }) async {
    _showPaymentTransitionLoading(context);

    try {
      await ref
          .read(invoiceDetailsRepositoryProvider)
          .ensureInvoiceDetails(invoiceNo);

      if (!mounted) return;

      // انتهى الانتظار، أغلق الـLoading أولًا
      _hidePaymentTransitionLoading();

      // بعدها افتح نافذة الطباعة
      await showDialog(
        context: dialogContext,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => PrintInvoiceDialog(
          invoiceNumber: invoiceNo,
          batchId: batchId,
          getInvoiceStatusCode: getInvoiceStatusForPrint,
        ),
      );
    } catch (e) {
      _hidePaymentTransitionLoading();

      if (!mounted) return;

      AppPopupAlert.show(
        context,
        message: parseError(e).toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      // حماية إضافية حتى لا يبقى معلقًا في أي حالة
      _hidePaymentTransitionLoading();
    }
  }

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

    return isArabic ? status.externalArDesc : status.externalEnDesc;
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

  void _selectCard() {
    widget.onSelect?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final tr = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isOnline = ref.watch(connectionProvider);

    final invoiceStatus = getInvoiceStatusCode(widget.invoice, context);
    final isEditingReading = invoiceStatus == "RDY" || invoiceStatus == "UNC";

    final isEstimatedSubscription = widget.invoice.lookup.any(
      (item) => item.lookupType == "CollectionType" && item.code == "EST",
    );

    final invoiceAsync = ref.watch(
      invoiceDetailProvider(widget.invoice.invoiceNo),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

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
                /// ================= AMOUNT =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    textDirection: isArabic
                        ? ui.TextDirection.ltr
                        : ui.TextDirection.rtl,
                    children: [
                      // ================= STATUS =================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getInvoiceStatusColor(
                            widget.invoice,
                            context,
                          ).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: getInvoiceStatusColor(
                              widget.invoice,
                              context,
                            ).withOpacity(0.25),
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
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              getInvoiceStatus(widget.invoice, context),
                              style: TextStyle(
                                color: getInvoiceStatusColor(
                                  widget.invoice,
                                  context,
                                ),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ================= FINANCIAL SUMMARY =================
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              // ================= INVOICE AMOUNT =================
                              Expanded(
                                child: _AmountItem(
                                  title: "المبلغ المستحق",
                                  value: NumberFormat(
                                    '#,##0.000',
                                  ).format(widget.invoice.totalDueAmount),
                                  color: AppColors.primaryDark,
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),

                              _AmountDivider(),

                              // ================= DUE AMOUNT =================
                              Expanded(
                                child: _AmountItem(
                                  title: tr.t('invoice_amount'),
                                  value: NumberFormat(
                                    '#,##0.000',
                                  ).format(widget.invoice.totalAmount),
                                  color: Colors.orange.shade700,
                                  icon: Icons.account_balance_wallet_outlined,
                                ),
                              ),

                              _AmountDivider(),

                              // ================= DEBT =================
                              Expanded(
                                child: invoiceAsync.when(
                                  data: (invoiceDetails) {
                                    return _AmountItem(
                                      title: "قيمة الديون",
                                      value: NumberFormat(
                                        '#,##0.000',
                                      ).format(invoiceDetails.totalDebt),
                                      color: Colors.red.shade700,
                                      icon: Icons.warning_amber_rounded,
                                    );
                                  },

                                  loading: () {
                                    return _AmountItem(
                                      title: "قيمة الديون",
                                      value: "...",
                                      color: Colors.red.shade700,
                                      icon: Icons.warning_amber_rounded,
                                    );
                                  },

                                  error: (error, stack) {
                                    return _AmountItem(
                                      title: "قيمة الديون",
                                      value: "—",
                                      color: Colors.red.shade700,
                                      icon: Icons.warning_amber_rounded,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InlineItem(
                          title: tr.t('service_address'),
                          value: widget.invoice.address,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: invoiceAsync.when(
                          data: (invoiceDetails) {
                            final subscriptionType = getLookupValue(
                              widget.invoice,
                              "CollectionType",
                              context,
                            );

                            final isMeter = subscriptionType.contains("مقياس");

                            return _InlineItem(
                              title: tr.t('subscription_type'),
                              value: subscriptionType,
                              valueWidget: isMeter
                                  ? FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            subscriptionType,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${invoiceDetails.waterMeterSerialNo ?? "-"})',
                                            maxLines: 1,
                                            softWrap: false,
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            );
                          },

                          loading: () {
                            return _InlineItem(
                              title: tr.t('subscription_type'),
                              value: getLookupValue(
                                widget.invoice,
                                "CollectionType",
                                context,
                              ),
                            );
                          },

                          error: (error, stack) {
                            return _InlineItem(
                              title: tr.t('subscription_type'),
                              value: getLookupValue(
                                widget.invoice,
                                "CollectionType",
                                context,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _InlineItem(
                          title: tr.t('consumption'),
                          value:
                              "${widget.invoice.consumptionQtyPotable.toInt()} م³",
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                /// ================= ACTIONS =================
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (getInvoiceStatusCode(widget.invoice, context) !=
                                "UEX" &&
                            getInvoiceStatusCode(widget.invoice, context) !=
                                "ISS")
                          _ActionButton(
                            title: Text(tr.t('view')),
                            icon: Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                            onBeforePressed: _selectCard,
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => InvoiceDetailsDialog(
                                  invoiceNumber: widget.invoice.invoiceNo,
                                ),
                              );
                            },
                          ),

                        if ((getInvoiceStatusCode(widget.invoice, context) ==
                                    "RDY" ||
                                getInvoiceStatusCode(widget.invoice, context) ==
                                    "UNC") &&
                            widget.invoice.totalAmount > 0)
                          _ActionButton(
                            title: Text(tr.t('print_notice')),
                            icon: Icons.print_outlined,
                            color: AppColors.warning,
                            onBeforePressed: _selectCard,
                            onPressed: () {
                              final invoiceNo = widget.invoice.invoiceNo;
                              final batchId = widget.batchId;

                              _openInvoiceAction(
                                invoiceNo: invoiceNo,
                                dialogBuilder: (_) => PaymentNoticeDialog(
                                  invoiceNumber: invoiceNo,
                                  batchId: batchId,
                                ),
                              );
                            },
                          ),
                        if (getInvoiceStatusCode(widget.invoice, context) ==
                            "COL")
                          _ActionButton(
                            title: Text(tr.t('print_invoice')),
                            icon: Icons.receipt_long,
                            color: AppColors.warning,
                            onBeforePressed: _selectCard,
                            onPressed: () {
                              final invoiceNo = widget.invoice.invoiceNo;
                              final batchId = widget.batchId;

                              _openInvoiceAction(
                                invoiceNo: invoiceNo,
                                dialogBuilder: (context) => PrintInvoiceDialog(
                                  invoiceNumber: invoiceNo,
                                  batchId: batchId,
                                  getInvoiceStatusCode:
                                      getInvoiceStatusForPrint,
                                ),
                              );
                            },
                          ),

                        if (!isEstimatedSubscription &&
                            (invoiceStatus == "ISS" ||
                                invoiceStatus == "UEX" ||
                                invoiceStatus == "RDY" ||
                                invoiceStatus == "UNC"))
                          _ActionButton(
                            title: Text(
                              isEditingReading
                                  ? 'تعديل القراءة'
                                  : tr.t('enter_reading'),
                            ),
                            icon: isEditingReading ? Icons.edit : Icons.speed,
                            color: const Color(0xFF2AAAE1),
                            onBeforePressed: _selectCard,
                            onPressed: () async {
                              try {
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => ReadingDialog(
                                    invoiceNumber: widget.invoice.invoiceNo,
                                    batchId: widget.batchId,
                                    isEditing: isEditingReading,
                                  ),
                                );
                              } catch (e, stack) {
                                debugPrint('[OPEN READING DIALOG ERROR] $e');
                                debugPrint(
                                  '[OPEN READING DIALOG STACK] $stack',
                                );

                                if (!context.mounted) return;

                                AppPopupAlert.show(
                                  context,
                                  message: parseError(e),
                                  isError: true,
                                );
                              }
                            },
                          ),

                        if ((getInvoiceStatusCode(widget.invoice, context) ==
                                    "RDY" ||
                                getInvoiceStatusCode(widget.invoice, context) ==
                                    "UNC") &&
                            isOnline)
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
                            onBeforePressed: _selectCard,

                            onPressed: () {
                              final invoiceNo = widget.invoice.invoiceNo;
                              final batchId = widget.batchId;

                              final paymentReference =
                                  widget.invoice.payment?.paymentRefNo
                                      .toString() ??
                                  '';
 

                              final amount = widget.invoice.totalDueAmount;

                              // نأخذ Navigator ثابتًا قبل أن تختفي بطاقة الفاتورة بسبب الفلتر
                              final rootNavigator = Navigator.of(
                                context,
                                rootNavigator: true,
                              );

                              showDialog(
                                context: rootNavigator.context,
                                useRootNavigator: true,
                                barrierDismissible: false,
                                builder: (_) => PaymentDialog(
                                  Invoicenumber: invoiceNo,
                                  batchId: batchId,
                                  paymentReference: paymentReference,
                                  amount: amount,
                                  onPaymentFinished:
                                      (
                                        bool success,
                                        Map<String, dynamic> data,
                                        String invoiceStatus,
                                      ) {
                                        WidgetsBinding.instance.addPostFrameCallback((
                                          _,
                                        ) {
                                          if (!rootNavigator.mounted) {
                                            _hidePaymentTransitionLoading();
                                            return;
                                          }

                                          showDialog(
                                            context: rootNavigator.context,
                                            useRootNavigator: true,
                                            barrierDismissible: false,
                                            builder: (_) => PaymentResultDialog(
                                              success: success,
                                              data: data,
                                              Invoicenumber: invoiceNo,
                                              invoiceStatus: success
                                                  ? "COL"
                                                  : invoiceStatus,
                                              onClose: success
                                                  ? () {
                                                      WidgetsBinding.instance
                                                          .addPostFrameCallback((
                                                            _,
                                                          ) {
                                                            if (!rootNavigator
                                                                .mounted)
                                                              return;

                                                            // يظهر فقط بعد نجاح الدفع وإغلاق شاشة النتيجة
                                                            _showPaymentTransitionLoading(
                                                              context,
                                                            );

                                                            _openPrintInvoice(
                                                              invoiceNo:
                                                                  invoiceNo,
                                                              batchId: batchId,
                                                              dialogContext:
                                                                  rootNavigator
                                                                      .context,
                                                            );
                                                          });
                                                    }
                                                  : null,
                                            ),
                                          );
                                        });
                                      },
                                ),
                              );
                            },

                            /**BUTTON FOR TESTING PAYEMTN */
                            // onPressed: () {
                            //   const bool isFakePaymentSuccess = true;

                            //   final batchId = widget.batchId;
                            //   final paidInvoiceNo = widget.invoice.invoiceNo;
                            //   final paidAmount = widget.invoice.totalDueAmount;

                            //   debugPrint('Payment invoice: $paidInvoiceNo');

                            //   showDialog(
                            //     context: context,
                            //     barrierDismissible: false,
                            //     builder: (_) => PaymentResultDialog(
                            //       success: isFakePaymentSuccess,
                            //       Invoicenumber: paidInvoiceNo,
                            //       invoiceStatus: 'COL',
                            //       data: {
                            //         "totalAmount": paidAmount,
                            //         "paymentMethod": "Test Card",
                            //         "rspMsg": isFakePaymentSuccess
                            //             ? "Approved"
                            //             : "Error -1",
                            //       },
                            //       onClose: isFakePaymentSuccess
                            //           ? () {
                            //               // لا تضع Navigator.pop هنا
                            //               // PaymentResultDialog يغلق نفسه داخليًا

                            //               WidgetsBinding.instance
                            //                   .addPostFrameCallback((_) {
                            //                     if (!context.mounted) return;

                            //                     _openInvoiceAction(
                            //                       invoiceNo: paidInvoiceNo,
                            //                       dialogBuilder: (_) =>
                            //                           PrintInvoiceDialog(
                            //                             invoiceNumber:
                            //                                 paidInvoiceNo,
                            //                             batchId: batchId,
                            //                             getInvoiceStatusCode:
                            //                                 getInvoiceStatusForPrint,
                            //                           ),
                            //                     );
                            //                   });
                            //             }
                            //           : null,
                            //     ),
                            //   );
                            // },
                          ),

                        if (getInvoiceStatusCode(widget.invoice, context) ==
                                "ISS" ||
                            (getInvoiceStatusCode(widget.invoice, context) ==
                                    "RDY" &&
                                widget.invoice.totalAmount > 0)
                        // getInvoiceStatusCode(widget.invoice, context) ==
                        //     "UNC" ||
                        // getInvoiceStatusCode(widget.invoice, context) ==
                        //     "UEX"
                        )
                          _ActionButton(
                            title: Text(tr.t('unreachable')),
                            icon: Icons.report_problem_outlined,
                            color: AppColors.danger,
                            onBeforePressed: _selectCard,
                            onPressed: () {
                              final invoiceNo = widget.invoice.invoiceNo;

                              _openInvoiceAction(
                                invoiceNo: invoiceNo,
                                dialogBuilder: (_) => UnreachableDialog(
                                  invoiceNumber: invoiceNo,
                                  batchId: widget.batchId,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
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

class _AmountItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _AmountItem({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.75)),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 1),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountDivider extends StatelessWidget {
  const _AmountDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.shade200,
    );
  }
}

class _InlineItem extends StatelessWidget {
  final String title;
  final String value;
  final Widget? valueWidget;

  const _InlineItem({
    required this.title,
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title :",
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child:
              valueWidget ??
              Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
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
  final VoidCallback? onBeforePressed;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    this.onPressed,
    this.onBeforePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: () {
            onBeforePressed?.call(); // ⭐ يحدد الكارد
            onPressed?.call(); // ينفذ العملية
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Icon(icon, size: 18), const SizedBox(width: 5), title],
          ),
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

              widget.onStartEndBatchLoading();
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
