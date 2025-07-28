import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/reg_data.dart';
import '../models/room_model.dart';

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
      version: 8, // เพิ่มเวอร์ชันเพื่ออัปเดตฐานข้อมูล
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
            status TEXT DEFAULT 'A',
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        // ตารางข้อมูลเพิ่มเติม - ปรับใหม่ให้รองรับหลาย registration ต่อคน
        await db.execute('''
          CREATE TABLE reg_additional_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            regId TEXT NOT NULL,
            visitId TEXT NOT NULL,
            startDate TEXT,
            endDate TEXT,
            shirtCount INTEGER DEFAULT 0,
            pantsCount INTEGER DEFAULT 0,
            matCount INTEGER DEFAULT 0,
            pillowCount INTEGER DEFAULT 0,
            blanketCount INTEGER DEFAULT 0,
            location TEXT,
            withChildren INTEGER DEFAULT 0,
            childrenCount INTEGER DEFAULT 0,
            notes TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE,
            UNIQUE(regId, visitId)
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

        // ตาราง app_settings (สำหรับ menu visibility และการตั้งค่าระบบ)
        await db.execute('''\n          CREATE TABLE app_settings (\n            key TEXT PRIMARY KEY,\n            value TEXT NOT NULL,\n            updated_at TEXT DEFAULT CURRENT_TIMESTAMP\n          )\n        ''');

        // ตาราง maps (ข้อมูลแผนที่)
        await db.execute('''
          CREATE TABLE maps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            image_path TEXT,
            image_width REAL,
            image_height REAL,
            is_active INTEGER DEFAULT 0,
            description TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // ตาราง rooms (ข้อมูลห้องพัก)
        await db.execute('''
          CREATE TABLE rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            size TEXT NOT NULL,
            capacity INTEGER NOT NULL,
            position_x REAL,
            position_y REAL,
            status TEXT DEFAULT 'available',
            description TEXT,
            current_occupant TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (current_occupant) REFERENCES regs (id) ON DELETE SET NULL
          )
        ''');

        // ตาราง room_bookings (การจองห้องพัก - สำหรับอนาคต)
        await db.execute('''
          CREATE TABLE room_bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            visitor_id TEXT NOT NULL,
            check_in_date TEXT NOT NULL,
            check_out_date TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
            FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
          )
        ''');

        // สร้าง indexes สำหรับตารางใหม่
        await db.execute('CREATE INDEX idx_rooms_status ON rooms(status)');
        await db.execute('CREATE INDEX idx_rooms_position ON rooms(position_x, position_y)');
        await db.execute('CREATE INDEX idx_room_bookings_room_id ON room_bookings(room_id)');
        await db.execute('CREATE INDEX idx_room_bookings_visitor_id ON room_bookings(visitor_id)');
        await db.execute('CREATE INDEX idx_room_bookings_dates ON room_bookings(check_in_date, check_out_date)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // เพิ่มตารางใหม่สำหรับข้อมูลเพิ่มเติม (เวอร์ชันเก่า)
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
        
        if (oldVersion < 7) {
          // ปรับปรุงโครงสร้าง reg_additional_info ให้รองรับหลาย visit ต่อคน
          
          // 1. Backup ข้อมูลเก่า
          await db.execute('''
            CREATE TABLE reg_additional_info_backup AS 
            SELECT * FROM reg_additional_info
          ''');
          
          // 2. ลบตารางเก่า
          await db.execute('DROP TABLE reg_additional_info');
          
          // 3. สร้างตารางใหม่
          await db.execute('''
            CREATE TABLE reg_additional_info (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              regId TEXT NOT NULL,
              visitId TEXT NOT NULL,
              startDate TEXT,
              endDate TEXT,
              shirtCount INTEGER DEFAULT 0,
              pantsCount INTEGER DEFAULT 0,
              matCount INTEGER DEFAULT 0,
              pillowCount INTEGER DEFAULT 0,
              blanketCount INTEGER DEFAULT 0,
              location TEXT,
              withChildren INTEGER DEFAULT 0,
              childrenCount INTEGER DEFAULT 0,
              notes TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE,
              UNIQUE(regId, visitId)
            )
          ''');
          
          // 4. Migrate ข้อมูลเก่าโดยสร้าง visitId จาก timestamp
          await db.execute('''
            INSERT INTO reg_additional_info 
            (regId, visitId, startDate, endDate, shirtCount, pantsCount, 
             matCount, pillowCount, blanketCount, location, withChildren, 
             childrenCount, notes, createdAt, updatedAt)
            SELECT 
              regId, 
              regId || '_' || COALESCE(createdAt, datetime('now')) as visitId,
              startDate, endDate, shirtCount, pantsCount, 
              matCount, pillowCount, blanketCount, location, withChildren, 
              childrenCount, notes, createdAt, updatedAt
            FROM reg_additional_info_backup
          ''');
          
          // 5. ลบ backup table
          await db.execute('DROP TABLE reg_additional_info_backup');
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

        if (oldVersion < 5) {
          // เพิ่มตาราง app_settings
          await db.execute('''
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // ตั้งค่าเริ่มต้นสำหรับ menu visibility
          await db.insert('app_settings', {
            'key': 'menu_white_robe_enabled',
            'value': 'false',
            'updated_at': DateTime.now().toIso8601String(),
          });
          await db.insert('app_settings', {
            'key': 'menu_booking_enabled', 
            'value': 'false',
            'updated_at': DateTime.now().toIso8601String(),
          });
          await db.insert('app_settings', {
            'key': 'menu_schedule_enabled',
            'value': 'true', 
            'updated_at': DateTime.now().toIso8601String(),
          });
          await db.insert('app_settings', {
            'key': 'menu_summary_enabled',
            'value': 'true',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        if (oldVersion < 6) {
          // เพิ่มคอลัมน์ status สำหรับ soft delete
          await db.execute('ALTER TABLE regs ADD COLUMN status TEXT DEFAULT \'A\'');
          
          // อัปเดตข้อมูลเก่าให้มี status = 'A'
          await db.execute('UPDATE regs SET status = \'A\' WHERE status IS NULL');
        }

        if (oldVersion < 8) {
          // เพิ่มตารางสำหรับระบบแผนที่และห้องพัก
          
          // ตาราง maps
          await db.execute('''
            CREATE TABLE maps (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              image_path TEXT,
              image_width REAL,
              image_height REAL,
              is_active INTEGER DEFAULT 0,
              description TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // ตาราง rooms
          await db.execute('''
            CREATE TABLE rooms (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              size TEXT NOT NULL,
              capacity INTEGER NOT NULL,
              position_x REAL,
              position_y REAL,
              status TEXT DEFAULT 'available',
              description TEXT,
              current_occupant TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (current_occupant) REFERENCES regs (id) ON DELETE SET NULL
            )
          ''');

          // ตาราง room_bookings
          await db.execute('''
            CREATE TABLE room_bookings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              room_id INTEGER NOT NULL,
              visitor_id TEXT NOT NULL,
              check_in_date TEXT NOT NULL,
              check_out_date TEXT NOT NULL,
              status TEXT DEFAULT 'pending',
              note TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
              FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
            )
          ''');

          // สร้าง indexes
          await db.execute('CREATE INDEX idx_rooms_status ON rooms(status)');
          await db.execute('CREATE INDEX idx_rooms_position ON rooms(position_x, position_y)');
          await db.execute('CREATE INDEX idx_room_bookings_room_id ON room_bookings(room_id)');
          await db.execute('CREATE INDEX idx_room_bookings_visitor_id ON room_bookings(visitor_id)');
          await db.execute('CREATE INDEX idx_room_bookings_dates ON room_bookings(check_in_date, check_out_date)');
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
    final res = await (await db).query(
      'regs',
      where: 'status = ?',
      whereArgs: ['A'],
      orderBy: 'first ASC',
    );
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  Future<List<RegData>> fetchByIdCard(bool hasIdCard) async {
    final res = await (await db).query(
      'regs',
      where: 'hasIdCard = ? AND status = ?',
      whereArgs: [hasIdCard ? 1 : 0, 'A'],
      orderBy: 'first ASC',
    );
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  // Soft delete - เปลี่ยนสถานะเป็น 'I' (Inactive)
  Future<void> delete(String id) async => (await db).update(
    'regs',
    {'status': 'I', 'updatedAt': DateTime.now().toIso8601String()},
    where: 'id = ?',
    whereArgs: [id],
  );

  // Hard delete - ลบจริงออกจากฐานข้อมูล (สำหรับ Admin)
  Future<void> hardDelete(String id) async =>
      (await db).delete('regs', where: 'id = ?', whereArgs: [id]);

  // ดึงรายการเพศที่มีอยู่จริงในฐานข้อมูล
  Future<List<String>> getAvailableGenders() async {
    final res = await (await db).rawQuery('''
      SELECT DISTINCT gender 
      FROM regs 
      WHERE status = 'A' AND gender IS NOT NULL AND gender != '' 
      ORDER BY gender ASC
    ''');
    return res.map((row) => row['gender'] as String).toList();
  }

  // ดึงรายการข้อมูลที่ถูกลบ (สำหรับ Developer Setting)
  Future<List<RegData>> fetchDeletedRecords() async {
    final res = await (await db).query(
      'regs',
      where: 'status = ?',
      whereArgs: ['I'],
      orderBy: 'updatedAt DESC',
    );
    return res.map((m) => RegData.fromMap(m)).toList();
  }

  // กู้คืนข้อมูลที่ถูกลบ (Restore)
  Future<void> restoreRecord(String id) async => (await db).update(
    'regs',
    {'status': 'A', 'updatedAt': DateTime.now().toIso8601String()},
    where: 'id = ?',
    whereArgs: [id],
  );

  // อัปเดตสถานะ stay ที่หมดอายุแล้วอัตโนมัติ
  Future<void> updateExpiredStays() async {
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
    
    await (await db).update(
      'stays',
      {'status': 'completed'},
      where: 'status IN (?, ?) AND date(end_date) < date(?)',
      whereArgs: ['active', 'extended', todayStr],
    );
  }

  // ฟังก์ชันสำหรับข้อมูลเพิ่มเติม
  Future<RegAdditionalInfo?> fetchAdditionalInfo(String regId) async {
    final res = await (await db).query(
      'reg_additional_info',
      where: 'regId = ?',
      whereArgs: [regId],
    );
    return res.isEmpty ? null : RegAdditionalInfo.fromMap(res.first);
  }

  // ฟังก์ชันใหม่สำหรับดึงข้อมูลเพิ่มเติมตาม regId เฉพาะ
  Future<RegAdditionalInfo?> fetchAdditionalInfoByRegId(String regId) async {
    final res = await (await db).query(
      'reg_additional_info',
      where: 'regId = ?',
      whereArgs: [regId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    return res.isEmpty ? null : RegAdditionalInfo.fromMap(res.first);
  }

  // ฟังก์ชันใหม่สำหรับดึงข้อมูลเพิ่มเติมตาม visitId เฉพาะ
  Future<RegAdditionalInfo?> fetchAdditionalInfoByVisitId(String visitId) async {
    final res = await (await db).query(
      'reg_additional_info',
      where: 'visitId = ?',
      whereArgs: [visitId],
      limit: 1,
    );
    return res.isEmpty ? null : RegAdditionalInfo.fromMap(res.first);
  }

  // ฟังก์ชันสำหรับดึงข้อมูลเพิ่มเติมทั้งหมดของ regId
  Future<List<RegAdditionalInfo>> fetchAllAdditionalInfoByRegId(String regId) async {
    final res = await (await db).query(
      'reg_additional_info',
      where: 'regId = ?',
      whereArgs: [regId],
      orderBy: 'createdAt DESC',
    );
    return res.map((row) => RegAdditionalInfo.fromMap(row)).toList();
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
        where: 'visitId = ?',
        whereArgs: [data.visitId],
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

    // สร้าง Stay record สำหรับการทดสอบ
    final stayRecord = StayRecord.create(
      visitorId: testData.id,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      note: 'ข้อมูลทดสอบการเข้าพัก',
    );
    await insertStay(stayRecord);

    // สร้าง additional info โดยใช้ visitId ที่เชื่อมกับ stay record
    final visitId = '${testData.id}_${stayRecord.createdAt.millisecondsSinceEpoch}';
    final additionalInfo = RegAdditionalInfo.create(
      regId: testData.id,
      visitId: visitId,
      shirtCount: 2,
      pantsCount: 2,
      matCount: 1,
      pillowCount: 1,
      blanketCount: 1,
      location: 'ห้อง 101',
      withChildren: false,
      notes: 'ข้อมูลทดสอบอุปกรณ์',
    );

    await insertAdditionalInfo(additionalInfo);

    // สร้างข้อมูลการมาครั้งที่ 2 (1 เดือนต่อมา)
    await Future.delayed(const Duration(milliseconds: 10)); // เพื่อให้ timestamp ต่างกัน
    final stayRecord2 = StayRecord.create(
      visitorId: testData.id,
      startDate: DateTime.now().add(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 37)),
      note: 'ข้อมูลทดสอบการเข้าพักครั้งที่ 2',
    );
    await insertStay(stayRecord2);

    final visitId2 = '${testData.id}_${stayRecord2.createdAt.millisecondsSinceEpoch}';
    final additionalInfo2 = RegAdditionalInfo.create(
      regId: testData.id,
      visitId: visitId2,
      shirtCount: 1,
      pantsCount: 1,
      matCount: 1,
      pillowCount: 0,
      blanketCount: 1,
      location: 'ห้อง 205',
      withChildren: true,
      childrenCount: 1,
      notes: 'ข้อมูลทดสอบอุปกรณ์ครั้งที่ 2 - มากับลูก',
    );

    await insertAdditionalInfo(additionalInfo2);
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

  // ดึงข้อมูล Stay ทั้งหมดของผู้เข้าพัก (พร้อมอัปเดตสถานะที่หมดอายุ)
  Future<List<StayRecord>> fetchAllStays(String visitorId) async {
    // อัปเดตสถานะที่หมดอายุก่อนดึงข้อมูล
    await updateExpiredStays();
    
    final res = await (await db).query(
      'stays',
      where: 'visitor_id = ?',
      whereArgs: [visitorId],
      orderBy: 'created_at DESC',
    );
    return res.map((m) => StayRecord.fromMap(m)).toList();
  }

  // ดึงข้อมูล Stay ที่ยัง active (พร้อมอัปเดตสถานะที่หมดอายุ)
  Future<List<StayRecord>> fetchActiveStays(String visitorId) async {
    // อัปเดตสถานะที่หมดอายุก่อนดึงข้อมูล
    await updateExpiredStays();
    
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final res = await (await db).query(
      'stays',
      where: 'visitor_id = ? AND date(end_date) >= date(?)',
      whereArgs: [visitorId, todayStr],
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

  // =================== DATA MANAGEMENT METHODS ===================

  // ดูสถิติฐานข้อมูล
  Future<Map<String, int>> getDatabaseStatistics() async {
    final database = await db;
    
    // นับจำนวน record ในแต่ละตาราง
    final regsCount = await database.rawQuery('SELECT COUNT(*) as count FROM regs WHERE status = ?', ['A']);
    final additionalInfoCount = await database.rawQuery('SELECT COUNT(*) as count FROM reg_additional_info');
    final staysCount = await database.rawQuery('SELECT COUNT(*) as count FROM stays');
    final deletedRegsCount = await database.rawQuery('SELECT COUNT(*) as count FROM regs WHERE status = ?', ['I']);
    
    return {
      'totalVisitors': regsCount.first['count'] as int,
      'deletedVisitors': deletedRegsCount.first['count'] as int,
      'totalAdditionalInfo': additionalInfoCount.first['count'] as int,
      'totalStays': staysCount.first['count'] as int,
    };
  }

  // ล้างข้อมูลทดสอบ (ลบเฉพาะข้อมูลที่มี flag ทดสอบ)
  Future<int> clearTestData() async {
    final database = await db;
    int deletedCount = 0;
    
    await database.transaction((txn) async {
      // ลบข้อมูลทดสอบจาก reg_additional_info ที่มี notes หรือ location เป็น test
      final deletedAdditionalInfo = await txn.delete(
        'reg_additional_info',
        where: 'notes LIKE ? OR location LIKE ?',
        whereArgs: ['%ทดสอบ%', '%ทดสอบ%'],
      );
      
      // ลบข้อมูลทดสอบจาก stays ที่มี note เป็น test
      final deletedStays = await txn.delete(
        'stays',
        where: 'note LIKE ?',
        whereArgs: ['%ทดสอบ%'],
      );
      
      // ลบข้อมูลทดสอบจาก regs ที่มี phone ขึ้นต้นด้วย 000 หรือ first name เป็น ทดสอบ
      final deletedRegs = await txn.delete(
        'regs',
        where: 'phone LIKE ? OR first LIKE ?',
        whereArgs: ['000%', '%ทดสอบ%'],
      );
      
      deletedCount = deletedRegs + deletedAdditionalInfo + deletedStays;
    });
    
    // VACUUM เพื่อเคลียร์ space
    await database.execute('VACUUM');
    
    return deletedCount;
  }

  // สร้างข้อมูลทดสอบหลายคน
  Future<void> createMultipleTestData() async {
    final testUsers = [
      {
        'id': '0001234567890',
        'first': 'ทดสอบ1',
        'last': 'ระบบ',
        'dob': '1 มกราคม 2540',
        'phone': '0001234567',
        'addr': 'กรุงเทพมหานคร, เขตปทุมวัน, แขวงลุมพินี, 123/1',
        'gender': 'ชาย',
      },
      {
        'id': '0001234567891',
        'first': 'ทดสอบ2',
        'last': 'พัฒนา',
        'dob': '15 กุมภาพันธ์ 2535',
        'phone': '0001234568',
        'addr': 'นนทบุรี, เขอมืองนนทบุรี, แขวงศูนย์กลาง, 456/2',
        'gender': 'หญิง',
      },
      {
        'id': '0001234567892',
        'first': 'ทดสอบ3',
        'last': 'เทสต์',
        'dob': '30 มีนาคม 2542',
        'phone': '0001234569',
        'addr': 'ปทุมธานี, เขตธัญบุรี, แขวงประชาธิปัตย์, 789/3',
        'gender': 'ชาย',
      },
      {
        'id': '0001234567893',
        'first': 'ทดสอบ4',
        'last': 'ตัวอย่าง',
        'dob': '22 เมษายน 2530',
        'phone': '0001234570',
        'addr': 'สมุทรปราการ, เขอบางพลี, แขวงบางพลีใหญ่, 321/4',
        'gender': 'หญิง',
      },
      {
        'id': '0001234567894',
        'first': 'ทดสอบ5',
        'last': 'สาธิต',
        'dob': '10 พฤษภาคม 2545',
        'phone': '0001234571',
        'addr': 'นครปฐม, เขอเมืองนครปฐม, แขวงพระปฐมเจดีย์, 654/5',
        'gender': 'ชาย',
      },
    ];

    for (final userData in testUsers) {
      // สร้างข้อมูลผู้ใช้
      final regData = RegData.manual(
        id: userData['id']!,
        first: userData['first']!,
        last: userData['last']!,
        dob: userData['dob']!,
        phone: userData['phone']!,
        addr: userData['addr']!,
        gender: userData['gender']!,
      );
      
      await insert(regData);

      // สร้างประวัติการเข้าพัก 1-3 ครั้งสำหรับแต่ละคน
      final visitCount = (userData['id']!.hashCode % 3) + 1; // 1-3 ครั้ง
      
      for (int i = 0; i < visitCount; i++) {
        await Future.delayed(const Duration(milliseconds: 5)); // เพื่อให้ timestamp ต่างกัน
        
        // สร้าง stay record
        final startDate = DateTime.now().subtract(Duration(days: 90 - (i * 30)));
        final endDate = startDate.add(Duration(days: 5 + (i * 2)));
        
        final stayRecord = StayRecord.create(
          visitorId: regData.id,
          startDate: startDate,
          endDate: endDate,
          note: 'ข้อมูลทดสอบการเข้าพักครั้งที่ ${i + 1}',
        );
        await insertStay(stayRecord);

        // สร้าง additional info
        final visitId = '${regData.id}_${stayRecord.createdAt.millisecondsSinceEpoch}';
        final additionalInfo = RegAdditionalInfo.create(
          regId: regData.id,
          visitId: visitId,
          shirtCount: 1 + (i % 3),
          pantsCount: 1 + (i % 3),
          matCount: 1,
          pillowCount: i > 0 ? 1 : 0,
          blanketCount: 1,
          location: 'ห้องทดสอบ ${100 + userData['id']!.hashCode % 50}',
          withChildren: i == 1, // ครั้งที่ 2 มากับเด็ก
          childrenCount: i == 1 ? 1 : null,
          notes: 'ข้อมูลทดสอบอุปกรณ์ครั้งที่ ${i + 1}',
        );

        await insertAdditionalInfo(additionalInfo);
      }
    }
  }

  // ล้างข้อมูลทั้งหมด (⚠️ ทำลายทุกข้อมูลในระบบ)
  Future<void> clearAllData() async {
    final database = await db;
    
    await database.transaction((txn) async {
      // ลบข้อมูลทั้งหมดในทุกตาราง (ตามลำดับ foreign key)
      await txn.delete('reg_additional_info'); // ลบข้อมูลเพิ่มเติมก่อน
      await txn.delete('stays'); // ลบข้อมูลการพัก
      await txn.delete('regs'); // ลบข้อมูลหลัก
      await txn.delete('app_settings'); // ลบการตั้งค่า
      
      // รีเซต auto increment sequences (SQLite)
      await txn.execute("DELETE FROM sqlite_sequence WHERE name IN ('reg_additional_info', 'stays')");
    });
    
    // VACUUM เพื่อเคลียร์ space และ compact database
    await database.execute('VACUUM');
    
    // สร้างการตั้งค่าเริ่มต้นใหม่
    await _initializeDefaultSettings();
  }

  // สร้างการตั้งค่าเริ่มต้นหลังจากล้างข้อมูล
  Future<void> _initializeDefaultSettings() async {
    await setSetting('menu_white_robe_enabled', 'false');
    await setSetting('menu_booking_enabled', 'false');
    await setSetting('menu_schedule_enabled', 'true');
    await setSetting('menu_summary_enabled', 'true');
  }

  // =================== APP SETTINGS METHODS ===================

  // ดึงค่า setting
  Future<String?> getSetting(String key) async {
    final res = await (await db).query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return res.isEmpty ? null : res.first['value'] as String;
  }

  // ตั้งค่า setting
  Future<void> setSetting(String key, String value) async {
    await (await db).insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ดึงค่า setting แบบ boolean
  Future<bool> getBoolSetting(String key, {bool defaultValue = false}) async {
    final value = await getSetting(key);
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  // ตั้งค่า setting แบบ boolean
  Future<void> setBoolSetting(String key, bool value) async {
    await setSetting(key, value.toString());
  }

  // ดึงการตั้งค่าเมนูทั้งหมด
  Future<Map<String, bool>> getAllMenuSettings() async {
    final whiteRobe = await getBoolSetting('menu_white_robe_enabled', defaultValue: false);
    final booking = await getBoolSetting('menu_booking_enabled', defaultValue: false);
    final schedule = await getBoolSetting('menu_schedule_enabled', defaultValue: true);
    final summary = await getBoolSetting('menu_summary_enabled', defaultValue: true);

    return {
      'whiteRobe': whiteRobe,
      'booking': booking,
      'schedule': schedule,
      'summary': summary,
    };
  }

  // =================== MAP MANAGEMENT METHODS ===================

  // ดึงแผนที่ทั้งหมด
  Future<List<MapData>> fetchAllMaps() async {
    final res = await (await db).query(
      'maps',
      orderBy: 'created_at DESC',
    );
    return res.map((m) => MapData.fromMap(m)).toList();
  }

  // ดึงแผนที่ที่กำลังใช้งาน
  Future<MapData?> fetchActiveMap() async {
    final res = await (await db).query(
      'maps',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );
    return res.isEmpty ? null : MapData.fromMap(res.first);
  }

  // เพิ่มแผนที่ใหม่
  Future<int> insertMap(MapData mapData) async {
    return await (await db).insert('maps', mapData.toMap());
  }

  // อัปเดตแผนที่
  Future<void> updateMap(MapData mapData) async {
    await (await db).update(
      'maps',
      mapData.toMap(),
      where: 'id = ?',
      whereArgs: [mapData.id],
    );
  }

  // ลบแผนที่
  Future<void> deleteMap(int mapId) async {
    await (await db).delete('maps', where: 'id = ?', whereArgs: [mapId]);
  }

  // ตั้งแผนที่เป็น active (และยกเลิก active ของแผนที่อื่น)
  Future<void> setActiveMap(int mapId) async {
    final database = await db;
    await database.transaction((txn) async {
      // ยกเลิก active ของแผนที่อื่น
      await txn.update(
        'maps',
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      // ตั้งแผนที่ใหม่เป็น active
      await txn.update(
        'maps',
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [mapId],
      );
    });
  }

  // =================== ROOM MANAGEMENT METHODS ===================

  // ดึงห้องพักทั้งหมด
  Future<List<Room>> fetchAllRooms() async {
    final res = await (await db).query(
      'rooms',
      orderBy: 'name ASC',
    );
    return res.map((m) => Room.fromMap(m)).toList();
  }

  // ดึงห้องพักตาม ID
  Future<Room?> fetchRoomById(int roomId) async {
    final res = await (await db).query(
      'rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );
    return res.isEmpty ? null : Room.fromMap(res.first);
  }

  // ดึงห้องพักที่มีตำแหน่งบนแผนที่
  Future<List<Room>> fetchRoomsWithPosition() async {
    final res = await (await db).query(
      'rooms',
      where: 'position_x IS NOT NULL AND position_y IS NOT NULL',
      orderBy: 'name ASC',
    );
    return res.map((m) => Room.fromMap(m)).toList();
  }

  // ดึงห้องพักตามสถานะ
  Future<List<Room>> fetchRoomsByStatus(RoomStatus status) async {
    final res = await (await db).query(
      'rooms',
      where: 'status = ?',
      whereArgs: [status.code],
      orderBy: 'name ASC',
    );
    return res.map((m) => Room.fromMap(m)).toList();
  }

  // เพิ่มห้องพักใหม่
  Future<int> insertRoom(Room room) async {
    return await (await db).insert('rooms', room.toMap());
  }

  // อัปเดตห้องพัก
  Future<void> updateRoom(Room room) async {
    await (await db).update(
      'rooms',
      room.toMap(),
      where: 'id = ?',
      whereArgs: [room.id],
    );
  }

  // ลบห้องพัก
  Future<void> deleteRoom(int roomId) async {
    await (await db).delete('rooms', where: 'id = ?', whereArgs: [roomId]);
  }

  // อัปเดตตำแหน่งห้องพัก
  Future<void> updateRoomPosition(int roomId, double x, double y) async {
    await (await db).update(
      'rooms',
      {
        'position_x': x,
        'position_y': y,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // อัปเดตสถานะห้องพัก
  Future<void> updateRoomStatus(int roomId, RoomStatus status, {String? occupantId}) async {
    await (await db).update(
      'rooms',
      {
        'status': status.code,
        'current_occupant': occupantId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [roomId],
    );
  }

  // ตรวจสอบว่าตำแหน่งนั้นมีห้องอื่นอยู่หรือไม่
  Future<bool> isPositionOccupied(double x, double y, {int? excludeRoomId}) async {
    String whereClause = 'ABS(position_x - ?) < 10 AND ABS(position_y - ?) < 10';
    List<dynamic> whereArgs = [x, y];

    if (excludeRoomId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeRoomId);
    }

    final res = await (await db).query(
      'rooms',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return res.isNotEmpty;
  }

  // สร้างข้อมูลห้องพักทดสอบ
  Future<void> createTestRooms() async {
    final testRooms = [
      Room.create(name: 'ห้อง 101', size: RoomSize.small, capacity: 2, description: 'ห้องเล็กสำหรับ 2 คน'),
      Room.create(name: 'ห้อง 102', size: RoomSize.medium, capacity: 4, description: 'ห้องกลางสำหรับ 4 คน'),
      Room.create(name: 'ศาลาใหญ่', size: RoomSize.large, capacity: 20, description: 'ศาลาใหญ่สำหรับกิจกรรมหมู่'),
      Room.create(name: 'ห้อง 201', size: RoomSize.small, capacity: 2, description: 'ห้องเล็กชั้น 2'),
      Room.create(name: 'ห้อง 202', size: RoomSize.medium, capacity: 4, description: 'ห้องกลางชั้น 2'),
    ];

    for (final room in testRooms) {
      await insertRoom(room);
    }
  }

  // ล้างข้อมูลแผนที่และห้องพักทั้งหมด
  Future<void> clearMapAndRoomData() async {
    final database = await db;
    await database.transaction((txn) async {
      await txn.delete('room_bookings');
      await txn.delete('rooms');
      await txn.delete('maps');
    });
  }

  // =================== ROOM BOOKING METHODS (สำหรับอนาคต) ===================

  // ดึงการจองห้องพักทั้งหมด
  Future<List<RoomBooking>> fetchAllBookings() async {
    final res = await (await db).query(
      'room_bookings',
      orderBy: 'created_at DESC',
    );
    return res.map((m) => RoomBooking.fromMap(m)).toList();
  }

  // ดึงการจองของห้องพักเฉพาะ
  Future<List<RoomBooking>> fetchBookingsByRoom(int roomId) async {
    final res = await (await db).query(
      'room_bookings',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'check_in_date ASC',
    );
    return res.map((m) => RoomBooking.fromMap(m)).toList();
  }

  // เพิ่มการจองห้องพัก
  Future<int> insertBooking(RoomBooking booking) async {
    return await (await db).insert('room_bookings', booking.toMap());
  }

  // อัปเดตการจองห้องพัก
  Future<void> updateBooking(RoomBooking booking) async {
    await (await db).update(
      'room_bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  // ลบการจองห้องพัก
  Future<void> deleteBooking(int bookingId) async {
    await (await db).delete('room_bookings', where: 'id = ?', whereArgs: [bookingId]);
  }
}
