import 'dart:ui';
import 'package:bwa_water_billing_collector_app/core/widgets/app_alert.dart';
import 'package:bwa_water_billing_collector_app/core/widgets/parseError.dart';
import 'package:bwa_water_billing_collector_app/features/Account/provider/account_provider.dart';
import 'package:flutter/material.dart';
import 'package:bwa_water_billing_collector_app/core/constants/AppColors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/account_model.dart';

class AccountDetailsDialog extends ConsumerWidget {
  const AccountDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: accountAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
          error: (error, stack) {
        final message = parseError(error);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppPopupAlert.show(context, message: message, isError: true);
        });

        return const SizedBox();
      },
        data: (account) {
          return _buildDialog(context, account);
        },
      ),
    );
  }

  Container _buildDialog(BuildContext context, AccountModel account) {
    return Container(
      width: 780,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [
            const Color(0xff27A9E1).withOpacity(0.16),
            const Color(0xff2F318B).withOpacity(0.08),
            Colors.white.withOpacity(0.97),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context),

                const SizedBox(height: 14),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _sectionTitle("البيانات الشخصية"),
                        _row([
                          _field("الاسم الأول عربي", account.firstNameAr),
                          _field("اسم الأب عربي", account.fatherNameAr),
                          _field("اسم الجد عربي", account.grandfatherNameAr),
                          _field("اللقب عربي", account.familyNameAr),
                        ]),
                        const SizedBox(height: 12),

                        // _row([
                        //   _field("الأسم الأول  انجليزي", account.firstNameEn),
                        //   _field("اسم الأب انجليزي", account.fatherNameEn),
                        //   _field("اسم الجد انجليزي", account.grandfatherNameEn),
                        //   _field("اللقب انجليزي", account.familyNameEn),
                        // ]),
                        const SizedBox(height: 12),
                        _sectionTitle("معلومات الإتصال"),
                        _row([
                          _field("اسم المستخدم", account.username),
                          _field("رقم الهاتف", "${account.phone}"),
                          _field("البريد الإلكتروني", account.email),
                     
                        ]),

                        // const SizedBox(height: 12),

                        // _sectionTitle("معلومات الهوية"),
                        // _row([
                        //   _field("رقم البطاقة الموحدة", account.nationalNumber),
                        //   _field("الرقم الوظيفي", account.nationalId),
                        // ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "إغلاق",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= HEADER (أفخم شوي بدون تغيير الشكل) =================
  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff2F318B), Color(0xff27A9E1)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white),
          const SizedBox(width: 10),
          const Text(
         "معلومات المستخدم",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

Widget _row(List<Widget> children) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return Row(
        // textDirection: TextDirection.rtl,
        children: children
            .map(
              (e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: e,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

Widget _field(String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.withOpacity(0.10)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            value.isEmpty  ? "-"  : value.endsWith("+") ? "+${value.substring(0, value.length - 1)}"
                : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 10),

    child: Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
