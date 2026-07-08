import 'package:bwa_water_billing_collector_app/core/widgets/BwaLoadingOverlay.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Provider/appUpdateProvider.dart';
import 'package:bwa_water_billing_collector_app/features/AppGate/Screen/UpdateScreen.dart';
import 'package:bwa_water_billing_collector_app/features/auth/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
 class AppGate extends ConsumerWidget {
  final VoidCallback onToggleLang;

  const AppGate({
    super.key,
    required this.onToggleLang,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final updateAsync = ref.watch(appUpdateProvider);

    return updateAsync.when(
      loading: () => const Scaffold(
        body: BwaLoadingOverlay(isLoading: true),
      ),

      error: (e, _) => Scaffold(
        body: Center(child: Text("Error: $e")),
      ),

      data: (update) {
        if (update.needUpdate) {
          return UpdateScreen(apkUrl: update.apkURL);
        }

        return LoginScreen(
          onToggleLang: onToggleLang,
          locale: locale,
        );
      },
    );
  }
}
