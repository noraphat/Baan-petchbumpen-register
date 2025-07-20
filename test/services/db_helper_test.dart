import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  group('DbHelper Tests', () {
    late DbHelper dbHelper;
    late Database testDb;

    setUpAll(() {
      // Initialize FFI
      sqfliteFfiInit();
    });

    setUp(() async {
      // Use in-memory database for testing
      databaseFactory = databaseFactoryFfi;
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, version) async {
          // Create tables - copy from DbHelper
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
      );

      dbHelper = DbHelper();
      // Override the db getter to use our test database
      // Note: Direct db override not possible due to private member access
    });

    tearDown(() async {
      await testDb.close();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final dbHelper1 = DbHelper();
        final dbHelper2 = DbHelper();
        expect(identical(dbHelper1, dbHelper2), isTrue);
      });
    });

    group('Basic CRUD Operations', () {
      test('should insert and fetch RegData correctly', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData);
        final retrieved = await dbHelper.fetchById('1234567890123');

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('1234567890123'));
        expect(retrieved.first, equals('สมชาย'));
        expect(retrieved.last, equals('ใจดี'));
        expect(retrieved.dob, equals('15 มกราคม 2530'));
        expect(retrieved.phone, equals('0812345678'));
        expect(retrieved.addr, equals('กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม'));
        expect(retrieved.gender, equals('ชาย'));
        expect(retrieved.hasIdCard, isFalse);
      });

      test('should return null for non-existent ID', () async {
        final retrieved = await dbHelper.fetchById('nonexistent');
        expect(retrieved, isNull);
      });

      test('should update existing RegData', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData);
        
        final updatedData = regData.copyWithEditable(
          phone: '0898765432',
        );
        await dbHelper.update(updatedData);

        final retrieved = await dbHelper.fetchById('1234567890123');
        expect(retrieved!.phone, equals('0898765432'));
      });

      test('should delete RegData', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData);
        await dbHelper.delete('1234567890123');

        final retrieved = await dbHelper.fetchById('1234567890123');
        expect(retrieved, isNull);
      });

      test('should replace data on conflict', () async {
        final regData1 = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        final regData2 = RegData.manual(
          id: '1234567890123', // Same ID
          first: 'สมหญิง',
          last: 'ใจงาม',
          dob: '20 กุมภาพันธ์ 2535',
          phone: '0898765432',
          addr: 'เชียงใหม่, เมืองเชียงใหม่, ช้างคลาน',
          gender: 'หญิง',
        );

        await dbHelper.insert(regData1);
        await dbHelper.insert(regData2); // Should replace

        final retrieved = await dbHelper.fetchById('1234567890123');
        expect(retrieved!.first, equals('สมหญิง'));
        expect(retrieved.last, equals('ใจงาม'));
        expect(retrieved.gender, equals('หญิง'));
      });
    });

    group('Query Operations', () {
      setUp(() async {
        // Insert test data
        final regData1 = RegData.fromIdCard(
          id: '1111111111111',
          first: 'สมชาย',
          last: 'มีบัตร',
          dob: '15 มกราคม 2530',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
          phone: '0811111111',
        );

        final regData2 = RegData.manual(
          id: '0822222222',
          first: 'สมหญิง',
          last: 'ไม่มีบัตร',
          dob: '20 กุมภาพันธ์ 2535',
          phone: '0822222222',
          addr: 'เชียงใหม่, เมืองเชียงใหม่, ช้างคลาน',
          gender: 'หญิง',
        );

        final regData3 = RegData.manual(
          id: '0833333333',
          first: 'กกก',
          last: 'ขขข',
          dob: '25 มีนาคม 2540',
          phone: '0833333333',
          addr: 'สงขลา, เมืองสงขลา, บ่อยาง',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData1);
        await dbHelper.insert(regData2);
        await dbHelper.insert(regData3);
      });

      test('should fetch all RegData ordered by first name', () async {
        final allData = await dbHelper.fetchAll();
        
        expect(allData.length, equals(3));
        expect(allData[0].first, equals('กกก')); // Should be first alphabetically
        expect(allData[1].first, equals('สมชาย'));
        expect(allData[2].first, equals('สมหญิง'));
      });

      test('should fetch RegData by ID card status', () async {
        final withIdCard = await dbHelper.fetchByIdCard(true);
        final withoutIdCard = await dbHelper.fetchByIdCard(false);

        expect(withIdCard.length, equals(1));
        expect(withIdCard[0].id, equals('1111111111111'));
        expect(withIdCard[0].hasIdCard, isTrue);

        expect(withoutIdCard.length, equals(2));
        expect(withoutIdCard.every((data) => !data.hasIdCard), isTrue);
      });
    });

    group('Additional Info Operations', () {
      late RegData testRegData;

      setUp(() async {
        testRegData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );
        await dbHelper.insert(testRegData);
      });

      test('should insert and fetch additional info correctly', () async {
        final startDate = DateTime(2024, 1, 15);
        final endDate = DateTime(2024, 1, 20);
        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          startDate: startDate,
          endDate: endDate,
          shirtCount: 2,
          pantsCount: 2,
          matCount: 1,
          pillowCount: 1,
          blanketCount: 1,
          location: 'ศาลาอุโบสถ ห้อง A1',
          withChildren: true,
          childrenCount: 2,
          notes: 'เจมังสวิรัติ ไม่ทานเนื้อสัตว์',
        );

        await dbHelper.insertAdditionalInfo(additionalInfo);
        final retrieved = await dbHelper.fetchAdditionalInfo('1234567890123');

        expect(retrieved, isNotNull);
        expect(retrieved!.regId, equals('1234567890123'));
        expect(retrieved.startDate, equals(startDate));
        expect(retrieved.endDate, equals(endDate));
        expect(retrieved.shirtCount, equals(2));
        expect(retrieved.pantsCount, equals(2));
        expect(retrieved.matCount, equals(1));
        expect(retrieved.pillowCount, equals(1));
        expect(retrieved.blanketCount, equals(1));
        expect(retrieved.location, equals('ศาลาอุโบสถ ห้อง A1'));
        expect(retrieved.withChildren, isTrue);
        expect(retrieved.childrenCount, equals(2));
        expect(retrieved.notes, equals('เจมังสวิรัติ ไม่ทานเนื้อสัตว์'));
      });

      test('should return null for non-existent additional info', () async {
        final retrieved = await dbHelper.fetchAdditionalInfo('nonexistent');
        expect(retrieved, isNull);
      });

      test('should update additional info', () async {
        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
          location: 'ห้องเก่า',
          notes: 'หมายเหตุเก่า',
        );

        await dbHelper.insertAdditionalInfo(additionalInfo);

        final updatedInfo = additionalInfo.copyWith(
          shirtCount: 3,
          location: 'ห้องใหม่',
          notes: 'หมายเหตุใหม่',
        );
        await dbHelper.updateAdditionalInfo(updatedInfo);

        final retrieved = await dbHelper.fetchAdditionalInfo('1234567890123');
        expect(retrieved!.shirtCount, equals(3));
        expect(retrieved.location, equals('ห้องใหม่'));
        expect(retrieved.notes, equals('หมายเหตุใหม่'));
      });

      test('should delete additional info', () async {
        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
        );

        await dbHelper.insertAdditionalInfo(additionalInfo);
        await dbHelper.deleteAdditionalInfo('1234567890123');

        final retrieved = await dbHelper.fetchAdditionalInfo('1234567890123');
        expect(retrieved, isNull);
      });

      test('should replace additional info on conflict', () async {
        final additionalInfo1 = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
          location: 'ห้องที่ 1',
        );

        final additionalInfo2 = RegAdditionalInfo.create(
          regId: '1234567890123', // Same regId
          shirtCount: 3,
          location: 'ห้องที่ 2',
        );

        await dbHelper.insertAdditionalInfo(additionalInfo1);
        await dbHelper.insertAdditionalInfo(additionalInfo2); // Should replace

        final retrieved = await dbHelper.fetchAdditionalInfo('1234567890123');
        expect(retrieved!.shirtCount, equals(3));
        expect(retrieved.location, equals('ห้องที่ 2'));
      });
    });

    group('Complex Operations', () {
      test('should fetch complete data (regData + additionalInfo)', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
          location: 'ห้อง A1',
        );

        await dbHelper.insert(regData);
        await dbHelper.insertAdditionalInfo(additionalInfo);

        final completeData = await dbHelper.fetchCompleteData('1234567890123');

        expect(completeData, isNotNull);
        expect(completeData!['regData'], isA<RegData>());
        expect(completeData['additionalInfo'], isA<RegAdditionalInfo>());

        final retrievedRegData = completeData['regData'] as RegData;
        final retrievedAdditionalInfo = completeData['additionalInfo'] as RegAdditionalInfo;

        expect(retrievedRegData.first, equals('สมชาย'));
        expect(retrievedAdditionalInfo.shirtCount, equals(2));
      });

      test('should return null for complete data when regData does not exist', () async {
        final completeData = await dbHelper.fetchCompleteData('nonexistent');
        expect(completeData, isNull);
      });

      test('should handle complete data when additionalInfo is missing', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData);

        final completeData = await dbHelper.fetchCompleteData('1234567890123');

        expect(completeData, isNotNull);
        expect(completeData!['regData'], isA<RegData>());
        expect(completeData['additionalInfo'], isNull);
      });

      test('should update editable fields only', () async {
        final regData = RegData.fromIdCard(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
          phone: '0812345678',
        );

        await dbHelper.insert(regData);
        await dbHelper.updateEditableFields('1234567890123', phone: '0898765432');

        final retrieved = await dbHelper.fetchById('1234567890123');
        expect(retrieved!.phone, equals('0898765432'));
        expect(retrieved.first, equals('สมชาย')); // Unchanged
        expect(retrieved.hasIdCard, isTrue); // Unchanged
      });

      test('should update all fields for manual registration', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        await dbHelper.insert(regData);

        final updatedData = regData.copyWithAll(
          first: 'สมหญิง',
          phone: '0898765432',
          gender: 'หญิง',
        );
        await dbHelper.updateAllFields(updatedData);

        final retrieved = await dbHelper.fetchById('1234567890123');
        expect(retrieved!.first, equals('สมหญิง'));
        expect(retrieved.phone, equals('0898765432'));
        expect(retrieved.gender, equals('หญิง'));
      });

      test('should update additional info fields with timestamp', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
          location: 'ห้องเก่า',
        );

        await dbHelper.insert(regData);
        await dbHelper.insertAdditionalInfo(additionalInfo);

        // Wait a bit to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        await dbHelper.updateAdditionalInfoFields(
          '1234567890123',
          additionalInfo.copyWith(shirtCount: 3, location: 'ห้องใหม่'),
        );

        final retrieved = await dbHelper.fetchAdditionalInfo('1234567890123');
        expect(retrieved!.shirtCount, equals(3));
        expect(retrieved.location, equals('ห้องใหม่'));
        expect(retrieved.updatedAt.isAfter(retrieved.createdAt), isTrue);
      });
    });

    group('Data Management', () {
      test('should clear all data', () async {
        final regData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );

        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          shirtCount: 2,
        );

        await dbHelper.insert(regData);
        await dbHelper.insertAdditionalInfo(additionalInfo);

        // Verify data exists
        expect(await dbHelper.fetchById('1234567890123'), isNotNull);
        expect(await dbHelper.fetchAdditionalInfo('1234567890123'), isNotNull);

        // Clear all data
        await dbHelper.clearAllData();

        // Verify data is cleared
        expect(await dbHelper.fetchById('1234567890123'), isNull);
        expect(await dbHelper.fetchAdditionalInfo('1234567890123'), isNull);
        expect(await dbHelper.fetchAll(), isEmpty);
      });

      test('should create test data', () async {
        await dbHelper.createTestData();

        final testRegData = await dbHelper.fetchById('1234567890123');
        final testAdditionalInfo = await dbHelper.fetchAdditionalInfo('1234567890123');

        expect(testRegData, isNotNull);
        expect(testRegData!.first, equals('ทดสอบ'));
        expect(testRegData.last, equals('ระบบ'));
        expect(testRegData.hasIdCard, isFalse);

        expect(testAdditionalInfo, isNotNull);
        expect(testAdditionalInfo!.shirtCount, equals(2));
        expect(testAdditionalInfo.location, equals('ห้อง 101'));
        expect(testAdditionalInfo.notes, equals('ข้อมูลทดสอบ'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty results gracefully', () async {
        final allData = await dbHelper.fetchAll();
        final withIdCard = await dbHelper.fetchByIdCard(true);
        final withoutIdCard = await dbHelper.fetchByIdCard(false);

        expect(allData, isEmpty);
        expect(withIdCard, isEmpty);
        expect(withoutIdCard, isEmpty);
      });

      test('should handle operations on non-existent data gracefully', () async {
        await dbHelper.updateEditableFields('nonexistent', phone: '0812345678');
        await dbHelper.deleteAdditionalInfo('nonexistent');

        // Should not throw exceptions
        expect(() async => await dbHelper.delete('nonexistent'), returnsNormally);
      });

      test('should handle null values in data correctly', () async {
        final regData = RegData(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '',
          addr: '',
          gender: 'ชาย',
          hasIdCard: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await dbHelper.insert(regData);
        final retrieved = await dbHelper.fetchById('1234567890123');

        expect(retrieved, isNotNull);
        expect(retrieved!.phone, equals(''));
        expect(retrieved.addr, equals(''));
      });
    });
  });
}

// Note: Extension removed due to private member access limitations in testing