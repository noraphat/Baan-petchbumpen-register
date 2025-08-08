import 'dart:convert';

/// ขนาดของห้องพัก
enum RoomSize {
  small('S', 'ขนาดเล็ก'),
  medium('M', 'ขนาดกลาง'),
  large('L', 'ขนาดใหญ่');

  const RoomSize(this.code, this.displayName);
  final String code;
  final String displayName;

  static RoomSize fromCode(String code) {
    return RoomSize.values.firstWhere((size) => size.code == code);
  }
}

/// สถานะของห้องพัก
enum RoomStatus {
  available('available', 'ว่าง'),
  reserved('reserved', 'ถูกจอง'),
  occupied('occupied', 'มีคนพัก');

  const RoomStatus(this.code, this.displayName);
  final String code;
  final String displayName;

  static RoomStatus fromCode(String code) {
    return RoomStatus.values.firstWhere((status) => status.code == code);
  }
}

/// รูปร่างของห้องพัก
enum RoomShape {
  square('square', 'สี่เหลี่ยมจตุรัส', 50.0, 50.0),
  rectangleHorizontal('rect_h', 'สี่เหลี่ยมผืนผ้า (แนวนอน)', 80.0, 50.0),
  rectangleVertical('rect_v', 'สี่เหลี่ยมผืนผ้า (แนวตั้ง)', 50.0, 80.0),
  rectangleHorizontalLarge(
    'rect_h_large',
    'สี่เหลี่ยมผืนผ้า (แนวนอน x2)',
    160.0,
    50.0,
  ),
  rectangleVerticalLarge(
    'rect_v_large',
    'สี่เหลี่ยมผืนผ้า (แนวตั้ง x2)',
    50.0,
    160.0,
  );

  const RoomShape(this.code, this.displayName, this.width, this.height);
  final String code;
  final String displayName;
  final double width;
  final double height;

  static RoomShape fromCode(String code) {
    return RoomShape.values.firstWhere((shape) => shape.code == code);
  }

  /// ดึงขนาดในรูปแบบ (width, height)
  (double, double) get size => (width, height);
}

/// โมเดลสำหรับข้อมูลห้องพัก
class Room {
  final int? id;
  final String name;
  final RoomSize size;
  final RoomShape shape;
  final int capacity;
  final double? positionX;
  final double? positionY;
  final RoomStatus status;
  final String? description;
  final String? currentOccupant; // เก็บ regId ของผู้ที่พักอยู่
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    this.id,
    required this.name,
    required this.size,
    this.shape = RoomShape.square,
    required this.capacity,
    this.positionX,
    this.positionY,
    this.status = RoomStatus.available,
    this.description,
    this.currentOccupant,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// สร้างห้องใหม่
  factory Room.create({
    required String name,
    required RoomSize size,
    RoomShape shape = RoomShape.square,
    required int capacity,
    String? description,
  }) {
    return Room(
      name: name,
      size: size,
      shape: shape,
      capacity: capacity,
      description: description,
    );
  }

  /// คัดลอกห้องพร้อมแก้ไขข้อมูล
  Room copyWith({
    int? id,
    String? name,
    RoomSize? size,
    RoomShape? shape,
    int? capacity,
    double? positionX,
    double? positionY,
    RoomStatus? status,
    String? description,
    String? currentOccupant,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      capacity: capacity ?? this.capacity,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      status: status ?? this.status,
      description: description ?? this.description,
      currentOccupant: currentOccupant ?? this.currentOccupant,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// แปลงเป็น Map สำหรับฐานข้อมูล
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'size': size.code,
      'shape': shape.code,
      'capacity': capacity,
      'position_x': positionX,
      'position_y': positionY,
      'status': status.code,
      'description': description,
      'current_occupant': currentOccupant,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// สร้างจาก Map ของฐานข้อมูล
  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      name: map['name'] as String,
      size: RoomSize.fromCode(map['size'] as String),
      shape: map['shape'] != null
          ? RoomShape.fromCode(map['shape'] as String)
          : RoomShape.square, // default สำหรับข้อมูลเก่า
      capacity: map['capacity'] as int,
      positionX: map['position_x'] as double?,
      positionY: map['position_y'] as double?,
      status: RoomStatus.fromCode(map['status'] as String),
      description: map['description'] as String?,
      currentOccupant: map['current_occupant'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// แปลงเป็น JSON
  String toJson() => json.encode(toMap());

  /// สร้างจาก JSON
  factory Room.fromJson(String source) => Room.fromMap(json.decode(source));

  /// ตรวจสอบว่าห้องมีตำแหน่งบนแผนที่หรือไม่
  bool get hasPosition => positionX != null && positionY != null;

  /// ตรวจสอบว่าห้องว่างหรือไม่
  bool get isAvailable => status == RoomStatus.available;

  /// ดึงขนาดของห้องในรูปแบบ (width, height) สำหรับ UI
  (double, double) getSizeForUI() {
    return shape.size;
  }

  @override
  String toString() {
    return 'Room(id: $id, name: $name, size: ${size.code}, capacity: $capacity, status: ${status.code}, position: ($positionX, $positionY))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// โมเดลสำหรับข้อมูลแผนที่
class MapData {
  final int? id;
  final String name;
  final String? imagePath; // path ของรูปภาพแผนที่
  final double? imageWidth;
  final double? imageHeight;
  final bool isActive; // แผนที่ที่กำลังใช้งาน
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  MapData({
    this.id,
    required this.name,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
    this.isActive = false,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// สร้างแผนที่ใหม่
  factory MapData.create({
    required String name,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
    String? description,
  }) {
    return MapData(
      name: name,
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      description: description,
    );
  }

  /// คัดลอกแผนที่พร้อมแก้ไขข้อมูล
  MapData copyWith({
    int? id,
    String? name,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
    bool? isActive,
    String? description,
    DateTime? updatedAt,
  }) {
    return MapData(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// แปลงเป็น Map สำหรับฐานข้อมูล
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_path': imagePath,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'is_active': isActive ? 1 : 0,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// สร้างจาก Map ของฐานข้อมูล
  factory MapData.fromMap(Map<String, dynamic> map) {
    return MapData(
      id: map['id'] as int?,
      name: map['name'] as String,
      imagePath: map['image_path'] as String?,
      imageWidth: map['image_width'] as double?,
      imageHeight: map['image_height'] as double?,
      isActive: (map['is_active'] as int) == 1,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// แปลงเป็น JSON
  String toJson() => json.encode(toMap());

  /// สร้างจาก JSON
  factory MapData.fromJson(String source) =>
      MapData.fromMap(json.decode(source));

  /// ตรวจสอบว่ามีรูปภาพแผนที่หรือไม่
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  String toString() {
    return 'MapData(id: $id, name: $name, imagePath: $imagePath, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// โมเดลสำหรับการจองห้องพัก (สำหรับอนาคต)
class RoomBooking {
  final int? id;
  final int roomId;
  final String visitorId; // เชื่อมกับ regs.id
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomBooking({
    this.id,
    required this.roomId,
    required this.visitorId,
    required this.checkInDate,
    required this.checkOutDate,
    this.status = 'pending',
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// คัดลอกการจองพร้อมแก้ไขข้อมูล
  RoomBooking copyWith({
    int? id,
    int? roomId,
    String? visitorId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return RoomBooking(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      visitorId: visitorId ?? this.visitorId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// แปลงเป็น Map สำหรับฐานข้อมูล
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'room_id': roomId,
      'visitor_id': visitorId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// สร้างจาก Map ของฐานข้อมูล
  factory RoomBooking.fromMap(Map<String, dynamic> map) {
    return RoomBooking(
      id: map['id'] as int?,
      roomId: map['room_id'] as int,
      visitorId: map['visitor_id'] as String,
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: DateTime.parse(map['check_out_date'] as String),
      status: map['status'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// ตรวจสอบว่าการจองยังใช้งานได้หรือไม่
  bool get isActive => status == 'confirmed' || status == 'pending';

  /// ตรวจสอบว่าการจองเสร็จสิ้นแล้วหรือไม่
  bool get isCompleted => status == 'completed';

  @override
  String toString() {
    return 'RoomBooking(id: $id, roomId: $roomId, visitorId: $visitorId, status: $status)';
  }
}

/// โมเดลสำหรับสรุปการใช้งานห้องพัก
class RoomUsageSummary {
  final String roomName;
  final int usageDays;
  final String dailyStatus;
  final int totalVisitors;
  final double occupancyRate;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckOut;
  final String roomSize;
  final String guestName;
  final bool isSingleDay;

  RoomUsageSummary({
    required this.roomName,
    required this.usageDays,
    required this.dailyStatus,
    required this.totalVisitors,
    required this.occupancyRate,
    this.lastCheckIn,
    this.lastCheckOut,
    this.roomSize = 'ไม่ระบุ',
    this.guestName = '',
    this.isSingleDay = false,
  });

  factory RoomUsageSummary.fromMap(Map<String, dynamic> map) {
    return RoomUsageSummary(
      roomName: map['room_name'] ?? '',
      usageDays: map['usage_days'] ?? 0,
      dailyStatus: map['daily_status'] ?? 'ว่าง',
      totalVisitors: map['total_visitors'] ?? 0,
      occupancyRate: (map['occupancy_rate'] ?? 0.0).toDouble(),
      lastCheckIn: map['last_check_in'] != null
          ? DateTime.parse(map['last_check_in'])
          : null,
      lastCheckOut: map['last_check_out'] != null
          ? DateTime.parse(map['last_check_out'])
          : null,
      roomSize: map['room_size'] ?? 'ไม่ระบุ',
      guestName: map['guest_name'] ?? '',
      isSingleDay: map['is_single_day'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'room_name': roomName,
      'usage_days': usageDays,
      'daily_status': dailyStatus,
      'total_visitors': totalVisitors,
      'occupancy_rate': occupancyRate,
      'last_check_in': lastCheckIn?.toIso8601String(),
      'last_check_out': lastCheckOut?.toIso8601String(),
      'room_size': roomSize,
      'guest_name': guestName,
      'is_single_day': isSingleDay,
    };
  }
}
