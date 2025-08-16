import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/platform_file_service.dart';
import '../../lib/services/backup_exceptions.dart';

void main() {
  group('PlatformFileService', () {
    late PlatformFileService service;

    setUp(() {
      service = PlatformFileService();
    });

    group('Basic functionality', () {
      test('service can be instantiated', () {
        expect(service, isA<PlatformFileService>());
      });
    });

    group('getSupportedBackupExtensions', () {
      test('returns platform-specific extensions', () {
        final extensions = service.getSupportedBackupExtensions();
        expect(extensions, isNotEmpty);
        expect(extensions, contains('.sql'));
        expect(extensions, contains('.json'));
      });
    });

    group('getMaxBackupFileSize', () {
      test('returns platform-specific max file size', () {
        final maxSize = service.getMaxBackupFileSize();
        expect(maxSize, greaterThan(0));
        expect(maxSize, lessThanOrEqualTo(100 * 1024 * 1024)); // Should be <= 100MB
      });
    });

    group('supportsBackgroundBackup', () {
      test('returns correct background support', () {
        final supports = service.supportsBackgroundBackup();
        expect(supports, isA<bool>());
      });
    });

    group('getRecommendedBackupFrequency', () {
      test('returns reasonable backup frequency', () {
        final frequency = service.getRecommendedBackupFrequency();
        expect(frequency.inHours, greaterThanOrEqualTo(12));
        expect(frequency.inHours, lessThanOrEqualTo(24));
      });
    });


    group('Platform-specific behavior', () {
      test('Android-specific configuration', () {
        if (Platform.isAndroid) {
          final extensions = service.getSupportedBackupExtensions();
          expect(extensions, contains('.db')); // Android supports .db files
          
          final maxSize = service.getMaxBackupFileSize();
          expect(maxSize, equals(100 * 1024 * 1024)); // 100MB for Android
        }
      });

      test('iOS-specific configuration', () {
        if (Platform.isIOS) {
          final extensions = service.getSupportedBackupExtensions();
          expect(extensions, isNot(contains('.db'))); // iOS doesn't include .db
          
          final maxSize = service.getMaxBackupFileSize();
          expect(maxSize, equals(50 * 1024 * 1024)); // 50MB for iOS
          
          final frequency = service.getRecommendedBackupFrequency();
          expect(frequency.inHours, equals(12)); // Twice daily for iOS
        }
      });
    });
  });
}