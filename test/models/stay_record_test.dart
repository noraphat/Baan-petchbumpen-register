import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';

void main() {
  group('StayRecord Tests', () {
    test('should create stay record with factory constructor', () {
      final startDate = DateTime(2024, 1, 15);
      final endDate = DateTime(2024, 1, 20);
      
      final stayRecord = StayRecord.create(
        visitorId: '1234567890123',
        startDate: startDate,
        endDate: endDate,
        status: 'active',
        note: 'พักธรรมดา',
      );

      expect(stayRecord.visitorId, equals('1234567890123'));
      expect(stayRecord.startDate, equals(startDate));
      expect(stayRecord.endDate, equals(endDate));
      expect(stayRecord.status, equals('active'));
      expect(stayRecord.note, equals('พักธรรมดา'));
      expect(stayRecord.createdAt, isNotNull);
    });

    test('should create stay record with default status', () {
      final stayRecord = StayRecord.create(
        visitorId: '9876543210987',
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
      );

      expect(stayRecord.status, equals('active'));
      expect(stayRecord.note, isNull);
    });

    test('should copy stay record with modified fields', () {
      final originalStay = StayRecord.create(
        visitorId: '1234567890123',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 20),
        status: 'active',
      );

      final copiedStay = originalStay.copyWith(
        endDate: DateTime(2024, 1, 25),
        status: 'extended',
        note: 'ขยายระยะเวลาพัก',
      );

      expect(copiedStay.endDate, equals(DateTime(2024, 1, 25)));
      expect(copiedStay.status, equals('extended'));
      expect(copiedStay.note, equals('ขยายระยะเวลาพัก'));
      expect(copiedStay.id, equals(originalStay.id));
      expect(copiedStay.visitorId, equals(originalStay.visitorId));
      expect(copiedStay.startDate, equals(originalStay.startDate));
      expect(copiedStay.createdAt, equals(originalStay.createdAt));
    });

    test('should convert to map correctly', () {
      final stayRecord = StayRecord(
        id: 1,
        visitorId: '1234567890123',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 20),
        status: 'completed',
        note: 'เสร็จสิ้นการพัก',
        createdAt: DateTime(2024, 1, 1),
      );

      final map = stayRecord.toMap();

      expect(map['id'], equals(1));
      expect(map['visitor_id'], equals('1234567890123'));
      expect(map['start_date'], equals('2024-01-15T00:00:00.000'));
      expect(map['end_date'], equals('2024-01-20T00:00:00.000'));
      expect(map['status'], equals('completed'));
      expect(map['note'], equals('เสร็จสิ้นการพัก'));
      expect(map['created_at'], equals('2024-01-01T00:00:00.000'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 2,
        'visitor_id': '9876543210987',
        'start_date': '2024-02-10T00:00:00.000',
        'end_date': '2024-02-15T00:00:00.000',
        'status': 'extended',
        'note': 'ขยายเวลา',
        'created_at': '2024-02-01T00:00:00.000',
      };

      final stayRecord = StayRecord.fromMap(map);

      expect(stayRecord.id, equals(2));
      expect(stayRecord.visitorId, equals('9876543210987'));
      expect(stayRecord.startDate, equals(DateTime(2024, 2, 10)));
      expect(stayRecord.endDate, equals(DateTime(2024, 2, 15)));
      expect(stayRecord.status, equals('extended'));
      expect(stayRecord.note, equals('ขยายเวลา'));
      expect(stayRecord.createdAt, equals(DateTime(2024, 2, 1)));
    });

    test('should handle null status in fromMap with default', () {
      final map = {
        'id': 3,
        'visitor_id': '1111111111111',
        'start_date': '2024-03-01T00:00:00.000',
        'end_date': '2024-03-05T00:00:00.000',
        'status': null,
        'note': null,
        'created_at': '2024-03-01T00:00:00.000',
      };

      final stayRecord = StayRecord.fromMap(map);

      expect(stayRecord.status, equals('active')); // default value
      expect(stayRecord.note, isNull);
    });

    group('Stay Status Logic', () {
      test('should identify active stay correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Stay ending today should be active
        final stayEndingToday = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 2)),
          endDate: today,
        );

        // Stay ending tomorrow should be active
        final stayEndingTomorrow = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: today.add(const Duration(days: 1)),
        );

        expect(stayEndingToday.isActive, isTrue);
        expect(stayEndingTomorrow.isActive, isTrue);
      });

      test('should identify expired stay correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Stay that ended yesterday should be expired
        final expiredStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
        );

        expect(expiredStay.isExpired, isTrue);
        expect(expiredStay.isActive, isFalse);
      });

      test('should return correct actual status for expired stay', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final expiredActiveStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
          status: 'active',
        );

        final expiredExtendedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
          status: 'extended',
        );

        final completedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
          status: 'completed',
        );

        expect(expiredActiveStay.actualStatus, equals('completed'));
        expect(expiredExtendedStay.actualStatus, equals('completed'));
        expect(completedStay.actualStatus, equals('completed'));
      });

      test('should return original status for non-expired stay', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final activeStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today,
          endDate: today.add(const Duration(days: 3)),
          status: 'active',
        );

        final extendedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today,
          endDate: today.add(const Duration(days: 5)),
          status: 'extended',
        );

        expect(activeStay.actualStatus, equals('active'));
        expect(extendedStay.actualStatus, equals('extended'));
        expect(activeStay.isActive, isTrue);
        expect(extendedStay.isActive, isTrue);
      });

      test('should detect if status update is needed', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final expiredActiveStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
          status: 'active',
        );

        final currentActiveStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today,
          endDate: today.add(const Duration(days: 3)),
          status: 'active',
        );

        final alreadyCompletedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 5)),
          endDate: today.subtract(const Duration(days: 1)),
          status: 'completed',
        );

        expect(expiredActiveStay.needsStatusUpdate, isTrue);
        expect(currentActiveStay.needsStatusUpdate, isFalse);
        expect(alreadyCompletedStay.needsStatusUpdate, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle same day start and end dates', () {
        final today = DateTime.now();
        final sameDay = DateTime(today.year, today.month, today.day);
        
        final sameDayStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: sameDay,
          endDate: sameDay,
        );

        expect(sameDayStay.isActive, isTrue);
        expect(sameDayStay.isExpired, isFalse);
      });

      test('should handle stays that start in the future', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final nextWeek = DateTime.now().add(const Duration(days: 7));
        
        final futureStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: tomorrow,
          endDate: nextWeek,
        );

        expect(futureStay.isActive, isTrue);
        expect(futureStay.isExpired, isFalse);
      });

      test('should handle midnight boundary correctly', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayMidnight = DateTime(now.year, now.month, now.day, 23, 59, 59);
        
        final stayEndingAtMidnight = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 2)),
          endDate: todayMidnight, // Should still be considered as ending today
        );

        // Since we only compare dates (not times), this should be active
        expect(stayEndingAtMidnight.isActive, isTrue);
      });
    });

    group('Date Comparison Logic', () {
      test('should correctly compare dates ignoring time components', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Different times on the same day
        final morningTime = DateTime(now.year, now.month, now.day, 8, 0);
        final eveningTime = DateTime(now.year, now.month, now.day, 20, 0);
        
        final morningStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: morningTime,
        );

        final eveningStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today.subtract(const Duration(days: 1)),
          endDate: eveningTime,
        );

        // Both should have the same active status since they end on the same day
        expect(morningStay.isActive, equals(eveningStay.isActive));
        expect(morningStay.isExpired, equals(eveningStay.isExpired));
      });
    });

    group('Status Combinations', () {
      test('should handle all possible status values correctly', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        final yesterday = today.subtract(const Duration(days: 1));

        final activeStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today,
          endDate: tomorrow,
          status: 'active',
        );

        final extendedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: today,
          endDate: tomorrow,
          status: 'extended',
        );

        final completedStay = StayRecord.create(
          visitorId: '1234567890123',
          startDate: yesterday.subtract(const Duration(days: 1)),
          endDate: yesterday,
          status: 'completed',
        );

        expect(activeStay.actualStatus, equals('active'));
        expect(extendedStay.actualStatus, equals('extended'));
        expect(completedStay.actualStatus, equals('completed'));
      });
    });
  });
}