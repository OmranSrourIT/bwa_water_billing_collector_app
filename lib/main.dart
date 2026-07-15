import 'package:bwa_water_billing_collector_app/core/Serivces/AppInfoService.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_provider.dart';
import 'package:bwa_water_billing_collector_app/core/offlineMode/providers/offline_database_sync_provider.dart';
import 'package:bwa_water_billing_collector_app/core/routes/RouterApp.dart';
import 'package:bwa_water_billing_collector_app/core/utlis/connection_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/batch/providers/batch_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoiceDetails_provider.dart';
import 'package:bwa_water_billing_collector_app/features/invoices/providers/invoice_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/lang/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.instance.database;

  print("SQLite Database Opened Successfully");
  

  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  FlutterDownloader.registerCallback(downloadCallback);

  await AppInfoService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  print("STATUS=$status PROGRESS=$progress");
}

class _MyAppState extends ConsumerState<MyApp> {
  Locale _locale = const Locale('ar');

  @override
  void initState() {
    super.initState();

    ref.listenManual(authProvider, (previous, next) async {
      if (previous?.successLogin != true && next.successLogin == true) {
        print("LOGIN SUCCESS => START INITIAL SYNC");
        if (ref.read(connectionProvider)) {
          await ref.read(initialSyncStateProvider.notifier).start(); //This is For Iraq Api Sync
          print("INITIAL SYNC FINISHED");
        }
      }
    });

    ref.listenManual<bool>(connectionProvider, (previous, next) async {
      if (next == true && previous == false) {
        print("Internet Connected => Start Sync");

        final success = await ref.read(syncEngineProvider).sync(); //This is For Iraq Api Sync

        if (success) {
          await ref.read(initialSyncStateProvider.notifier).start(); //This is For LocalDB  Sync
          ref.invalidate(batchProvider);
          ref.invalidate(invoicesProvider); 
          ref.invalidate(invoiceDetailProvider);
          // ref.invalidate(failureReasonProvider);
          // ref.invalidate(fieldFailureLookupProvider);
        }
      }
    });
  }

  void toggleLang() {
    setState(() {
      _locale = _locale.languageCode == 'en'
          ? const Locale('ar')
          : const Locale('en');
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = RouterApp(ref: ref, toggleLang: toggleLang, locale: _locale);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(fontFamily: 'Tajawal'),
    );
  }
}
