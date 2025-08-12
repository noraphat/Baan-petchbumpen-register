import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/room_model.dart';

/// Service for managing room bookings and validating practice date ranges
/// This service centralizes booking-related validation logic
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  /// Get the booking date range for a visitor
  /// Returns the min check_in_date to max check_out_date from non-cancelled bookings
  /// This is used to validate that practice dates cover all booked periods
  static Future<DateTimeRange?> getBookingRange(String visitorId) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT MIN(check_in_date) AS min_check_in, MAX(check_out_date) AS max_check_out
        FROM room_bookings
        WHERE visitor_id = ? AND status != 'cancelled'
      ''',
        [visitorId],
      );

      if (result.isNotEmpty) {
        final row = result.first;
        final minCheckIn = row['min_check_in'] as String?;
        final maxCheckOut = row['max_check_out'] as String?;

        if (minCheckIn != null && maxCheckOut != null) {
          return DateTimeRange(
            start: DateTime.parse(minCheckIn),
            end: DateTime.parse(maxCheckOut),
          );
        }
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get booking range: $e');
    }
  }

  /// Check if visitor has any room bookings
  /// Used to determine if booking validation is necessary
  static Future<bool> hasRoomBookings(String visitorId) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.query(
        'room_bookings',
        where: 'visitor_id = ? AND status != ?',
        whereArgs: [visitorId, 'cancelled'],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check room bookings: $e');
    }
  }

  /// Validate if practice date range covers all room bookings
  /// This is the core validation logic mentioned in the requirements
  static Future<String?> validatePracticeRangeWithBookings({
    required String visitorId,
    required DateTime practiceStart,
    required DateTime practiceEnd,
  }) async {
    try {
      // Check if visitor has any bookings
      final hasBookings = await hasRoomBookings(visitorId);
      if (!hasBookings) return null; // No bookings = no validation needed

      // Get booking date range
      final bookingRange = await getBookingRange(visitorId);
      if (bookingRange == null) return null; // No active bookings

      // Normalize dates to date-only (remove time component)
      final practiceStartDate = DateTime(
        practiceStart.year,
        practiceStart.month,
        practiceStart.day,
      );
      final practiceEndDate = DateTime(
        practiceEnd.year,
        practiceEnd.month,
        practiceEnd.day,
      );
      final bookingStartDate = DateTime(
        bookingRange.start.year,
        bookingRange.start.month,
        bookingRange.start.day,
      );
      final bookingEndDate = DateTime(
        bookingRange.end.year,
        bookingRange.end.month,
        bookingRange.end.day,
      );

      // Check if practice range covers all booking dates
      final practiceStartsAfterBooking = practiceStartDate.isAfter(
        bookingStartDate,
      );
      final practiceEndsBeforeBooking = practiceEndDate.isBefore(
        bookingEndDate,
      );

      if (practiceStartsAfterBooking || practiceEndsBeforeBooking) {
        return 'ช่วงปฏิบัติธรรมต้องครอบคลุมช่วงที่จองห้องไว้ กรุณาปรับช่วงจองห้องก่อน';
      }

      return null; // Validation passed
    } catch (e) {
      throw Exception('Failed to validate practice range with bookings: $e');
    }
  }

  /// Update room booking check out date
  Future<bool> updateRoomBookingCheckOut({
    required int bookingId,
    required DateTime newCheckOutDate,
    required String visitorId,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.update(
        'room_bookings',
        {
          'check_out_date': newCheckOutDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update room booking check out: $e');
    }
  }

  /// Transfer room booking to another room
  Future<bool> transferRoom({
    required int currentBookingId,
    required int targetRoomId,
    required String visitorId,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      // Get target room name from rooms table
      final roomResult = await db.query(
        'rooms',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [targetRoomId],
      );

      if (roomResult.isEmpty) {
        throw Exception('Target room not found');
      }

      final targetRoomName = roomResult.first['name'] as String;

      final result = await db.update(
        'room_bookings',
        {
          'room_name': targetRoomName,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [currentBookingId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to transfer room: $e');
    }
  }

  /// Cancel room booking
  Future<bool> cancelBooking({
    required int bookingId,
    required String visitorId,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.update(
        'room_bookings',
        {'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Get room usage summary for a date range
  Future<List<RoomUsageSummary>> getRoomUsageSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          r.name as room_name,
          COUNT(DISTINCT rb.id) as total_bookings,
          COALESCE(SUM(JULIANDAY(rb.check_out_date) - JULIANDAY(rb.check_in_date)), 0) as usage_days,
          CASE 
            WHEN rb.status = 'active' THEN 'มีผู้เข้าพัก'
            WHEN rb.status = 'reserved' THEN 'จองแล้ว'
            ELSE 'ว่าง'
          END as daily_status,
          COUNT(DISTINCT rb.visitor_id) as total_visitors,
          COALESCE((COUNT(DISTINCT rb.id) * 100.0 / (JULIANDAY(?) - JULIANDAY(?) + 1)), 0.0) as occupancy_rate,
          MAX(rb.check_in_date) as last_check_in,
          MAX(rb.check_out_date) as last_check_out,
          r.size as room_size,
          '' as guest_name,
          0 as is_single_day
        FROM room_bookings rb
        JOIN rooms r ON rb.room_id = r.id
        WHERE rb.check_in_date <= ? 
          AND rb.check_out_date >= ?
          AND rb.status != 'cancelled'
        GROUP BY r.name, r.size
        ORDER BY r.name
      ''',
        [
          endDate.toIso8601String(),
          startDate.toIso8601String(),
          endDate.toIso8601String(),
          startDate.toIso8601String(),
        ],
      );

      return result.map((row) => RoomUsageSummary.fromMap(row)).toList();
    } catch (e) {
      throw Exception('Failed to get room usage summary: $e');
    }
  }

  /// Get database helper instance
  DbHelper get dbHelper => DbHelper();

  /// Check if booking can be cancelled
  Future<bool> canCancelBooking({
    required int bookingId,
    required String visitorId,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      final result = await db.query(
        'room_bookings',
        columns: ['check_in_date', 'status'],
        where: 'id = ? AND visitor_id = ?',
        whereArgs: [bookingId, visitorId],
      );

      if (result.isEmpty) return false;

      final booking = result.first;
      final checkInDate = DateTime.parse(booking['check_in_date'] as String);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final checkInDateOnly = DateTime(
        checkInDate.year,
        checkInDate.month,
        checkInDate.day,
      );

      // สามารถยกเลิกได้เฉพาะวันที่เช็คอินเท่านั้น
      return checkInDateOnly.isAtSameMomentAs(todayDate) &&
          booking['status'] == 'active';
    } catch (e) {
      throw Exception('Failed to check if booking can be cancelled: $e');
    }
  }

  /// Update room booking dates with validation
  Future<bool> updateRoomBookingDatesWithValidation({
    required int bookingId,
    required DateTime newCheckInDate,
    required DateTime newCheckOutDate,
    required String visitorId,
  }) async {
    final dbHelper = DbHelper();
    final db = await dbHelper.db;

    try {
      // ตรวจสอบว่ามีการจองอื่นในช่วงเวลาเดียวกันหรือไม่
      final conflictResult = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM room_bookings
        WHERE id != ? 
          AND room_id = (SELECT room_id FROM room_bookings WHERE id = ?)
          AND status != 'cancelled'
          AND (
            (check_in_date <= ? AND check_out_date > ?) OR
            (check_in_date < ? AND check_out_date >= ?) OR
            (check_in_date >= ? AND check_out_date <= ?)
          )
      ''',
        [
          bookingId,
          bookingId,
          newCheckOutDate.toIso8601String(),
          newCheckInDate.toIso8601String(),
          newCheckOutDate.toIso8601String(),
          newCheckInDate.toIso8601String(),
          newCheckInDate.toIso8601String(),
          newCheckOutDate.toIso8601String(),
        ],
      );

      final hasConflict = (conflictResult.first['count'] as int) > 0;
      if (hasConflict) {
        return false; // มีการจองซ้อน
      }

      // อัพเดตข้อมูลการจอง
      final result = await db.update(
        'room_bookings',
        {
          'check_in_date': newCheckInDate.toIso8601String(),
          'check_out_date': newCheckOutDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND visitor_id = ?',
        whereArgs: [bookingId, visitorId],
      );

      return result > 0;
    } catch (e) {
      throw Exception('Failed to update room booking dates: $e');
    }
  }
}
