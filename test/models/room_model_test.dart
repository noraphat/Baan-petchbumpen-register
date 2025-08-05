import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/models/room_model.dart';

void main() {
  group('RoomSize Tests', () {
    test('should create room size with correct properties', () {
      expect(RoomSize.small.code, equals('S'));
      expect(RoomSize.small.displayName, equals('ขนาดเล็ก'));
      expect(RoomSize.medium.code, equals('M'));
      expect(RoomSize.medium.displayName, equals('ขนาดกลาง'));
      expect(RoomSize.large.code, equals('L'));
      expect(RoomSize.large.displayName, equals('ขนาดใหญ่'));
    });

    test('should create RoomSize from code correctly', () {
      expect(RoomSize.fromCode('S'), equals(RoomSize.small));
      expect(RoomSize.fromCode('M'), equals(RoomSize.medium));
      expect(RoomSize.fromCode('L'), equals(RoomSize.large));
    });

    test('should throw error for invalid room size code', () {
      expect(() => RoomSize.fromCode('X'), throwsStateError);
    });
  });

  group('RoomStatus Tests', () {
    test('should create room status with correct properties', () {
      expect(RoomStatus.available.code, equals('available'));
      expect(RoomStatus.available.displayName, equals('ว่าง'));
      expect(RoomStatus.reserved.code, equals('reserved'));
      expect(RoomStatus.reserved.displayName, equals('ถูกจอง'));
      expect(RoomStatus.occupied.code, equals('occupied'));
      expect(RoomStatus.occupied.displayName, equals('มีคนพัก'));
    });

    test('should create RoomStatus from code correctly', () {
      expect(RoomStatus.fromCode('available'), equals(RoomStatus.available));
      expect(RoomStatus.fromCode('reserved'), equals(RoomStatus.reserved));
      expect(RoomStatus.fromCode('occupied'), equals(RoomStatus.occupied));
    });

    test('should throw error for invalid room status code', () {
      expect(() => RoomStatus.fromCode('invalid'), throwsStateError);
    });
  });

  group('RoomShape Tests', () {
    test('should create room shape with correct properties', () {
      expect(RoomShape.square.code, equals('square'));
      expect(RoomShape.square.displayName, equals('สี่เหลี่ยมจตุรัส'));
      expect(RoomShape.square.width, equals(50.0));
      expect(RoomShape.square.height, equals(50.0));
      
      expect(RoomShape.rectangleHorizontal.code, equals('rect_h'));
      expect(RoomShape.rectangleHorizontal.width, equals(80.0));
      expect(RoomShape.rectangleHorizontal.height, equals(50.0));
    });

    test('should get size tuple correctly', () {
      final (width, height) = RoomShape.square.size;
      expect(width, equals(50.0));
      expect(height, equals(50.0));
      
      final (w2, h2) = RoomShape.rectangleHorizontalLarge.size;
      expect(w2, equals(160.0));
      expect(h2, equals(50.0));
    });

    test('should create RoomShape from code correctly', () {
      expect(RoomShape.fromCode('square'), equals(RoomShape.square));
      expect(RoomShape.fromCode('rect_h'), equals(RoomShape.rectangleHorizontal));
      expect(RoomShape.fromCode('rect_v'), equals(RoomShape.rectangleVertical));
    });

    test('should throw error for invalid room shape code', () {
      expect(() => RoomShape.fromCode('invalid'), throwsStateError);
    });
  });

  group('Room Tests', () {
    test('should create room with factory constructor', () {
      final room = Room.create(
        name: 'ห้องทดสอบ',
        size: RoomSize.medium,
        shape: RoomShape.square,
        capacity: 4,
        description: 'ห้องสำหรับทดสอบ',
      );

      expect(room.name, equals('ห้องทดสอบ'));
      expect(room.size, equals(RoomSize.medium));
      expect(room.shape, equals(RoomShape.square));
      expect(room.capacity, equals(4));
      expect(room.status, equals(RoomStatus.available));
      expect(room.description, equals('ห้องสำหรับทดสอบ'));
      expect(room.createdAt, isNotNull);
      expect(room.updatedAt, isNotNull);
    });

    test('should create room with default values', () {
      final room = Room(
        name: 'ห้องพื้นฐาน',
        size: RoomSize.small,
        capacity: 2,
      );

      expect(room.shape, equals(RoomShape.square));
      expect(room.status, equals(RoomStatus.available));
      expect(room.positionX, isNull);
      expect(room.positionY, isNull);
      expect(room.currentOccupant, isNull);
    });

    test('should copy room with modified fields', () {
      final originalRoom = Room.create(
        name: 'ห้องเดิม',
        size: RoomSize.small,
        capacity: 2,
      );

      final copiedRoom = originalRoom.copyWith(
        name: 'ห้องใหม่',
        status: RoomStatus.occupied,
        currentOccupant: '1234567890123',
        positionX: 100.0,
        positionY: 200.0,
      );

      expect(copiedRoom.name, equals('ห้องใหม่'));
      expect(copiedRoom.status, equals(RoomStatus.occupied));
      expect(copiedRoom.currentOccupant, equals('1234567890123'));
      expect(copiedRoom.positionX, equals(100.0));
      expect(copiedRoom.positionY, equals(200.0));
      expect(copiedRoom.size, equals(originalRoom.size));
      expect(copiedRoom.capacity, equals(originalRoom.capacity));
      expect(copiedRoom.createdAt, equals(originalRoom.createdAt));
      expect(copiedRoom.updatedAt.isAfter(originalRoom.updatedAt), isTrue);
    });

    test('should convert to map correctly', () {
      final room = Room(
        id: 1,
        name: 'ห้องทดสอบ',
        size: RoomSize.medium,
        shape: RoomShape.rectangleHorizontal,
        capacity: 4,
        positionX: 150.0,
        positionY: 250.0,
        status: RoomStatus.occupied,
        description: 'ห้องสำหรับทดสอบ',
        currentOccupant: '1234567890123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final map = room.toMap();

      expect(map['id'], equals(1));
      expect(map['name'], equals('ห้องทดสอบ'));
      expect(map['size'], equals('M'));
      expect(map['shape'], equals('rect_h'));
      expect(map['capacity'], equals(4));
      expect(map['position_x'], equals(150.0));
      expect(map['position_y'], equals(250.0));
      expect(map['status'], equals('occupied'));
      expect(map['description'], equals('ห้องสำหรับทดสอบ'));
      expect(map['current_occupant'], equals('1234567890123'));
      expect(map['created_at'], equals('2024-01-01T00:00:00.000'));
      expect(map['updated_at'], equals('2024-01-02T00:00:00.000'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'name': 'ห้องทดสอบ',
        'size': 'L',
        'shape': 'rect_v',
        'capacity': 6,
        'position_x': 300.0,
        'position_y': 400.0,
        'status': 'reserved',
        'description': 'ห้องขนาดใหญ่',
        'current_occupant': '9876543210987',
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-02T00:00:00.000',
      };

      final room = Room.fromMap(map);

      expect(room.id, equals(1));
      expect(room.name, equals('ห้องทดสอบ'));
      expect(room.size, equals(RoomSize.large));
      expect(room.shape, equals(RoomShape.rectangleVertical));
      expect(room.capacity, equals(6));
      expect(room.positionX, equals(300.0));
      expect(room.positionY, equals(400.0));
      expect(room.status, equals(RoomStatus.reserved));
      expect(room.description, equals('ห้องขนาดใหญ่'));
      expect(room.currentOccupant, equals('9876543210987'));
      expect(room.createdAt, equals(DateTime(2024, 1, 1)));
      expect(room.updatedAt, equals(DateTime(2024, 1, 2)));
    });

    test('should handle missing shape in fromMap with default', () {
      final map = {
        'id': 1,
        'name': 'ห้องเก่า',
        'size': 'M',
        'capacity': 4,
        'position_x': null,
        'position_y': null,
        'status': 'available',
        'description': null,
        'current_occupant': null,
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      };

      final room = Room.fromMap(map);

      expect(room.shape, equals(RoomShape.square)); // default value
      expect(room.positionX, isNull);
      expect(room.positionY, isNull);
      expect(room.description, isNull);
      expect(room.currentOccupant, isNull);
    });

    test('should check if room has position', () {
      final roomWithPosition = Room(
        name: 'ห้องมีตำแหน่ง',
        size: RoomSize.small,
        capacity: 2,
        positionX: 100.0,
        positionY: 100.0,
      );

      final roomWithoutPosition = Room(
        name: 'ห้องไม่มีตำแหน่ง',
        size: RoomSize.small,
        capacity: 2,
      );

      expect(roomWithPosition.hasPosition, isTrue);
      expect(roomWithoutPosition.hasPosition, isFalse);
    });

    test('should check if room is available', () {
      final availableRoom = Room(
        name: 'ห้องว่าง',
        size: RoomSize.small,
        capacity: 2,
        status: RoomStatus.available,
      );

      final occupiedRoom = Room(
        name: 'ห้องไม่ว่าง',
        size: RoomSize.small,
        capacity: 2,
        status: RoomStatus.occupied,
      );

      expect(availableRoom.isAvailable, isTrue);
      expect(occupiedRoom.isAvailable, isFalse);
    });

    test('should get size for UI correctly', () {
      final room = Room(
        name: 'ห้องทดสอบ',
        size: RoomSize.medium,
        shape: RoomShape.rectangleHorizontalLarge,
        capacity: 8,
      );

      final (width, height) = room.getSizeForUI();
      expect(width, equals(160.0));
      expect(height, equals(50.0));
    });

    test('should convert to and from JSON correctly', () {
      final originalRoom = Room.create(
        name: 'ห้องJSON',
        size: RoomSize.large,
        shape: RoomShape.square,
        capacity: 6,
        description: 'ทดสอบ JSON',
      );

      final json = originalRoom.toJson();
      final roomFromJson = Room.fromJson(json);

      expect(roomFromJson.name, equals(originalRoom.name));
      expect(roomFromJson.size, equals(originalRoom.size));
      expect(roomFromJson.shape, equals(originalRoom.shape));
      expect(roomFromJson.capacity, equals(originalRoom.capacity));
      expect(roomFromJson.description, equals(originalRoom.description));
    });

    test('should have correct equality and hashCode', () {
      final room1 = Room(id: 1, name: 'ห้อง1', size: RoomSize.small, capacity: 2);
      final room2 = Room(id: 1, name: 'ห้อง2', size: RoomSize.large, capacity: 6);
      final room3 = Room(id: 2, name: 'ห้อง1', size: RoomSize.small, capacity: 2);

      expect(room1, equals(room2)); // same ID
      expect(room1, isNot(equals(room3))); // different ID
      expect(room1.hashCode, equals(room2.hashCode));
      expect(room1.hashCode, isNot(equals(room3.hashCode)));
    });

    test('should have meaningful toString', () {
      final room = Room(
        id: 1,
        name: 'ห้องทดสอบ',
        size: RoomSize.medium,
        capacity: 4,
        status: RoomStatus.available,
        positionX: 100.0,
        positionY: 200.0,
      );

      final string = room.toString();
      expect(string, contains('Room('));
      expect(string, contains('id: 1'));
      expect(string, contains('name: ห้องทดสอบ'));
      expect(string, contains('size: M'));
      expect(string, contains('capacity: 4'));
      expect(string, contains('status: available'));
      expect(string, contains('position: (100.0, 200.0)'));
    });
  });

  group('MapData Tests', () {
    test('should create map data with factory constructor', () {
      final mapData = MapData.create(
        name: 'แผนที่ทดสอบ',
        imagePath: '/path/to/image.png',
        imageWidth: 800.0,
        imageHeight: 600.0,
        description: 'แผนที่สำหรับทดสอบ',
      );

      expect(mapData.name, equals('แผนที่ทดสอบ'));
      expect(mapData.imagePath, equals('/path/to/image.png'));
      expect(mapData.imageWidth, equals(800.0));
      expect(mapData.imageHeight, equals(600.0));
      expect(mapData.isActive, isFalse);
      expect(mapData.description, equals('แผนที่สำหรับทดสอบ'));
      expect(mapData.createdAt, isNotNull);
      expect(mapData.updatedAt, isNotNull);
    });

    test('should copy map data with modified fields', () {
      final originalMap = MapData.create(
        name: 'แผนที่เดิม',
        imagePath: '/old/path.png',
      );

      final copiedMap = originalMap.copyWith(
        name: 'แผนที่ใหม่',
        isActive: true,
        imageWidth: 1024.0,
        imageHeight: 768.0,
      );

      expect(copiedMap.name, equals('แผนที่ใหม่'));
      expect(copiedMap.isActive, isTrue);
      expect(copiedMap.imageWidth, equals(1024.0));
      expect(copiedMap.imageHeight, equals(768.0));
      expect(copiedMap.imagePath, equals(originalMap.imagePath));
      expect(copiedMap.createdAt, equals(originalMap.createdAt));
      expect(copiedMap.updatedAt.isAfter(originalMap.updatedAt), isTrue);
    });

    test('should convert to map correctly', () {
      final mapData = MapData(
        id: 1,
        name: 'แผนที่ทดสอบ',
        imagePath: '/test/image.jpg',
        imageWidth: 1200.0,
        imageHeight: 900.0,
        isActive: true,
        description: 'แผนที่หลัก',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final map = mapData.toMap();

      expect(map['id'], equals(1));
      expect(map['name'], equals('แผนที่ทดสอบ'));
      expect(map['image_path'], equals('/test/image.jpg'));
      expect(map['image_width'], equals(1200.0));
      expect(map['image_height'], equals(900.0));
      expect(map['is_active'], equals(1));
      expect(map['description'], equals('แผนที่หลัก'));
      expect(map['created_at'], equals('2024-01-01T00:00:00.000'));
      expect(map['updated_at'], equals('2024-01-02T00:00:00.000'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 2,
        'name': 'แผนที่จากแมพ',
        'image_path': '/map/from/map.png',
        'image_width': 800.0,
        'image_height': 600.0,
        'is_active': 0,
        'description': 'สร้างจาก Map',
        'created_at': '2024-02-01T00:00:00.000',
        'updated_at': '2024-02-02T00:00:00.000',
      };

      final mapData = MapData.fromMap(map);

      expect(mapData.id, equals(2));
      expect(mapData.name, equals('แผนที่จากแมพ'));
      expect(mapData.imagePath, equals('/map/from/map.png'));
      expect(mapData.imageWidth, equals(800.0));
      expect(mapData.imageHeight, equals(600.0));
      expect(mapData.isActive, isFalse);
      expect(mapData.description, equals('สร้างจาก Map'));
      expect(mapData.createdAt, equals(DateTime(2024, 2, 1)));
      expect(mapData.updatedAt, equals(DateTime(2024, 2, 2)));
    });

    test('should check if has image', () {
      final mapWithImage = MapData.create(
        name: 'แผนที่มีรูป',
        imagePath: '/path/to/image.png',
      );

      final mapWithoutImage = MapData.create(
        name: 'แผนที่ไม่มีรูป',
      );

      final mapWithEmptyPath = MapData.create(
        name: 'แผนที่เส้นทางว่าง',
        imagePath: '',
      );

      expect(mapWithImage.hasImage, isTrue);
      expect(mapWithoutImage.hasImage, isFalse);
      expect(mapWithEmptyPath.hasImage, isFalse);
    });

    test('should convert to and from JSON correctly', () {
      final originalMapData = MapData.create(
        name: 'แผนที่ JSON',
        imagePath: '/json/test.png',
        imageWidth: 640.0,
        imageHeight: 480.0,
        description: 'ทดสอบ JSON',
      );

      final json = originalMapData.toJson();
      final mapDataFromJson = MapData.fromJson(json);

      expect(mapDataFromJson.name, equals(originalMapData.name));
      expect(mapDataFromJson.imagePath, equals(originalMapData.imagePath));
      expect(mapDataFromJson.imageWidth, equals(originalMapData.imageWidth));
      expect(mapDataFromJson.imageHeight, equals(originalMapData.imageHeight));
      expect(mapDataFromJson.description, equals(originalMapData.description));
    });

    test('should have correct equality and hashCode', () {
      final map1 = MapData(id: 1, name: 'แผนที่1');
      final map2 = MapData(id: 1, name: 'แผนที่2');
      final map3 = MapData(id: 2, name: 'แผนที่1');

      expect(map1, equals(map2)); // same ID
      expect(map1, isNot(equals(map3))); // different ID
      expect(map1.hashCode, equals(map2.hashCode));
      expect(map1.hashCode, isNot(equals(map3.hashCode)));
    });

    test('should have meaningful toString', () {
      final mapData = MapData(
        id: 1,
        name: 'แผนที่ทดสอบ',
        imagePath: '/test.png',
        isActive: true,
      );

      final string = mapData.toString();
      expect(string, contains('MapData('));
      expect(string, contains('id: 1'));
      expect(string, contains('name: แผนที่ทดสอบ'));
      expect(string, contains('imagePath: /test.png'));
      expect(string, contains('isActive: true'));
    });
  });

  group('RoomBooking Tests', () {
    test('should create room booking correctly', () {
      final checkIn = DateTime(2024, 1, 15);
      final checkOut = DateTime(2024, 1, 20);
      
      final booking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: checkIn,
        checkOutDate: checkOut,
        status: 'confirmed',
        note: 'การจองทดสอบ',
      );

      expect(booking.roomId, equals(1));
      expect(booking.visitorId, equals('1234567890123'));
      expect(booking.checkInDate, equals(checkIn));
      expect(booking.checkOutDate, equals(checkOut));
      expect(booking.status, equals('confirmed'));
      expect(booking.note, equals('การจองทดสอบ'));
      expect(booking.createdAt, isNotNull);
      expect(booking.updatedAt, isNotNull);
    });

    test('should create room booking with default status', () {
      final booking = RoomBooking(
        roomId: 2,
        visitorId: '9876543210987',
        checkInDate: DateTime(2024, 2, 1),
        checkOutDate: DateTime(2024, 2, 5),
      );

      expect(booking.status, equals('pending'));
    });

    test('should copy room booking with modified fields', () {
      final originalBooking = RoomBooking(
        id: 1,
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'pending',
      );

      final copiedBooking = originalBooking.copyWith(
        status: 'confirmed',
        note: 'ได้รับการยืนยันแล้ว',
        checkOutDate: DateTime(2024, 1, 22),
      );

      expect(copiedBooking.status, equals('confirmed'));
      expect(copiedBooking.note, equals('ได้รับการยืนยันแล้ว'));
      expect(copiedBooking.checkOutDate, equals(DateTime(2024, 1, 22)));
      expect(copiedBooking.id, equals(originalBooking.id));
      expect(copiedBooking.roomId, equals(originalBooking.roomId));
      expect(copiedBooking.visitorId, equals(originalBooking.visitorId));
      expect(copiedBooking.checkInDate, equals(originalBooking.checkInDate));
      expect(copiedBooking.createdAt, equals(originalBooking.createdAt));
      expect(copiedBooking.updatedAt.isAfter(originalBooking.updatedAt), isTrue);
    });

    test('should convert to map correctly', () {
      final booking = RoomBooking(
        id: 1,
        roomId: 2,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'confirmed',
        note: 'การจองพิเศษ',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final map = booking.toMap();

      expect(map['id'], equals(1));
      expect(map['room_id'], equals(2));
      expect(map['visitor_id'], equals('1234567890123'));
      expect(map['check_in_date'], equals('2024-01-15T00:00:00.000'));
      expect(map['check_out_date'], equals('2024-01-20T00:00:00.000'));
      expect(map['status'], equals('confirmed'));
      expect(map['note'], equals('การจองพิเศษ'));
      expect(map['created_at'], equals('2024-01-01T00:00:00.000'));
      expect(map['updated_at'], equals('2024-01-02T00:00:00.000'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 3,
        'room_id': 4,
        'visitor_id': '9876543210987',
        'check_in_date': '2024-02-10T00:00:00.000',
        'check_out_date': '2024-02-15T00:00:00.000',
        'status': 'cancelled',
        'note': 'ยกเลิกการจอง',
        'created_at': '2024-02-01T00:00:00.000',
        'updated_at': '2024-02-05T00:00:00.000',
      };

      final booking = RoomBooking.fromMap(map);

      expect(booking.id, equals(3));
      expect(booking.roomId, equals(4));
      expect(booking.visitorId, equals('9876543210987'));
      expect(booking.checkInDate, equals(DateTime(2024, 2, 10)));
      expect(booking.checkOutDate, equals(DateTime(2024, 2, 15)));
      expect(booking.status, equals('cancelled'));
      expect(booking.note, equals('ยกเลิกการจอง'));
      expect(booking.createdAt, equals(DateTime(2024, 2, 1)));
      expect(booking.updatedAt, equals(DateTime(2024, 2, 5)));
    });

    test('should check if booking is active', () {
      final pendingBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'pending',
      );

      final confirmedBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'confirmed',
      );

      final cancelledBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'cancelled',
      );

      final completedBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'completed',
      );

      expect(pendingBooking.isActive, isTrue);
      expect(confirmedBooking.isActive, isTrue);
      expect(cancelledBooking.isActive, isFalse);
      expect(completedBooking.isActive, isFalse);
    });

    test('should check if booking is completed', () {
      final completedBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'completed',
      );

      final pendingBooking = RoomBooking(
        roomId: 1,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'pending',
      );

      expect(completedBooking.isCompleted, isTrue);
      expect(pendingBooking.isCompleted, isFalse);
    });

    test('should have meaningful toString', () {
      final booking = RoomBooking(
        id: 1,
        roomId: 2,
        visitorId: '1234567890123',
        checkInDate: DateTime(2024, 1, 15),
        checkOutDate: DateTime(2024, 1, 20),
        status: 'confirmed',
      );

      final string = booking.toString();
      expect(string, contains('RoomBooking('));
      expect(string, contains('id: 1'));
      expect(string, contains('roomId: 2'));
      expect(string, contains('visitorId: 1234567890123'));
      expect(string, contains('status: confirmed'));
    });
  });
}