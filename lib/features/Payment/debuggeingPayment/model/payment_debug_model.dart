 

import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/model/payment_debug_event.dart';

class PaymentDebugModel {
  final DateTime startedAt;

  DateTime? finishedAt;

  bool success = false;

  final Map<String, dynamic> request = {};

  final Map<String, dynamic> response = {};

  final List<PaymentDebugEvent> events = [];

  PaymentDebugModel({
    required this.startedAt,
  });
}
