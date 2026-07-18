import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);
 
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'username': 'Username',
      'password': 'Password',
      'login': 'LOGIN',
      'enter_username': 'Enter username',
      'enter_password': 'Enter password',
      'username_required': 'Username is required',
      'password_required': 'Password is required',
      'title': 'Water Billing Collection System',
      'subtitle': 'Billing & Collection Management System',
      'password_forgot': 'Forgot Password?',
      'version': 'Version',
      'home_title': 'Water Billing System',
     'home_subtitle': 'Billing System - Collector Panel', 
      'account_info': 'Account Information',
      'logout': 'Logout', 
      'pending': 'Pending',
      'remaining': 'Remaining',
      'completed': 'Completed',
      'collected_amount': 'Collected Amount', 
      'batch': 'Batch',
      'assigned_date': 'Assigned Date',
      'total_invoices': 'Total Invoices',
      'due_date': 'Due Date', 
      'search_invoice': 'Search by Account Number or Customer Name',
      'subscription_type': 'Subscription Type',
      'search_by_status': 'Search by Status', 
      'invoice_no': 'Invoice No',
      'account_no': 'Account No',
      'occupancy_type': 'Occupancy Type',
      'residential': 'Residential',
      'customer_name': 'Customer Name', 
      'invoice_amount': 'Invoice Amount',
      'under_collection': 'Under Collection', 
      'service_address': 'Service Address',
      'consumption': 'Consumption',
      'view': 'View',
      'print_invoice': 'Print Invoice',
      'enter_reading': 'Enter Reading',
      'print_notice': 'Print Notice',
      'unreachable': 'Unreachable', 
      'active_batch': 'Active Batch',
      'end_batch': 'End Batch',
      'search_batch': 'Search Batch',
      'batch_record': 'Batch Record',
      'no_batches_found': 'No Records Found',
        'pay_invoice' : 'Pay Now',
        'change_password':"Change Password"
    },
    'ar': {
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'enter_username': 'أدخل اسم المستخدم',
      'enter_password': 'أدخل كلمة المرور',
      'username_required': 'اسم المستخدم مطلوب',
      'password_required': 'كلمة المرور مطلوبة',
      'title': 'نظام تحصيل فواتير المياه',
      'subtitle': 'نظام إدارة الفواتير والتحصيل',
      'version': 'الإصدار',
      'password_forgot': 'هل نسيت كلمة السر؟',
      'home_title': 'نظام فوترة خدمات المياه',
      'home_subtitle': 'لوحة الجابي', 
      'account_info':'معلومات المستخدم',
      'logout': 'تسجيل الخروج', 
      'pending': 'المتعذرة',
      'remaining': 'المتبقية',
      'completed': 'المنجزة',
      'collected_amount': 'المبلغ المحصل', 
      'batch': 'السجل',
      'assigned_date': 'تاريخ الإسناد',
      'total_invoices': 'عدد الفواتير',
      'due_date': 'الموعد النهائي', 
      'search_invoice': 'بحث برقم الحساب أو اسم المشترك',
      'subscription_type': 'نوع الاشتراك',
      'search_by_status': 'البحث بالحالة', 
      'invoice_no': 'رقم الفاتورة',
      'account_no': 'رقم الحساب',
      'occupancy_type': 'نوع الإشغال',
      'residential': 'سكني',
      'customer_name': 'اسم المشترك', 
      'invoice_amount': 'قيمة الفاتورة',
      'under_collection': 'قيد التحصيل', 
      'service_address': 'عنوان الخدمة',
      'consumption': 'ك.الاستهلاك', 
      'view': 'عرض',
      'print_invoice': 'طباعة الفاتورة',
      'enter_reading': 'إدخال قراءة',
      'print_notice': 'طباعة إشعار',
      'unreachable': 'تعذر', 
      'active_batch': 'السجل النشط',
      'end_batch': 'إنهاء السجل',
      'change_password':"تغيير كلمة المرور",
      'search_batch': 'ابحث عن السجل',
      'batch_record': 'سجل دفعة',
      'no_batches_found': 'لا يوجد سجلات',
      'pay_invoice' : 'دفع'
    },
  };

  String t(String key) {
    return _values[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'ar';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
