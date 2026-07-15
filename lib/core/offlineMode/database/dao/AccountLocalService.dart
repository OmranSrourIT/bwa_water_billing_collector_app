import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/Account/model/account_model.dart';
import 'package:sqflite/sqflite.dart';

class AccountLocalService {
  final AppDatabase db;

  AccountLocalService(this.db);

  Future<void> saveAccount(AccountModel account) async {
    final database = await db.database;

    await database.insert(
      "account",
      {
        "username": account.username,

        "first_name_ar": account.firstNameAr,
        "father_name_ar": account.fatherNameAr,
        "grandfather_name_ar": account.grandfatherNameAr,
        "family_name_ar": account.familyNameAr,

        "first_name_en": account.firstNameEn,
        "father_name_en": account.fatherNameEn,
        "grandfather_name_en": account.grandfatherNameEn,
        "family_name_en": account.familyNameEn,

        "email": account.email,

        "national_id": account.nationalId,
        "phone": account.phone,
        "country_code": account.countryCode,

        "unified_card_no": account.unifiedCardNo,
        "national_number": account.nationalNumber,

        "synced": 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AccountModel> getAccount() async {
    final database = await db.database;

    final result = await database.query(
      "account",
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception("No account found");
    }

    final json = result.first;

    return AccountModel(
      firstNameAr: json["first_name_ar"] as String? ?? "",
      fatherNameAr: json["father_name_ar"] as String? ?? "",
      grandfatherNameAr: json["grandfather_name_ar"] as String? ?? "",
      familyNameAr: json["family_name_ar"] as String? ?? "",

      firstNameEn: json["first_name_en"] as String? ?? "",
      fatherNameEn: json["father_name_en"] as String? ?? "",
      grandfatherNameEn: json["grandfather_name_en"] as String? ?? "",
      familyNameEn: json["family_name_en"] as String? ?? "",

      username: json["username"] as String? ?? "",
      email: json["email"] as String? ?? "",

      nationalId: json["national_id"] as String? ?? "",
      phone: json["phone"] as String? ?? "",
      countryCode: json["country_code"] as String? ?? "",

      unifiedCardNo: json["unified_card_no"] as String? ?? "",
      nationalNumber: json["national_number"] as String? ?? "",
    );
  }
}
