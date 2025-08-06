import 'package:flutter/foundation.dart';
import '../models/reg_data.dart';
import 'db_helper.dart';

/// บริการจัดการการลงทะเบียนผู้ปฏิบัติธรรม
/// รองรับ 4 กรณีการใช้งาน:
/// 1. มาครั้งแรกพร้อมบัตรประชาชน -> hasIdCard = 1
/// 2. มาครั้งที่ 2 ไม่พกบัตร -> ใช้ข้อมูลเดิม hasIdCard = 1
/// 3. มาครั้งแรกไม่ใช้บัตร -> hasIdCard = 0
/// 4. มาครั้งต่อมาแล้วพกบัตรมาครั้งแรก -> อัปเดต hasIdCard = 0 -> 1
class RegistrationService {
  final DbHelper _dbHelper = DbHelper();

  /// ตรวจสอบว่ามี RegData อยู่ในฐานข้อมูลแล้วหรือไม่
  Future<RegData?> findExistingRegistration(String id) async {
    try {
      final db = await _dbHelper.db;
      final results = await db.query(
        'regs',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (results.isEmpty) return null;
      
      return RegData.fromMap(results.first);
    } catch (e) {
      debugPrint('❌ Error finding registration: $e');
      return null;
    }
  }

  /// กรณีที่ 1: มาครั้งแรกพร้อมบัตรประชาชน
  /// สร้างข้อมูลใหม่ + set hasIdCard = 1
  Future<RegData?> registerWithIdCard({
    required String id,
    required String first,
    required String last,
    required String dob,
    required String addr,
    required String gender,
    String phone = '',
  }) async {
    try {
      // ตรวจสอบว่ายังไม่มีข้อมูลเดิม
      final existing = await findExistingRegistration(id);
      if (existing != null) {
        debugPrint('❌ ID $id มีข้อมูลอยู่แล้ว');
        return null;
      }

      // สร้างข้อมูลใหม่
      final regData = RegData.fromIdCard(
        id: id,
        first: first,
        last: last,
        dob: dob,
        addr: addr,
        gender: gender,
        phone: phone,
      );

      final db = await _dbHelper.db;
      await db.insert('regs', regData.toMap());

      debugPrint('✅ ลงทะเบียนด้วยบัตรประชาชนสำเร็จ: $id');
      return regData;
    } catch (e) {
      debugPrint('❌ Error registering with ID card: $e');
      return null;
    }
  }

  /// กรณีที่ 2: มาครั้งที่ 2 แต่ไม่พกบัตร
  /// ค้นหาข้อมูลเดิม + ตรวจสอบ hasIdCard = 1
  /// ไม่อัปเดตข้อมูล regs เดิม
  Future<RegData?> validateExistingWithIdCard(String id) async {
    try {
      final existing = await findExistingRegistration(id);
      
      if (existing == null) {
        debugPrint('❌ ไม่พบข้อมูล ID: $id');
        return null;
      }

      if (!existing.hasIdCard) {
        debugPrint('❌ ID $id ไม่ได้ลงทะเบียนด้วยบัตรประชาชน');
        return null;
      }

      debugPrint('✅ พบข้อมูลเดิม (มีบัตร): $id');
      return existing;
    } catch (e) {
      debugPrint('❌ Error validating existing registration: $e');
      return null;
    }
  }

  /// กรณีที่ 3: มาครั้งแรก (แต่ไม่ได้ใช้บัตร)
  /// กรอกข้อมูลเองแบบ Manual + set hasIdCard = 0
  Future<RegData?> registerManual({
    required String id,
    required String first,
    required String last,
    required String dob,
    required String phone,
    required String addr,
    required String gender,
  }) async {
    try {
      // ตรวจสอบว่ายังไม่มีข้อมูลเดิม
      final existing = await findExistingRegistration(id);
      if (existing != null) {
        debugPrint('❌ ID $id มีข้อมูลอยู่แล้ว');
        return null;
      }

      // สร้างข้อมูลใหม่
      final regData = RegData.manual(
        id: id,
        first: first,
        last: last,
        dob: dob,
        phone: phone,
        addr: addr,
        gender: gender,
      );

      final db = await _dbHelper.db;
      await db.insert('regs', regData.toMap());

      debugPrint('✅ ลงทะเบียนแบบ Manual สำเร็จ: $id');
      return regData;
    } catch (e) {
      debugPrint('❌ Error registering manually: $e');
      return null;
    }
  }

  /// กรณีที่ 4: มาครั้งต่อมา แล้วพกบัตรมาครั้งแรก
  /// อัปเดตข้อมูลจากบัตร + set hasIdCard = 1
  Future<RegData?> upgradeToIdCard({
    required String id,
    required String first,
    required String last,
    required String dob,
    required String addr,
    required String gender,
    String phone = '',
  }) async {
    try {
      // ตรวจสอบว่ามีข้อมูลเดิม และ hasIdCard = 0
      final existing = await findExistingRegistration(id);
      if (existing == null) {
        debugPrint('❌ ไม่พบข้อมูล ID: $id');
        return null;
      }

      if (existing.hasIdCard) {
        debugPrint('❌ ID $id ได้ลงทะเบียนด้วยบัตรประชาชนแล้ว');
        return existing; // ส่งข้อมูลเดิมกลับ
      }

      // อัปเดตข้อมูลจากบัตร + hasIdCard = 1
      final updatedData = RegData(
        id: id,
        first: first,
        last: last,
        dob: dob,
        phone: phone.isNotEmpty ? phone : existing.phone,
        addr: addr,
        gender: gender,
        hasIdCard: true, // อัปเกรดเป็นมีบัตร
        status: existing.status,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      final db = await _dbHelper.db;
      await db.update(
        'regs',
        updatedData.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      debugPrint('✅ อัปเกรดเป็นบัตรประชาชนสำเร็จ: $id');
      return updatedData;
    } catch (e) {
      debugPrint('❌ Error upgrading to ID card: $e');
      return null;
    }
  }

  /// อัปเดตข้อมูลที่แก้ไขได้ (สำหรับคนไม่มีบัตร)
  Future<RegData?> updateEditableData({
    required String id,
    String? first,
    String? last,
    String? dob,
    String? phone,
    String? addr,
    String? gender,
    String? status,
  }) async {
    try {
      final existing = await findExistingRegistration(id);
      if (existing == null) {
        debugPrint('❌ ไม่พบข้อมูล ID: $id');
        return null;
      }

      if (existing.hasIdCard) {
        // หากมีบัตร แก้ไขได้เฉพาะเบอร์โทร
        final updatedData = existing.copyWithEditable(
          phone: phone,
        );

        final db = await _dbHelper.db;
        await db.update(
          'regs',
          updatedData.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );

        debugPrint('✅ อัปเดตเบอร์โทรสำเร็จ: $id');
        return updatedData;
      } else {
        // หากไม่มีบัตร แก้ไขได้ทั้งหมด
        final updatedData = existing.copyWithAll(
          first: first,
          last: last,
          dob: dob,
          phone: phone,
          addr: addr,
          gender: gender,
          status: status,
        );

        final db = await _dbHelper.db;
        await db.update(
          'regs',
          updatedData.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );

        debugPrint('✅ อัปเดตข้อมูลแบบ Manual สำเร็จ: $id');
        return updatedData;
      }
    } catch (e) {
      debugPrint('❌ Error updating registration: $e');
      return null;
    }
  }

  /// ตรวจสอบว่าข้อมูลส่วนไหนแก้ไขได้
  bool canEditField(RegData regData, String fieldName) {
    if (!regData.hasIdCard) {
      // ไม่มีบัตร = แก้ไขได้ทั้งหมด
      return true;
    }

    // มีบัตร = แก้ไขได้เฉพาะเบอร์โทร
    return fieldName == 'phone';
  }

  /// ลบข้อมูลการลงทะเบียน (สำหรับทดสอบหรือการจัดการ)
  Future<bool> deleteRegistration(String id) async {
    try {
      final db = await _dbHelper.db;
      final deletedRows = await db.delete(
        'regs',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (deletedRows > 0) {
        debugPrint('✅ ลบข้อมูลการลงทะเบียนสำเร็จ: $id');
        return true;
      } else {
        debugPrint('❌ ไม่พบข้อมูลที่จะลบ: $id');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting registration: $e');
      return false;
    }
  }

  /// ดึงรายชื่อผู้ลงทะเบียนทั้งหมด
  Future<List<RegData>> getAllRegistrations() async {
    try {
      final db = await _dbHelper.db;
      final results = await db.query(
        'regs',
        orderBy: 'createdAt DESC',
      );

      return results.map((map) => RegData.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting all registrations: $e');
      return [];
    }
  }

  /// ค้นหาผู้ลงทะเบียนตามคำค้นหา
  Future<List<RegData>> searchRegistrations(String searchTerm) async {
    try {
      final db = await _dbHelper.db;
      final results = await db.query(
        'regs',
        where: 'id LIKE ? OR first LIKE ? OR last LIKE ? OR phone LIKE ?',
        whereArgs: [
          '%$searchTerm%',
          '%$searchTerm%',
          '%$searchTerm%',
          '%$searchTerm%',
        ],
        orderBy: 'updatedAt DESC',
      );

      return results.map((map) => RegData.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ Error searching registrations: $e');
      return [];
    }
  }
}