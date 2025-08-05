import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/booking_service.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late BookingService bookingService;
  late DbHelper dbHelper;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    bookingService = BookingService();
    dbHelper = bookingService.dbHelper;
    
    // Clear database before each test
    await dbHelper.clearAllData();
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('BookingValidationResult Tests', () {
    test('should create success result', () {
      final result = BookingValidationResult.success();
      
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('should create error result', () {
      const errorMessage = 'การจองไม่ถูกต้อง';
      final result = BookingValidationResult.error(errorMessage);
      
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals(errorMessage));
    });

    test('should create result with parameters', () {
      final validResult = const BookingValidationResult(isValid: true);
      final invalidResult = const BookingValidationResult(
        isValid: false, 
        errorMessage: 'เกิดข้อผิดพลาด'
      );
      
      expect(validResult.isValid, isTrue);
      expect(validResult.errorMessage, isNull);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errorMessage, equals('เกิดข้อผิดพลาด'));
    });
  });

  group('Basic Booking Operations', () {
    test('should access DbHelper instance', () {
      expect(bookingService.dbHelper, isNotNull);
      expect(bookingService.dbHelper, isA<DbHelper>());
    });

    test('should create room booking successfully', () async {
      // Create test data
      final visitor = RegData.manual(
        id: '0812345678',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2530',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร',
        gender: 'ชาย',
      );
      await dbHelper.insert(visitor);

      // Create practice period (reg_additional_info)
      final additionalInfo = RegAdditionalInfo.create(
        regId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      await dbHelper.insertAdditionalInfo(additionalInfo);

      // Create stay record
      final stay = StayRecord.create(
        visitorId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        status: 'active',
      );
      await dbHelper.insertStay(stay);

      // Create room (assuming rooms table exists)
      final db = await dbHelper.db;
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Test creating booking
      final result = await bookingService.createRoomBooking(
        roomId: 1,
        visitorId: visitor.id,
        checkInDate: DateTime(2024, 1, 10),
        checkOutDate: DateTime(2024, 1, 15),
      );

      expect(result, isTrue);

      // Verify booking was created
      final bookings = await db.query('room_bookings');
      expect(bookings.length, equals(1));
      expect(bookings.first['room_id'], equals(1));
      expect(bookings.first['visitor_id'], equals(visitor.id));
      expect(bookings.first['status'], equals('active'));
    });

    test('should fail to create booking with conflict', () async {
      // Setup test data similar to previous test
      final visitor = RegData.manual(
        id: '0812345678',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2530',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร',
        gender: 'ชาย',
      );
      await dbHelper.insert(visitor);

      final additionalInfo = RegAdditionalInfo.create(
        regId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      await dbHelper.insertAdditionalInfo(additionalInfo);

      final stay = StayRecord.create(
        visitorId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        status: 'active',
      );
      await dbHelper.insertStay(stay);

      final db = await dbHelper.db;
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create first booking
      await bookingService.createRoomBooking(
        roomId: 1,
        visitorId: visitor.id,
        checkInDate: DateTime(2024, 1, 10),
        checkOutDate: DateTime(2024, 1, 15),
      );

      // Try to create conflicting booking
      final result = await bookingService.createRoomBooking(
        roomId: 1,
        visitorId: 'another_visitor',
        checkInDate: DateTime(2024, 1, 12),
        checkOutDate: DateTime(2024, 1, 18),
      );

      expect(result, isFalse);
    });
  });

  group('Booking Conflict Detection', () {
    test('should detect booking conflicts correctly', () async {
      final db = await dbHelper.db;
      
      // Create room
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create existing booking
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Test various conflict scenarios
      
      // Overlapping start
      bool hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 8),
        endDate: DateTime(2024, 1, 12),
      );
      expect(hasConflict, isTrue);

      // Overlapping end
      hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 13),
        endDate: DateTime(2024, 1, 18),
      );
      expect(hasConflict, isTrue);

      // Completely inside
      hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 11),
        endDate: DateTime(2024, 1, 14),
      );
      expect(hasConflict, isTrue);

      // Completely outside (no conflict)
      hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 20),
        endDate: DateTime(2024, 1, 25),
      );
      expect(hasConflict, isFalse);

      // Same dates
      hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
      );
      expect(hasConflict, isTrue);
    });

    test('should exclude booking when checking conflicts', () async {
      final db = await dbHelper.db;
      
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Should not find conflict when excluding the same booking
      final hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
        excludeBookingId: 1,
      );
      
      expect(hasConflict, isFalse);
    });

    test('should ignore cancelled bookings', () async {
      final db = await dbHelper.db;
      
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create cancelled booking
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'cancelled',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Should not find conflict with cancelled booking
      final hasConflict = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
      );
      
      expect(hasConflict, isFalse);
    });
  });

  group('Booking Validation', () {
    test('should validate booking cancellation rules', () async {
      final db = await dbHelper.db;
      
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      // Create booking that started yesterday (cannot cancel)
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': yesterday.toIso8601String().split('T')[0],
        'check_out_date': tomorrow.toIso8601String().split('T')[0],
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await bookingService.canCancelBooking(
        bookingId: 1,
        visitorId: 'visitor1',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('มีประวัติการเข้าพักแล้ว'));
    });

    test('should allow cancellation for future bookings', () async {
      final db = await dbHelper.db;
      
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextWeek = DateTime.now().add(const Duration(days: 7));

      // Create future booking (can cancel)
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': tomorrow.toIso8601String().split('T')[0],
        'check_out_date': nextWeek.toIso8601String().split('T')[0],
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await bookingService.canCancelBooking(
        bookingId: 1,
        visitorId: 'visitor1',
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('should validate room transfer availability', () async {
      final db = await dbHelper.db;
      
      // Create rooms
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('rooms', {
        'id': 2,
        'name': 'ห้อง 2',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create booking in room 1
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create conflicting booking in room 2
      await db.insert('room_bookings', {
        'id': 2,
        'room_id': 2,
        'visitor_id': 'visitor2',
        'check_in_date': '2024-01-12',
        'check_out_date': '2024-01-18',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Try to transfer to conflicting room
      final result = await bookingService.canTransferRoom(
        currentBookingId: 1,
        targetRoomId: 2,
        visitorId: 'visitor1',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('ห้องปลายทางไม่ว่าง'));
    });
  });

  group('Booking Operations', () {
    test('should cancel booking successfully', () async {
      final db = await dbHelper.db;
      
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextWeek = DateTime.now().add(const Duration(days: 7));

      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': tomorrow.toIso8601String().split('T')[0],
        'check_out_date': nextWeek.toIso8601String().split('T')[0],
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      final result = await bookingService.cancelBooking(
        bookingId: 1,
        visitorId: 'visitor1',
      );

      expect(result, isTrue);

      // Verify booking status
      final bookings = await db.query('room_bookings', where: 'id = ?', whereArgs: [1]);
      expect(bookings.first['status'], equals('cancelled'));
    });

    test('should transfer room successfully', () async {
      final db = await dbHelper.db;
      
      // Create rooms
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('rooms', {
        'id': 2,
        'name': 'ห้อง 2',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create booking in room 1
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Transfer to room 2
      final result = await bookingService.transferRoom(
        currentBookingId: 1,
        targetRoomId: 2,
        visitorId: 'visitor1',
      );

      expect(result, isTrue);

      // Verify room change
      final bookings = await db.query('room_bookings', where: 'id = ?', whereArgs: [1]);
      expect(bookings.first['room_id'], equals(2));
    });
  });

  group('Room Usage Summary', () {
    test('should generate daily room status correctly', () async {
      final db = await dbHelper.db;
      
      // Create rooms
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      await db.insert('rooms', {
        'id': 2,
        'name': 'ห้อง 2',
        'size': 'L',
        'capacity': 6,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create visitor
      final visitor = RegData.manual(
        id: '0812345678',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2530',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร',
        gender: 'ชาย',
      );
      await dbHelper.insert(visitor);

      // Create booking for room 1
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': visitor.id,
        'check_in_date': '2024-01-15',
        'check_out_date': '2024-01-20',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Get daily status for 2024-01-15
      final summary = await bookingService.getRoomUsageSummary(
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 15),
      );

      expect(summary.length, equals(2));
      
      final room1Summary = summary.firstWhere((s) => s.roomId == 1);
      final room2Summary = summary.firstWhere((s) => s.roomId == 2);

      expect(room1Summary.dailyStatus, equals('จองแล้ว'));
      expect(room1Summary.guestName, equals('สมชาย ใจดี'));
      expect(room1Summary.isSingleDay, isTrue);

      expect(room2Summary.dailyStatus, equals('ว่าง'));
      expect(room2Summary.guestName, equals(''));
      expect(room2Summary.isSingleDay, isTrue);
    });

    test('should generate multi-day usage summary correctly', () async {
      final db = await dbHelper.db;
      
      // Create room
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Create multiple bookings
      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': 'visitor1',
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('room_bookings', {
        'id': 2,
        'room_id': 1,
        'visitor_id': 'visitor2',
        'check_in_date': '2024-01-20',
        'check_out_date': '2024-01-25',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Get usage summary for the month
      final summary = await bookingService.getRoomUsageSummary(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      expect(summary.length, equals(1));
      
      final roomSummary = summary.first;
      expect(roomSummary.roomId, equals(1));
      expect(roomSummary.usageDays, greaterThan(0));
      expect(roomSummary.isSingleDay, isFalse);
    });
  });

  group('RoomUsageSummary Class', () {
    test('should create RoomUsageSummary correctly', () {
      final summary = RoomUsageSummary(
        roomId: 1,
        roomName: 'ห้อง 1',
        roomSize: 'M',
        capacity: 4,
        usageDays: 5,
        dailyStatus: 'จองแล้ว',
        guestName: 'สมชาย ใจดี',
        isSingleDay: false,
      );

      expect(summary.roomId, equals(1));
      expect(summary.roomName, equals('ห้อง 1'));
      expect(summary.roomSize, equals('M'));
      expect(summary.capacity, equals(4));
      expect(summary.usageDays, equals(5));
      expect(summary.dailyStatus, equals('จองแล้ว'));
      expect(summary.guestName, equals('สมชาย ใจดี'));
      expect(summary.isSingleDay, isFalse);
    });

    test('should generate correct toString for single day', () {
      final summary = RoomUsageSummary(
        roomId: 1,
        roomName: 'ห้อง 1',
        roomSize: 'M',
        capacity: 4,
        usageDays: 0,
        dailyStatus: 'จองแล้ว',
        guestName: 'สมชาย ใจดี',
        isSingleDay: true,
      );

      final string = summary.toString();
      expect(string, contains('ห้อง 1'));
      expect(string, contains('จองแล้ว'));
      expect(string, contains('สมชาย ใจดี'));
    });

    test('should generate correct toString for multi-day', () {
      final summary = RoomUsageSummary(
        roomId: 1,
        roomName: 'ห้อง 1',
        roomSize: 'M',
        capacity: 4,
        usageDays: 15,
        dailyStatus: '',
        guestName: '',
        isSingleDay: false,
      );

      final string = summary.toString();
      expect(string, contains('ห้อง 1'));
      expect(string, contains('15 วัน'));
    });

    test('should handle empty guest name in toString', () {
      final summary = RoomUsageSummary(
        roomId: 1,
        roomName: 'ห้อง 1',
        roomSize: 'M',
        capacity: 4,
        usageDays: 0,
        dailyStatus: 'ว่าง',
        guestName: '',
        isSingleDay: true,
      );

      final string = summary.toString();
      expect(string, contains('ห้อง 1'));
      expect(string, contains('ว่าง'));
      expect(string, isNot(contains(' - ')));
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle database errors gracefully', () async {
      // Close database to simulate error
      final db = await dbHelper.db;
      await db.close();

      final result = await bookingService.hasBookingConflict(
        roomId: 1,
        startDate: DateTime(2024, 1, 10),
        endDate: DateTime(2024, 1, 15),
      );

      // Should return false (no conflict) when database error occurs
      expect(result, isFalse);
    });

    test('should handle missing booking data', () async {
      final result = await bookingService.canCancelBooking(
        bookingId: 999,
        visitorId: 'nonexistent',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('ไม่พบข้อมูลการจอง'));
    });

    test('should handle invalid date ranges', () async {
      final summary = await bookingService.getRoomUsageSummary(
        startDate: DateTime(2024, 1, 31),
        endDate: DateTime(2024, 1, 1), // End before start
      );

      // Should handle gracefully and return empty or handle the logic
      expect(summary, isA<List<RoomUsageSummary>>());
    });

    test('should handle same start and end dates', () async {
      final sameDate = DateTime(2024, 1, 15);
      final summary = await bookingService.getRoomUsageSummary(
        startDate: sameDate,
        endDate: sameDate,
      );

      expect(summary, isA<List<RoomUsageSummary>>());
      // Should be treated as single day
      if (summary.isNotEmpty) {
        expect(summary.first.isSingleDay, isTrue);
      }
    });
  });

  group('Legacy Method Compatibility', () {
    test('should maintain backward compatibility for updateRoomBookingDates', () async {
      final visitor = RegData.manual(
        id: '0812345678',
        first: 'สมชาย',
        last: 'ใจดี',
        dob: '15 มกราคม 2530',
        phone: '0812345678',
        addr: 'กรุงเทพมหานคร',
        gender: 'ชาย',
      );
      await dbHelper.insert(visitor);

      final additionalInfo = RegAdditionalInfo.create(
        regId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );
      await dbHelper.insertAdditionalInfo(additionalInfo);

      final stay = StayRecord.create(
        visitorId: visitor.id,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        status: 'active',
      );
      await dbHelper.insertStay(stay);

      final db = await dbHelper.db;
      await db.insert('rooms', {
        'id': 1,
        'name': 'ห้อง 1',
        'size': 'M',
        'capacity': 4,
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.insert('room_bookings', {
        'id': 1,
        'room_id': 1,
        'visitor_id': visitor.id,
        'check_in_date': '2024-01-10',
        'check_out_date': '2024-01-15',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Test legacy method
      final result = await bookingService.updateRoomBookingDates(
        bookingId: 1,
        newCheckInDate: DateTime(2024, 1, 12),
        newCheckOutDate: DateTime(2024, 1, 18),
        visitorId: visitor.id,
      );

      expect(result, isA<bool>());
    });
  });
}