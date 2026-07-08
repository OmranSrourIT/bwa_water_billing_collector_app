import 'dart:ui';
import 'package:flutter/material.dart';

class AppPopupAlert {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _PopupAlert(message: message, isError: isError, onOk: onOk);
      },
    );
  }
}

class _PopupAlert extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback? onOk;

  const _PopupAlert({required this.message, required this.isError, this.onOk});

  @override
  State<_PopupAlert> createState() => _PopupAlertState();
}

class _PopupAlertState extends State<_PopupAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    scale = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    fade = Tween<double>(begin: 0, end: 1).animate(controller);

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: FadeTransition(
        opacity: fade,
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Icon(
                    widget.isError
                        ? Icons.cancel_rounded
                        : Icons.check_circle_rounded,
                    size: 55,
                    color: widget.isError ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.isError ? "تحذير" : "نجاح",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isError ? Colors.red : Colors.green,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, decoration: TextDecoration.none,),
                    
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isError
                            ? Colors.red
                            : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onOk != null) {
                          widget.onOk!();
                        }
                      },
                      child: const Text(
                        "تم",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
