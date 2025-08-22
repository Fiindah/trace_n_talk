// database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Pola Singleton untuk memastikan hanya ada satu instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Menginisialisasi database
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mandarin_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE character_results(id INTEGER PRIMARY KEY AUTOINCREMENT, character TEXT, isCorrect INTEGER, date TEXT)',
        );
      },
    );
  }

  // Menambahkan data hasil tulisan ke database
  Future<int> insertResult(Map<String, dynamic> result) async {
    final db = await database;
    return await db.insert(
      'character_results',
      result,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Mengambil semua data hasil tulisan dari database
  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;
    return await db.query('character_results', orderBy: 'date DESC');
  }
}
