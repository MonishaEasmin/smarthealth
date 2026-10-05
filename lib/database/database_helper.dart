import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_health_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        gender TEXT,
        age INTEGER,
        bloodGroup TEXT,
        height REAL,
        weight REAL,
        email TEXT UNIQUE,
        password TEXT,
        profileImage TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT,
        name TEXT,
        type TEXT,
        startDate TEXT,
        endDate TEXT,
        pillCount INTEGER,
        doseUnit TEXT,
        frequency TEXT,
        scheduleTimes TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER,
        userEmail TEXT,
        medicationName TEXT,
        dateTime TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT,
        imagePath TEXT,
        date TEXT
      )
    ''');
  }

  Future<int> registerUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('users', row);
  }

  // 🔑 প্রোফাইল আপডেট করার জন্য মিসিং মেথডটি যুক্ত করা হলো
  Future<int> updateUser(Map<String, dynamic> row, String email) async {
    final db = await instance.database;
    return await db.update(
      'users',
      row,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await instance.database;
    final res = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> deleteMedication(int id) async {
    final db = await instance.database;
    await db.delete('medication_logs', where: 'medicationId = ?', whereArgs: [id]);
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePassword(String email, String newPassword) async {
    final db = await instance.database;
    return await db.update('users', {'password': newPassword}, where: 'email = ?', whereArgs: [email]);
  }
}