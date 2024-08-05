import 'package:sqflite/sqflite.dart';

import 'note.dart';

class NotesDatabase {
  static final _name = "NotesDatabase.db";
  static final _version = 1;

  Database? _database; // Database is now nullable
  static final tableName = 'notes';

  Future<void> initDatabase() async {
    _database = await openDatabase(
      _name,
      version: _version,
      onCreate: (Database db, int version) async {
        await db.execute(
          '''CREATE TABLE $tableName (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          content TEXT,
          noteColor TEXT
          )'''
        );
      },
    );
  }

  Future<int> insertNote(Note note) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.insert(
      tableName,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateNote(Note note) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.update(
      tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.query(tableName);
  }

  Future<Map<String, dynamic>?> getNotes(int id) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    var result = await _database!.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;
  }

  Future<int> deleteAllNotes() async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.delete(tableName);
  }

  Future<int> deleteNote(int id) async {
    if (_database == null) {
      throw Exception('Database not initialized');
    }
    return await _database!.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null; // Ensure the database reference is cleared
    }
  }
}
