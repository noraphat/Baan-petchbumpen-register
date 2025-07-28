import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'db_helper.dart';
import '../models/room_model.dart';

/// Service สำหรับจัดการระบบแผนที่และห้องพัก
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final DbHelper _dbHelper = DbHelper();
  final ImagePicker _imagePicker = ImagePicker();

  // =================== MAP MANAGEMENT ===================

  /// ดึงแผนที่ทั้งหมด
  Future<List<MapData>> getAllMaps() async {
    return await _dbHelper.fetchAllMaps();
  }

  /// ดึงแผนที่ที่กำลังใช้งาน
  Future<MapData?> getActiveMap() async {
    return await _dbHelper.fetchActiveMap();
  }

  /// ฟังก์ชันสำรองสำหรับถ่ายภาพ (ลองหลายวิธี)
  Future<String?> _captureImageWithFallback() async {
    // วิธีที่ 1: ใช้การตั้งค่าพื้นฐาน
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) return await _saveImageToStorage(image);
    } catch (e) {
      debugPrint('Method 1 failed: $e');
    }

    // วิธีที่ 2: ใช้การตั้งค่าที่เจาะจงมากขึ้น
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
      if (image != null) return await _saveImageToStorage(image);
    } catch (e) {
      debugPrint('Method 2 failed: $e');
    }

    // วิธีที่ 3: ลองใช้กล้องหน้า
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) return await _saveImageToStorage(image);
    } catch (e) {
      debugPrint('Method 3 failed: $e');
    }

    // ถ้าทุกวิธีล้มเหลว
    throw Exception('กล้องไม่พร้อมใช้งาน กรุณาลองใช้ "เลือกภาพจากแกลเลอรี่" แทน\n\nหมายเหตุ: ฟังก์ชันสแกน QR ใช้ระบบกล้องแยกต่างหาก (mobile_scanner) ซึ่งแตกต่างจากระบบถ่ายภาพ (image_picker)');
  }

  /// บันทึกภาพไปยัง storage พร้อมปรับขนาด
  Future<String> _saveImageToStorage(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mapDir = Directory(path.join(appDir.path, 'maps'));
    if (!await mapDir.exists()) {
      await mapDir.create(recursive: true);
    }

    final fileName = 'map_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = path.join(mapDir.path, fileName);
    
    try {
      // อ่านไฟล์ภาพต้นฉบับ
      final originalFile = File(image.path);
      final bytes = await originalFile.readAsBytes();
      
      // ตรวจสอบขนาดไฟล์ ถ้าใหญ่เกิน 5MB ให้ปรับขนาด
      if (bytes.length > 5 * 1024 * 1024) { // 5MB
        debugPrint('Image size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB - Resizing...');
        
        // สำหรับตอนนี้ใช้วิธีง่าย ๆ คือ copy ไฟล์ไปก่อน
        // ในอนาคตสามารถเพิ่มการ resize จริง ๆ ด้วย package เช่น image
        final File newFile = await originalFile.copy(newPath);
        
        debugPrint('Image saved with size: ${(await newFile.length() / 1024 / 1024).toStringAsFixed(2)}MB');
        return newFile.path;
      } else {
        // ไฟล์ขนาดเล็ก copy ตรง ๆ
        final File newFile = await originalFile.copy(newPath);
        debugPrint('Image saved (original size): ${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB');
        return newFile.path;
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      // Fallback: copy ตรง ๆ
      final File newFile = await File(image.path).copy(newPath);
      return newFile.path;
    }
  }

  /// อัปโหลดภาพแผนที่ใหม่
  Future<String?> uploadMapImage({ImageSource source = ImageSource.gallery}) async {
    try {
      if (source == ImageSource.camera) {
        // ใช้ฟังก์ชันสำรองสำหรับถ่ายภาพ
        return await _captureImageWithFallback();
      } else {
        // สำหรับ gallery ใช้การตั้งค่าปกติ
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 85,
        );

        if (image == null) return null;
        return await _saveImageToStorage(image);
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException details: code=${e.code}, message=${e.message}, details=${e.details}');
      
      // จัดการข้อผิดพลาดเฉพาะ
      switch (e.code) {
        case 'no_available_camera':
          if (source == ImageSource.camera) {
            throw Exception(
              'ไม่สามารถเข้าถึงกล้องได้\n\n'
              '📱 วิธีแก้ไข:\n'
              '• ใช้ "เลือกภาพจากแกลเลอรี่" แทน\n'
              '• หรือถ่ายภาพด้วยแอปกล้องก่อน แล้วเลือกจากแกลเลอรี่'
            );
          } else {
            throw Exception('ไม่สามารถเข้าถึงแกลเลอรี่ได้');
          }
        case 'camera_access_denied':
          throw Exception('ไม่ได้รับอนุญาตให้เข้าถึงกล้อง\nกรุณาอนุญาตในการตั้งค่าแอป');
        case 'photo_access_denied':
          throw Exception('ไม่ได้รับอนุญาตให้เข้าถึงแกลเลอรี่\nกรุณาอนุญาตในการตั้งค่าแอป');
        case 'invalid_image':
          throw Exception('รูปภาพไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
        default:
          throw Exception('เกิดข้อผิดพลาด: ${e.code}\n${e.message ?? ''}');
      }
    } catch (e) {
      debugPrint('General error uploading map image: $e');
      if (e.toString().contains('Exception:')) {
        rethrow; // ส่งต่อ Exception ที่เราสร้างไว้
      }
      throw Exception('ไม่สามารถเลือกภาพได้: $e');
    }
  }

  /// บันทึกแผนที่ใหม่
  Future<int?> saveMap({
    required String name,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
    String? description,
  }) async {
    try {
      final mapData = MapData.create(
        name: name,
        imagePath: imagePath,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        description: description,
      );

      return await _dbHelper.insertMap(mapData);
    } catch (e) {
      debugPrint('Error saving map: $e');
      return null;
    }
  }

  /// อัปเดตแผนที่
  Future<bool> updateMap(MapData mapData) async {
    try {
      await _dbHelper.updateMap(mapData);
      return true;
    } catch (e) {
      debugPrint('Error updating map: $e');
      return false;
    }
  }

  /// ตั้งแผนที่เป็น active
  Future<bool> setActiveMap(int mapId) async {
    try {
      await _dbHelper.setActiveMap(mapId);
      return true;
    } catch (e) {
      debugPrint('Error setting active map: $e');
      return false;
    }
  }

  /// ลบแผนที่
  Future<bool> deleteMap(int mapId) async {
    try {
      // ดึงข้อมูลแผนที่ก่อนลบ
      final maps = await _dbHelper.fetchAllMaps();
      final mapToDelete = maps.where((m) => m.id == mapId).firstOrNull;

      // ลบไฟล์ภาพ (ถ้ามี)
      if (mapToDelete?.imagePath != null) {
        final file = File(mapToDelete!.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // ลบจากฐานข้อมูล
      await _dbHelper.deleteMap(mapId);
      return true;
    } catch (e) {
      debugPrint('Error deleting map: $e');
      return false;
    }
  }

  // =================== ROOM MANAGEMENT ===================

  /// ดึงห้องพักทั้งหมด
  Future<List<Room>> getAllRooms() async {
    return await _dbHelper.fetchAllRooms();
  }

  /// ดึงห้องพักที่มีตำแหน่งบนแผนที่
  Future<List<Room>> getRoomsWithPosition() async {
    return await _dbHelper.fetchRoomsWithPosition();
  }

  /// ดึงห้องพักตามสถานะ
  Future<List<Room>> getRoomsByStatus(RoomStatus status) async {
    return await _dbHelper.fetchRoomsByStatus(status);
  }

  /// เพิ่มห้องพักใหม่
  Future<int?> addRoom({
    required String name,
    required RoomSize size,
    RoomShape shape = RoomShape.square,
    required int capacity,
    String? description,
  }) async {
    try {
      final room = Room.create(
        name: name,
        size: size,
        shape: shape,
        capacity: capacity,
        description: description,
      );

      return await _dbHelper.insertRoom(room);
    } catch (e) {
      debugPrint('Error adding room: $e');
      return null;
    }
  }

  /// อัปเดตข้อมูลห้องพัก
  Future<bool> updateRoom(Room room) async {
    try {
      await _dbHelper.updateRoom(room);
      return true;
    } catch (e) {
      debugPrint('Error updating room: $e');
      return false;
    }
  }

  /// อัปเดตตำแหน่งห้องพัก (รับค่าเป็น percentage)
  Future<bool> updateRoomPosition(int roomId, double x, double y) async {
    try {
      // ตรวจสอบว่าตำแหน่งนั้นมีห้องอื่นอยู่หรือไม่
      final isOccupied = await _dbHelper.isPositionOccupied(x, y, excludeRoomId: roomId);
      if (isOccupied) {
        return false; // ตำแหน่งนี้มีห้องอื่นอยู่แล้ว
      }

      // บันทึกค่าเป็น percentage (0-100)
      await _dbHelper.updateRoomPosition(roomId, x, y);
      return true;
    } catch (e) {
      debugPrint('Error updating room position: $e');
      return false;
    }
  }

  /// อัปเดตสถานะห้องพัก
  Future<bool> updateRoomStatus(int roomId, RoomStatus status, {String? occupantId}) async {
    try {
      await _dbHelper.updateRoomStatus(roomId, status, occupantId: occupantId);
      return true;
    } catch (e) {
      debugPrint('Error updating room status: $e');
      return false;
    }
  }

  /// ลบห้องพัก
  Future<bool> deleteRoom(int roomId) async {
    try {
      await _dbHelper.deleteRoom(roomId);
      return true;
    } catch (e) {
      debugPrint('Error deleting room: $e');
      return false;
    }
  }

  /// ตรวจสอบว่าตำแหน่งนั้นสามารถวางห้องได้หรือไม่
  Future<bool> canPlaceRoom(double x, double y, {int? excludeRoomId}) async {
    return !(await _dbHelper.isPositionOccupied(x, y, excludeRoomId: excludeRoomId));
  }

  /// ค้นหาตำแหน่งที่เหมาะสมสำหรับวางห้องใหม่
  Future<(double, double)?> findAvailablePosition({
    double startX = 50,
    double startY = 50,
    double spacing = 80,
    double maxX = 800,
    double maxY = 600,
  }) async {
    for (double y = startY; y < maxY; y += spacing) {
      for (double x = startX; x < maxX; x += spacing) {
        if (await canPlaceRoom(x, y)) {
          return (x, y);
        }
      }
    }
    return null; // ไม่พบตำแหน่งว่าง
  }

  // =================== ROOM STATUS MANAGEMENT ===================

  /// อัปเดตสถานะห้องพักตามข้อมูลการเข้าพัก
  Future<void> updateRoomStatusFromStays() async {
    try {
      final allRooms = await getAllRooms();
      // อัปเดตสถานะห้องพักตามข้อมูลการเข้าพัก

      for (final room in allRooms) {
        if (room.currentOccupant != null) {
          // ตรวจสอบสถานะการเข้าพักปัจจุบัน
          final stayStatus = await _dbHelper.checkStayStatus(room.currentOccupant!);
          
          if (stayStatus['isActive'] == true) {
            // ยังมีคนพัก
            await updateRoomStatus(room.id!, RoomStatus.occupied, occupantId: room.currentOccupant);
          } else {
            // ไม่มีคนพักแล้ว
            await updateRoomStatus(room.id!, RoomStatus.available);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating room status from stays: $e');
    }
  }

  /// กำหนดห้องให้กับผู้เข้าพัก
  Future<bool> assignRoomToVisitor(int roomId, String visitorId) async {
    try {
      final room = await _dbHelper.fetchRoomById(roomId);
      if (room == null || !room.isAvailable) {
        return false; // ห้องไม่มีอยู่หรือไม่ว่าง
      }

      await updateRoomStatus(roomId, RoomStatus.occupied, occupantId: visitorId);
      return true;
    } catch (e) {
      debugPrint('Error assigning room to visitor: $e');
      return false;
    }
  }

  /// ปลดการกำหนดห้องจากผู้เข้าพัก
  Future<bool> unassignRoomFromVisitor(int roomId) async {
    try {
      await updateRoomStatus(roomId, RoomStatus.available);
      return true;
    } catch (e) {
      debugPrint('Error unassigning room from visitor: $e');
      return false;
    }
  }

  // =================== UTILITY METHODS ===================

  /// ดึงข้อมูลสถิติห้องพัก
  Future<Map<String, dynamic>> getRoomStatistics() async {
    try {
      final allRooms = await getAllRooms();
      final availableRooms = allRooms.where((r) => r.status == RoomStatus.available);
      final occupiedRooms = allRooms.where((r) => r.status == RoomStatus.occupied);
      final reservedRooms = allRooms.where((r) => r.status == RoomStatus.reserved);
      final roomsWithPosition = allRooms.where((r) => r.hasPosition);

      return {
        'totalRooms': allRooms.length,
        'availableRooms': availableRooms.length,
        'occupiedRooms': occupiedRooms.length,
        'reservedRooms': reservedRooms.length,
        'roomsWithPosition': roomsWithPosition.length,
        'roomsWithoutPosition': allRooms.length - roomsWithPosition.length,
        'totalCapacity': allRooms.fold<int>(0, (sum, room) => sum + room.capacity),
        'availableCapacity': availableRooms.fold<int>(0, (sum, room) => sum + room.capacity),
      };
    } catch (e) {
      debugPrint('Error getting room statistics: $e');
      return {};
    }
  }

  /// สร้างข้อมูลทดสอบ
  Future<void> createTestData() async {
    try {
      await _dbHelper.createTestRooms();
      
      // สร้างแผนที่ทดสอบ
      await saveMap(
        name: 'แผนที่ทดสอบ',
        description: 'แผนที่สำหรับทดสอบระบบ',
      );
    } catch (e) {
      debugPrint('Error creating test data: $e');
    }
  }

  /// ล้างข้อมูลทั้งหมด
  Future<void> clearAllData() async {
    try {
      // ลบไฟล์ภาพแผนที่ทั้งหมด
      final maps = await getAllMaps();
      for (final map in maps) {
        if (map.imagePath != null) {
          final file = File(map.imagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      // ล้างข้อมูลในฐานข้อมูล
      await _dbHelper.clearMapAndRoomData();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }
}