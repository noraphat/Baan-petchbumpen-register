import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  group('DbHelper Service Tests', () {
    late DbHelper dbHelper;

    setUpAll(() async {
      // Initialize sqflite for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DbHelper();
      await dbHelper.clearAllData();
    });

    tearDown(() async {
      await dbHelper.clearAllData();
    });

    test('should insert and fetch RegData', () async {
      final testUser = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      await dbHelper.insert(testUser);
      final fetchedUser = await dbHelper.fetchById(testUser.id);

      expect(fetchedUser, isNotNull);
      expect(fetchedUser!.id, testUser.id);
      expect(fetchedUser.first, testUser.first);
      expect(fetchedUser.last, testUser.last);
    });

    test('should update RegData', () async {
      final testUser = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      await dbHelper.insert(testUser);

      final updatedUser = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดีใหม่',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      await dbHelper.update(updatedUser);
      final fetchedUser = await dbHelper.fetchById(testUser.id);

      expect(fetchedUser!.last, 'ใจดีใหม่');
    });

    test('should delete RegData', () async {
      final testUser = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      await dbHelper.insert(testUser);
      await dbHelper.delete(testUser.id);
      final fetchedUser = await dbHelper.fetchById(testUser.id);

      expect(fetchedUser?.status, equals('I'));
    });

    test('should fetch all RegData', () async {
      final testUser1 = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      final testUser2 = RegData.manual(
        id: '9876543210987',
        first: 'สมหญิง',
        last: 'ใจดี',
        dob: '20 มกราคม 2500',
        phone: '0898765432',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'หญิง',
      );

      await dbHelper.insert(testUser1);
      await dbHelper.insert(testUser2);

      final allUsers = await dbHelper.fetchAll();
      expect(allUsers.length, 2);
    });

    test('should get available genders', () async {
      final testUser1 = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      final testUser2 = RegData.manual(
        id: '9876543210987',
        first: 'สมหญิง',
        last: 'ใจดี',
        dob: '20 มกราคม 2500',
        phone: '0898765432',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'หญิง',
      );

      await dbHelper.insert(testUser1);
      await dbHelper.insert(testUser2);

      final genders = await dbHelper.getAvailableGenders();
      expect(genders.contains('ชาย'), true);
      expect(genders.contains('หญิง'), true);
    });
  });
}
