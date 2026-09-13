class ApiConstants {
  static const String baseUrl = "https://stgbwa.asimti.iq/rest";
    static const String baseUrlQR = "https://stgbwa.asimti.iq";

  //ProdIraq   ===> https://bwa.asimti.iq
  //Stage Iraq ===> https://stgbwa.asimti.iq
  //Dev Amman ===> https://bwa.infinite-tek.com:8443
  //Test Amman ===> http://149.200.251.200:9090

   static String get environment {
  if (baseUrl.contains("stgbwa.asimti.iq")) {
    return "STAGE";
  }

  if (baseUrl.contains("bwa.asimti.iq")) {
    return "PROD";
  }

  if (baseUrl.contains("bwa.infinite-tek.com")) {
    return "DEV";
  }

  if (baseUrl.contains("149.200.251.200")) {
    return "TEST";
  }

  return "UNKNOWN";
}
  static String get environmentLabel {
    switch (environment) {
      case "PROD":
        return "Production";
         case "STAGE":
          return "STAGE";
      case "DEV":
        return "Development";
      case "TEST":
        return "Testing";
      default:
        return "UNKNOWN";
    }
  }


  static const String authToken = "/auth/v1/auth/token";
  static const String batches =
      "/collectormobileapi/v1/collectionbatch/collector";
  static String invoices(String batchId) =>
      '/collectormobileapi/v1/collectionbatch/invoices/$batchId';
  static String invoiceDetails(String invoiceNumber) =>
      '/collectormobileapi/v1/collectionbatch/Invoice/$invoiceNumber';
  static String lookupStatus(String lookupStatus) =>
      '/collectormobileapi/v1/collectionbatch/Lookup/$lookupStatus';

  static String failureReason =
      '/collectormobileapi/v1/collectionbatch/FailureReason';

  static String insertReading =
      "/collectormobileapi/v1/collectionbatch/InsertReading";

  static const String endBatch =
      "/collectormobileapi/v1/collectionbatch/EndBatch";

  static String updateNoticePrint =
      "/collectormobileapi/v1/collectionbatch/UpdateNoticePrint";

  static const accountDetail = "/collectormobileapi/v1/AccountDetail";

  static const changePassword =
      "/collectormobileapi/v1/AccountDetail/ChangePassword";

  static const forgotPassword = "/v1/ForgetPassword";
  static String updateInvoiceStatus =
      "/collectormobileapi/v1/collectionbatch/invoicestatus";

  //  static const currentVersion = "1.3.2";

  static String updateAppVersion(String version) => "/v1/apkRelease/$version";

  static const String payment =
      "/collectormobileapi/v1/collectionbatch/Payment";

      
   static String verofNumberPrintNotice(String Number) => "/#/viewpayment/${Number}";
   static const String insertLocation =
    "/collectormobileapi/v1/collectionbatch/coordinates";
}
