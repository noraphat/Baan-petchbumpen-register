import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/map_service.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/room_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late MapService mapService;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mapService = MapService();
    
    // Clear database before each test
    await mapService.clearAllData();
  });

  tearDown(() async {
    await mapService.clearAllData();
  });

  group('MapService Singleton', () {
    test('should return same instance', () {
      final instance1 = MapService();
      final instance2 = MapService();
      
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('Map Management', () {
    test('should save map successfully', () async {
      final mapId = await mapService.saveMap(
        name: 'แผนที่ทดสอบ',
        description: 'แผนที่สำหรับทดสอบ',
      );

      expect(mapId, isNotNull);
      expect(mapId, greaterThan(0));

      // Verify map was saved
      final maps = await mapService.getAllMaps();
      expect(maps.length, equals(1));
      expect(maps.first.name, equals('แผนที่ทดสอบ'));
      expect(maps.first.description, equals('แผนที่สำหรับทดสอบ'));
    });

    test('should save map with image path', () async {
      const imagePath = '/test/path/image.jpg';
      final mapId = await mapService.saveMap(
        name: 'แผนที่มีรูป',
        imagePath: imagePath,
        imageWidth: 800.0,
        imageHeight: 600.0,
        description: 'แผนที่ที่มีรูปภาพ',
      );

      expect(mapId, isNotNull);
      
      final maps = await mapService.getAllMaps();
      final savedMap = maps.firstWhere((m) => m.id == mapId);
      
      expect(savedMap.imagePath, equals(imagePath));
      expect(savedMap.imageWidth, equals(800.0));
      expect(savedMap.imageHeight, equals(600.0));
      expect(savedMap.hasImage, isTrue);
    });

    test('should get all maps', () async {
      await mapService.saveMap(name: 'แผนที่ 1');
      await mapService.saveMap(name: 'แผนที่ 2');
      await mapService.saveMap(name: 'แผนที่ 3');

      final maps = await mapService.getAllMaps();
      expect(maps.length, equals(3));
      
      final names = maps.map((m) => m.name).toList();
      expect(names, containsAll(['แผนที่ 1', 'แผนที่ 2', 'แผนที่ 3']));
    });

    test('should set active map', () async {
      final mapId = await mapService.saveMap(name: 'แผนที่หลัก');
      expect(mapId, isNotNull);

      final result = await mapService.setActiveMap(mapId!);
      expect(result, isTrue);

      final activeMap = await mapService.getActiveMap();
      expect(activeMap, isNotNull);
      expect(activeMap!.id, equals(mapId));
      expect(activeMap.isActive, isTrue);
    });

    test('should get active map', () async {
      // No active map initially
      final noActiveMap = await mapService.getActiveMap();
      expect(noActiveMap, isNull);

      // Create and set active map
      final mapId = await mapService.saveMap(name: 'แผนที่หลัก');
      await mapService.setActiveMap(mapId!);

      final activeMap = await mapService.getActiveMap();
      expect(activeMap, isNotNull);
      expect(activeMap!.name, equals('แผนที่หลัก'));
      expect(activeMap.isActive, isTrue);
    });

    test('should update map', () async {
      final mapId = await mapService.saveMap(name: 'แผนที่เก่า');
      final maps = await mapService.getAllMaps();
      final mapToUpdate = maps.firstWhere((m) => m.id == mapId);

      final updatedMap = mapToUpdate.copyWith(
        name: 'แผนที่ใหม่',
        description: 'อัปเดตแล้ว',
      );

      final result = await mapService.updateMap(updatedMap);
      expect(result, isTrue);

      final updatedMaps = await mapService.getAllMaps();
      final updated = updatedMaps.firstWhere((m) => m.id == mapId);
      expect(updated.name, equals('แผนที่ใหม่'));
      expect(updated.description, equals('อัปเดตแล้ว'));
    });

    test('should delete map', () async {
      final mapId = await mapService.saveMap(name: 'แผนที่จะลบ');
      
      // Verify map exists
      final mapsBeforeDelete = await mapService.getAllMaps();
      expect(mapsBeforeDelete.length, equals(1));

      final result = await mapService.deleteMap(mapId!);
      expect(result, isTrue);

      // Verify map was deleted
      final mapsAfterDelete = await mapService.getAllMaps();
      expect(mapsAfterDelete.length, equals(0));
    });
  });

  group('Room Management', () {
    test('should add room successfully', () async {
      final roomId = await mapService.addRoom(
        name: 'ห้อง 1',
        size: RoomSize.medium,
        shape: RoomShape.square,
        capacity: 4,
        description: 'ห้องทดสอบ',
      );

      expect(roomId, isNotNull);
      expect(roomId, greaterThan(0));

      // Verify room was added
      final rooms = await mapService.getAllRooms();
      expect(rooms.length, equals(1));
      
      final addedRoom = rooms.first;
      expect(addedRoom.name, equals('ห้อง 1'));
      expect(addedRoom.size, equals(RoomSize.medium));
      expect(addedRoom.shape, equals(RoomShape.square));
      expect(addedRoom.capacity, equals(4));
      expect(addedRoom.description, equals('ห้องทดสอบ'));
      expect(addedRoom.status, equals(RoomStatus.available));
    });

    test('should get all rooms', () async {
      await mapService.addRoom(name: 'ห้อง 1', size: RoomSize.small, capacity: 2);
      await mapService.addRoom(name: 'ห้อง 2', size: RoomSize.medium, capacity: 4);
      await mapService.addRoom(name: 'ห้อง 3', size: RoomSize.large, capacity: 6);

      final rooms = await mapService.getAllRooms();
      expect(rooms.length, equals(3));
      
      final names = rooms.map((r) => r.name).toList();
      expect(names, containsAll(['ห้อง 1', 'ห้อง 2', 'ห้อง 3']));
    });

    test('should get rooms with position', () async {
      final roomId1 = await mapService.addRoom(name: 'ห้องมีตำแหน่ง', size: RoomSize.small, capacity: 2);
      await mapService.addRoom(name: 'ห้องไม่มีตำแหน่ง', size: RoomSize.small, capacity: 2);

      // Set position for room1
      await mapService.updateRoomPosition(roomId1!, 100.0, 200.0);

      final roomsWithPosition = await mapService.getRoomsWithPosition();
      expect(roomsWithPosition.length, equals(1));
      expect(roomsWithPosition.first.name, equals('ห้องมีตำแหน่ง'));
      expect(roomsWithPosition.first.hasPosition, isTrue);
    });

    test('should get rooms by status', () async {
      final roomId1 = await mapService.addRoom(name: 'ห้องว่าง', size: RoomSize.small, capacity: 2);
      final roomId2 = await mapService.addRoom(name: 'ห้องจอง', size: RoomSize.small, capacity: 2);

      // Update room2 status
      await mapService.updateRoomStatus(roomId2!, RoomStatus.reserved);

      final availableRooms = await mapService.getRoomsByStatus(RoomStatus.available);
      final reservedRooms = await mapService.getRoomsByStatus(RoomStatus.reserved);

      expect(availableRooms.length, equals(1));
      expect(availableRooms.first.name, equals('ห้องว่าง'));

      expect(reservedRooms.length, equals(1));
      expect(reservedRooms.first.name, equals('ห้องจอง'));
    });

    test('should update room', () async {
      final roomId = await mapService.addRoom(name: 'ห้องเก่า', size: RoomSize.small, capacity: 2);
      final rooms = await mapService.getAllRooms();
      final roomToUpdate = rooms.firstWhere((r) => r.id == roomId);

      final updatedRoom = roomToUpdate.copyWith(
        name: 'ห้องใหม่',
        capacity: 4,
        description: 'อัปเดตแล้ว',
      );

      final result = await mapService.updateRoom(updatedRoom);
      expect(result, isTrue);

      final updatedRooms = await mapService.getAllRooms();
      final updated = updatedRooms.firstWhere((r) => r.id == roomId);
      expect(updated.name, equals('ห้องใหม่'));
      expect(updated.capacity, equals(4));
      expect(updated.description, equals('อัปเดตแล้ว'));
    });

    test('should update room position', () async {
      final roomId = await mapService.addRoom(name: 'ห้องทดสอบ', size: RoomSize.small, capacity: 2);

      final result = await mapService.updateRoomPosition(roomId!, 150.0, 250.0);
      expect(result, isTrue);

      final rooms = await mapService.getAllRooms();
      final room = rooms.firstWhere((r) => r.id == roomId);
      expect(room.positionX, equals(150.0));
      expect(room.positionY, equals(250.0));
      expect(room.hasPosition, isTrue);
    });

    test('should update room status', () async {
      final roomId = await mapService.addRoom(name: 'ห้องทดสอบ', size: RoomSize.small, capacity: 2);

      final result = await mapService.updateRoomStatus(roomId!, RoomStatus.occupied, occupantId: 'visitor123');
      expect(result, isTrue);

      final rooms = await mapService.getAllRooms();
      final room = rooms.firstWhere((r) => r.id == roomId);
      expect(room.status, equals(RoomStatus.occupied));
      expect(room.currentOccupant, equals('visitor123'));
    });

    test('should delete room', () async {
      final roomId = await mapService.addRoom(name: 'ห้องจะลบ', size: RoomSize.small, capacity: 2);
      
      // Verify room exists
      final roomsBeforeDelete = await mapService.getAllRooms();
      expect(roomsBeforeDelete.length, equals(1));

      final result = await mapService.deleteRoom(roomId!);
      expect(result, isTrue);

      // Verify room was deleted
      final roomsAfterDelete = await mapService.getAllRooms();
      expect(roomsAfterDelete.length, equals(0));
    });
  });

  group('Position Management', () {
    test('should check if position can be placed', () async {
      final roomId = await mapService.addRoom(name: 'ห้อง 1', size: RoomSize.small, capacity: 2);
      await mapService.updateRoomPosition(roomId!, 100.0, 100.0);

      // Same position should not be available
      final canPlace1 = await mapService.canPlaceRoom(100.0, 100.0);
      expect(canPlace1, isFalse);

      // Different position should be available
      final canPlace2 = await mapService.canPlaceRoom(200.0, 200.0);
      expect(canPlace2, isTrue);

      // Same position should be available when excluding the room
      final canPlace3 = await mapService.canPlaceRoom(100.0, 100.0, excludeRoomId: roomId);
      expect(canPlace3, isTrue);
    });

    test('should find available position', () async {
      // Place a room at starting position
      final roomId = await mapService.addRoom(name: 'ห้อง 1', size: RoomSize.small, capacity: 2);
      await mapService.updateRoomPosition(roomId!, 50.0, 50.0);

      // Find next available position
      final position = await mapService.findAvailablePosition();
      
      expect(position, isNotNull);
      expect(position!.$1, greaterThan(50.0)); // x should be different
      expect(position.$2, greaterThanOrEqualTo(50.0)); // y should be same or different
    });

    test('should prevent room position conflicts', () async {
      final roomId1 = await mapService.addRoom(name: 'ห้อง 1', size: RoomSize.small, capacity: 2);
      final roomId2 = await mapService.addRoom(name: 'ห้อง 2', size: RoomSize.small, capacity: 2);

      // Place first room
      await mapService.updateRoomPosition(roomId1!, 100.0, 100.0);

      // Try to place second room at same position should fail
      final result = await mapService.updateRoomPosition(roomId2!, 100.0, 100.0);
      expect(result, isFalse);

      // Place at different position should succeed
      final result2 = await mapService.updateRoomPosition(roomId2, 200.0, 200.0);
      expect(result2, isTrue);
    });
  });

  group('Room Status Management', () {
    test('should assign room to visitor', () async {
      final roomId = await mapService.addRoom(name: 'ห้องทดสอบ', size: RoomSize.small, capacity: 2);
      
      final result = await mapService.assignRoomToVisitor(roomId!, 'visitor123');
      expect(result, isTrue);

      final rooms = await mapService.getAllRooms();
      final room = rooms.firstWhere((r) => r.id == roomId);
      expect(room.status, equals(RoomStatus.occupied));
      expect(room.currentOccupant, equals('visitor123'));
    });

    test('should not assign occupied room', () async {
      final roomId = await mapService.addRoom(name: 'ห้องจอง', size: RoomSize.small, capacity: 2);
      
      // First assignment should succeed
      await mapService.assignRoomToVisitor(roomId!, 'visitor1');
      
      // Second assignment should fail
      final result = await mapService.assignRoomToVisitor(roomId, 'visitor2');
      expect(result, isFalse);
    });

    test('should unassign room from visitor', () async {
      final roomId = await mapService.addRoom(name: 'ห้องทดสอบ', size: RoomSize.small, capacity: 2);
      
      // Assign then unassign
      await mapService.assignRoomToVisitor(roomId!, 'visitor123');
      final result = await mapService.unassignRoomFromVisitor(roomId);
      expect(result, isTrue);

      final rooms = await mapService.getAllRooms();
      final room = rooms.firstWhere((r) => r.id == roomId);
      expect(room.status, equals(RoomStatus.available));
      expect(room.currentOccupant, isNull);
    });
  });

  group('Statistics and Utilities', () {
    test('should get room statistics', () async {
      // Create rooms with different statuses
      final roomId1 = await mapService.addRoom(name: 'ห้องว่าง 1', size: RoomSize.small, capacity: 2);
      final roomId2 = await mapService.addRoom(name: 'ห้องว่าง 2', size: RoomSize.medium, capacity: 4);
      final roomId3 = await mapService.addRoom(name: 'ห้องจอง', size: RoomSize.large, capacity: 6);

      // Set different statuses
      await mapService.updateRoomStatus(roomId3!, RoomStatus.occupied);
      
      // Set positions for some rooms
      await mapService.updateRoomPosition(roomId1!, 100.0, 100.0);
      await mapService.updateRoomPosition(roomId2!, 200.0, 200.0);

      final stats = await mapService.getRoomStatistics();

      expect(stats['totalRooms'], equals(3));
      expect(stats['availableRooms'], equals(2));
      expect(stats['occupiedRooms'], equals(1));
      expect(stats['reservedRooms'], equals(0));
      expect(stats['roomsWithPosition'], equals(2));
      expect(stats['roomsWithoutPosition'], equals(1));
      expect(stats['totalCapacity'], equals(12)); // 2 + 4 + 6
      expect(stats['availableCapacity'], equals(6)); // 2 + 4 (only available rooms)
    });

    test('should handle empty statistics', () async {
      final stats = await mapService.getRoomStatistics();

      expect(stats['totalRooms'], equals(0));
      expect(stats['availableRooms'], equals(0));
      expect(stats['occupiedRooms'], equals(0));
      expect(stats['reservedRooms'], equals(0));
      expect(stats['roomsWithPosition'], equals(0));
      expect(stats['roomsWithoutPosition'], equals(0));
      expect(stats['totalCapacity'], equals(0));
      expect(stats['availableCapacity'], equals(0));
    });

    test('should create test data', () async {
      await mapService.createTestData();

      // Verify test data was created
      final maps = await mapService.getAllMaps();
      final rooms = await mapService.getAllRooms();

      expect(maps.length, greaterThan(0));
      expect(rooms.length, greaterThan(0));
    });

    test('should clear all data', () async {
      // Create some data
      await mapService.saveMap(name: 'แผนที่ 1');
      await mapService.addRoom(name: 'ห้อง 1', size: RoomSize.small, capacity: 2);

      // Verify data exists
      final mapsBefore = await mapService.getAllMaps();
      final roomsBefore = await mapService.getAllRooms();
      expect(mapsBefore.length, greaterThan(0));
      expect(roomsBefore.length, greaterThan(0));

      // Clear all data
      await mapService.clearAllData();

      // Verify data was cleared
      final mapsAfter = await mapService.getAllMaps();
      final roomsAfter = await mapService.getAllRooms();
      expect(mapsAfter.length, equals(0));
      expect(roomsAfter.length, equals(0));
    });
  });

  group('Error Handling', () {
    test('should handle addRoom error gracefully', () async {
      final roomId = await mapService.addRoom(
        name: '', // Empty name might cause issues
        size: RoomSize.small,
        capacity: -1, // Invalid capacity
      );
      
      // Method should handle errors and return null or valid result
      expect(roomId, isA<int?>());
    });

    test('should handle updateRoom error gracefully', () async {
      final invalidRoom = Room(
        id: 999, // Non-existent ID
        name: 'ห้องไม่มีจริง',
        size: RoomSize.small,
        capacity: 2,
      );

      final result = await mapService.updateRoom(invalidRoom);
      expect(result, isFalse);
    });

    test('should handle deleteRoom error gracefully', () async {
      // Try to delete non-existent room
      final result = await mapService.deleteRoom(999);
      expect(result, isFalse);
    });

    test('should handle updateRoomPosition error gracefully', () async {
      // Try to update position of non-existent room
      final result = await mapService.updateRoomPosition(999, 100.0, 100.0);
      expect(result, isFalse);
    });

    test('should handle updateRoomStatus error gracefully', () async {
      // Try to update status of non-existent room
      final result = await mapService.updateRoomStatus(999, RoomStatus.occupied);
      expect(result, isFalse);
    });

    test('should handle assignRoomToVisitor error gracefully', () async {
      // Try to assign non-existent room
      final result = await mapService.assignRoomToVisitor(999, 'visitor123');
      expect(result, isFalse);
    });

    test('should handle statistics errors gracefully', () async {
      final stats = await mapService.getRoomStatistics();
      expect(stats, isA<Map<String, dynamic>>());
    });
  });
}