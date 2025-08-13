import 'dart:io';
import '../models/backup_settings.dart';
import 'backup_exceptions.dart';
import 'sql_export_service.dart';
import 'file_management_service.dart';

/// Service สำหรับจัดการ auto backup รายวัน
/// ตรวจสอบและสร้างไฟล์ backup ในรูปแบบ DD.sql
class AutoBackupService {
  final SqlExportService _sqlExportService;
  final FileManagementService _fileManagementService;
  
  AutoBackupService({
    SqlExportService? sqlExportService,
    FileManagementService? fileManagementService,
  }) : _sqlExportService = sqlExportService ?? SqlExportService(),
        _fileManagementService = fileManagementService ?? FileManagementService();

  /// ตรวจสอบและทำ daily backup ถ้าจำเป็น
  /// จะสร้างไฟล์ backup เฉพาะเมื่อยังไม่มีไฟล์สำหรับวันนั้น
  Future<void> performDailyBackupIfNeeded() async {
    try {
      final today = DateTime.now();
      final fileName = getDailyBackupFileName(today);
      
      // ตรวจสอบว่าไฟล์ backup สำหรับวันนี้มีอยู่แล้วหรือไม่
      if (await shouldPerformBackup(fileName, today)) {
        await _performDailyBackup(fileName);
      }
    } catch (e) {
      throw BackupException(
        'Failed to perform daily backup: ${e.toString()}',
        code: 'DAILY_BACKUP_FAILED',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบว่าควรทำ backup หรือไม่
  /// คืนค่า true ถ้า:
  /// 1. ไฟล์ backup ยังไม่มี หรือ
  /// 2. ไฟล์ backup มีอยู่แต่ไม่ใช่วันเดียวกัน
  Future<bool> shouldPerformBackup(String fileName, DateTime targetDate) async {
    try {
      if (!await _fileManagementService.backupFileExists(fileName)) {
        return true; // ไฟล์ไม่มี ต้องสร้างใหม่
      }

      // ตรวจสอบว่าไฟล์ที่มีอยู่เป็นของวันเดียวกันหรือไม่
      final backupDir = await _fileManagementService.getBackupDirectory();
      final filePath = '$backupDir/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        final fileModified = await file.lastModified();
        return !_isSameDay(fileModified, targetDate);
      }
      
      return true;
    } catch (e) {
      // ถ้าเกิดข้อผิดพลาดในการตรวจสอบ ให้ทำ backup เพื่อความปลอดภัย
      return true;
    }
  }

  /// สร้างชื่อไฟล์ backup รายวันในรูปแบบ DD.sql
  String getDailyBackupFileName(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.sql';
  }

  /// อัปเดต timestamp ของ backup ล่าสุด
  Future<void> updateLastBackupTime(DateTime backupTime) async {
    // Note: การอัปเดต settings จะถูกจัดการโดย BackupService
    // method นี้เป็น placeholder สำหรับการอัปเดตใน BackupService
  }

  /// ทำ daily backup จริง
  Future<String> _performDailyBackup(String fileName) async {
    try {
      // สร้าง SQL content
      final sqlContent = await _sqlExportService.exportToSql();
      
      // บันทึกไฟล์
      final filePath = await _fileManagementService.createBackupFile(fileName, sqlContent);
      
      // ทำความสะอาดไฟล์เก่า
      await _fileManagementService.deleteOldBackups();
      
      return filePath;
    } catch (e) {
      throw BackupException(
        'Failed to create daily backup file: ${e.toString()}',
        code: 'BACKUP_FILE_CREATION_FAILED',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบว่าสองวันเป็นวันเดียวกันหรือไม่
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// ตรวจสอบว่า auto backup ควรทำงานหรือไม่
  /// ตรวจสอบจาก settings และเงื่อนไขต่างๆ
  Future<bool> shouldScheduleAutoBackup(BackupSettings settings) async {
    if (!settings.autoBackupEnabled) {
      return false;
    }

    // ตรวจสอบว่ามีการ backup วันนี้แล้วหรือไม่
    final today = DateTime.now();
    final fileName = getDailyBackupFileName(today);
    
    return await shouldPerformBackup(fileName, today);
  }

  /// ทำ auto backup และอัปเดต settings
  /// คืนค่า path ของไฟล์ที่สร้างขึ้น หรือ null ถ้าไม่ได้สร้าง
  Future<String?> performAutoBackup(BackupSettings settings) async {
    try {
      if (!await shouldScheduleAutoBackup(settings)) {
        return null; // ไม่จำเป็นต้องทำ backup
      }

      final today = DateTime.now();
      final fileName = getDailyBackupFileName(today);
      final filePath = await _performDailyBackup(fileName);
      
      return filePath;
    } catch (e) {
      throw BackupException(
        'Auto backup failed: ${e.toString()}',
        code: 'AUTO_BACKUP_FAILED',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบสถานะของ backup files
  /// คืนค่าข้อมูลสถิติของไฟล์ backup
  Future<Map<String, dynamic>> getBackupStatus() async {
    try {
      final backupFiles = await _fileManagementService.getBackupFiles();
      final today = DateTime.now();
      final todayFileName = getDailyBackupFileName(today);
      
      // ตรวจสอบว่ามี backup วันนี้หรือไม่
      final hasTodayBackup = await _fileManagementService.backupFileExists(todayFileName);
      
      // หาไฟล์ backup ล่าสุด
      DateTime? lastBackupDate;
      String? lastBackupFile;
      
      for (final filePath in backupFiles) {
        final file = File(filePath);
        if (await file.exists() && filePath.endsWith('.sql')) {
          final fileModified = await file.lastModified();
          if (lastBackupDate == null || fileModified.isAfter(lastBackupDate)) {
            lastBackupDate = fileModified;
            lastBackupFile = filePath;
          }
        }
      }
      
      return {
        'totalBackupFiles': backupFiles.length,
        'hasTodayBackup': hasTodayBackup,
        'lastBackupDate': lastBackupDate?.toIso8601String(),
        'lastBackupFile': lastBackupFile,
        'todayFileName': todayFileName,
      };
    } catch (e) {
      throw BackupException(
        'Failed to get backup status: ${e.toString()}',
        code: 'BACKUP_STATUS_FAILED',
        originalError: e,
      );
    }
  }
}