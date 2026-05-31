import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  static Database? _db;

  DatabaseService._();

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'docscan.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE documents (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          title          TEXT    NOT NULL,
          created_at     TEXT    NOT NULL,
          page_count     INTEGER NOT NULL,
          pdf_path       TEXT    NOT NULL,
          thumbnail_path TEXT,
          image_paths    TEXT
        )
      '''),
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE documents ADD COLUMN image_paths TEXT');
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAll() async =>
      (await db).query('documents', orderBy: 'created_at DESC');

  Future<int> insertDoc({
    required String title,
    required int pageCount,
    required String pdfPath,
    String? thumbnailPath,
    List<String> imagePaths = const [],
  }) async {
    return (await db).insert('documents', {
      'title': title,
      'created_at': DateTime.now().toIso8601String(),
      'page_count': pageCount,
      'pdf_path': pdfPath,
      'thumbnail_path': thumbnailPath,
      'image_paths': jsonEncode(imagePaths),
    });
  }

  Future<int> updateDoc({
    required int id,
    required String title,
    required int pageCount,
    required String pdfPath,
    String? thumbnailPath,
    List<String> imagePaths = const [],
  }) async {
    return (await db).update(
      'documents',
      {
        'title': title,
        'created_at': DateTime.now().toIso8601String(),
        'page_count': pageCount,
        'pdf_path': pdfPath,
        'thumbnail_path': thumbnailPath,
        'image_paths': jsonEncode(imagePaths),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async =>
      (await db).delete('documents', where: 'id = ?', whereArgs: [id]);
}
