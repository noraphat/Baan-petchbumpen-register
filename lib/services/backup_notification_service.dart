import 'dart:async';
import 'package:flutter/material.dart';

/// Service for managing backup operation notifications and progress updates
class BackupNotificationService {
  static BackupNotificationService? _instance;
  static BackupNotificationService get instance => _instance ??= BackupNotificationService._();
  
  BackupNotificationService._();

  final StreamController<BackupNotification> _notificationController =
      StreamController<BackupNotification>.broadcast();

  /// Stream of backup notifications
  Stream<BackupNotification> get notificationStream => _notificationController.stream;

  /// Show progress notification
  void showProgress({
    required String operation,
    required String message,
    double? progress,
    bool isIndeterminate = false,
  }) {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.progress,
        operation: operation,
        message: message,
        progress: progress,
        isIndeterminate: isIndeterminate,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show success notification
  void showSuccess({
    required String operation,
    required String message,
    String? details,
  }) {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.success,
        operation: operation,
        message: message,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show error notification
  void showError({
    required String operation,
    required String message,
    String? details,
    dynamic error,
  }) {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.error,
        operation: operation,
        message: message,
        details: details,
        error: error,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show warning notification
  void showWarning({
    required String operation,
    required String message,
    String? details,
  }) {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.warning,
        operation: operation,
        message: message,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show info notification
  void showInfo({
    required String operation,
    required String message,
    String? details,
  }) {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.info,
        operation: operation,
        message: message,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Clear all notifications
  void clearNotifications() {
    _notificationController.add(
      BackupNotification(
        type: BackupNotificationType.clear,
        operation: 'system',
        message: 'Clear notifications',
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    if (!_notificationController.isClosed) {
      _notificationController.close();
    }
  }
}

/// Types of backup notifications
enum BackupNotificationType {
  progress,
  success,
  error,
  warning,
  info,
  clear,
}

/// Backup notification data
class BackupNotification {
  final BackupNotificationType type;
  final String operation;
  final String message;
  final String? details;
  final double? progress;
  final bool isIndeterminate;
  final dynamic error;
  final DateTime timestamp;

  const BackupNotification({
    required this.type,
    required this.operation,
    required this.message,
    this.details,
    this.progress,
    this.isIndeterminate = false,
    this.error,
    required this.timestamp,
  });

  /// Get icon for notification type
  IconData get icon {
    switch (type) {
      case BackupNotificationType.progress:
        return Icons.sync;
      case BackupNotificationType.success:
        return Icons.check_circle;
      case BackupNotificationType.error:
        return Icons.error;
      case BackupNotificationType.warning:
        return Icons.warning_amber;
      case BackupNotificationType.info:
        return Icons.info;
      case BackupNotificationType.clear:
        return Icons.clear;
    }
  }

  /// Get color for notification type
  Color get color {
    switch (type) {
      case BackupNotificationType.progress:
        return Colors.blue;
      case BackupNotificationType.success:
        return Colors.green;
      case BackupNotificationType.error:
        return Colors.red;
      case BackupNotificationType.warning:
        return Colors.orange;
      case BackupNotificationType.info:
        return Colors.blue;
      case BackupNotificationType.clear:
        return Colors.grey;
    }
  }

  /// Get display title for notification
  String get title {
    switch (type) {
      case BackupNotificationType.progress:
        return 'กำลังดำเนินการ...';
      case BackupNotificationType.success:
        return 'สำเร็จ';
      case BackupNotificationType.error:
        return 'เกิดข้อผิดพลาด';
      case BackupNotificationType.warning:
        return 'คำเตือน';
      case BackupNotificationType.info:
        return 'ข้อมูล';
      case BackupNotificationType.clear:
        return 'ล้างการแจ้งเตือน';
    }
  }

  @override
  String toString() {
    return 'BackupNotification(type: $type, operation: $operation, message: $message, timestamp: $timestamp)';
  }
}

/// Widget for displaying backup notifications
class BackupNotificationWidget extends StatefulWidget {
  final BackupNotificationService notificationService;
  final Duration displayDuration;
  final bool showProgress;

  const BackupNotificationWidget({
    super.key,
    required this.notificationService,
    this.displayDuration = const Duration(seconds: 4),
    this.showProgress = true,
  });

  @override
  State<BackupNotificationWidget> createState() => _BackupNotificationWidgetState();
}

class _BackupNotificationWidgetState extends State<BackupNotificationWidget>
    with TickerProviderStateMixin {
  final List<BackupNotification> _notifications = [];
  late StreamSubscription<BackupNotification> _subscription;
  final Map<BackupNotification, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    _subscription = widget.notificationService.notificationStream.listen(_handleNotification);
  }

  @override
  void dispose() {
    _subscription.cancel();
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleNotification(BackupNotification notification) {
    if (!mounted) return;

    setState(() {
      if (notification.type == BackupNotificationType.clear) {
        _notifications.clear();
        for (final controller in _animationControllers.values) {
          controller.dispose();
        }
        _animationControllers.clear();
      } else {
        // Remove old notifications of the same operation for progress updates
        if (notification.type == BackupNotificationType.progress) {
          _notifications.removeWhere((n) => 
            n.operation == notification.operation && 
            n.type == BackupNotificationType.progress
          );
        }

        _notifications.add(notification);

        // Create animation controller for the notification
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        _animationControllers[notification] = controller;
        controller.forward();

        // Auto-remove non-progress notifications after duration
        if (notification.type != BackupNotificationType.progress) {
          Timer(widget.displayDuration, () {
            _removeNotification(notification);
          });
        }
      }
    });
  }

  void _removeNotification(BackupNotification notification) {
    if (!mounted) return;

    final controller = _animationControllers[notification];
    if (controller != null) {
      controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _notifications.remove(notification);
            _animationControllers.remove(notification);
          });
        }
        controller.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Column(
        children: _notifications.map((notification) {
          final controller = _animationControllers[notification];
          if (controller == null) return const SizedBox.shrink();

          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: controller,
                  curve: Curves.easeOut,
                )),
                child: FadeTransition(
                  opacity: controller,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notification.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          notification.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                notification.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (notification.details != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  notification.details!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (widget.showProgress && 
                                  notification.type == BackupNotificationType.progress &&
                                  notification.progress != null) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: notification.progress,
                                  backgroundColor: Colors.white30,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (notification.type != BackupNotificationType.progress)
                          IconButton(
                            onPressed: () => _removeNotification(notification),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 18,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}