import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'backup_exceptions.dart';

/// Centralized error handling and user feedback service for backup operations
class BackupErrorHandler {
  static BackupErrorHandler? _instance;
  static BackupErrorHandler get instance => _instance ??= BackupErrorHandler._();
  
  BackupErrorHandler._();

  /// Handle backup operation errors and show appropriate user feedback
  void handleError(
    BuildContext context,
    dynamic error, {
    String? operation,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    final errorInfo = _analyzeError(error);
    
    // Log the error for debugging
    logError(operation ?? 'Unknown operation', error);
    
    if (showSnackBar && context.mounted) {
      _showErrorSnackBar(context, errorInfo, onRetry);
    }
  }

  /// Show success message to user
  void showSuccess(
    BuildContext context,
    String message, {
    String? details,
    IconData? icon,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? Icons.check_circle,
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
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Log success for debugging
    logInfo('Success: $message${details != null ? ' - $details' : ''}');
  }

  /// Show warning message to user
  void showWarning(
    BuildContext context,
    String message, {
    String? details,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber,
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
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );

    // Log warning for debugging
    logWarning('Warning: $message${details != null ? ' - $details' : ''}');
  }

  /// Show confirmation dialog for destructive operations
  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
    Color? confirmColor,
    IconData? icon,
    Widget? customContent,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: confirmColor ?? Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title)),
            ],
          ),
          content: customContent ?? Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor ?? Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Log error with detailed information
  void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final errorMessage = _getErrorMessage(error);
    final errorCode = _getErrorCode(error);
    
    developer.log(
      'Backup Error in $operation: $errorMessage',
      name: 'BackupErrorHandler',
      level: 1000, // ERROR level
      error: error,
      stackTrace: stackTrace ?? (error is Error ? error.stackTrace : null),
    );

    // Additional structured logging
    developer.log(
      'Error Details: {operation: $operation, code: $errorCode, type: ${error.runtimeType}}',
      name: 'BackupErrorHandler',
      level: 1000,
    );
  }

  /// Log warning message
  void logWarning(String message) {
    developer.log(
      message,
      name: 'BackupErrorHandler',
      level: 900, // WARNING level
    );
  }

  /// Log info message
  void logInfo(String message) {
    developer.log(
      message,
      name: 'BackupErrorHandler',
      level: 800, // INFO level
    );
  }

  /// Log debug message
  void logDebug(String message) {
    developer.log(
      message,
      name: 'BackupErrorHandler',
      level: 700, // DEBUG level
    );
  }

  /// Analyze error and return user-friendly information
  ErrorInfo _analyzeError(dynamic error) {
    if (error is FilePermissionException) {
      return ErrorInfo(
        title: 'ไม่มีสิทธิ์เข้าถึงไฟล์',
        message: 'แอปไม่สามารถเขียนไฟล์ได้ กรุณาอนุญาตการเข้าถึงที่เก็บข้อมูล',
        suggestion: 'ไปที่การตั้งค่าแอปเพื่ออนุญาตการเข้าถึงไฟล์',
        icon: Icons.folder_off,
        color: Colors.orange,
        isRetryable: true,
      );
    }

    if (error is InvalidBackupFileException) {
      return ErrorInfo(
        title: 'ไฟล์สำรองข้อมูลไม่ถูกต้อง',
        message: 'ไฟล์ที่เลือกไม่ใช่ไฟล์สำรองข้อมูลที่ถูกต้อง หรือไฟล์เสียหาย',
        suggestion: 'กรุณาเลือกไฟล์สำรองข้อมูลที่ถูกต้อง (.sql หรือ .json)',
        icon: Icons.error_outline,
        color: Colors.red,
        isRetryable: true,
      );
    }

    if (error is StorageException) {
      return ErrorInfo(
        title: 'พื้นที่เก็บข้อมูลไม่เพียงพอ',
        message: 'พื้นที่เก็บข้อมูลในเครื่องไม่เพียงพอสำหรับการสำรองข้อมูล',
        suggestion: 'กรุณาลบไฟล์ที่ไม่จำเป็นหรือย้ายไฟล์ไปยังที่เก็บข้อมูลอื่น',
        icon: Icons.storage,
        color: Colors.red,
        isRetryable: false,
      );
    }

    if (error is DatabaseBackupException) {
      return ErrorInfo(
        title: 'เกิดข้อผิดพลาดกับฐานข้อมูล',
        message: 'ไม่สามารถเข้าถึงหรือประมวลผลข้อมูลได้',
        suggestion: 'กรุณาลองใหม่อีกครั้ง หากยังไม่ได้ให้รีสตาร์ทแอป',
        icon: Icons.storage,
        color: Colors.red,
        isRetryable: true,
      );
    }

    if (error is RestoreException) {
      return ErrorInfo(
        title: 'การกู้คืนข้อมูลล้มเหลว',
        message: 'ไม่สามารถกู้คืนข้อมูลจากไฟล์สำรองได้',
        suggestion: 'ตรวจสอบไฟล์สำรองและลองใหม่อีกครั้ง',
        icon: Icons.restore,
        color: Colors.red,
        isRetryable: true,
      );
    }

    if (error is BackupException) {
      return ErrorInfo(
        title: 'เกิดข้อผิดพลาดในการสำรองข้อมูล',
        message: error.message,
        suggestion: 'กรุณาลองใหม่อีกครั้ง หากยังไม่ได้ให้ตรวจสอบการตั้งค่า',
        icon: Icons.backup,
        color: Colors.red,
        isRetryable: true,
      );
    }

    // Generic error handling
    return ErrorInfo(
      title: 'เกิดข้อผิดพลาดที่ไม่คาดคิด',
      message: 'เกิดข้อผิดพลาดที่ไม่สามารถระบุได้',
      suggestion: 'กรุณาลองใหม่อีกครั้ง หากยังไม่ได้ให้รีสตาร์ทแอป',
      icon: Icons.error,
      color: Colors.red,
      isRetryable: true,
    );
  }

  /// Show error snack bar with retry option
  void _showErrorSnackBar(
    BuildContext context,
    ErrorInfo errorInfo,
    VoidCallback? onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  errorInfo.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorInfo.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              errorInfo.message,
              style: const TextStyle(fontSize: 12),
            ),
            if (errorInfo.suggestion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '💡 ${errorInfo.suggestion}',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        backgroundColor: errorInfo.color,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: errorInfo.isRetryable && onRetry != null
            ? SnackBarAction(
                label: 'ลองใหม่',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is BackupException) {
      return error.message;
    }
    return error.toString();
  }

  /// Get error code if available
  String? _getErrorCode(dynamic error) {
    if (error is BackupException) {
      return error.code;
    }
    return null;
  }
}

/// Information about an error for user feedback
class ErrorInfo {
  final String title;
  final String message;
  final String suggestion;
  final IconData icon;
  final Color color;
  final bool isRetryable;

  const ErrorInfo({
    required this.title,
    required this.message,
    required this.suggestion,
    required this.icon,
    required this.color,
    required this.isRetryable,
  });
}