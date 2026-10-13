import 'package:flutter/material.dart';

class ExecutionPrintLayout extends StatelessWidget {
  final String accountNo;
  final String customerName;
  final String reason;
  final String collectorName;
  final String collectorPhone;
  final String printedAt;

  const ExecutionPrintLayout({
    super.key,
    required this.accountNo,
    required this.customerName,
    required this.reason,
    required this.collectorName,
    required this.collectorPhone,
    required this.printedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          height: 1.2,
          color: Colors.black,
        ),
        child: SizedBox(
          width: 576,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Governerate2_logo.png',
                      width: 120,
                      height: 120,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        children: [
                          Text(
                            'دائرة ماء بغداد',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'نظام فوترة وجباية الماء',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'إشعار تعذر تنفيذ القراءة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/images/VerticalAsimati.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 2, color: Colors.black),
                _sectionTitle('بيانات المشترك والحساب'),
                _row('رقم الحساب :', accountNo),
                _row('اسم المشترك :', customerName),
                _row('اسم الجابي :', collectorName),
                _row('رقم هاتف الجابي :', collectorPhone),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    border :  Border.all(color: Colors.black87, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      
                      Text(
                        'يرجى العلم بأنه تعذّرت قراءة مقياس الماء الخاص بالحساب أعلاه، وذلك بسبب: $reason.\n\nوعليه، يرجى المبادرة بمراجعة دائرة الماء أو التواصل مع الجابي على رقم الهاتف الموضّح أعلاه، وذلك لتجنّب انقطاع الخدمة.\n\nشاكرين لكم حسن تعاونكم.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _printDateRow(_formattedPrintedAt),
                const SizedBox(height: 10),
                const Divider(thickness: 2, color: Colors.black),
                const Center(
                  child: Text(
                    'دائرة ماء بغداد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
    );
  }

  String get _formattedPrintedAt {
    final value = printedAt.trim();
    final parts = value.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      final timeParts = parts[1].split(':');
      if (timeParts.length >= 2) {
        return '${parts[0]} / ${timeParts[0]}:${timeParts[1]}';
      }
    }

    return value;
  }

  Widget _printDateRow(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'تاريخ ووقت الطباعة :',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 185,
              child: Text(
                title,
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                value.trim().isEmpty ? '-' : value,
                textDirection: value.contains("+964")
                ? TextDirection.ltr
                : TextDirection.rtl,
                textAlign: TextAlign.left,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
