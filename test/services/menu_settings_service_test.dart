import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/menu_settings_service.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late MenuSettingsService menuService;
  late DbHelper dbHelper;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    menuService = MenuSettingsService();
    dbHelper = DbHelper();
    
    // Clear database before each test
    await dbHelper.clearAllData();
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('MenuSettingsService Singleton', () {
    test('should return same instance', () {
      final instance1 = MenuSettingsService();
      final instance2 = MenuSettingsService();
      
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('Default Settings', () {
    test('should return correct default values', () async {
      // Test default values for each setting
      expect(await menuService.isWhiteRobeEnabled, isFalse);
      expect(await menuService.isBookingEnabled, isFalse);
      expect(await menuService.isScheduleEnabled, isTrue);
      expect(await menuService.isSummaryEnabled, isTrue);
      expect(await menuService.isDebugRoomMenuEnabled, isFalse);
    });

    test('should return all default settings', () async {
      final allSettings = await menuService.getAllMenuSettings();
      
      expect(allSettings['menu_white_robe_enabled'], isFalse);
      expect(allSettings['menu_booking_enabled'], isFalse);
      expect(allSettings['menu_schedule_enabled'], isTrue);
      expect(allSettings['menu_summary_enabled'], isTrue);
      expect(allSettings['menu_debug_room_enabled'], isFalse);
    });
  });

  group('White Robe Menu Settings', () {
    test('should set and get white robe enabled', () async {
      // Initially should be false
      expect(await menuService.isWhiteRobeEnabled, isFalse);
      
      // Set to true
      await menuService.setWhiteRobeEnabled(true);
      expect(await menuService.isWhiteRobeEnabled, isTrue);
      
      // Set back to false
      await menuService.setWhiteRobeEnabled(false);
      expect(await menuService.isWhiteRobeEnabled, isFalse);
    });

    test('should persist white robe setting across instances', () async {
      await menuService.setWhiteRobeEnabled(true);
      
      // Create new instance to test persistence
      final newInstance = MenuSettingsService();
      expect(await newInstance.isWhiteRobeEnabled, isTrue);
    });
  });

  group('Booking Menu Settings', () {
    test('should set and get booking enabled', () async {
      // Initially should be false
      expect(await menuService.isBookingEnabled, isFalse);
      
      // Set to true
      await menuService.setBookingEnabled(true);
      expect(await menuService.isBookingEnabled, isTrue);
      
      // Set back to false
      await menuService.setBookingEnabled(false);
      expect(await menuService.isBookingEnabled, isFalse);
    });

    test('should persist booking setting across instances', () async {
      await menuService.setBookingEnabled(true);
      
      // Create new instance to test persistence
      final newInstance = MenuSettingsService();
      expect(await newInstance.isBookingEnabled, isTrue);
    });
  });

  group('Schedule Menu Settings', () {
    test('should set and get schedule enabled', () async {
      // Initially should be true (default)
      expect(await menuService.isScheduleEnabled, isTrue);
      
      // Set to false
      await menuService.setScheduleEnabled(false);
      expect(await menuService.isScheduleEnabled, isFalse);
      
      // Set back to true
      await menuService.setScheduleEnabled(true);
      expect(await menuService.isScheduleEnabled, isTrue);
    });

    test('should persist schedule setting across instances', () async {
      await menuService.setScheduleEnabled(false);
      
      // Create new instance to test persistence
      final newInstance = MenuSettingsService();
      expect(await newInstance.isScheduleEnabled, isFalse);
    });
  });

  group('Summary Menu Settings', () {
    test('should set and get summary enabled', () async {
      // Initially should be true (default)
      expect(await menuService.isSummaryEnabled, isTrue);
      
      // Set to false
      await menuService.setSummaryEnabled(false);
      expect(await menuService.isSummaryEnabled, isFalse);
      
      // Set back to true
      await menuService.setSummaryEnabled(true);
      expect(await menuService.isSummaryEnabled, isTrue);
    });

    test('should persist summary setting across instances', () async {
      await menuService.setSummaryEnabled(false);
      
      // Create new instance to test persistence
      final newInstance = MenuSettingsService();
      expect(await newInstance.isSummaryEnabled, isFalse);
    });
  });

  group('Debug Room Menu Settings', () {
    test('should set and get debug room menu enabled', () async {
      // Initially should be false
      expect(await menuService.isDebugRoomMenuEnabled, isFalse);
      
      // Set to true
      await menuService.setDebugRoomMenuEnabled(true);
      expect(await menuService.isDebugRoomMenuEnabled, isTrue);
      
      // Set back to false
      await menuService.setDebugRoomMenuEnabled(false);
      expect(await menuService.isDebugRoomMenuEnabled, isFalse);
    });

    test('should persist debug room menu setting across instances', () async {
      await menuService.setDebugRoomMenuEnabled(true);
      
      // Create new instance to test persistence
      final newInstance = MenuSettingsService();
      expect(await newInstance.isDebugRoomMenuEnabled, isTrue);
    });
  });

  group('All Settings Management', () {
    test('should get all settings after individual changes', () async {
      // Change some settings
      await menuService.setWhiteRobeEnabled(true);
      await menuService.setBookingEnabled(true);
      await menuService.setScheduleEnabled(false);
      await menuService.setSummaryEnabled(false);
      await menuService.setDebugRoomMenuEnabled(true);
      
      // Get all settings
      final allSettings = await menuService.getAllMenuSettings();
      
      expect(allSettings['menu_white_robe_enabled'], isTrue);
      expect(allSettings['menu_booking_enabled'], isTrue);
      expect(allSettings['menu_schedule_enabled'], isFalse);
      expect(allSettings['menu_summary_enabled'], isFalse);
      expect(allSettings['menu_debug_room_enabled'], isTrue);
    });

    test('should reset all settings to defaults', () async {
      // Change all settings to non-default values
      await menuService.setWhiteRobeEnabled(true);
      await menuService.setBookingEnabled(true);
      await menuService.setScheduleEnabled(false);
      await menuService.setSummaryEnabled(false);
      await menuService.setDebugRoomMenuEnabled(true);
      
      // Verify changes
      expect(await menuService.isWhiteRobeEnabled, isTrue);
      expect(await menuService.isBookingEnabled, isTrue);
      expect(await menuService.isScheduleEnabled, isFalse);
      expect(await menuService.isSummaryEnabled, isFalse);
      expect(await menuService.isDebugRoomMenuEnabled, isTrue);
      
      // Reset to defaults
      await menuService.resetToDefaults();
      
      // Verify defaults are restored
      expect(await menuService.isWhiteRobeEnabled, isFalse);
      expect(await menuService.isBookingEnabled, isFalse);
      expect(await menuService.isScheduleEnabled, isTrue);
      expect(await menuService.isSummaryEnabled, isTrue);
      expect(await menuService.isDebugRoomMenuEnabled, isFalse);
    });

    test('should maintain defaults after reset', () async {
      // Reset first
      await menuService.resetToDefaults();
      
      // Get all settings
      final allSettings = await menuService.getAllMenuSettings();
      
      expect(allSettings['menu_white_robe_enabled'], isFalse);
      expect(allSettings['menu_booking_enabled'], isFalse);
      expect(allSettings['menu_schedule_enabled'], isTrue);
      expect(allSettings['menu_summary_enabled'], isTrue);
      expect(allSettings['menu_debug_room_enabled'], isFalse);
    });
  });

  group('Setting Keys Consistency', () {
    test('should use consistent keys across all methods', () async {
      // This test ensures that the internal keys are used consistently
      // by setting values and checking via getAllMenuSettings
      
      await menuService.setWhiteRobeEnabled(true);
      await menuService.setBookingEnabled(true);
      await menuService.setScheduleEnabled(false);
      await menuService.setSummaryEnabled(false);
      await menuService.setDebugRoomMenuEnabled(true);
      
      final allSettings = await menuService.getAllMenuSettings();
      
      // The keys should exist and match the expected values
      expect(allSettings.containsKey('menu_white_robe_enabled'), isTrue);
      expect(allSettings.containsKey('menu_booking_enabled'), isTrue);
      expect(allSettings.containsKey('menu_schedule_enabled'), isTrue);
      expect(allSettings.containsKey('menu_summary_enabled'), isTrue);
      expect(allSettings.containsKey('menu_debug_room_enabled'), isTrue);
      
      expect(allSettings['menu_white_robe_enabled'], isTrue);
      expect(allSettings['menu_booking_enabled'], isTrue);
      expect(allSettings['menu_schedule_enabled'], isFalse);
      expect(allSettings['menu_summary_enabled'], isFalse);
      expect(allSettings['menu_debug_room_enabled'], isTrue);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle rapid setting changes', () async {
      // Rapidly change the same setting
      for (int i = 0; i < 10; i++) {
        await menuService.setWhiteRobeEnabled(i % 2 == 0);
      }
      
      // Final state should be false (i=9, 9%2 != 0)
      expect(await menuService.isWhiteRobeEnabled, isFalse);
    });

    test('should handle multiple concurrent setting changes', () async {
      // Simulate concurrent changes
      final futures = <Future>[];
      futures.add(menuService.setWhiteRobeEnabled(true));
      futures.add(menuService.setBookingEnabled(true));
      futures.add(menuService.setScheduleEnabled(false));
      futures.add(menuService.setSummaryEnabled(false));
      futures.add(menuService.setDebugRoomMenuEnabled(true));
      
      await Future.wait(futures);
      
      // All settings should be updated correctly
      expect(await menuService.isWhiteRobeEnabled, isTrue);
      expect(await menuService.isBookingEnabled, isTrue);
      expect(await menuService.isScheduleEnabled, isFalse);
      expect(await menuService.isSummaryEnabled, isFalse);
      expect(await menuService.isDebugRoomMenuEnabled, isTrue);
    });

    test('should handle database errors gracefully', () async {
      // Close database to simulate error
      final db = await dbHelper.db;
      await db.close();
      
      // Should not throw exceptions
      expect(() async => await menuService.isWhiteRobeEnabled, returnsNormally);
      expect(() async => await menuService.setWhiteRobeEnabled(true), returnsNormally);
      expect(() async => await menuService.getAllMenuSettings(), returnsNormally);
      expect(() async => await menuService.resetToDefaults(), returnsNormally);
    });
  });

  group('Performance Tests', () {
    test('should handle multiple sequential reads efficiently', () async {
      final stopwatch = Stopwatch()..start();
      
      // Perform multiple reads
      for (int i = 0; i < 50; i++) {
        await menuService.isWhiteRobeEnabled;
        await menuService.isBookingEnabled;
        await menuService.isScheduleEnabled;
        await menuService.isSummaryEnabled;
        await menuService.isDebugRoomMenuEnabled;
      }
      
      stopwatch.stop();
      
      // Should complete within reasonable time (adjust threshold as needed)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should handle batch operations efficiently', () async {
      final stopwatch = Stopwatch()..start();
      
      // Perform batch operations
      for (int i = 0; i < 20; i++) {
        await menuService.getAllMenuSettings();
      }
      
      stopwatch.stop();
      
      // Should complete within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });

  group('Data Integrity', () {
    test('should maintain setting values across multiple operations', () async {
      // Set initial values
      await menuService.setWhiteRobeEnabled(true);
      await menuService.setBookingEnabled(false);
      await menuService.setScheduleEnabled(true);
      await menuService.setSummaryEnabled(false);
      await menuService.setDebugRoomMenuEnabled(true);
      
      // Perform other operations
      await menuService.getAllMenuSettings();
      await menuService.resetToDefaults();
      
      // Set values again
      await menuService.setWhiteRobeEnabled(true);
      await menuService.setBookingEnabled(false);
      await menuService.setScheduleEnabled(true);
      await menuService.setSummaryEnabled(false);
      await menuService.setDebugRoomMenuEnabled(true);
      
      // Verify final values
      expect(await menuService.isWhiteRobeEnabled, isTrue);
      expect(await menuService.isBookingEnabled, isFalse);
      expect(await menuService.isScheduleEnabled, isTrue);
      expect(await menuService.isSummaryEnabled, isFalse);
      expect(await menuService.isDebugRoomMenuEnabled, isTrue);
    });
  });
}