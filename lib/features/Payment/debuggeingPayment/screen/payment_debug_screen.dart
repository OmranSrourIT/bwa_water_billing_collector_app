import 'package:bwa_water_billing_collector_app/features/Payment/debuggeingPayment/service/payment_debug_service.dart';
import 'package:flutter/material.dart';
 
class PaymentDebugScreen extends StatelessWidget {
  const PaymentDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = PaymentDebugService.session;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Payment Debug"),
        ),
        body: const Center(
          child: Text("No payment session available"),
        ),
      );
    }

    final success = session.success;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Payment Debug"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              backgroundColor:
                  success ? Colors.green.shade100 : Colors.red.shade100,
              label: Text(
                success ? "SUCCESS" : "FAILED",
                style: TextStyle(
                  color: success ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const SizedBox(height: 8),

          _SectionTitle("Session"),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  _Row(
                    "Started",
                    session.startedAt.toString(),
                  ),

                  const Divider(),

                  _Row(
                    "Finished",
                    session.finishedAt?.toString() ?? "-",
                  ),

                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle("Request"),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: session.request.entries
                    .map(
                      (e) => _Row(
                        e.key,
                        e.value.toString(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _SectionTitle("Response"),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: session.response.entries
                    .map(
                      (e) => _Row(
                        e.key,
                        e.value.toString(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String value;

  const _Row(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [

          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: SelectableText(value),
          ),

        ],
      ),
    );
  }
}
