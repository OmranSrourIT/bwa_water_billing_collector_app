class InvoiceInformationModel {
  final String invoiceNumber;
  final DateTime? periodFromDate;
  final DateTime? periodToDate;

  final String customerName;
  final String propertyAddress;
  final String customerMobileNo;

  final String usageTypeName;
  final String invoiceTypeName;
  final String collectorName;
  final double previousReading;
  final double currentReading;

  final DateTime? currentReadDateTime;

  final double totalInvoiceAmount;
  final String totalInvoiceAmountCalculated;
  final DateTime? previousReadingDateTime;
  final String accountNo;

  final double estimatedPotableWater;
  final double estimatedRawWater;
  final double consumptionQtyRow;
  final double consumptionQtyPotable;
  final String customerID;
  final int cycleCode;

  final String region;

  final DateTime? installationDate;

  final String collectionPeriodDescription;

  final PaymentModel? payment;

  final List<InvoiceDetailModel> invoiceDetails;

  final List<FieldFailureReasonModel> failureReasons;

  final List<LookupModel> lookup;
  final String? attachment;

  InvoiceInformationModel({
    required this.invoiceNumber,
    this.periodFromDate,
    this.periodToDate,

    required this.customerName,
    required this.propertyAddress,
    required this.customerMobileNo,
    required this.usageTypeName,
    required this.invoiceTypeName,
    required this.collectorName,
    required this.previousReading,
    required this.currentReading,

    this.currentReadDateTime,

    required this.totalInvoiceAmount,
    required this.totalInvoiceAmountCalculated,
    this.previousReadingDateTime,
    required this.accountNo,

    required this.estimatedPotableWater,
    required this.estimatedRawWater,
    required this.consumptionQtyRow,
    required this.consumptionQtyPotable,
    required this.customerID,
    required this.cycleCode,
    required this.region,

    this.installationDate,

    required this.collectionPeriodDescription,

    this.payment,

    required this.invoiceDetails,

    required this.failureReasons,
    required this.lookup,
    this.attachment,
  });

  factory InvoiceInformationModel.fromJson(Map<String, dynamic> json) {
    final attachmentData = json["Attachment"];

    String? attachment;

    if (attachmentData is Map<String, dynamic>) {
      attachment =
          attachmentData["Base64"] ??
          attachmentData["url"] ??
          attachmentData["path"];
    } else if (attachmentData is String) {
      attachment = attachmentData;
    } else {
      attachment = null;
    }

    return InvoiceInformationModel(
      invoiceNumber: json["InvoiceNumber"] ?? "",

      periodFromDate: json["PeriodFromDate"] != null
          ? DateTime.tryParse(json["PeriodFromDate"])
          : null,

      periodToDate: json["PeriodToDate"] != null
          ? DateTime.tryParse(json["PeriodToDate"])
          : null,

      customerName: json["CustomerName"] ?? "",

      propertyAddress: json["PropertyAddress"] ?? "",

      customerMobileNo: json["CustomerMobileNo"] ?? "",

      usageTypeName: json["UsageTypeName"] ?? "",

      invoiceTypeName: json["InvoiceTypeName"] ?? "",

      collectorName: json["CollectorName"] ?? "",

      previousReading: (json["PreviousReading"] ?? 0).toDouble(),

      currentReading: (json["CurrentReading"] ?? 0).toDouble(),

      currentReadDateTime: json["CurrentReadDateTime"] != null
          ? DateTime.parse(json["CurrentReadDateTime"])
          : null,

      totalInvoiceAmount: (json["TotalInvoiceAmount"] ?? 0).toDouble(),

      totalInvoiceAmountCalculated: json["TotalInvoiceAmountCalculated"] ?? "",

      previousReadingDateTime: json["PreviousReadingDateTime"] != null
          ? DateTime.parse(json["PreviousReadingDateTime"])
          : null,

      accountNo: json["AccountNo"] ?? "",

      estimatedPotableWater: (json["EstimatedPotableWater"] ?? 0).toDouble(),

      estimatedRawWater: (json["EstimatedRawWater"] ?? 0).toDouble(),
      consumptionQtyPotable: (json["ConsumptionQtyPotable"] ?? 0).toDouble(),

      consumptionQtyRow: (json["ConsumptionQtyRow"] ?? 0).toDouble(),

      customerID: json["CustomerID"]?.toString() ?? "",

      cycleCode: (json["CycleCode"] ?? 0),

      region: json["Region"] ?? "",

      installationDate: json["InstallationDate"] != null
          ? DateTime.parse(json["InstallationDate"])
          : null,

      collectionPeriodDescription: json["CollectionPeriodDescription"] ?? "",

      payment: json["Payment"] != null
          ? PaymentModel.fromJson(json["Payment"])
          : null,

      invoiceDetails: (json["InvoiceDetail"] as List? ?? [])
          .map((e) => InvoiceDetailModel.fromJson(e))
          .toList(),

      failureReasons: (json["FieldFailureReason"] as List? ?? [])
          .map((e) => FieldFailureReasonModel.fromJson(e))
          .toList(),

      lookup: (json["Lookup"] as List? ?? [])
          .map((e) => LookupModel.fromJson(e))
          .toList(),

      attachment: attachment,
    );
  }
}

class InvoiceDetailModel {
  final int sequenceNo;
  final String description;
  final double amount;
  final String amountFormatted;

  InvoiceDetailModel({
    required this.sequenceNo,
    required this.description,
    required this.amount,
    required this.amountFormatted,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      sequenceNo: json["SequenceNo"] ?? 0,

      description: json["Description"] ?? "",

      amount: (json["Amount"] ?? 0).toDouble(),

      amountFormatted: json["AmountFormatted"] ?? "",
    );
  }
}

class FieldFailureReasonModel {
  final String failureReasonCode;
  final String failureNotes;
  final String? attachment;

  FieldFailureReasonModel({
    required this.failureReasonCode,
    required this.failureNotes,
    this.attachment,
  });

  factory FieldFailureReasonModel.fromJson(Map<String, dynamic> json) {
    final attachmentData = json["Attachment"];

    String? attachment;

    if (attachmentData is Map<String, dynamic>) {
      attachment =
          attachmentData["Base64"] ??
          attachmentData["url"] ??
          attachmentData["path"];
    } else if (attachmentData is String) {
      attachment = attachmentData;
    } else {
      attachment = null;
    }

    return FieldFailureReasonModel(
      failureReasonCode: json["FailureReasonCode"] ?? "",
      failureNotes: json["FailureNotes"] ?? "",
      attachment: attachment,
    );
  }
}

class LookupModel {
  final String lookupType;

  final String code;

  final String arDesc;

  final String enDesc;

  LookupModel({
    required this.lookupType,
    required this.code,
    required this.arDesc,
    required this.enDesc,
  });

  factory LookupModel.fromJson(Map<String, dynamic> json) {
    return LookupModel(
      lookupType: json["LookupType"] ?? "",

      code: json["Code"] ?? "",

      arDesc: json["ArDesc"] ?? "",

      enDesc: json["EnDesc"] ?? "",
    );
  }

  factory LookupModel.empty() {
    return LookupModel(lookupType: "", code: "", arDesc: "", enDesc: "");
  }
}

class PaymentModel {
  final int paymentRefNo;
  final DateTime? paymentDate;

  PaymentModel({required this.paymentRefNo, this.paymentDate});

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentRefNo: json["PaymentRefNo"] ?? 0,

      paymentDate: json["PaymentDate"] != null
          ? DateTime.tryParse(json["PaymentDate"])
          : null,
    );
  }
}
