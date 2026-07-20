class PaymentDebugEvent {
  final DateTime time;
  final String title;
  final String? description;

  const PaymentDebugEvent({
    required this.time,
    required this.title,
    this.description,
  });
}
