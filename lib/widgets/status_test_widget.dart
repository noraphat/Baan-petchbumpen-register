import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reg_data.dart';

class StatusTestWidget extends StatelessWidget {
  const StatusTestWidget({super.key});

  Future<void> _createExpiredStaysForTesting() async {
    final dbHelper = DbHelper();
    
    try {
      // ลองดึงผู้ใช้ที่มีอยู่แล้ว
      final visitors = await dbHelper.fetchAll();
      if (visitors.isEmpty) {
        print('⚠️ ไม่มีข้อมูลผู้ปฏิบัติธรรม กรุณาสร้างข้อมูลก่อน');
        return;
      }
      
      final visitor = visitors.first;
      final today = DateTime.now();
      
      // สร้าง Stay ที่หมดอายุแล้ว (เมื่อ 3 วันที่แล้ว - เมื่อ 1 วันที่แล้ว)
      final expiredStay1 = StayRecord.create(
        visitorId: visitor.id,
        startDate: today.subtract(const Duration(days: 3)),
        endDate: today.subtract(const Duration(days: 1)), // หมดอายุแล้ว
        status: 'active', // ยังเป็น active ในฐานข้อมูล
        note: 'ทดสอบ - ควรอัปเดตเป็น completed',
      );
      
      // สร้าง Stay ที่หมดอายุแล้ว (เมื่อ 5 วันที่แล้ว - เมื่อ 2 วันที่แล้ว)
      final expiredStay2 = StayRecord.create(
        visitorId: visitor.id,
        startDate: today.subtract(const Duration(days: 5)),
        endDate: today.subtract(const Duration(days: 2)), // หมดอายุแล้ว
        status: 'extended', // ยังเป็น extended ในฐานข้อมูล
        note: 'ทดสอบ - ควรอัปเดตเป็น completed',
      );
      
      // สร้าง Stay ที่ยังไม่หมดอายุ (วันนี้ - อีก 2 วัน)
      final activeStay = StayRecord.create(
        visitorId: visitor.id,
        startDate: today,
        endDate: today.add(const Duration(days: 2)), // ยังไม่หมดอายุ
        status: 'active',
        note: 'ทดสอบ - ควรยังคงเป็น active',
      );
      
      // เพิ่มข้อมูลในฐานข้อมูล
      await dbHelper.insertStay(expiredStay1);
      await dbHelper.insertStay(expiredStay2);
      await dbHelper.insertStay(activeStay);
      
      print('✅ สร้างข้อมูลทดสอบสำหรับ Status Update แล้ว');
      print('📊 รายการที่สร้าง:');
      print('  - Stay หมดอายุ 1: ${visitor.first} ${visitor.last} (active → completed)');
      print('  - Stay หมดอายุ 2: ${visitor.first} ${visitor.last} (extended → completed)');
      print('  - Stay ยังไม่หมดอายุ: ${visitor.first} ${visitor.last} (active)');
      
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการสร้างข้อมูลทดสอบ: $e');
    }
  }

  Future<void> _testStatusUpdate() async {
    final dbHelper = DbHelper();
    
    try {
      print('🔄 ทดสอบการอัปเดตสถานะ...');
      
      // ดึงข้อมูล Stay ทั้งหมดก่อนอัปเดต
      final allVisitors = await dbHelper.fetchAll();
      if (allVisitors.isEmpty) {
        print('⚠️ ไม่มีข้อมูลผู้ปฏิบัติธรรม');
        return;
      }
      
      final visitor = allVisitors.first;
      print('📝 ก่อนอัปเดต:');
      final staysBeforeUpdate = await dbHelper.fetchAllStays(visitor.id);
      for (final stay in staysBeforeUpdate) {
        print('  - วันที่: ${_formatDate(stay.startDate)} - ${_formatDate(stay.endDate)}');
        print('    สถานะในฐานข้อมูล: ${stay.status}');
        print('    สถานะจริง: ${stay.actualStatus}');
        print('    หมดอายุ: ${stay.isExpired}');
        print('    ต้องการอัปเดต: ${stay.needsStatusUpdate}');
      }
      
      // รันฟังก์ชันอัปเดตสถานะ
      await dbHelper.updateExpiredStays();
      
      print('\n📝 หลังอัปเดต:');
      final staysAfterUpdate = await dbHelper.fetchAllStays(visitor.id);
      for (final stay in staysAfterUpdate) {
        print('  - วันที่: ${_formatDate(stay.startDate)} - ${_formatDate(stay.endDate)}');
        print('    สถานะในฐานข้อมูล: ${stay.status}');
        print('    สถานะจริง: ${stay.actualStatus}');
      }
      
      print('✅ ทดสอบการอัปเดตสถานะเสร็จสิ้น');
      
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการทดสอบ: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: _createExpiredStaysForTesting,
          backgroundColor: Colors.blue,
          heroTag: "create_test_data",
          child: const Icon(Icons.add_alarm, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: _testStatusUpdate,
          backgroundColor: Colors.green,
          heroTag: "test_status_update",
          child: const Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }
}