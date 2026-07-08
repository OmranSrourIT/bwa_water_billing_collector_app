import 'invoice_status.dart';

class InvoiceModel {
  final String invoiceNo;
  final String accountNo;
  final String customerName;
  final String address;
  final String usageType;
  final String collectorName;
  final double totalAmount;
  final bool isNotified;
  final bool isMeterRollover;
  final double consumptionQtyRow; 
  final double consumptionQtyPotable;
  final PaymentModel? payment;
  final List<LookupModelParent> lookup;
  

  InvoiceModel({
    required this.invoiceNo,
    required this.accountNo,
    required this.customerName,
    required this.address,
    required this.usageType,
    required this.totalAmount,
    required this.isNotified,
    required this.isMeterRollover,
        this.payment,
    required this.lookup,
    required this.consumptionQtyRow,
    this.consumptionQtyPotable = 0.0,
    required this.collectorName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceNo: json["InvoiceNumber"] ?? "",

      accountNo: json["AccountNo"] ?? "",

      customerName: json["CustomerName"] ?? "",

      address: json["PropertyAddress"] ?? "",

      usageType: json["UsageTypeName"] ?? "",

      collectorName: json["CollectorName"] ?? "",
      
      consumptionQtyRow: (json["ConsumptionQtyRow"] ?? 0).toDouble(),

      consumptionQtyPotable: (json["ConsumptionQtyPotable"] ?? 0).toDouble(),

      totalAmount: (json["TotalInvoiceAmount"] ?? 0).toDouble(),

      isNotified: json["IsNotified"] ?? false,

      isMeterRollover: json["IsMeterRollover"] ?? false,

         payment: json["Payment"] != null
          ? PaymentModel.fromJson(json["Payment"])
          : null,

      lookup: (json["Lookup"] as List? ?? [])
          .map((e) => LookupModelParent.fromJson(e))
          .toList(),
    );
  }
}

class LookupModelParent {
  final String lookupType;

  final String code;

  final String arDesc;

  final String enDesc;

  LookupModelParent({
    required this.lookupType,
    required this.code,
    required this.arDesc,
    required this.enDesc,
  });

  factory LookupModelParent.fromJson(Map<String, dynamic> json) {
    return LookupModelParent(
      lookupType: json["LookupType"] ?? "",

      code: json["Code"] ?? "",

      arDesc: json["ArDesc"] ?? "",

      enDesc: json["EnDesc"] ?? "",
    );
  }

  factory LookupModelParent.empty() {
    return LookupModelParent(lookupType: "", code: "", arDesc: "", enDesc: "");
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
