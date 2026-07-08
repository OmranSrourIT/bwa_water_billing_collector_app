class AccountModel {
  final String firstNameAr;
  final String fatherNameAr;
  final String grandfatherNameAr;
  final String familyNameAr;

  final String firstNameEn;
  final String fatherNameEn;
  final String grandfatherNameEn;
  final String familyNameEn;

  final String username;
  final String email;

  final String nationalId;
  final String phone;
  final String countryCode;

  final String unifiedCardNo;
  final String nationalNumber;

  AccountModel({
    required this.firstNameAr,
    required this.fatherNameAr,
    required this.grandfatherNameAr,
    required this.familyNameAr,

    required this.firstNameEn,
    required this.fatherNameEn,
    required this.grandfatherNameEn,
    required this.familyNameEn,

    required this.username,
    required this.email,

    required this.nationalId,
    required this.phone,
    required this.countryCode,

    required this.unifiedCardNo,
    required this.nationalNumber,
  });
}
