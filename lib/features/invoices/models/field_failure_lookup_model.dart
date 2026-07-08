class FieldFailureLookupModel {

  final String code;
  final String arDesc;
  final String enDesc;
  final int? order;


  FieldFailureLookupModel({
    required this.code,
    required this.arDesc,
    required this.enDesc,
    this.order,
  });



  factory FieldFailureLookupModel.fromJson(
      Map<String, dynamic> json) {

    return FieldFailureLookupModel(

      code: json["Code"] ?? "",

      arDesc: json["ArDesc"] ?? "",

      enDesc: json["EnDesc"] ?? "",
      order: json["Order"] ?? "",

    );

  }


  factory FieldFailureLookupModel.empty(){

    return FieldFailureLookupModel(
      code: "",
      arDesc: "",
      enDesc: "",
      order: null,
    );

  }

}
