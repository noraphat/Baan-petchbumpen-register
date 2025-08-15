import 'dart:async';
import 'dart:developer' as developer;
import '../models/backup_settings.dart';
import 'backup_exceptions.dart';
import 'backup_service.dart';
import 'auto_backup_service.dart';

/// Service สำหรับจัดการ scheduling ของ auto backup
/// รับผิดชอบการตรวจสอบและทำ backup เมื่อเปิดแอป
class BackupSchedulerService {
  static BackupSchedulerService? _instance;
  static BackupSchedulerService get instance => _instance ??= BackupSchedulerService._();
  
  /// Reset the singleton instance (for testing purposes)
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  BackupSchedulerService._();

  final BackupService _backupService = BackupService.instance;
  final AutoBackupService _autoBackupService = AutoBackupService();
  
  Timer? _schedulerTimer;
  bool _isInitialized = false;
  bool _isBackupInProgress = false;

  /// Initialize the backup scheduler
  /// ควรเรียกใช้เมื่อแอปเริ่มต้น
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _logOperation('Initializing backup scheduler');
      
      // ตรวจสอบและทำ backup เมื่อเปิดแอป
      await _checkAndPerformStartupBackup();
      
      // เริ่ม periodic timer สำหรับตรวจสอบ backup
      _startPeriodicCheck();
      
      _isInitialized = true;
      _logOperation('Backup scheduler initialized successfully');
    } catch (e) {
      _logError('Failed to initialize backup scheduler', e);
      throw BackupException(
        'Failed to initialize backup scheduler: ${e.toString()}',
        code: 'SCHEDULER_INIT_FAILED',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบและทำ backup เมื่อเปิดแอป
  Future<void> _checkAndPerformStartupBackup() async {
    try {
      _logOperation('Checking startup backup requirements');
      
      final settings = await _backupService.getBackupSettings();
      
      if (!settings.autoBackupEnabled) {
        _logOperation('Auto backup is disabled, skipping startup backup');
        return;
      }

      // ตรวจสอบว่าควรทำ backup หรือไม่
      if (await _shouldPerformBackup(settings)) {
        _logOperation('Performing startup backup');
        await _performBackupSafely();
      } else {
        _logOperation('Startup backup not needed');
      }
    } catch (e) {
      _logError('Startup backup check failed', e);
      // ไม่ throw error เพื่อไม่ให้กระทบการเปิดแอป
    }
  }

  /// Handle app lifecycle changes
  /// เรียกใช้เมื่อแอปกลับมาจาก background
  Future<void> onAppResumed() async {
    try {
      _logOperation('App resumed, checking backup requirements');
      
      if (!_isInitialized) {
        await initialize();
        return;
      }

      // ตรวจสอบว่าควรทำ backup หรือไม่
      final settings = await _backupService.getBackupSettings();
      if (settings.autoBackupEnabled && await _shouldPerformBackup(settings)) {
        _logOperation('Performing backup after app resume');
        await _performBackupSafely();
      }
    } catch (e) {
      _logError('App resume backup check failed', e);
      // ไม่ throw error เพื่อไม่ให้กระทบการทำงานของแอป
    }
  }

  /// Handle app going to background
  /// เรียกใช้เมื่อแอปจะไป background
  void onAppPaused() {
    _logOperation('App paused, backup scheduler remains active');
    // Scheduler จะยังคงทำงานใน background
    // ไม่ต้องหยุดการทำงาน
  }

  /// เริ่ม periodic timer สำหรับตรวจสอบ backup
  void _startPeriodicCheck() {
    // ตรวจสอบทุก 1 ชั่วโมง
    _schedulerTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _performPeriodicBackupCheck();
    });
    
    _logOperation('Periodic backup check started (every 1 hour)');
  }

  /// ตรวจสอบ backup แบบ periodic
  Future<void> _performPeriodicBackupCheck() async {
    if (_isBackupInProgress) {
      _logOperation('Backup already in progress, skipping periodic check');
      return;
    }

    try {
      _logOperation('Performing periodic backup check');
      
      final settings = await _backupService.getBackupSettings();
      
      if (!settings.autoBackupEnabled) {
        return;
      }

      if (await _shouldPerformBackup(settings)) {
        _logOperation('Performing periodic backup');
        await _performBackupSafely();
      }
    } catch (e) {
      _logError('Periodic backup check failed', e);
      // ไม่ throw error เพื่อไม่ให้กระทบการทำงานของแอป
    }
  }

  /// ตรวจสอบว่าควรทำ backup หรือไม่
  Future<bool> _shouldPerformBackup(BackupSettings settings) async {
    try {
      // ตรวจสอบว่า auto backup เปิดอยู่หรือไม่
      if (!settings.autoBackupEnabled) {
        return false;
      }

      // ตรวจสอบว่ามี backup วันนี้แล้วหรือไม่
      final today = DateTime.now();
      final fileName = _autoBackupService.getDailyBackupFileName(today);
      
      return await _autoBackupService.shouldPerformBackup(fileName, today);
    } catch (e) {
      _logError('Failed to check if backup should be performed', e);
      return false; // ถ้าเกิดข้อผิดพลาด ไม่ทำ backup เพื่อความปลอดภัย
    }
  }

  /// ทำ backup อย่างปลอดภัย (ไม่ให้ crash แอป)
  Future<void> _performBackupSafely() async {
    if (_isBackupInProgress) {
      _logOperation('Backup already in progress, skipping');
      return;
    }

    _isBackupInProgress = true;
    
    try {
      _logOperation('Starting safe backup operation');
      
      await _backupService.performDailyBackup();
      
      _logOperation('Safe backup operation completed successfully');
    } catch (e) {
      _logError('Safe backup operation failed', e);
      // ไม่ throw error เพื่อไม่ให้กระทบการทำงานของแอป
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// บังคับให้ทำ backup ทันที (สำหรับการทดสอบ)
  Future<void> forceBackupNow() async {
    try {
      _logOperation('Forcing backup now');
      
      final settings = await _backupService.getBackupSettings();
      
      if (!settings.autoBackupEnabled) {
        throw BackupException(
          'Auto backup is disabled',
          code: 'AUTO_BACKUP_DISABLED',
        );
      }

      await _performBackupSafely();
      
      _logOperation('Force backup completed');
    } catch (e) {
      _logError('Force backup failed', e);
      rethrow;
    }
  }

  /// ตรวจสอบสถานะของ scheduler
  Map<String, dynamic> getSchedulerStatus() {
    return {
      'isInitialized': _isInitialized,
      'isBackupInProgress': _isBackupInProgress,
      'hasActiveTimer': _schedulerTimer?.isActive ?? false,
      'timerPeriod': '1 hour',
    };
  }

  /// หยุดการทำงานของ scheduler
  void stop() {
    _logOperation('Stopping backup scheduler');
    
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _isInitialized = false;
    
    _logOperation('Backup scheduler stopped');
  }

  /// เริ่มการทำงานของ scheduler ใหม่
  Future<void> restart() async {
    _logOperation('Restarting backup scheduler');
    
    stop();
    await initialize();
    
    _logOperation('Backup scheduler restarted');
  }

  /// ตรวจสอบและทำความสะอาดไฟล์ backup เก่า
  Future<void> performMaintenanceCleanup() async {
    try {
      _logOperation('Performing maintenance cleanup');
      
      await _backupService.cleanOldBackups();
      
      _logOperation('Maintenance cleanup completed');
    } catch (e) {
      _logError('Maintenance cleanup failed', e);
      // ไม่ throw error เพื่อไม่ให้กระทบการทำงานของแอป
    }
  }

  /// ตรวจสอบสถานะของไฟล์ backup
  Future<Map<String, dynamic>> getBackupStatus() async {
    try {
      return await _autoBackupService.getBackupStatus();
    } catch (e) {
      _logError('Failed to get backup status', e);
      return {
        'error': e.toString(),
        'totalBackupFiles': 0,
        'hasTodayBackup': false,
        'lastBackupDate': null,
        'lastBackupFile': null,
        'todayFileName': null,
      };
    }
  }

  /// Log operation for debugging
  void _logOperation(String message) {
    developer.log(
      message,
      name: 'BackupSchedulerService',
      level: 800, // INFO level
    );
  }

  /// Log error for debugging
  void _logError(String message, dynamic error) {
    developer.log(
      message,
      name: 'BackupSchedulerService',
      level: 1000, // ERROR level
      error: error,
      stackTrace: error is Error ? error.stackTrace : null,
    );
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}