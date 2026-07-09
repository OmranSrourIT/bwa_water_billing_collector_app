import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectionProvider = StateNotifierProvider<ConnectionNotifier, bool>(
  (ref) => ConnectionNotifier(),
);

class ConnectionNotifier extends StateNotifier<bool> {
  late StreamSubscription _subscription;

  ConnectionNotifier() : super(true) {
    _init();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    state = await _checkInternet();
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      final hasNetwork = result != ConnectivityResult.none;

      if (!hasNetwork) {
        state = false;
        return;
      }
 
      final hasInternet = await _checkInternet();
      state = hasInternet;
    });
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
