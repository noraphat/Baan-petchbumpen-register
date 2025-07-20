import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';
import 'package:flutter_petchbumpen_register/services/address_service.dart';

void main() {
  group('RegData Tests', () {
    group('Factory Constructors', () {
      test('fromIdCard creates RegData with ID card correctly', () {
        final regData = RegData.fromIdCard(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
          phone: '0812345678',
        );

        expect(regData.id, equals('1234567890123'));
        expect(regData.first, equals('สมชาย'));
        expect(regData.last, equals('ใจดี'));
        expect(regData.dob, equals('15 มกราคม 2530'));
        expect(regData.phone, equals('0812345678'));
        expect(regData.addr, equals('กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม'));
        expect(regData.gender, equals('ชาย'));
        expect(regData.hasIdCard, isTrue);
        expect(regData.createdAt, isNotNull);
        expect(regData.updatedAt, isNotNull);
      });

      test('manual creates RegData without ID card correctly', () {
        final regData = RegData.manual(
          id: '0812345678',
          first: 'สมหญิง',
          last: 'ใจงาม',
          dob: '20 กุมภาพันธ์ 2535',
          phone: '0812345678',
          addr: 'เชียงใหม่, เมืองเชียงใหม่, ช้างคลาน',
          gender: 'หญิง',
        );

        expect(regData.id, equals('0812345678'));
        expect(regData.first, equals('สมหญิง'));
        expect(regData.last, equals('ใจงาม'));
        expect(regData.dob, equals('20 กุมภาพันธ์ 2535'));
        expect(regData.phone, equals('0812345678'));
        expect(regData.addr, equals('เชียงใหม่, เมืองเชียงใหม่, ช้างคลาน'));
        expect(regData.gender, equals('หญิง'));
        expect(regData.hasIdCard, isFalse);
        expect(regData.createdAt, isNotNull);
        expect(regData.updatedAt, isNotNull);
      });
    });

    group('Data Serialization', () {
      test('toMap converts RegData to Map correctly', () {
        final now = DateTime.now();
        final regData = RegData(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
          hasIdCard: true,
          createdAt: now,
          updatedAt: now,
        );

        final map = regData.toMap();

        expect(map['id'], equals('1234567890123'));
        expect(map['first'], equals('สมชาย'));
        expect(map['last'], equals('ใจดี'));
        expect(map['dob'], equals('15 มกราคม 2530'));
        expect(map['phone'], equals('0812345678'));
        expect(map['addr'], equals('กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม'));
        expect(map['gender'], equals('ชาย'));
        expect(map['hasIdCard'], equals(1));
        expect(map['createdAt'], equals(now.toIso8601String()));
        expect(map['updatedAt'], equals(now.toIso8601String()));
      });

      test('fromMap creates RegData from Map correctly', () {
        final now = DateTime.now();
        final map = {
          'id': '1234567890123',
          'first': 'สมชาย',
          'last': 'ใจดี',
          'dob': '15 มกราคม 2530',
          'phone': '0812345678',
          'addr': 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          'gender': 'ชาย',
          'hasIdCard': 1,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        final regData = RegData.fromMap(map);

        expect(regData.id, equals('1234567890123'));
        expect(regData.first, equals('สมชาย'));
        expect(regData.last, equals('ใจดี'));
        expect(regData.dob, equals('15 มกราคม 2530'));
        expect(regData.phone, equals('0812345678'));
        expect(regData.addr, equals('กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม'));
        expect(regData.gender, equals('ชาย'));
        expect(regData.hasIdCard, isTrue);
        expect(regData.createdAt, equals(now));
        expect(regData.updatedAt, equals(now));
      });

      test('fromMap handles null/empty values correctly', () {
        final map = {
          'id': '1234567890123',
          'first': 'สมชาย',
          'last': 'ใจดี',
          'dob': '15 มกราคม 2530',
          'phone': null,
          'addr': null,
          'gender': null,
          'hasIdCard': 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final regData = RegData.fromMap(map);

        expect(regData.phone, equals(''));
        expect(regData.addr, equals(''));
        expect(regData.gender, equals('อื่น ๆ'));
        expect(regData.hasIdCard, isFalse);
      });
    });

    group('Copy Methods', () {
      late RegData originalData;

      setUp(() {
        originalData = RegData.fromIdCard(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
          phone: '0812345678',
        );
      });

      test('copyWithEditable updates only editable fields', () {
        final newPhone = '0898765432';
        final updatedData = originalData.copyWithEditable(phone: newPhone);

        expect(updatedData.phone, equals(newPhone));
        expect(updatedData.id, equals(originalData.id));
        expect(updatedData.first, equals(originalData.first));
        expect(updatedData.last, equals(originalData.last));
        expect(updatedData.dob, equals(originalData.dob));
        expect(updatedData.addr, equals(originalData.addr));
        expect(updatedData.gender, equals(originalData.gender));
        expect(updatedData.hasIdCard, equals(originalData.hasIdCard));
        expect(updatedData.createdAt, equals(originalData.createdAt));
        expect(updatedData.updatedAt.isAfter(originalData.updatedAt), isTrue);
      });

      test('copyWithAll updates all fields for manual registration', () {
        final manualData = RegData.manual(
          id: '0812345678',
          first: 'สมหญิง',
          last: 'ใจงาม',
          dob: '20 กุมภาพันธ์ 2535',
          phone: '0812345678',
          addr: 'เชียงใหม่, เมืองเชียงใหม่, ช้างคลาน',
          gender: 'หญิง',
        );

        final updatedData = manualData.copyWithAll(
          first: 'สมหญิงใหม่',
          last: 'ใจงามใหม่',
          phone: '0898765432',
          gender: 'แม่ชี',
        );

        expect(updatedData.first, equals('สมหญิงใหม่'));
        expect(updatedData.last, equals('ใจงามใหม่'));
        expect(updatedData.phone, equals('0898765432'));
        expect(updatedData.gender, equals('แม่ชี'));
        expect(updatedData.id, equals(manualData.id));
        expect(updatedData.dob, equals(manualData.dob));
        expect(updatedData.addr, equals(manualData.addr));
        expect(updatedData.hasIdCard, equals(manualData.hasIdCard));
        expect(updatedData.createdAt, equals(manualData.createdAt));
        expect(updatedData.updatedAt.isAfter(manualData.updatedAt), isTrue);
      });
    });
  });

  group('RegAdditionalInfo Tests', () {
    group('Factory Constructor', () {
      test('create builds RegAdditionalInfo correctly', () {
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

        expect(additionalInfo.regId, equals('1234567890123'));
        expect(additionalInfo.startDate, equals(startDate));
        expect(additionalInfo.endDate, equals(endDate));
        expect(additionalInfo.shirtCount, equals(2));
        expect(additionalInfo.pantsCount, equals(2));
        expect(additionalInfo.matCount, equals(1));
        expect(additionalInfo.pillowCount, equals(1));
        expect(additionalInfo.blanketCount, equals(1));
        expect(additionalInfo.location, equals('ศาลาอุโบสถ ห้อง A1'));
        expect(additionalInfo.withChildren, isTrue);
        expect(additionalInfo.childrenCount, equals(2));
        expect(additionalInfo.notes, equals('เจมังสวิรัติ ไม่ทานเนื้อสัตว์'));
        expect(additionalInfo.createdAt, isNotNull);
        expect(additionalInfo.updatedAt, isNotNull);
      });

      test('create handles null values correctly', () {
        final additionalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
        );

        expect(additionalInfo.regId, equals('1234567890123'));
        expect(additionalInfo.startDate, isNull);
        expect(additionalInfo.endDate, isNull);
        expect(additionalInfo.shirtCount, isNull);
        expect(additionalInfo.pantsCount, isNull);
        expect(additionalInfo.matCount, isNull);
        expect(additionalInfo.pillowCount, isNull);
        expect(additionalInfo.blanketCount, isNull);
        expect(additionalInfo.location, isNull);
        expect(additionalInfo.withChildren, isFalse);
        expect(additionalInfo.childrenCount, isNull);
        expect(additionalInfo.notes, isNull);
        expect(additionalInfo.createdAt, isNotNull);
        expect(additionalInfo.updatedAt, isNotNull);
      });
    });

    group('Data Serialization', () {
      test('toMap converts RegAdditionalInfo to Map correctly', () {
        final startDate = DateTime(2024, 1, 15);
        final endDate = DateTime(2024, 1, 20);
        final now = DateTime.now();
        
        final additionalInfo = RegAdditionalInfo(
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
          createdAt: now,
          updatedAt: now,
        );

        final map = additionalInfo.toMap();

        expect(map['regId'], equals('1234567890123'));
        expect(map['startDate'], equals(startDate.toIso8601String()));
        expect(map['endDate'], equals(endDate.toIso8601String()));
        expect(map['shirtCount'], equals(2));
        expect(map['pantsCount'], equals(2));
        expect(map['matCount'], equals(1));
        expect(map['pillowCount'], equals(1));
        expect(map['blanketCount'], equals(1));
        expect(map['location'], equals('ศาลาอุโบสถ ห้อง A1'));
        expect(map['withChildren'], equals(1));
        expect(map['childrenCount'], equals(2));
        expect(map['notes'], equals('เจมังสวิรัติ ไม่ทานเนื้อสัตว์'));
        expect(map['createdAt'], equals(now.toIso8601String()));
        expect(map['updatedAt'], equals(now.toIso8601String()));
      });

      test('fromMap creates RegAdditionalInfo from Map correctly', () {
        final startDate = DateTime(2024, 1, 15);
        final endDate = DateTime(2024, 1, 20);
        final now = DateTime.now();
        
        final map = {
          'regId': '1234567890123',
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'shirtCount': 2,
          'pantsCount': 2,
          'matCount': 1,
          'pillowCount': 1,
          'blanketCount': 1,
          'location': 'ศาลาอุโบสถ ห้อง A1',
          'withChildren': 1,
          'childrenCount': 2,
          'notes': 'เจมังสวิรัติ ไม่ทานเนื้อสัตว์',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        final additionalInfo = RegAdditionalInfo.fromMap(map);

        expect(additionalInfo.regId, equals('1234567890123'));
        expect(additionalInfo.startDate, equals(startDate));
        expect(additionalInfo.endDate, equals(endDate));
        expect(additionalInfo.shirtCount, equals(2));
        expect(additionalInfo.pantsCount, equals(2));
        expect(additionalInfo.matCount, equals(1));
        expect(additionalInfo.pillowCount, equals(1));
        expect(additionalInfo.blanketCount, equals(1));
        expect(additionalInfo.location, equals('ศาลาอุโบสถ ห้อง A1'));
        expect(additionalInfo.withChildren, isTrue);
        expect(additionalInfo.childrenCount, equals(2));
        expect(additionalInfo.notes, equals('เจมังสวิรัติ ไม่ทานเนื้อสัตว์'));
        expect(additionalInfo.createdAt, equals(now));
        expect(additionalInfo.updatedAt, equals(now));
      });

      test('fromMap handles null values correctly', () {
        final now = DateTime.now();
        final map = {
          'regId': '1234567890123',
          'startDate': null,
          'endDate': null,
          'shirtCount': null,
          'pantsCount': null,
          'matCount': null,
          'pillowCount': null,
          'blanketCount': null,
          'location': null,
          'withChildren': 0,
          'childrenCount': null,
          'notes': null,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        final additionalInfo = RegAdditionalInfo.fromMap(map);

        expect(additionalInfo.startDate, isNull);
        expect(additionalInfo.endDate, isNull);
        expect(additionalInfo.shirtCount, isNull);
        expect(additionalInfo.pantsCount, isNull);
        expect(additionalInfo.matCount, isNull);
        expect(additionalInfo.pillowCount, isNull);
        expect(additionalInfo.blanketCount, isNull);
        expect(additionalInfo.location, isNull);
        expect(additionalInfo.withChildren, isFalse);
        expect(additionalInfo.childrenCount, isNull);
        expect(additionalInfo.notes, isNull);
      });
    });

    group('Copy Method', () {
      late RegAdditionalInfo originalInfo;

      setUp(() {
        originalInfo = RegAdditionalInfo.create(
          regId: '1234567890123',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 20),
          shirtCount: 2,
          pantsCount: 2,
          matCount: 1,
          pillowCount: 1,
          blanketCount: 1,
          location: 'ศาลาอุโบสถ ห้อง A1',
          withChildren: true,
          childrenCount: 2,
          notes: 'เจมังสวิรัติ',
        );
      });

      test('copyWith updates specified fields only', () {
        final newEndDate = DateTime(2024, 1, 25);
        final updatedInfo = originalInfo.copyWith(
          endDate: newEndDate,
          shirtCount: 3,
          withChildren: false,
          notes: 'อัปเดตแล้ว',
        );

        expect(updatedInfo.endDate, equals(newEndDate));
        expect(updatedInfo.shirtCount, equals(3));
        expect(updatedInfo.withChildren, isFalse);
        expect(updatedInfo.notes, equals('อัปเดตแล้ว'));
        
        // Unchanged fields
        expect(updatedInfo.regId, equals(originalInfo.regId));
        expect(updatedInfo.startDate, equals(originalInfo.startDate));
        expect(updatedInfo.pantsCount, equals(originalInfo.pantsCount));
        expect(updatedInfo.matCount, equals(originalInfo.matCount));
        expect(updatedInfo.pillowCount, equals(originalInfo.pillowCount));
        expect(updatedInfo.blanketCount, equals(originalInfo.blanketCount));
        expect(updatedInfo.location, equals(originalInfo.location));
        expect(updatedInfo.childrenCount, equals(originalInfo.childrenCount));
        expect(updatedInfo.createdAt, equals(originalInfo.createdAt));
        expect(updatedInfo.updatedAt.isAfter(originalInfo.updatedAt), isTrue);
      });
    });
  });

  group('AddressInfo Tests', () {
    late AddressService mockAddressService;

    setUp(() {
      // Since AddressService is a singleton, we'll use a simple mock approach
      mockAddressService = AddressService();
      // Initialize with mock data
      mockAddressService.provinces = [
        Province(1, 'กรุงเทพมหานคร'),
        Province(2, 'เชียงใหม่'),
      ];
      mockAddressService.districts = [
        District(101, 1, 'เขตบางรัก'),
        District(201, 2, 'เมืองเชียงใหม่'),
      ];
      mockAddressService.subs = [
        SubDistrict(1001, 101, 'แขวงสีลม'),
        SubDistrict(2001, 201, 'ตำบลช้างคลาน'),
      ];
    });

    test('fromFullAddress parses address string correctly', () {
      const fullAddress = 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม, บ้านเลขที่ 123/45';
      
      final addressInfo = AddressInfo.fromFullAddress(fullAddress, mockAddressService);

      expect(addressInfo.provinceId, equals(1));
      expect(addressInfo.districtId, equals(101));
      expect(addressInfo.subDistrictId, equals(1001));
      expect(addressInfo.additionalAddress, equals('บ้านเลขที่ 123/45'));
    });

    test('toFullAddress reconstructs address string correctly', () {
      final addressInfo = AddressInfo(
        provinceId: 1,
        districtId: 101,
        subDistrictId: 1001,
        additionalAddress: 'บ้านเลขที่ 123/45',
      );

      final fullAddress = addressInfo.toFullAddress(mockAddressService);

      expect(fullAddress, equals('กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม, บ้านเลขที่ 123/45'));
    });

    test('handles incomplete address parts gracefully', () {
      const incompleteAddress = 'กรุงเทพมหานคร';
      
      final addressInfo = AddressInfo.fromFullAddress(incompleteAddress, mockAddressService);

      expect(addressInfo.provinceId, isNull);
      expect(addressInfo.districtId, isNull);
      expect(addressInfo.subDistrictId, isNull);
      expect(addressInfo.additionalAddress, isNull);
    });

    test('toFullAddress returns empty string for incomplete data', () {
      final incompleteAddressInfo = AddressInfo(provinceId: 1); // Missing district and sub-district

      final fullAddress = incompleteAddressInfo.toFullAddress(mockAddressService);

      expect(fullAddress, equals(''));
    });
  });
}