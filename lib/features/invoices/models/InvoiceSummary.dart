import 'package:bwa_water_billing_collector_app/features/invoices/models/invoice_model.dart';

class InvoiceSummary {
  final double collectedAmount;
  final int completed;
  final int remaining;
  final int pending;
  final int rejected;

  InvoiceSummary({
    required this.collectedAmount,
    required this.completed,
    required this.remaining,
    required this.pending,
    required this.rejected,
  });
}

InvoiceSummary calculateSummary(List<InvoiceModel> invoices) {
  double collectedAmount = 0;
  int completed = 0;
  int remaining = 0;
  int pending = 0;
  int rejected = 0;

  for (final inv in invoices) {
    final status = inv.lookup.firstWhere(
      (l) => l.lookupType == "InvoiceStatus",
      orElse: () => LookupModelParent.empty(),
    );

    final amount = inv.totalAmount;

    if (status.code == "COL") {
      completed++;
      collectedAmount += amount;
    } 
    else if (status.code == "ISS") {
      remaining++;
    } 
    else if (status.code == "UNC") {
      pending++;
    }
  }

  return InvoiceSummary(
    collectedAmount: collectedAmount,
    completed: completed,
    remaining: remaining,
    pending: pending,
    rejected:rejected
  );
}
