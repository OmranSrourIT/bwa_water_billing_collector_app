class ApiConstants {
  static const String baseUrl = "https://bwa.asimti.iq/rest";

  static const String authToken = "/auth/v1/auth/token";
  static const String batches =
      "/collectormobileapi/v1/collectionbatch/collector";
  static String invoices(String batchId) =>
      '/collectormobileapi/v1/collectionbatch/invoices/$batchId';
  static String invoiceDetails(String invoiceNumber) =>
      '/collectormobileapi/v1/collectionbatch/Invoice/$invoiceNumber';
  static String lookupStatus(String lookupStatus) =>
      '/collectormobileapi/v1/collectionbatch/Lookup/$lookupStatus';

  static String failureReason = '/collectormobileapi/v1/collectionbatch/FailureReason';

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
  static String updateInvoiceStatus =    "/collectormobileapi/v1/collectionbatch/invoicestatus";

  //  static const currentVersion = "1.3.2";

  static String updateAppVersion(String version) => "/v1/apkRelease/$version";

  static const String payment = "/collectormobileapi/v1/collectionbatch/Payment";
}
