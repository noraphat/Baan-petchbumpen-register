import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reg_data.dart';

class DbHelper {
  static final DbHelper _inst = DbHelper._internal();
  factory DbHelper() => _inst;
  DbHelper._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'dhamma_reg.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE regs (
            id TEXT PRIMARY KEY,
            first TEXT,
            last TEXT,
            dob TEXT,
            phone TEXT,
            addr TEXT,
            gender TEXT
          )
        ''');
      },
    );
  }

  Future<RegData?> fetchById(String id) async {
    final res = await (await db).query('regs', where: 'id = ?', whereArgs: [id]);
    return res.isEmpty ? null : RegData.fromMap(res.first);
  }

  Future<void> insert(RegData data) async =>
      (await db).insert('regs', data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}
