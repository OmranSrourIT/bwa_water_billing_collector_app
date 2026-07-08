import 'package:flutter/material.dart';

class ConnectionStatusDialog {
  static void show({required BuildContext context, required bool isOnline}) {
    showDialog(
      context: context,
      barrierDismissible: false, // لازم يضغط OK
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOnline ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// ICON
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          isOnline
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          size: 50,
                          color: isOnline ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  /// TEXT
                  Text(
                    isOnline ? "تم الاتصال بنجاح" : "لا يوجد اتصال بالإنترنت",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isOnline
                        ? "النظام يعمل بشكل طبيعي"
                        : "الرجاء الاتصال بالإنترنت",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),

                  const SizedBox(height: 20),

                  /// OK BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
