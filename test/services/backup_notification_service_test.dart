import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/services/backup_notification_service.dart';

void main() {
  group('BackupNotificationService', () {
    late BackupNotificationService notificationService;
    late StreamSubscription<BackupNotification> subscription;
    late List<BackupNotification> receivedNotifications;

    setUp(() {
      notificationService = BackupNotificationService.instance;
      receivedNotifications = [];
      subscription = notificationService.notificationStream.listen((notification) {
        receivedNotifications.add(notification);
      });
    });

    tearDown(() {
      subscription.cancel();
      receivedNotifications.clear();
    });

    test('should emit progress notification', () async {
      notificationService.showProgress(
        operation: 'Test Operation',
        message: 'Test progress message',
        progress: 0.5,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.progress));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test progress message'));
      expect(notification.progress, equals(0.5));
    });

    test('should emit success notification', () async {
      notificationService.showSuccess(
        operation: 'Test Operation',
        message: 'Test success message',
        details: 'Test details',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.success));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test success message'));
      expect(notification.details, equals('Test details'));
    });

    test('should emit error notification', () async {
      final testError = Exception('Test error');
      
      notificationService.showError(
        operation: 'Test Operation',
        message: 'Test error message',
        details: 'Test error details',
        error: testError,
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.error));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test error message'));
      expect(notification.details, equals('Test error details'));
      expect(notification.error, equals(testError));
    });

    test('should emit warning notification', () async {
      notificationService.showWarning(
        operation: 'Test Operation',
        message: 'Test warning message',
        details: 'Test warning details',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.warning));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test warning message'));
      expect(notification.details, equals('Test warning details'));
    });

    test('should emit info notification', () async {
      notificationService.showInfo(
        operation: 'Test Operation',
        message: 'Test info message',
        details: 'Test info details',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.info));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test info message'));
      expect(notification.details, equals('Test info details'));
    });

    test('should emit clear notification', () async {
      notificationService.clearNotifications();

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(1));
      final notification = receivedNotifications.first;
      expect(notification.type, equals(BackupNotificationType.clear));
      expect(notification.operation, equals('system'));
      expect(notification.message, equals('Clear notifications'));
    });

    test('should handle multiple notifications', () async {
      notificationService.showProgress(
        operation: 'Operation 1',
        message: 'Progress 1',
        progress: 0.3,
      );

      notificationService.showSuccess(
        operation: 'Operation 2',
        message: 'Success 1',
      );

      notificationService.showError(
        operation: 'Operation 3',
        message: 'Error 1',
      );

      await Future.delayed(const Duration(milliseconds: 10));

      expect(receivedNotifications.length, equals(3));
      expect(receivedNotifications[0].type, equals(BackupNotificationType.progress));
      expect(receivedNotifications[1].type, equals(BackupNotificationType.success));
      expect(receivedNotifications[2].type, equals(BackupNotificationType.error));
    });
  });

  group('BackupNotification', () {
    test('should create notification with all properties', () {
      final timestamp = DateTime.now();
      final error = Exception('Test error');

      const notification = BackupNotification(
        type: BackupNotificationType.error,
        operation: 'Test Operation',
        message: 'Test Message',
        details: 'Test Details',
        progress: 0.5,
        isIndeterminate: true,
        error: 'Test Error',
        timestamp: timestamp,
      );

      expect(notification.type, equals(BackupNotificationType.error));
      expect(notification.operation, equals('Test Operation'));
      expect(notification.message, equals('Test Message'));
      expect(notification.details, equals('Test Details'));
      expect(notification.progress, equals(0.5));
      expect(notification.isIndeterminate, isTrue);
      expect(notification.error, equals('Test Error'));
      expect(notification.timestamp, equals(timestamp));
    });

    test('should return correct icon for each notification type', () {
      expect(const BackupNotification(
        type: BackupNotificationType.progress,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.sync));

      expect(const BackupNotification(
        type: BackupNotificationType.success,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.check_circle));

      expect(const BackupNotification(
        type: BackupNotificationType.error,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.error));

      expect(const BackupNotification(
        type: BackupNotificationType.warning,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.warning_amber));

      expect(const BackupNotification(
        type: BackupNotificationType.info,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.info));

      expect(const BackupNotification(
        type: BackupNotificationType.clear,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).icon, equals(Icons.clear));
    });

    test('should return correct color for each notification type', () {
      expect(const BackupNotification(
        type: BackupNotificationType.progress,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.blue));

      expect(const BackupNotification(
        type: BackupNotificationType.success,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.green));

      expect(const BackupNotification(
        type: BackupNotificationType.error,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.red));

      expect(const BackupNotification(
        type: BackupNotificationType.warning,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.orange));

      expect(const BackupNotification(
        type: BackupNotificationType.info,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.blue));

      expect(const BackupNotification(
        type: BackupNotificationType.clear,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).color, equals(Colors.grey));
    });

    test('should return correct title for each notification type', () {
      expect(const BackupNotification(
        type: BackupNotificationType.progress,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('กำลังดำเนินการ...'));

      expect(const BackupNotification(
        type: BackupNotificationType.success,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('สำเร็จ'));

      expect(const BackupNotification(
        type: BackupNotificationType.error,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('เกิดข้อผิดพลาด'));

      expect(const BackupNotification(
        type: BackupNotificationType.warning,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('คำเตือน'));

      expect(const BackupNotification(
        type: BackupNotificationType.info,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('ข้อมูล'));

      expect(const BackupNotification(
        type: BackupNotificationType.clear,
        operation: 'test',
        message: 'test',
        timestamp: timestamp,
      ).title, equals('ล้างการแจ้งเตือน'));
    });

    test('should have correct toString implementation', () {
      final timestamp = DateTime.now();
      final notification = BackupNotification(
        type: BackupNotificationType.success,
        operation: 'Test Operation',
        message: 'Test Message',
        timestamp: timestamp,
      );

      final expectedString = 'BackupNotification(type: BackupNotificationType.success, operation: Test Operation, message: Test Message, timestamp: $timestamp)';
      expect(notification.toString(), equals(expectedString));
    });
  });

  group('BackupNotificationWidget', () {
    testWidgets('should display notifications correctly', (WidgetTester tester) async {
      final notificationService = BackupNotificationService.instance;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                BackupNotificationWidget(
                  notificationService: notificationService,
                  displayDuration: const Duration(milliseconds: 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Show a success notification
      notificationService.showSuccess(
        operation: 'Test',
        message: 'Test success message',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Test success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show progress indicator for progress notifications', (WidgetTester tester) async {
      final notificationService = BackupNotificationService.instance;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                BackupNotificationWidget(
                  notificationService: notificationService,
                  showProgress: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Show a progress notification
      notificationService.showProgress(
        operation: 'Test',
        message: 'Test progress message',
        progress: 0.5,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Test progress message'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('should clear notifications when clear is called', (WidgetTester tester) async {
      final notificationService = BackupNotificationService.instance;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                BackupNotificationWidget(
                  notificationService: notificationService,
                ),
              ],
            ),
          ),
        ),
      );

      // Show a notification
      notificationService.showSuccess(
        operation: 'Test',
        message: 'Test message',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Test message'), findsOneWidget);

      // Clear notifications
      notificationService.clearNotifications();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Test message'), findsNothing);
    });
  });
}

// Helper constant for tests
const timestamp = Duration(milliseconds: 1640995200000); // 2022-01-01 00:00:00