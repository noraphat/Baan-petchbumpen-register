import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  group('RegData Model Tests', () {
    test('should create RegData from manual constructor', () {
      final regData = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      expect(regData.id, '1234567890123');
      expect(regData.first, 'สมชาย');
      expect(regData.last, 'ใจดี');
      expect(regData.dob, '15 มกราคม 2500');
      expect(regData.phone, '0812345678');
      expect(regData.addr, 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์');
      expect(regData.gender, 'ชาย');
      expect(regData.hasIdCard, false);
      expect(regData.status, 'A');
    });

    test('should create RegData from ID card constructor', () {
      final regData = RegData.fromIdCard(
        id: '1234567890123',
        first: 'สมหญิง',
        last: 'ใจดี',
        dob: '20 มกราคม 2500',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'หญิง',
        phone: '0898765432',
      );

      expect(regData.id, '1234567890123');
      expect(regData.first, 'สมหญิง');
      expect(regData.last, 'ใจดี');
      expect(regData.dob, '20 มกราคม 2500');
      expect(regData.phone, '0898765432');
      expect(regData.addr, 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์');
      expect(regData.gender, 'หญิง');
      expect(regData.hasIdCard, true);
      expect(regData.status, 'A');
    });

    test('should convert RegData to Map', () {
      final regData = RegData.manual(
        id: '1234567890123',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2500',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        gender: 'ชาย',
      );

      final map = regData.toMap();

      expect(map['id'], '1234567890123');
      expect(map['first'], 'สมชาย');
      expect(map['last'], 'ใจดี');
      expect(map['dob'], '15 มกราคม 2500');
      expect(map['phone'], '0812345678');
      expect(map['addr'], 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์');
      expect(map['gender'], 'ชาย');
      expect(map['hasIdCard'], 0);
      expect(map['status'], 'A');
    });

    test('should create RegData from Map', () {
      final map = {
        'id': '1234567890123',
        'first': 'สมชาย',
        'last': 'ใจดี',
        'dob': '15 มกราคม 2500',
        'phone': '0812345678',
        'addr': 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์',
        'gender': 'ชาย',
        'hasIdCard': 0,
        'status': 'A',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final regData = RegData.fromMap(map);

      expect(regData.id, '1234567890123');
      expect(regData.first, 'สมชาย');
      expect(regData.last, 'ใจดี');
      expect(regData.dob, '15 มกราคม 2500');
      expect(regData.phone, '0812345678');
      expect(regData.addr, 'กรุงเทพมหานคร, บางรัก, สุริยวงศ์');
      expect(regData.gender, 'ชาย');
      expect(regData.hasIdCard, false);
      expect(regData.status, 'A');
    });
  });
}
