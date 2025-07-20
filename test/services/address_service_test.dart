import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_petchbumpen_register/services/address_service.dart';

void main() {
  group('AddressService Tests', () {
    late AddressService addressService;

    setUp(() {
      addressService = AddressService();
      // Reset the singleton for each test
      addressService.provinces.clear();
      addressService.districts.clear();
      addressService.subs.clear();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final service1 = AddressService();
        final service2 = AddressService();
        expect(identical(service1, service2), isTrue);
      });
    });

    group('Data Models', () {
      test('Province model stores data correctly', () {
        final province = Province(1, 'กรุงเทพมหานคร');
        expect(province.id, equals(1));
        expect(province.nameTh, equals('กรุงเทพมหานคร'));
      });

      test('District model stores data correctly', () {
        final district = District(101, 1, 'เขตบางรัก');
        expect(district.id, equals(101));
        expect(district.provinceId, equals(1));
        expect(district.nameTh, equals('เขตบางรัก'));
      });

      test('SubDistrict model stores data correctly', () {
        final subDistrict = SubDistrict(1001, 101, 'แขวงสีลม');
        expect(subDistrict.id, equals(1001));
        expect(subDistrict.amphureId, equals(101));
        expect(subDistrict.nameTh, equals('แขวงสีลม'));
      });
    });

    group('Data Loading and Parsing', () {
      setUpAll(() {
        // Mock the asset bundle loading
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              final String key = methodCall.arguments;
              if (key == 'assets/addresses/thai_provinces.json') {
                return '''[
                  {"id": 1, "name_th": "กรุงเทพมหานคร"},
                  {"id": 2, "name_th": "เชียงใหม่"},
                  {"id": 3, "name_th": "สงขลา"}
                ]''';
              } else if (key == 'assets/addresses/thai_amphures.json') {
                return '''[
                  {"id": 101, "province_id": 1, "name_th": "เขตบางรัก"},
                  {"id": 102, "province_id": 1, "name_th": "เขตจตุจักร"},
                  {"id": 201, "province_id": 2, "name_th": "เมืองเชียงใหม่"},
                  {"id": 301, "province_id": 3, "name_th": "เมืองสงขลา"}
                ]''';
              } else if (key == 'assets/addresses/thai_tambons.json') {
                return '''[
                  {"id": 1001, "amphure_id": 101, "name_th": "แขวงสีลม"},
                  {"id": 1002, "amphure_id": 101, "name_th": "แขวงสุริยวงศ์"},
                  {"id": 1003, "amphure_id": 102, "name_th": "แขวงลาดยาว"},
                  {"id": 2001, "amphure_id": 201, "name_th": "ตำบลช้างคลาน"},
                  {"id": 3001, "amphure_id": 301, "name_th": "ตำบลบ่อยาง"}
                ]''';
              }
            }
            return null;
          },
        );
      });

      tearDownAll(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('flutter/assets'), null);
      });

      test('should load and parse provinces correctly', () async {
        await addressService.init();

        expect(addressService.provinces.length, equals(3));
        expect(addressService.provinces[0].id, equals(1));
        expect(addressService.provinces[0].nameTh, equals('กรุงเทพมหานคร'));
        expect(addressService.provinces[1].id, equals(2));
        expect(addressService.provinces[1].nameTh, equals('เชียงใหม่'));
        expect(addressService.provinces[2].id, equals(3));
        expect(addressService.provinces[2].nameTh, equals('สงขลา'));
      });

      test('should load and parse districts correctly', () async {
        await addressService.init();

        expect(addressService.districts.length, equals(4));
        
        final bangrakDistrict = addressService.districts
            .where((d) => d.id == 101)
            .first;
        expect(bangrakDistrict.provinceId, equals(1));
        expect(bangrakDistrict.nameTh, equals('เขตบางรัก'));
        
        final chatuchakDistrict = addressService.districts
            .where((d) => d.id == 102)
            .first;
        expect(chatuchakDistrict.provinceId, equals(1));
        expect(chatuchakDistrict.nameTh, equals('เขตจตุจักร'));
      });

      test('should load and parse sub-districts correctly', () async {
        await addressService.init();

        expect(addressService.subs.length, equals(5));
        
        final silomSub = addressService.subs
            .where((s) => s.id == 1001)
            .first;
        expect(silomSub.amphureId, equals(101));
        expect(silomSub.nameTh, equals('แขวงสีลม'));
        
        final changklanSub = addressService.subs
            .where((s) => s.id == 2001)
            .first;
        expect(changklanSub.amphureId, equals(201));
        expect(changklanSub.nameTh, equals('ตำบลช้างคลาน'));
      });

      test('should not reload data if already initialized', () async {
        await addressService.init();
        final initialProvinceCount = addressService.provinces.length;
        
        // Try to init again
        await addressService.init();
        
        expect(addressService.provinces.length, equals(initialProvinceCount));
      });
    });

    group('Data Filtering and Searching', () {
      setUp(() async {
        // Set up mock data manually for filtering tests
        addressService.provinces = [
          Province(1, 'กรุงเทพมหานคร'),
          Province(2, 'เชียงใหม่'),
          Province(3, 'สงขลา'),
        ];
        
        addressService.districts = [
          District(101, 1, 'เขตบางรัก'),
          District(102, 1, 'เขตจตุจักร'),
          District(201, 2, 'เมืองเชียงใหม่'),
          District(301, 3, 'เมืองสงขลา'),
        ];
        
        addressService.subs = [
          SubDistrict(1001, 101, 'แขวงสีลม'),
          SubDistrict(1002, 101, 'แขวงสุริยวงศ์'),
          SubDistrict(1003, 102, 'แขวงลาดยาว'),
          SubDistrict(2001, 201, 'ตำบลช้างคลาน'),
          SubDistrict(3001, 301, 'ตำบลบ่อยาง'),
        ];
      });

      test('districtsOf should return districts for specific province', () {
        final bangkokDistricts = addressService.districtsOf(1);
        
        expect(bangkokDistricts.length, equals(2));
        expect(bangkokDistricts[0].nameTh, equals('เขตบางรัก'));
        expect(bangkokDistricts[1].nameTh, equals('เขตจตุจักร'));
        
        final chiangmaiDistricts = addressService.districtsOf(2);
        expect(chiangmaiDistricts.length, equals(1));
        expect(chiangmaiDistricts[0].nameTh, equals('เมืองเชียงใหม่'));
      });

      test('subsOf should return sub-districts for specific district', () {
        final bangrakSubs = addressService.subsOf(101);
        
        expect(bangrakSubs.length, equals(2));
        expect(bangrakSubs[0].nameTh, equals('แขวงสีลม'));
        expect(bangrakSubs[1].nameTh, equals('แขวงสุริยวงศ์'));
        
        final chatuchakSubs = addressService.subsOf(102);
        expect(chatuchakSubs.length, equals(1));
        expect(chatuchakSubs[0].nameTh, equals('แขวงลาดยาว'));
      });

      test('should return empty list for non-existent province', () {
        final nonExistentDistricts = addressService.districtsOf(999);
        expect(nonExistentDistricts, isEmpty);
      });

      test('should return empty list for non-existent district', () {
        final nonExistentSubs = addressService.subsOf(999);
        expect(nonExistentSubs, isEmpty);
      });
    });

    group('ID Lookup Methods', () {
      setUp(() {
        addressService.provinces = [
          Province(1, 'กรุงเทพมหานคร'),
          Province(2, 'เชียงใหม่'),
        ];
        
        addressService.districts = [
          District(101, 1, 'เขตบางรัก'),
          District(201, 2, 'เมืองเชียงใหม่'),
        ];
        
        addressService.subs = [
          SubDistrict(1001, 101, 'แขวงสีลม'),
          SubDistrict(2001, 201, 'ตำบลช้างคลาน'),
        ];
      });

      test('provinceById should return correct province', () {
        final province = addressService.provinceById(1);
        expect(province?.nameTh, equals('กรุงเทพมหานคร'));
      });

      test('districtById should return correct district', () {
        final district = addressService.districtById(101);
        expect(district?.nameTh, equals('เขตบางรัก'));
      });

      test('subById should return correct sub-district', () {
        final sub = addressService.subById(1001);
        expect(sub?.nameTh, equals('แขวงสีลม'));
      });

      test('should return empty object for non-existent IDs', () {
        final nonExistentProvince = addressService.provinceById(999);
        expect(nonExistentProvince?.nameTh, equals(''));
        
        final nonExistentDistrict = addressService.districtById(999);
        expect(nonExistentDistrict?.nameTh, equals(''));
        
        final nonExistentSub = addressService.subById(999);
        expect(nonExistentSub?.nameTh, equals(''));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty JSON arrays gracefully', () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return '[]'; // Empty array
            }
            return null;
          },
        );

        expect(() async => await addressService.init(), returnsNormally);
      });

      test('should handle malformed JSON gracefully', () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return '{invalid json}'; // Malformed JSON
            }
            return null;
          },
        );

        expect(() async => await addressService.init(), throwsFormatException);
      });

      test('should handle missing asset files gracefully', () {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            throw Exception('Asset not found');
          },
        );

        expect(() async => await addressService.init(), throwsException);
      });
    });
  });
}