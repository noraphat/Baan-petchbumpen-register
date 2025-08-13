import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'backup_exceptions.dart';

/// Service สำหรับ export ข้อมูลเป็น JSON format
/// รองรับการ export ข้อมูลจากทุก table โดยไม่ mask ข้อมูล
class JsonExportService {
  final DbHelper _dbHelper = DbHelper();

  /// Export ข้อมูลทั้งหมดเป็น JSON format
  /// Returns: file path ของไฟล์ที่สร้างขึ้น
  Future<String> exportAllTablesToJson() async {
    try {
      final database = await _dbHelper.db;
      
      // ดึงข้อมูลจากทุก table
      final exportData = await _collectAllTableData(database);
      
      // สร้างไฟล์ JSON
      final filePath = await saveJsonToFile(exportData);
      
      return filePath;
    } catch (e) {
      throw BackupException(
        'Failed to export data to JSON: ${e.toString()}',
        code: 'JSON_EXPORT_ERROR',
        originalError: e,
      );
    }
  }

  /// รวบรวมข้อมูลจากทุก table ในฐานข้อมูล
  Future<Map<String, dynamic>> _collectAllTableData(Database database) async {
    final exportData = <String, dynamic>{};
    
    // ข้อมูล metadata
    exportData['export_info'] = {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'database_version': await _getDatabaseVersion(database),
    };
    
    // ข้อมูลจากแต่ละ table
    final tables = <String, dynamic>{};
    
    // Export regs table (ข้อมูลหลักผู้เข้าพัก)
    tables['regs'] = await exportTableToJson(database, 'regs');
    
    // Export reg_additional_info table (ข้อมูลเพิ่มเติม)
    tables['reg_additional_info'] = await exportTableToJson(database, 'reg_additional_info');
    
    // Export stays table (ประวัติการเข้าพัก)
    tables['stays'] = await exportTableToJson(database, 'stays');
    
    // Export app_settings table (การตั้งค่าแอป)
    tables['app_settings'] = await exportTableToJson(database, 'app_settings');
    
    // Export maps table (ข้อมูลแผนที่)
    tables['maps'] = await exportTableToJson(database, 'maps');
    
    // Export rooms table (ข้อมูลห้องพัก)
    tables['rooms'] = await exportTableToJson(database, 'rooms');
    
    // Export room_bookings table (การจองห้องพัก)
    tables['room_bookings'] = await exportTableToJson(database, 'room_bookings');
    
    exportData['tables'] = tables;
    
    // คำนวณจำนวน record ทั้งหมด
    int totalRecords = 0;
    for (final tableData in tables.values) {
      if (tableData is List) {
        totalRecords += tableData.length;
      }
    }
    exportData['export_info']['total_records'] = totalRecords;
    
    return exportData;
  }

  /// Export ข้อมูลจาก table เฉพาะ
  Future<List<Map<String, dynamic>>> exportTableToJson(
    Database database, 
    String tableName,
  ) async {
    try {
      // ตรวจสอบว่า table มีอยู่จริง
      final tableExists = await _checkTableExists(database, tableName);
      if (!tableExists) {
        return [];
      }
      
      // ดึงข้อมูลทั้งหมดจาก table (ไม่ mask ข้อมูล)
      final result = await database.query(tableName);
      
      return result;
    } catch (e) {
      throw BackupException(
        'Failed to export table $tableName: ${e.toString()}',
        code: 'TABLE_EXPORT_ERROR',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบว่า table มีอยู่ในฐานข้อมูลหรือไม่
  Future<bool> _checkTableExists(Database database, String tableName) async {
    try {
      final result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ดึง database version
  Future<int> _getDatabaseVersion(Database database) async {
    try {
      final result = await database.rawQuery('PRAGMA user_version');
      return result.first['user_version'] as int;
    } catch (e) {
      return 0;
    }
  }

  /// บันทึกข้อมูล JSON ลงไฟล์
  Future<String> saveJsonToFile(Map<String, dynamic> data) async {
    try {
      // สร้างชื่อไฟล์พร้อม timestamp
      final fileName = generateJsonFileName();
      
      // หา directory สำหรับบันทึกไฟล์
      final directory = await _getBackupDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // แปลงข้อมูลเป็น JSON string (pretty format)
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // บันทึกไฟล์
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      throw BackupException(
        'Failed to save JSON file: ${e.toString()}',
        code: 'FILE_SAVE_ERROR',
        originalError: e,
      );
    }
  }

  /// สร้างชื่อไฟล์ JSON พร้อม timestamp
  String generateJsonFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    return 'backup_$timestamp.json';
  }

  /// หา directory สำหรับเก็บไฟล์ backup
  Future<Directory> _getBackupDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      
      // สร้าง directory ถ้ายังไม่มี
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      return backupDir;
    } catch (e) {
      throw BackupException(
        'Failed to access backup directory: ${e.toString()}',
        code: 'DIRECTORY_ACCESS_ERROR',
        originalError: e,
      );
    }
  }

  /// ดึงรายการไฟล์ backup JSON ทั้งหมด
  Future<List<String>> getJsonBackupFiles() async {
    try {
      final backupDir = await _getBackupDirectory();
      final files = await backupDir.list().toList();
      
      return files
          .where((file) => file is File && file.path.endsWith('.json'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      throw BackupException(
        'Failed to list JSON backup files: ${e.toString()}',
        code: 'FILE_LIST_ERROR',
        originalError: e,
      );
    }
  }

  /// ตรวจสอบขนาดไฟล์ JSON backup
  Future<int> getJsonFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// อ่านและ validate JSON backup file
  Future<Map<String, dynamic>?> readJsonBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // ตรวจสอบ structure พื้นฐาน
      if (!data.containsKey('export_info') || !data.containsKey('tables')) {
        throw BackupException(
          'Invalid JSON backup file structure',
          code: 'INVALID_JSON_STRUCTURE',
        );
      }
      
      return data;
    } on BackupException {
      // Re-throw BackupException as-is
      rethrow;
    } catch (e) {
      throw BackupException(
        'Failed to read JSON backup file: ${e.toString()}',
        code: 'JSON_READ_ERROR',
        originalError: e,
      );
    }
  }
}