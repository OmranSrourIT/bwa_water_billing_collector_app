import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Provider/appUpdateProvider.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Screen/UpdateScreen.dart';
import 'package:bwa_water_billing_collector_app/features/auth/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppGate extends ConsumerStatefulWidget {
  final VoidCallback onToggleLang;

  const AppGate({super.key, required this.onToggleLang});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(appUpdateProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final updateAsync = ref.watch(appUpdateProvider);

    return updateAsync.when(
      loading: () => const Scaffold(body: BwaLoadingOverlay(isLoading: true)),

      error: (error, stack) {
        final message = parseError(error);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppPopupAlert.show(context, message: message, isError: true);
        });

        return const SizedBox();
      },

      data: (update) {
        if (update.needUpdate) {
          return UpdateScreen(apkUrl: update.apkURL);
        }

        return LoginScreen(onToggleLang: widget.onToggleLang, locale: locale);
      },
    );
  }
}
