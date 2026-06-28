import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notification_log.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sigapin_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notification_logs(
            id INTEGER PRIMARY KEY,
            judul TEXT,
            isi_pesan TEXT,
            tipe TEXT,
            gambar_url TEXT,
            sent_by TEXT,
            is_read INTEGER,
            created_at TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveLogs(List<NotificationLog> logs) async {
    final db = await database;
    final batch = db.batch();
    for (var log in logs) {
      batch.insert(
        'notification_logs',
        {
          'id': log.id,
          'judul': log.judul,
          'isi_pesan': log.isiPesan,
          'tipe': log.tipe,
          'gambar_url': log.gambarUrl,
          'sent_by': log.sentBy,
          'is_read': log.isRead ? 1 : 0,
          'created_at': log.createdAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<NotificationLog>> getLogs({int limit = 20, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notification_logs',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) {
      return NotificationLog(
        id: maps[i]['id'],
        judul: maps[i]['judul'],
        isiPesan: maps[i]['isi_pesan'],
        tipe: maps[i]['tipe'],
        gambarUrl: maps[i]['gambar_url'],
        sentBy: maps[i]['sent_by'],
        isRead: maps[i]['is_read'] == 1,
        createdAt: maps[i]['created_at'] != null ? DateTime.parse(maps[i]['created_at']) : null,
      );
    });
  }

  static Future<void> markAsRead(int id) async {
    final db = await database;
    await db.update(
      'notification_logs',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('notification_logs');
  }
}
