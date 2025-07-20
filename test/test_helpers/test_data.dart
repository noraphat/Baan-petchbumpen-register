import 'package:flutter_petchbumpen_register/models/reg_data.dart';
import 'package:flutter_petchbumpen_register/services/address_service.dart';

/// Test data helpers for consistent test data across the test suite
class TestData {
  // Sample RegData for testing
  static RegData get sampleRegDataWithIdCard => RegData.fromIdCard(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2530',
        addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
        gender: 'ชาย',
        phone: '0812345678',
      );

  static RegData get sampleRegDataManual => RegData.manual(
        id: '0823456789',
        first: 'สมหญิง',
        last: 'ใจงาม',
        dob: '20 กุมภาพันธ์ 2535',
        phone: '0823456789',
        addr: 'เชียงใหม่, เมืองเชียงใหม่, ตำบลช้างคลาน',
        gender: 'หญิง',
      );

  static RegData get sampleRegDataMonk => RegData.manual(
        id: '0834567890',
        first: 'พระสมจิตต์',
        last: 'ธรรมสาโร',
        dob: '10 พฤษภาคม 2520',
        phone: '0834567890',
        addr: 'สงขลา, เมืองสงขลา, ตำบลบ่อยาง',
        gender: 'พระ',
      );

  static RegData get sampleRegDataNun => RegData.manual(
        id: '0845678901',
        first: 'แม่ชีสมจิตต์',
        last: 'ธรรมชาดา',
        dob: '5 มิถุนายน 2525',
        phone: '0845678901',
        addr: 'นครปฐม, เมืองนครปฐม, ตำบลพระปฐมเจดีย์',
        gender: 'แม่ชี',
      );

  // Sample RegAdditionalInfo for testing
  static RegAdditionalInfo get sampleAdditionalInfo => RegAdditionalInfo.create(
        regId: '1234567890123',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 22),
        shirtCount: 2,
        pantsCount: 2,
        matCount: 1,
        pillowCount: 1,
        blanketCount: 1,
        location: 'ศาลาอุโบสถ ห้อง A1',
        withChildren: false,
        notes: 'เจมังสวิรัติ ไม่ทานเนื้อสัตว์',
      );

  static RegAdditionalInfo get sampleAdditionalInfoWithChildren => RegAdditionalInfo.create(
        regId: '0823456789',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        shirtCount: 3,
        pantsCount: 3,
        matCount: 2,
        pillowCount: 2,
        blanketCount: 2,
        location: 'ศาลาปฏิบัติธรรม ห้อง B2',
        withChildren: true,
        childrenCount: 2,
        notes: 'มากับลูก 2 คน อายุ 8 และ 12 ปี',
      );

  static RegAdditionalInfo get sampleAdditionalInfoMinimal => RegAdditionalInfo.create(
        regId: '0834567890',
        startDate: DateTime(2024, 3, 10),
        endDate: DateTime(2024, 3, 15),
        shirtCount: 1,
        pantsCount: 1,
        matCount: 1,
        pillowCount: 1,
        blanketCount: 1,
        location: 'กุฏิสงฆ์ ห้อง C3',
        withChildren: false,
        notes: 'พระสงฆ์',
      );

  // Mock address data for testing
  static List<Province> get mockProvinces => [
        Province(1, 'กรุงเทพมหานคร'),
        Province(2, 'เชียงใหม่'),
        Province(3, 'สงขลา'),
        Province(4, 'นครปฐม'),
        Province(5, 'ขอนแก่น'),
      ];

  static List<District> get mockDistricts => [
        // Bangkok districts
        District(101, 1, 'เขตบางรัก'),
        District(102, 1, 'เขตจตุจักร'),
        District(103, 1, 'เขตปทุมวัน'),
        District(104, 1, 'เขตวัฒนา'),
        
        // Chiang Mai districts
        District(201, 2, 'เมืองเชียงใหม่'),
        District(202, 2, 'สันทราย'),
        District(203, 2, 'ดอยสะเก็ด'),
        
        // Songkhla districts
        District(301, 3, 'เมืองสงขลา'),
        District(302, 3, 'หาดใหญ่'),
        
        // Nakhon Pathom districts
        District(401, 4, 'เมืองนครปฐม'),
        District(402, 4, 'กำแพงแสน'),
        
        // Khon Kaen districts
        District(501, 5, 'เมืองขอนแก่น'),
        District(502, 5, 'บ้านไผ่'),
      ];

  static List<SubDistrict> get mockSubDistricts => [
        // Bangkok sub-districts
        SubDistrict(1001, 101, 'แขวงสีลม'),
        SubDistrict(1002, 101, 'แขวงสุริยวงศ์'),
        SubDistrict(1003, 102, 'แขวงลาดยาว'),
        SubDistrict(1004, 102, 'แขวงจอมพล'),
        SubDistrict(1005, 103, 'แขวงลุมพินี'),
        SubDistrict(1006, 104, 'แขวงคลองตันเหนือ'),
        
        // Chiang Mai sub-districts
        SubDistrict(2001, 201, 'ตำบลช้างคลาน'),
        SubDistrict(2002, 201, 'ตำบลวัดเกต'),
        SubDistrict(2003, 202, 'ตำบลสันทราย'),
        SubDistrict(2004, 203, 'ตำบลดอยสะเก็ด'),
        
        // Songkhla sub-districts
        SubDistrict(3001, 301, 'ตำบลบ่อยาง'),
        SubDistrict(3002, 301, 'ตำบลเขารูปช้าง'),
        SubDistrict(3003, 302, 'ตำบลหาดใหญ่'),
        
        // Nakhon Pathom sub-districts
        SubDistrict(4001, 401, 'ตำบลพระปฐมเจดีย์'),
        SubDistrict(4002, 401, 'ตำบลท่าตะเกียง'),
        SubDistrict(4003, 402, 'ตำบลกำแพงแสน'),
        
        // Khon Kaen sub-districts
        SubDistrict(5001, 501, 'ตำบลในเมือง'),
        SubDistrict(5002, 502, 'ตำบลบ้านไผ่'),
      ];

  // Sample form input data
  static Map<String, String> get validFormData => {
        'id': '1234567890123',
        'first': 'สมชาย',
        'last': 'ใจดี',
        'dob': '15 มกราคม 2530',
        'phone': '0812345678',
        'gender': 'ชาย',
      };

  static Map<String, String> get invalidFormData => {
        'id': '123', // Too short
        'first': '', // Empty
        'last': '', // Empty
        'dob': '', // Empty
        'phone': '',
        'gender': 'ชาย',
      };

  // Gender options
  static List<String> get genderOptions => [
        'พระ',
        'สามเณร',
        'แม่ชี',
        'ชาย',
        'หญิง',
        'อื่นๆ',
      ];

  // Test dates with Buddhist Era formatting
  static Map<String, String> get thaiDateExamples => {
        '15 มกราคม 2530': 'January 15, 1987',
        '20 กุมภาพันธ์ 2535': 'February 20, 1992',
        '10 พฤษภาคม 2520': 'May 10, 1977',
        '5 มิถุนายน 2525': 'June 5, 1982',
        '31 ธันวาคม 2566': 'December 31, 2023',
      };

  // Test phone numbers
  static List<String> get validPhoneNumbers => [
        '0812345678',
        '0823456789',
        '0834567890',
        '0845678901',
        '0856789012',
      ];

  static List<String> get invalidPhoneNumbers => [
        '123', // Too short
        '08123456789', // Too long
        'abcd123456', // Contains letters
        '', // Empty
        '1234567890', // Doesn't start with 0
      ];

  // Test addresses
  static Map<String, String> get sampleAddresses => {
        'bangkok_full': 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม, บ้านเลขที่ 123/45',
        'chiangmai_full': 'เชียงใหม่, เมืองเชียงใหม่, ตำบลช้างคลาน, หมู่ 5 บ้านเลขที่ 67',
        'songkhla_minimal': 'สงขลา, เมืองสงขลา, ตำบลบ่อยาง',
        'nakhon_pathom': 'นครปฐม, เมืองนครปฐม, ตำบลพระปฐมเจดีย์, ซอย 10',
      };

  // Common test scenarios
  static List<Map<String, dynamic>> get testScenarios => [
        {
          'name': 'Regular Person with ID Card',
          'regData': sampleRegDataWithIdCard,
          'additionalInfo': sampleAdditionalInfo,
          'hasIdCard': true,
          'canEditAll': false,
        },
        {
          'name': 'Manual Registration Without ID Card',
          'regData': sampleRegDataManual,
          'additionalInfo': sampleAdditionalInfoWithChildren,
          'hasIdCard': false,
          'canEditAll': true,
        },
        {
          'name': 'Monk Registration',
          'regData': sampleRegDataMonk,
          'additionalInfo': sampleAdditionalInfoMinimal,
          'hasIdCard': false,
          'canEditAll': true,
        },
        {
          'name': 'Nun Registration',
          'regData': sampleRegDataNun,
          'additionalInfo': null,
          'hasIdCard': false,
          'canEditAll': true,
        },
      ];

  // Error test cases
  static Map<String, dynamic> get errorTestCases => {
        'duplicate_id': {
          'description': 'Duplicate ID registration attempt',
          'id': '1234567890123',
          'expectedError': 'ID already exists',
        },
        'invalid_date': {
          'description': 'Invalid date format',
          'date': '32 มกราคม 2530',
          'expectedError': 'Invalid date',
        },
        'missing_required_fields': {
          'description': 'Missing required form fields',
          'data': {'id': '1234567890123'},
          'expectedErrors': ['first', 'last', 'dob'],
        },
      };

  // Performance test data
  static List<RegData> generateLargeDataset(int count) {
    final List<RegData> dataset = [];
    
    for (int i = 0; i < count; i++) {
      dataset.add(RegData.manual(
        id: '${1000000000000 + i}',
        first: 'ผู้ทดสอบ${i + 1}',
        last: 'ระบบ',
        dob: '${(i % 28) + 1} มกราคม ${2500 + (i % 50)}',
        phone: '08${i.toString().padLeft(8, '0')}',
        addr: 'จังหวัดทดสอบ, อำเภอทดสอบ, ตำบลทดสอบ${i + 1}',
        gender: genderOptions[i % genderOptions.length],
      ));
    }
    
    return dataset;
  }

  // Utility methods for test setup
  static void setupMockAddressService(AddressService service) {
    service.provinces.clear();
    service.districts.clear();
    service.subs.clear();
    
    service.provinces.addAll(mockProvinces);
    service.districts.addAll(mockDistricts);
    service.subs.addAll(mockSubDistricts);
  }

  static Future<void> insertSampleData(dynamic dbHelper) async {
    // Insert sample registration data
    await dbHelper.insert(sampleRegDataWithIdCard);
    await dbHelper.insert(sampleRegDataManual);
    await dbHelper.insert(sampleRegDataMonk);
    
    // Insert sample additional info
    await dbHelper.insertAdditionalInfo(sampleAdditionalInfo);
    await dbHelper.insertAdditionalInfo(sampleAdditionalInfoWithChildren);
    await dbHelper.insertAdditionalInfo(sampleAdditionalInfoMinimal);
  }

  // Clean up methods
  static Future<void> clearAllData(dynamic dbHelper) async {
    await dbHelper.clearAllData();
  }
}