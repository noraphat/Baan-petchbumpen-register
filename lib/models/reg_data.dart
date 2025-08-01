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
  final String status;    // 'A' = Active, 'I' = Inactive
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
    required this.status,
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
        'status': status,
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
        status: m['status'] ?? 'A',
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
        status: 'A',
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
        status: 'A',
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
        status: status,
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
    String? status,
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
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

class RegAdditionalInfo {
  final int? id;                // Auto-increment ID (PK)
  final String regId;           // เชื่อมกับ RegData
  final String visitId;         // Unique visit identifier สำหรับแยกแต่ละครั้งที่มา
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
    this.id,
    required this.regId,
    required this.visitId,
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
        if (id != null) 'id': id,
        'regId': regId,
        'visitId': visitId,
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
        id: m['id'],
        regId: m['regId'],
        visitId: m['visitId'] ?? m['regId'], // fallback for old data
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
    String? visitId,
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
  }) {
    final now = DateTime.now();
    final generatedVisitId = visitId ?? '${regId}_${now.millisecondsSinceEpoch}';
    
    return RegAdditionalInfo(
      regId: regId,
      visitId: generatedVisitId,
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
      createdAt: now,
      updatedAt: now,
    );
  }

  // อัปเดตข้อมูลเพิ่มเติม
  RegAdditionalInfo copyWith({
    int? id,
    String? visitId,
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
        id: id ?? this.id,
        regId: regId,
        visitId: visitId ?? this.visitId,
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

// คลาสสำหรับจัดการข้อมูลการเข้าพัก
class StayRecord {
  final int? id;
  final String visitorId;       // เชื่อมกับ RegData.id
  final DateTime startDate;     // วันที่เริ่มพัก
  final DateTime endDate;       // วันที่สิ้นสุด
  final String status;          // 'active', 'extended', 'completed'
  final String? note;           // หมายเหตุ
  final DateTime createdAt;     // วันที่สร้างข้อมูล

  StayRecord({
    this.id,
    required this.visitorId,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'visitor_id': visitorId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };

  factory StayRecord.fromMap(Map<String, dynamic> m) => StayRecord(
        id: m['id'],
        visitorId: m['visitor_id'],
        startDate: DateTime.parse(m['start_date']),
        endDate: DateTime.parse(m['end_date']),
        status: m['status'] ?? 'active',
        note: m['note'],
        createdAt: DateTime.parse(m['created_at']),
      );

  // สร้าง Stay record ใหม่
  factory StayRecord.create({
    required String visitorId,
    required DateTime startDate,
    required DateTime endDate,
    String status = 'active',
    String? note,
  }) => StayRecord(
        visitorId: visitorId,
        startDate: startDate,
        endDate: endDate,
        status: status,
        note: note,
        createdAt: DateTime.now(),
      );

  // อัพเดต Stay record
  StayRecord copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? note,
  }) => StayRecord(
        id: id,
        visitorId: visitorId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  // ตรวจสอบว่า stay ยังคง active อยู่หรือไม่
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Stay ถือว่า active ถ้า endDate >= วันนี้ (รวมวันเดียวกัน)
    return endDateOnly.isAfter(today) || endDateOnly.isAtSameMomentAs(today);
  }

  // ตรวจสอบว่า stay หมดอายุแล้วหรือไม่
  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
    
    // Stay หมดอายุถ้า endDate < วันนี้
    return endDateOnly.isBefore(today);
  }

  // ได้สถานะที่ถูกต้องตามเวลาจริง
  String get actualStatus {
    if (isExpired && (status == 'active' || status == 'extended')) {
      return 'completed'; // ปรับสถานะเป็น completed หากหมดอายุแล้ว
    }
    return status; // ใช้สถานะเดิมหากยังไม่หมดอายุ
  }

  // ตรวจสอบว่าต้องอัปเดตสถานะในฐานข้อมูลหรือไม่
  bool get needsStatusUpdate {
    return isExpired && (status == 'active' || status == 'extended');
  }
}
