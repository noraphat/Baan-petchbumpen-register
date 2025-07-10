import '../services/address_service.dart';

class RegData {
  final String id;        // บัตร/โทร
  final String first;
  final String last;
  final String dob;       // วันเกิด
  final String phone;
  final String addr;
  final String gender;
  final bool hasIdCard;   // มีบัตรประชาชนหรือไม่
  final DateTime createdAt; // วันที่สร้างข้อมูล
  final DateTime updatedAt; // วันที่แก้ไขล่าสุด

  RegData({
    required this.id,
    required this.first,
    required this.last,
    required this.dob,
    required this.phone,
    required this.addr,
    required this.gender,
    required this.hasIdCard,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'first': first,
        'last': last,
        'dob': dob,
        'phone': phone,
        'addr': addr,
        'gender': gender,
        'hasIdCard': hasIdCard ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RegData.fromMap(Map<String, dynamic> m) => RegData(
        id: m['id'],
        first: m['first'],
        last: m['last'],
        dob: m['dob'],
        phone: m['phone'] ?? '',
        addr: m['addr'] ?? '',
        gender: m['gender'] ?? 'อื่น ๆ',
        hasIdCard: m['hasIdCard'] == 1,
        createdAt: DateTime.parse(m['createdAt']),
        updatedAt: DateTime.parse(m['updatedAt']),
      );

  // สร้าง RegData ใหม่สำหรับคนมีบัตรประชาชน
  factory RegData.fromIdCard({
    required String id,
    required String first,
    required String last,
    required String dob,
    required String addr,
    required String gender,
    String phone = '',
  }) => RegData(
        id: id,
        first: first,
        last: last,
        dob: dob,
        phone: phone,
        addr: addr,
        gender: gender,
        hasIdCard: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // สร้าง RegData ใหม่สำหรับคนไม่มีบัตรประชาชน
  factory RegData.manual({
    required String id,
    required String first,
    required String last,
    required String dob,
    required String phone,
    required String addr,
    required String gender,
  }) => RegData(
        id: id,
        first: first,
        last: last,
        dob: dob,
        phone: phone,
        addr: addr,
        gender: gender,
        hasIdCard: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // อัปเดตข้อมูลที่แก้ไขได้ (สำหรับคนมีบัตร)
  RegData copyWithEditable({
    String? phone,
    DateTime? updatedAt,
  }) => RegData(
        id: id,
        first: first,
        last: last,
        dob: dob,
        phone: phone ?? this.phone,
        addr: addr,
        gender: gender,
        hasIdCard: hasIdCard,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  // อัปเดตข้อมูลทั้งหมด (สำหรับคนไม่มีบัตร)
  RegData copyWithAll({
    String? first,
    String? last,
    String? dob,
    String? phone,
    String? addr,
    String? gender,
    DateTime? updatedAt,
  }) => RegData(
        id: id,
        first: first ?? this.first,
        last: last ?? this.last,
        dob: dob ?? this.dob,
        phone: phone ?? this.phone,
        addr: addr ?? this.addr,
        gender: gender ?? this.gender,
        hasIdCard: hasIdCard,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

class RegAdditionalInfo {
  final String regId;           // เชื่อมกับ RegData
  final DateTime? startDate;    // วันที่เริ่มต้น
  final DateTime? endDate;      // วันที่สิ้นสุด
  final int? shirtCount;        // จำนวนเสื้อขาว
  final int? pantsCount;        // จำนวนกางเกงขาว
  final int? matCount;          // จำนวนเสื่อ
  final int? pillowCount;       // จำนวนหมอน
  final int? blanketCount;      // จำนวนผ้าห่ม
  final String? location;       // ห้อง/ศาลา/สถานที่พัก
  final bool withChildren;      // มากับเด็ก
  final int? childrenCount;     // จำนวนเด็ก
  final String? notes;          // หมายเหตุ
  final DateTime createdAt;     // วันที่สร้าง
  final DateTime updatedAt;     // วันที่แก้ไขล่าสุด

  RegAdditionalInfo({
    required this.regId,
    this.startDate,
    this.endDate,
    this.shirtCount,
    this.pantsCount,
    this.matCount,
    this.pillowCount,
    this.blanketCount,
    this.location,
    this.withChildren = false,
    this.childrenCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'regId': regId,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'shirtCount': shirtCount,
        'pantsCount': pantsCount,
        'matCount': matCount,
        'pillowCount': pillowCount,
        'blanketCount': blanketCount,
        'location': location,
        'withChildren': withChildren ? 1 : 0,
        'childrenCount': childrenCount,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RegAdditionalInfo.fromMap(Map<String, dynamic> m) => RegAdditionalInfo(
        regId: m['regId'],
        startDate: m['startDate'] != null ? DateTime.parse(m['startDate']) : null,
        endDate: m['endDate'] != null ? DateTime.parse(m['endDate']) : null,
        shirtCount: m['shirtCount'],
        pantsCount: m['pantsCount'],
        matCount: m['matCount'],
        pillowCount: m['pillowCount'],
        blanketCount: m['blanketCount'],
        location: m['location'],
        withChildren: m['withChildren'] == 1,
        childrenCount: m['childrenCount'],
        notes: m['notes'],
        createdAt: DateTime.parse(m['createdAt']),
        updatedAt: DateTime.parse(m['updatedAt']),
      );

  // สร้างข้อมูลเพิ่มเติมใหม่
  factory RegAdditionalInfo.create({
    required String regId,
    DateTime? startDate,
    DateTime? endDate,
    int? shirtCount,
    int? pantsCount,
    int? matCount,
    int? pillowCount,
    int? blanketCount,
    String? location,
    bool withChildren = false,
    int? childrenCount,
    String? notes,
  }) => RegAdditionalInfo(
        regId: regId,
        startDate: startDate,
        endDate: endDate,
        shirtCount: shirtCount,
        pantsCount: pantsCount,
        matCount: matCount,
        pillowCount: pillowCount,
        blanketCount: blanketCount,
        location: location,
        withChildren: withChildren,
        childrenCount: childrenCount,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // อัปเดตข้อมูลเพิ่มเติม
  RegAdditionalInfo copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? shirtCount,
    int? pantsCount,
    int? matCount,
    int? pillowCount,
    int? blanketCount,
    String? location,
    bool? withChildren,
    int? childrenCount,
    String? notes,
    DateTime? updatedAt,
  }) => RegAdditionalInfo(
        regId: regId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        shirtCount: shirtCount ?? this.shirtCount,
        pantsCount: pantsCount ?? this.pantsCount,
        matCount: matCount ?? this.matCount,
        pillowCount: pillowCount ?? this.pillowCount,
        blanketCount: blanketCount ?? this.blanketCount,
        location: location ?? this.location,
        withChildren: withChildren ?? this.withChildren,
        childrenCount: childrenCount ?? this.childrenCount,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

// คลาสสำหรับจัดการที่อยู่แยกส่วน (ช่วยในการแก้ไข)
class AddressInfo {
  final int? provinceId;
  final int? districtId;
  final int? subDistrictId;
  final String? additionalAddress;

  AddressInfo({
    this.provinceId,
    this.districtId,
    this.subDistrictId,
    this.additionalAddress,
  });

  // แปลงจากที่อยู่เต็มเป็น AddressInfo
  factory AddressInfo.fromFullAddress(String fullAddress, AddressService addressService) {
    final parts = fullAddress.split(', ');
    if (parts.length < 3) return AddressInfo();

    final provinceName = parts[0].trim();
    final districtName = parts[1].trim();
    final subDistrictName = parts[2].trim();
    final additional = parts.length > 3 ? parts.sublist(3).join(', ') : '';

    final province = addressService.provinces.firstWhere(
      (p) => p.nameTh == provinceName,
      orElse: () => addressService.provinces.first,
    );

    final district = addressService.districtsOf(province.id).firstWhere(
      (d) => d.nameTh == districtName,
      orElse: () => addressService.districtsOf(province.id).first,
    );

    final subDistrict = addressService.subsOf(district.id).firstWhere(
      (s) => s.nameTh == subDistrictName,
      orElse: () => addressService.subsOf(district.id).first,
    );

    return AddressInfo(
      provinceId: province.id,
      districtId: district.id,
      subDistrictId: subDistrict.id,
      additionalAddress: additional,
    );
  }

  // แปลง AddressInfo เป็นที่อยู่เต็ม
  String toFullAddress(AddressService addressService) {
    if (provinceId == null || districtId == null || subDistrictId == null) {
      return '';
    }

    final province = addressService.provinces.firstWhere((p) => p.id == provinceId);
    final district = addressService.districts.firstWhere((d) => d.id == districtId);
    final subDistrict = addressService.subs.firstWhere((s) => s.id == subDistrictId);

    final parts = [
      province.nameTh,
      district.nameTh,
      subDistrict.nameTh,
    ];

    if (additionalAddress != null && additionalAddress!.isNotEmpty) {
      parts.add(additionalAddress!);
    }

    return parts.join(', ');
  }
}
