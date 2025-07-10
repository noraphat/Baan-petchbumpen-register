import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// ----------------- โมเดลพื้นฐาน -----------------
class Province {
  final int id;
  final String nameTh;
  Province(this.id, this.nameTh);
}

class District {
  final int id;
  final int provinceId;
  final String nameTh;
  District(this.id, this.provinceId, this.nameTh);
}

class SubDistrict {
  final int id;
  final int amphureId; // (== district id) ***สำคัญ: ชื่อคีย์ใน JSON***
  final String nameTh;
  SubDistrict(this.id, this.amphureId, this.nameTh);
}

/// ----------------- AddressService แบบ singleton -----------------
class AddressService {
  // ---- สร้าง instance เดียวใช้ทั่วแอป ----
  static final AddressService _inst = AddressService._internal();
  factory AddressService() => _inst;
  AddressService._internal();

  // ---- คอลเลกชันข้อมูล ----
  List<Province> provinces = [];
  List<District> districts = [];
  List<SubDistrict> subs    = [];

  /// โหลดไฟล์ JSON (เรียกครั้งแรกครั้งเดียวพอ)
  Future<void> init() async {
    if (provinces.isNotEmpty) return;   // เคยโหลดแล้ว
    // 1. provinces
    final pJson = await rootBundle.loadString(
        'assets/addresses/thai_provinces.json');
    final pList = json.decode(pJson) as List;
    provinces = [
      for (var e in pList) Province(e['id'], e['name_th'])
    ];

    // 2. districts (amphur)
    final dJson = await rootBundle.loadString(
        'assets/addresses/thai_amphures.json');
    final dList = json.decode(dJson) as List;
    districts = [
      for (var e in dList)
        District(e['id'], e['province_id'], e['name_th'])
    ];

    // 3. sub-districts (tambon) **ใช้ amphure_id**
    final sJson = await rootBundle.loadString(
        'assets/addresses/thai_tambons.json');
    final sList = json.decode(sJson) as List;
    subs = [
      for (var e in sList)
        SubDistrict(e['id'], e['amphure_id'], e['name_th'])
    ];
  }

  /// คืนลิสต์อำเภอในจังหวัดที่ระบุ
  List<District> districtsOf(int provinceId) =>
      districts.where((e) => e.provinceId == provinceId).toList();

  /// คืนลิสต์ตำบลในอำเภอ (amphur) ที่ระบุ
  List<SubDistrict> subsOf(int amphureId) =>
      subs.where((e) => e.amphureId == amphureId).toList();

  /// (Optionเสริม) หา object จาก id
  Province? provinceById(int id) =>
      provinces.firstWhere((e) => e.id == id, orElse: () => Province(id, ''));
  District? districtById(int id) =>
      districts.firstWhere((e) => e.id == id, orElse: () => District(id, 0, ''));
  SubDistrict? subById(int id) =>
      subs.firstWhere((e) => e.id == id, orElse: () => SubDistrict(id, 0, ''));
}
