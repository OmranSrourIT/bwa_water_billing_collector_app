import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'initial_sync_provider.dart';

class InitialSyncState {
  final bool loading;

  final String message;

  final bool completed;

  InitialSyncState({
    this.loading = false,
    this.message = "",
    this.completed = false,
  });
}

class InitialSyncNotifier extends StateNotifier<InitialSyncState> {
  final Ref ref;

  InitialSyncNotifier(this.ref) : super(InitialSyncState());

  Future<void> start() async {
    state = InitialSyncState(loading: true, message: "جاري تجهيز البيانات...");

    try {
      await ref
          .read(initialSyncProvider)
          .downloadInitialData(
            onProgress: (msg) {
              state = InitialSyncState(loading: true, message: msg);
            },
          );

      state = InitialSyncState(
        loading: false,
        completed: true,
        message: "تم تحميل البيانات بنجاح",
      );
    } catch (e) {
      state = InitialSyncState(
        loading: false,
        message: "حدث خطأ أثناء تحميل البيانات",
      );
    }
  }
}

final initialSyncStateProvider =
    StateNotifierProvider<InitialSyncNotifier, InitialSyncState>((ref) {
      return InitialSyncNotifier(ref);
    });
