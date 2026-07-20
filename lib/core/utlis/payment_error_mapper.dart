class PaymentErrorMapper {
  static String getMessage(String code, String? msg) {
    switch (code) {
      case "-1":
        return "انتهى مهلة العملية، يرجى المحاولة مرة أخرى";

      case "-2":
        return "تعذر التحقق من أمان الجهاز";

      case "-3":
        return "رمز تفعيل T Pay غير صحيح";

      case "-4":
        return "يرجى التحقق من الإتصال والمحاولة مرة اخرى";

      case "-13":
        if (msg?.contains("116") ?? false) return "تعذر إتمام عملية الدفع لعدم كفاية الرصيد في البطاقة";

        if (msg?.contains("117") ?? false) return "الرقم السري للبطاقة غير صحيح. يُرجى التحقق منه وإعادة المحاولة.";

        if (msg?.contains("123") ?? false) return "تم تجاوز الحد المسموح للبطاقة";

        return msg.toString();

      case "-14":
        return "تم إلغاء العملية";

      case "-15":
        return "لا يمكن تنفيذ عملية الدفع اثناء إتصال جهاز الدفع عبر ال USB , يرجى فصل الإتصال ثم إعادة المحاولة";

      case "-16":
        return "المبلغ تجاوز الحد المسموح";

      case "-17":
        return "نوع البطاقة غير مدعوم";

      case "-18":
        return "البطاقة غير صالحة أو منتهية الصلاحية";

      case "-19":
        return "تعذر قراءه بيانات البطاقة";

      case "-20":
        return "تم إزالة البطاقة قبل اكتمال عملية القراءة";

      case "-22":
        return "الجهاز غير مفعل على T Pay";

      case "-23":
        return "بيانات الدفع غير صحيحة";

      case "-100":
        return "حدث خطأ غير متوقع اثناء الدفع";

      default:
        return msg ?? "حدث خطأ أثناء الدفع";
    }
  }
}
