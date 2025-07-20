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
      version: 4, // เพิ่มเวอร์ชันเพื่ออัปเดตฐานข้อมูล
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

        // ตาราง stays (การพำนักแต่ละครั้ง)
        await db.execute('''
          CREATE TABLE stays (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            visitor_id TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            status TEXT DEFAULT 'active',
            note TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
          )
        ''');

        // สร้าง indexes
        await db.execute('CREATE INDEX idx_stays_visitor_id ON stays(visitor_id)');
        await db.execute('CREATE INDEX idx_stays_date_range ON stays(start_date, end_date)');
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
          await db.execute(
            'ALTER TABLE regs ADD COLUMN hasIdCard INTEGER DEFAULT 0',
          );
          await db.execute('ALTER TABLE regs ADD COLUMN createdAt TEXT');
          await db.execute('ALTER TABLE regs ADD COLUMN updatedAt TEXT');

          // อัปเดตข้อมูลเก่า
          final now = DateTime.now().toIso8601String();
          await db.execute(
            'UPDATE regs SET hasIdCard = 0, createdAt = ?, updatedAt = ?',
            [now, now],
          );
        }

        if (oldVersion < 4) {
          // เพิ่มตาราง stays
          await db.execute('''
            CREATE TABLE stays (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              visitor_id TEXT NOT NULL,
              start_date TEXT NOT NULL,
              end_date TEXT NOT NULL,
              status TEXT DEFAULT 'active',
              note TEXT,
              created_at TEXT DEFAULT CURRENT_TIMESTAMP,
              FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
            )
          ''');

          // สร้าง indexes
          await db.execute('CREATE INDEX idx_stays_visitor_id ON stays(visitor_id)');
          await db.execute('CREATE INDEX idx_stays_date_range ON stays(start_date, end_date)');
        }
      },
    );
  }

  // ฟังก์ชันสำหรับข้อมูลหลัก
  Future<RegData?> fetchById(String id) async {
    final res = await (await db).query(
      'regs',
      where: 'id = ?',
      whereArgs: [id],
    );
    return res.isEmpty ? null : RegData.fromMap(res.first);
  }

  Future<void> insert(RegData data) async => (await db).insert(
    'regs',
    data.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> update(RegData data) async => (await db).update(
    'regs',
    data.toMap(),
    where: 'id = ?',
    whereArgs: [data.id],
  );

  Future<List<RegData>> fetchAll() async {
    final res = await (await db).query('regs', orderBy: 'first ASC');
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  Future<List<RegData>> fetchByIdCard(bool hasIdCard) async {
    final res = await (await db).query(
      'regs',
      where: 'hasIdCard = ?',
      whereArgs: [hasIdCard ? 1 : 0],
      orderBy: 'first ASC',
    );
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  Future<void> delete(String id) async =>
      (await db).delete('regs', where: 'id = ?', whereArgs: [id]);

  // ฟังก์ชันสำหรับข้อมูลเพิ่มเติม
  Future<RegAdditionalInfo?> fetchAdditionalInfo(String regId) async {
    final res = await (await db).query(
      'reg_additional_info',
      where: 'regId = ?',
      whereArgs: [regId],
    );
    return res.isEmpty ? null : RegAdditionalInfo.fromMap(res.first);
  }

  Future<void> insertAdditionalInfo(RegAdditionalInfo data) async =>
      (await db).insert(
        'reg_additional_info',
        data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> updateAdditionalInfo(RegAdditionalInfo data) async =>
      (await db).update(
        'reg_additional_info',
        data.toMap(),
        where: 'regId = ?',
        whereArgs: [data.regId],
      );

  Future<void> deleteAdditionalInfo(String regId) async => (await db).delete(
    'reg_additional_info',
    where: 'regId = ?',
    whereArgs: [regId],
  );

  // ฟังก์ชันรวม - ดึงข้อมูลหลักและข้อมูลเพิ่มเติมพร้อมกัน
  Future<Map<String, dynamic>?> fetchCompleteData(String id) async {
    final regData = await fetchById(id);
    if (regData == null) return null;

    final additionalInfo = await fetchAdditionalInfo(id);

    return {'regData': regData, 'additionalInfo': additionalInfo};
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
  Future<void> updateAdditionalInfoFields(
    String regId,
    RegAdditionalInfo additionalInfo,
  ) async {
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

  // ฟังก์ชันสร้างข้อมูลทดสอบ
  Future<void> createTestData() async {
    final testData = RegData.manual(
      id: '1234567890123',
      first: 'ทดสอบ',
      last: 'ระบบ',
      dob: '15 มกราคม 2530',
      phone: '0812345678',
      addr: 'กรุงเทพมหานคร, เขตปทุมวัน, แขวงลุมพินี, 123/456',
      gender: 'ชาย',
    );

    await insert(testData);

    final additionalInfo = RegAdditionalInfo.create(
      regId: testData.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      shirtCount: 2,
      pantsCount: 2,
      matCount: 1,
      pillowCount: 1,
      blanketCount: 1,
      location: 'ห้อง 101',
      withChildren: false,
      notes: 'ข้อมูลทดสอบ',
    );

    await insertAdditionalInfo(additionalInfo);
  }

  // ฟังก์ชันแสดงข้อมูลทั้งหมดในฐานข้อมูล (สำหรับ Debug)
  Future<void> debugPrintAllData() async {
    final allRegs = await fetchAll();
    print('=== ข้อมูลทั้งหมดในฐานข้อมูล ===');
    for (final reg in allRegs) {
      print('ID: ${reg.id}');
      print('ชื่อ: ${reg.first} ${reg.last}');
      print('ที่อยู่: ${reg.addr}');
      print('เบอร์โทร: ${reg.phone}');
      print('---');

      final additionalInfo = await fetchAdditionalInfo(reg.id);
      if (additionalInfo != null) {
        print('ข้อมูลเพิ่มเติม:');
        print('  เสื้อ: ${additionalInfo.shirtCount}');
        print('  กางเกง: ${additionalInfo.pantsCount}');
        print('  สถานที่: ${additionalInfo.location}');
        print('  หมายเหตุ: ${additionalInfo.notes}');
      }
      print('==================');
    }
  }

  // =================== STAY MANAGEMENT METHODS ===================

  // ดึงข้อมูล Stay ล่าสุดของผู้เข้าพัก
  Future<StayRecord?> fetchLatestStay(String visitorId) async {
    final res = await (await db).query(
      'stays',
      where: 'visitor_id = ?',
      whereArgs: [visitorId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return res.isEmpty ? null : StayRecord.fromMap(res.first);
  }

  // ดึงข้อมูล Stay ทั้งหมดของผู้เข้าพัก
  Future<List<StayRecord>> fetchAllStays(String visitorId) async {
    final res = await (await db).query(
      'stays',
      where: 'visitor_id = ?',
      whereArgs: [visitorId],
      orderBy: 'created_at DESC',
    );
    return res.map((m) => StayRecord.fromMap(m)).toList();
  }

  // ดึงข้อมูล Stay ที่ยัง active
  Future<List<StayRecord>> fetchActiveStays(String visitorId) async {
    final now = DateTime.now().toIso8601String();
    final res = await (await db).query(
      'stays',
      where: 'visitor_id = ? AND end_date >= ?',
      whereArgs: [visitorId, now],
      orderBy: 'created_at DESC',
    );
    return res.map((m) => StayRecord.fromMap(m)).toList();
  }

  // เพิ่ม Stay record ใหม่
  Future<int> insertStay(StayRecord stay) async {
    return await (await db).insert('stays', stay.toMap());
  }

  // อัพเดต Stay record
  Future<void> updateStay(StayRecord stay) async {
    await (await db).update(
      'stays',
      stay.toMap(),
      where: 'id = ?',
      whereArgs: [stay.id],
    );
  }

  // ลบ Stay record
  Future<void> deleteStay(int stayId) async {
    await (await db).delete('stays', where: 'id = ?', whereArgs: [stayId]);
  }

  // ตรวจสอบสถานะการเข้าพักปัจจุบัน
  Future<Map<String, dynamic>> checkStayStatus(String visitorId) async {
    final latestStay = await fetchLatestStay(visitorId);

    if (latestStay == null) {
      return {
        'hasStay': false,
        'isActive': false,
        'canCreateNew': true,
        'latestStay': null,
      };
    }

    // ใช้ isActive method ที่แก้ไขแล้ว
    final isActive = latestStay.isActive;

    return {
      'hasStay': true,
      'isActive': isActive,
      'canCreateNew': !isActive,
      'latestStay': latestStay,
    };
  }

  // อัพเดตสถานะ Stay เป็น completed
  Future<void> completeStay(int stayId) async {
    await (await db).update(
      'stays',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [stayId],
    );
  }

  // ตรวจสอบว่ามีการจองซ้อนทับหรือไม่
  Future<bool> hasOverlappingStay(String visitorId, DateTime startDate, DateTime endDate, {int? excludeStayId}) async {
    String whereClause = 'visitor_id = ? AND ((start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?))';
    List<dynamic> whereArgs = [
      visitorId,
      startDate.toIso8601String(), startDate.toIso8601String(),
      endDate.toIso8601String(), endDate.toIso8601String(),
      startDate.toIso8601String(), endDate.toIso8601String(),
    ];

    if (excludeStayId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeStayId);
    }

    final res = await (await db).query(
      'stays',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return res.isNotEmpty;
  }
}
