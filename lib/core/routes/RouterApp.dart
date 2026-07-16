 
import 'dart:ui';
import 'package:bwa_water_billing_collector_app/features/auth/screens/forgot_password_screen.dart';
import 'package:bwa_water_billing_collector_app/features/security/screen/security_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bwa_water_billing_collector_app/features/auth/providers/auth_provider.dart';
import 'package:bwa_water_billing_collector_app/features/auth/screens/LoginScreen.dart';
import 'package:bwa_water_billing_collector_app/features/home/screen/HomeScreen.dart';

GoRouter RouterApp({
  required WidgetRef ref,
  required void Function() toggleLang,
  required Locale locale,
}) {
  final router = GoRouter(
    initialLocation: '/gate',
    refreshListenable: GoRouterRefreshStream(
      ref.read(authProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final auth = ref.read(authProvider);

      final loggedIn = auth.user != null;

      final initialized = auth.initialized;

      final isLogin = state.matchedLocation == '/login';

      final isForgot = state.matchedLocation == '/forgot-password';

      final isGate = state.matchedLocation == '/gate';

      if (!initialized) {
        return null;
      }
      

      if (auth.tokenExpired) {
        return '/login';
      }

      if (loggedIn) {
        if (isLogin || isGate) {
          return '/home';
        }

        return null;
      }

      if (!loggedIn) {
        if (!isLogin && !isForgot && !isGate) {
          return '/login';
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return LoginScreen(onToggleLang: toggleLang, locale: locale);
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          return const ForgotPasswordScreen();
        },
      ),
      // GoRoute(
      //   path: '/gate',
      //   builder: (context, state) {
      //     return AppGate(onToggleLang: toggleLang);
      //   },
      // ),
      GoRoute(
        path: '/gate',
        builder: (context, state) {
          return SecurityGate(onToggleLang: toggleLang);
        },
      ),
    ],
  );
  return router;
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((event) {
      notifyListeners();
    });
  }
}
