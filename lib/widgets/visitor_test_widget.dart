import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reg_data.dart';

class VisitorTestWidget extends StatelessWidget {
  const VisitorTestWidget({super.key});

  Future<void> _createTestData() async {
    final dbHelper = DbHelper();
    
    // ข้อมูลทดสอบ 1 - คนมีบัตรประชาชน
    final visitor1 = RegData.fromIdCard(
      id: '1234567890123',
      first: 'สมศักดิ์',
      last: 'ใจดี',
      dob: '15 มกราคม 2530',
      addr: 'กรุงเทพมหานคร, เขตปทุมวัน, แขวงลุมพินี, 123/456',
      gender: 'ชาย',
      phone: '0812345678',
    );
    
    // ข้อมูลทดสอบ 2 - คนไม่มีบัตรประชาชน
    final visitor2 = RegData.manual(
      id: '0898765432',
      first: 'สมหมาย',
      last: 'ใจเย็น',
      dob: '28 กุมภาพันธ์ 2545',
      phone: '0898765432',
      addr: 'เชียงใหม่, เมืองเชียงใหม่, ศรีภูมิ, 789/123',
      gender: 'หญิง',
    );
    
    try {
      await dbHelper.insert(visitor1);
      await dbHelper.insert(visitor2);
      
      // เพิ่มข้อมูลเพิ่มเติม
      final additionalInfo1 = RegAdditionalInfo.create(
        regId: visitor1.id,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        shirtCount: 2,
        pantsCount: 2,
        matCount: 1,
        pillowCount: 1,
        blanketCount: 1,
        location: 'ศาลา A-1',
        notes: 'แพ้อาหารทะเล',
      );
      
      final additionalInfo2 = RegAdditionalInfo.create(
        regId: visitor2.id,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        shirtCount: 1,
        pantsCount: 1,
        matCount: 1,
        pillowCount: 1,
        blanketCount: 1,
        location: 'กุฏิ B-5',
        notes: 'ต้องการห้องเงียบ',
      );
      
      await dbHelper.insertAdditionalInfo(additionalInfo1);
      await dbHelper.insertAdditionalInfo(additionalInfo2);
      
      // เพิ่มประวัติการเข้าพัก
      final stay1 = StayRecord.create(
        visitorId: visitor1.id,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        status: 'active',
        note: 'การปฏิบัติธรรมครั้งแรก',
      );
      
      final stay2 = StayRecord.create(
        visitorId: visitor2.id,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        status: 'active',
        note: 'ต่อเวลาปฏิบัติธรรม',
      );
      
      await dbHelper.insertStay(stay1);
      await dbHelper.insertStay(stay2);
      
      print('✅ สร้างข้อมูลทดสอบเรียบร้อยแล้ว');
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการสร้างข้อมูลทดสอบ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _createTestData,
      backgroundColor: Colors.orange,
      child: const Icon(Icons.add_box, color: Colors.white),
    );
  }
}