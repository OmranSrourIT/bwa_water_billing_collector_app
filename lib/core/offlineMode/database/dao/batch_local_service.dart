 
import 'package:bwa_water_billing_collector_app/core/offlineMode/database/app_database.dart';
import 'package:bwa_water_billing_collector_app/features/batch/models/batch_model.dart';
import 'package:sqflite/sqflite.dart';

class BatchLocalService {

  final AppDatabase db;

  BatchLocalService(this.db);

 
  Future<void> insertBatches(List<BatchModel> batches) async {

    final database = await db.database;  
    final batch = database.batch();  
    for(final item in batches){

      batch.insert(
        "batches",
        {
          "batch_number": item.batchNumber,
          "assigned_date": item.assignedDate.toIso8601String(),
          "collection_due_date": item.collectionDueDate.toIso8601String(),
          "status_code": item.statusCode,
          "synced": 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

    } 
    await batch.commit(noResult: true);
  }



  Future<List<BatchModel>> getAllBatches() async {

    final database = await db.database;


    final result = await database.query(
      "batches",
      orderBy: "assigned_date DESC",
    );


    return result.map((json){

      return BatchModel(
        batchNumber: json["batch_number"] as String,
        assignedDate: DateTime.parse(
          json["assigned_date"] as String,
        ),
        collectionDueDate: DateTime.parse(
          json["collection_due_date"] as String,
        ),
        statusCode: json["status_code"] as String,
      );

    }).toList();

  }



  Future<void> deleteAllBatches() async {

    final database = await db.database;

    await database.delete("batches");

  }


}
