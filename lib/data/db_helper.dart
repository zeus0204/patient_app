import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Singleton class for DBHelper
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'healthcare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create 'users' table
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullName TEXT,
            email TEXT UNIQUE,
            phoneNumber TEXT,
            password TEXT
          )
        ''');

        // Create 'user_info' table with a foreign key reference to 'users.id'
        await db.execute('''
          CREATE TABLE user_info (
            id INTEGER PRIMARY KEY,
            user_id INTEGER, -- Foreign Key linked to users.id
            address TEXT,
            contact TEXT,
            birthday TEXT,
            avatar_url TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE medical_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER, -- Foreign Key linked to users.id
            title TEXT,
            subtitle TEXT,
            description TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            doctor_id INTEGER,
            hospital_id INTEGER,
            day TEXT,
            time TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (doctor_id) REFERENCES doctors (id),
            FOREIGN KEY (hospital_id) REFERENCES hospitals (id)
          )
        ''');
      },
    );
  }


  // Insert user data
  Future<void> insertUser(Map<String, dynamic> userData) async {
    final db = await database;
    try {
      await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if(e is DatabaseException && e.isUniqueConstraintError()) {
        throw Exception('Email already exists. Please use a different email');
      }
      else {
        throw Exception('An error occirred while inserting the user');
      }
    }
  }
  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }
  Future<Map<String, dynamic>?> getUserInfoByUserId(int userId) async {
  final db = await database; // Assume `database` initializes your SQLite instance
  final result = await db.query(
    'user_info', // Replace with your actual table name
    where: 'user_id = ?',
    whereArgs: [userId],
  );
  return result.isNotEmpty ? result.first : null; // Return the first record if found
}

  Future<void> updateUser({
    required int id,
    String? fullName,
    String? phoneNumber,
  }) async {
    final db = await database;

    // Only update fields if they are not null
    Map<String, dynamic> updatedUserData = {};
    if (fullName != null) updatedUserData['fullName'] = fullName;
    if (phoneNumber != null) updatedUserData['phoneNumber'] = phoneNumber;

    if (updatedUserData.isNotEmpty) {
      await db.update(
        'users',
        updatedUserData,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> upsertUserInfo({
    required int userId,
    String? address,
    String? contact,
    DateTime? birthday,
  }) async {
    final db = await database;

    // Prepare the updated user info
    Map<String, dynamic> updatedUserInfoData = {};
    if (address != null) updatedUserInfoData['address'] = address;
    if (contact != null) updatedUserInfoData['contact'] = contact;
    if (birthday != null) updatedUserInfoData['birthday'] = birthday.toIso8601String();

    if (updatedUserInfoData.isNotEmpty) {
      // Check if a UserInfo entry already exists for the user
      final existingRecord = await db.query(
        'user_info',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (existingRecord.isNotEmpty) {
        // Update existing record
        await db.update(
          'user_info',
          updatedUserInfoData,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      } else {
        // Insert new record if it doesn't exist
        await db.insert(
          'user_info',
          {
            'user_id': userId,
            ...updatedUserInfoData,
          },
        );
      }
    }
  }

  // Insert a medical history record
  Future<void> insertMedicalHistory(Map<String, dynamic> medicalHistory) async {
    final db = await database;
    await db.insert('medical_history', medicalHistory);
  }

  // Fetch all medical history records for a user
  Future<List<Map<String, dynamic>>> getMedicalHistoryByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'medical_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Delete a medical history record
  Future<void> deleteMedicalHistory(int id) async {
    final db = await database;
    await db.delete(
      'medical_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMedicalHistory(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'medical_history',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertAppointment(Map<String, dynamic> appointmentData) async {
    final db = await database;
    await db.insert('appointments', appointmentData);
  }

  // Fetch appointments for a specific patient
  Future<List<Map<String, dynamic>>> getAppointmentsByPatientId(int patientId) async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'user_id = ?',
      whereArgs: [patientId],
    );
  }

  Future<List<Map<String, dynamic>>> getAppointmentsById(int id) async {
    final db = await database;
    return await db.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getUserIdByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id'], // Only fetch the 'id' column
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int; // Return the userId
    }
    return null; // Return null if the email doesn't exist
  }

  Future<void> deleteAppointment(int appointmentId) async {
    final db = await database;
    await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<void> updateAppointment(int id, Map<String, dynamic> updatedData) async {
    final db = await database;
    await db.update(
      'appointments',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
