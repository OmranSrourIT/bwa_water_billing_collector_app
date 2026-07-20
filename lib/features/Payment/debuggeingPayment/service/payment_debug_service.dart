 

import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/model/payment_debug_event.dart';
import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/model/payment_debug_model.dart';

class PaymentDebugService {
  PaymentDebugService._();

  static PaymentDebugModel? _session;

  static PaymentDebugModel? get session => _session;

  static void start({
    required Map<String, dynamic> request,
  }) {
    _session = PaymentDebugModel(
      startedAt: DateTime.now(),
    );

    _session!.request.addAll(request);

    addEvent(
      title: "Payment Started",
      description: "Payment request created",
    );
  }

  static void addEvent({
    required String title,
    String? description,
  }) {
    if (_session == null) return;

    _session!.events.add(
      PaymentDebugEvent(
        time: DateTime.now(),
        title: title,
        description: description,
      ),
    );
  }

  static void finish({
    required bool success,
    required Map<String, dynamic> response,
  }) {
    if (_session == null) return;

    _session!.success = success;
    _session!.finishedAt = DateTime.now();

    _session!.response.clear();
    _session!.response.addAll(response);

    addEvent(
      title: success ? "Payment Success" : "Payment Failed",
      description: response["rspMsg"]?.toString(),
    );
  }

  static void clear() {
    _session = null;
  }
}
