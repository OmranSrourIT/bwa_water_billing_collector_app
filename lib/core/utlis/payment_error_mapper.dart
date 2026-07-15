class PaymentErrorMapper {
  static String getMessage(String code, String? msg) {
    switch (code) {
      case "-1":
        return "انتهى وقت العملية، يرجى المحاولة مرة أخرى";

      case "-2":
        return "تعذر التحقق من أمان الجهاز";

      case "-3":
        return "رمز تفعيل T Pay غير صحيح";

      case "-4":
        return "مشكلة في الاتصال بالسيرفر";

      case "-13":
        if (msg?.contains("151") ?? false) return "الرصيد غير كافي";

        if (msg?.contains("117") ?? false) return "الرقم السري غير صحيح";

        if (msg?.contains("123") ?? false) return "تجاوزت حد البطاقة";

        return msg.toString();

      case "-14":
        return "تم إلغاء العملية";

      case "-15":
        return msg.toString();

      case "-16":
        return "المبلغ تجاوز الحد المسموح";

      case "-17":
        return "نوع البطاقة غير مدعوم";

      case "-18":
        return "البطاقة غير صالحة أو منتهية";

      case "-19":
        return "خطأ في قراءة بيانات البطاقة";

      case "-20":
        return "تم إزالة البطاقة قبل اكتمال القراءة";

      case "-22":
        return "الجهاز غير مفعل على T Pay";

      case "-23":
        return "بيانات الدفع غير صحيحة";

      case "-100":
        return "حدث خطأ غير متوقع";

      default:
        return msg ?? "حدث خطأ أثناء الدفع";
    }
  }
}
