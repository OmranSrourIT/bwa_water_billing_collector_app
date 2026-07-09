import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();

    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, "bwa_collector.db");
    print("databasePath ${databasePath}");
    print("path ${path}");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // BATCHES
        await db.execute('''
      CREATE TABLE batches(
        batch_number TEXT PRIMARY KEY,
        assigned_date TEXT NOT NULL,
        collection_due_date TEXT NOT NULL,
        status_code TEXT NOT NULL,
        synced INTEGER DEFAULT 1
      )
    ''');

        // INVOICES

        await db.execute('''
CREATE TABLE invoices(
  invoice_no TEXT PRIMARY KEY,

  batch_number TEXT NOT NULL,

  account_no TEXT,
  customer_name TEXT,
  address TEXT,
  usage_type TEXT,
  collector_name TEXT,

  total_amount REAL,

  consumption_qty_row REAL,
  consumption_qty_potable REAL,

  is_notified INTEGER,
  is_meter_rollover INTEGER,


  -- كامل Payment Model
  payment_json TEXT,


  -- كامل Lookup List
  lookup_json TEXT,


  synced INTEGER DEFAULT 1,


  FOREIGN KEY(batch_number)
  REFERENCES batches(batch_number)
)
''');
        // INVOICE DETAILS

        await db.execute('''
      CREATE TABLE invoice_details(
        invoice_no TEXT PRIMARY KEY,

        period_from_date TEXT,
        period_to_date TEXT,

        customer_name TEXT,
        property_address TEXT,
        customer_mobile_no TEXT,

        usage_type_name TEXT,
        invoice_type_name TEXT,
        collector_name TEXT,

        previous_reading REAL,
        current_reading REAL,

        current_read_date_time TEXT,
        previous_reading_date_time TEXT,

        total_invoice_amount REAL,
        total_invoice_amount_calculated TEXT,

        account_no TEXT,

        estimated_potable_water REAL,
        estimated_raw_water REAL,

        consumption_qty_row REAL,
        consumption_qty_potable REAL,

        customer_id TEXT,
        cycle_code INTEGER,

        region TEXT,
        installation_date TEXT,

        collection_period_description TEXT,

        payment_ref_no INTEGER,
        payment_date TEXT,

        

         invoice_details_json TEXT,

         failure_reasons_json TEXT,

         lookup_json TEXT,
         
         

        synced INTEGER DEFAULT 1
      )
    ''');

        await db.execute('''
CREATE TABLE invoice_attachments(

 id INTEGER PRIMARY KEY AUTOINCREMENT,

 invoice_no TEXT NOT NULL,

 type TEXT NOT NULL,

 attachment TEXT

)
''');

        // UNREACHABLE (تعذر القراءة)
        await db.execute('''
      CREATE TABLE unreachable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        invoice_no TEXT NOT NULL,

        failure_reason_code TEXT,
        failure_reason TEXT,
        failure_notes TEXT,

        attachment TEXT,

        created_at TEXT,

        synced INTEGER DEFAULT 0
      )
    ''');

        await db.execute('''
CREATE TABLE lookups(

  id INTEGER PRIMARY KEY AUTOINCREMENT,

  lookup_type TEXT NOT NULL,

  code TEXT NOT NULL,

  ar_desc TEXT,

  en_desc TEXT,

  order_no INTEGER,

  UNIQUE(lookup_type, code)

)
''');

        // SYNC QUEUE

        await db.execute('''
      CREATE TABLE sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        type TEXT NOT NULL,

        reference_no TEXT NOT NULL,

        payload TEXT NOT NULL,

        status TEXT DEFAULT 'pending',

        retries INTEGER DEFAULT 0,

        created_at TEXT
      )
    ''');
      },
    );
  }
}
