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
      version: 3, // เพิ่มเวอร์ชันเพื่ออัปเดตฐานข้อมูล
      onCreate: (db, _) async {
        // ตารางข้อมูลหลัก
        await db.execute('''
          CREATE TABLE regs (
            id TEXT PRIMARY KEY,
            first TEXT,
            last TEXT,
            dob TEXT,
            phone TEXT,
            addr TEXT,
            gender TEXT,
            hasIdCard INTEGER,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');
        
        // ตารางข้อมูลเพิ่มเติม
        await db.execute('''
          CREATE TABLE reg_additional_info (
            regId TEXT PRIMARY KEY,
            startDate TEXT,
            endDate TEXT,
            shirtCount INTEGER,
            pantsCount INTEGER,
            matCount INTEGER,
            pillowCount INTEGER,
            blanketCount INTEGER,
            location TEXT,
            withChildren INTEGER,
            childrenCount INTEGER,
            notes TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // เพิ่มตารางใหม่สำหรับข้อมูลเพิ่มเติม
          await db.execute('''
            CREATE TABLE reg_additional_info (
              regId TEXT PRIMARY KEY,
              startDate TEXT,
              endDate TEXT,
              shirtCount INTEGER,
              pantsCount INTEGER,
              matCount INTEGER,
              pillowCount INTEGER,
              blanketCount INTEGER,
              location TEXT,
              withChildren INTEGER,
              childrenCount INTEGER,
              notes TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE
            )
          ''');
        }
        
        if (oldVersion < 3) {
          // เพิ่มคอลัมน์ใหม่ในตาราง regs
          await db.execute('ALTER TABLE regs ADD COLUMN hasIdCard INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE regs ADD COLUMN createdAt TEXT');
          await db.execute('ALTER TABLE regs ADD COLUMN updatedAt TEXT');
          
          // อัปเดตข้อมูลเก่า
          final now = DateTime.now().toIso8601String();
          await db.execute('UPDATE regs SET hasIdCard = 0, createdAt = ?, updatedAt = ?', [now, now]);
        }
      },
    );
  }

  // ฟังก์ชันสำหรับข้อมูลหลัก
  Future<RegData?> fetchById(String id) async {
    final res = await (await db).query('regs', where: 'id = ?', whereArgs: [id]);
    return res.isEmpty ? null : RegData.fromMap(res.first);
  }

  Future<void> insert(RegData data) async =>
      (await db).insert('regs', data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> update(RegData data) async =>
      (await db).update('regs', data.toMap(), where: 'id = ?', whereArgs: [data.id]);

  Future<List<RegData>> fetchAll() async {
    final res = await (await db).query('regs', orderBy: 'first ASC');
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  Future<List<RegData>> fetchByIdCard(bool hasIdCard) async {
    final res = await (await db).query(
      'regs', 
      where: 'hasIdCard = ?', 
      whereArgs: [hasIdCard ? 1 : 0],
      orderBy: 'first ASC'
    );
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  Future<void> delete(String id) async =>
      (await db).delete('regs', where: 'id = ?', whereArgs: [id]);

  // ฟังก์ชันสำหรับข้อมูลเพิ่มเติม
  Future<RegAdditionalInfo?> fetchAdditionalInfo(String regId) async {
    final res = await (await db).query('reg_additional_info', where: 'regId = ?', whereArgs: [regId]);
    return res.isEmpty ? null : RegAdditionalInfo.fromMap(res.first);
  }

  Future<void> insertAdditionalInfo(RegAdditionalInfo data) async =>
      (await db).insert('reg_additional_info', data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateAdditionalInfo(RegAdditionalInfo data) async =>
      (await db).update('reg_additional_info', data.toMap(), where: 'regId = ?', whereArgs: [data.regId]);

  Future<void> deleteAdditionalInfo(String regId) async =>
      (await db).delete('reg_additional_info', where: 'regId = ?', whereArgs: [regId]);

  // ฟังก์ชันรวม - ดึงข้อมูลหลักและข้อมูลเพิ่มเติมพร้อมกัน
  Future<Map<String, dynamic>?> fetchCompleteData(String id) async {
    final regData = await fetchById(id);
    if (regData == null) return null;
    
    final additionalInfo = await fetchAdditionalInfo(id);
    
    return {
      'regData': regData,
      'additionalInfo': additionalInfo,
    };
  }

  // ฟังก์ชันสำหรับการแก้ไขข้อมูล
  Future<void> updateEditableFields(String id, {String? phone}) async {
    final data = await fetchById(id);
    if (data == null) return;

    final updatedData = data.copyWithEditable(phone: phone);
    await update(updatedData);
  }

  Future<void> updateAllFields(RegData data) async {
    final updatedData = data.copyWithAll(updatedAt: DateTime.now());
    await update(updatedData);
  }

  // ฟังก์ชันสำหรับการแก้ไขข้อมูลเพิ่มเติม
  Future<void> updateAdditionalInfoFields(String regId, RegAdditionalInfo additionalInfo) async {
    final updatedInfo = additionalInfo.copyWith(updatedAt: DateTime.now());
    await updateAdditionalInfo(updatedInfo);
  }

  // ฟังก์ชันล้างข้อมูลทั้งหมด (สำหรับ Debug)
  Future<void> clearAllData() async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('reg_additional_info');
      await txn.delete('regs');
    });
  }
}
