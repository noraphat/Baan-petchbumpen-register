# Design Document - Backup System Enhancement

## Overview

ออกแบบระบบสำรองข้อมูลที่ครบครันสำหรับแอปพลิเคชัน Flutter โดยมีความสามารถในการ Export ข้อมูลเป็น JSON, Auto Backup รายวัน, และ Restore ข้อมูลจากไฟล์ backup พร้อมกับการจัดการไฟล์อย่างมีประสิทธิภาพ

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Settings UI                    │
├─────────────────────────────────────────────────────────────┤
│                    Backup Service Layer                     │
├─────────────────────────────────────────────────────────────┤
│  JSON Export │  SQL Export  │  Auto Backup │  Restore      │
│  Service     │  Service     │  Service     │  Service      │
├─────────────────────────────────────────────────────────────┤
│                    File Management Layer                    │
├─────────────────────────────────────────────────────────────┤
│                    Database Layer (SQLite)                  │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
BackupService
├── JsonExportService
├── SqlExportService  
├── AutoBackupService
├── RestoreService
└── FileManagementService
```

## Components and Interfaces

### 1. BackupService (Main Service)

**Purpose:** หลักในการจัดการระบบ backup ทั้งหมด

**Interface:**
```dart
class BackupService {
  // JSON Export
  Future<String> exportToJson();
  
  // Auto Backup
  Future<void> enableAutoBackup();
  Future<void> disableAutoBackup();
  Future<void> performDailyBackup();
  bool isAutoBackupEnabled();
  DateTime? getLastBackupTime();
  
  // Restore
  Future<void> restoreFromFile(String filePath);
  
  // File Management
  Future<void> cleanOldBackups();
  Future<List<String>> getBackupFiles();
  
  // Settings
  Future<void> saveBackupSettings(BackupSettings settings);
  Future<BackupSettings> getBackupSettings();
}
```

### 2. JsonExportService

**Purpose:** จัดการการ export ข้อมูลเป็น JSON format

**Interface:**
```dart
class JsonExportService {
  Future<String> exportAllTablesToJson();
  Future<Map<String, dynamic>> exportTableToJson(String tableName);
  Future<String> saveJsonToFile(Map<String, dynamic> data);
  String generateJsonFileName();
}
```

**JSON Structure:**
```json
{
  "export_info": {
    "timestamp": "2024-01-15T10:30:00Z",
    "version": "1.0",
    "total_records": 1250
  },
  "tables": {
    "regs": [
      {
        "id": "1234567890123",
        "first": "สมชาย",
        "last": "ใจดี",
        "phone": "0812345678",
        "created_at": "2024-01-15T08:00:00Z"
      }
    ],
    "stays": [...],
    "additional_info": [...],
    "settings": [...]
  }
}
```

### 3. SqlExportService

**Purpose:** จัดการการ export ข้อมูลเป็น SQL format สำหรับ auto backup

**Interface:**
```dart
class SqlExportService {
  Future<String> exportToSql();
  Future<String> generateCreateTableStatements();
  Future<String> generateInsertStatements();
  Future<String> generateIndexStatements();
  Future<String> saveSqlToFile(String sqlContent, String fileName);
}
```

**SQL Structure:**
```sql
-- Backup created on 2024-01-15 10:30:00
-- Database version: 1.0

-- Drop existing tables
DROP TABLE IF EXISTS additional_info;
DROP TABLE IF EXISTS stays;
DROP TABLE IF EXISTS regs;
DROP TABLE IF EXISTS settings;

-- Create tables
CREATE TABLE regs (
  id TEXT PRIMARY KEY,
  first TEXT NOT NULL,
  last TEXT NOT NULL,
  phone TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_regs_phone ON regs(phone);
CREATE INDEX idx_regs_created_at ON regs(created_at);

-- Insert data
INSERT INTO regs VALUES ('1234567890123', 'สมชาย', 'ใจดี', '0812345678', '2024-01-15T08:00:00Z');
```

### 4. AutoBackupService

**Purpose:** จัดการ auto backup รายวัน

**Interface:**
```dart
class AutoBackupService {
  Future<void> scheduleAutoBackup();
  Future<void> performDailyBackupIfNeeded();
  Future<bool> shouldPerformBackup();
  Future<String> getDailyBackupFileName();
  Future<void> updateLastBackupTime();
}
```

**Auto Backup Logic:**
```dart
Future<void> performDailyBackupIfNeeded() async {
  final today = DateTime.now();
  final fileName = '${today.day.toString().padLeft(2, '0')}.sql';
  final filePath = await _getBackupFilePath(fileName);
  
  // Check if backup already exists for today
  if (await File(filePath).exists()) {
    final fileModified = await File(filePath).lastModified();
    if (_isSameDay(fileModified, today)) {
      return; // Skip backup for today
    }
  }
  
  // Perform backup
  final sqlContent = await SqlExportService().exportToSql();
  await File(filePath).writeAsString(sqlContent);
  
  // Clean old backups
  await _cleanOldBackups();
}
```

### 5. RestoreService

**Purpose:** จัดการการ restore ข้อมูลจากไฟล์ backup

**Interface:**
```dart
class RestoreService {
  Future<void> restoreFromSqlFile(String filePath);
  Future<void> createEmergencyBackup();
  Future<bool> validateBackupFile(String filePath);
  Future<void> dropAllTables();
  Future<void> executeSqlFile(String filePath);
  Future<bool> verifyRestoreIntegrity();
}
```

**Restore Process:**
```dart
Future<void> restoreFromSqlFile(String filePath) async {
  // 1. Validate backup file
  if (!await validateBackupFile(filePath)) {
    throw BackupException('Invalid backup file');
  }
  
  // 2. Create emergency backup
  await createEmergencyBackup();
  
  try {
    // 3. Drop all tables
    await dropAllTables();
    
    // 4. Execute SQL file
    await executeSqlFile(filePath);
    
    // 5. Verify integrity
    if (!await verifyRestoreIntegrity()) {
      throw BackupException('Restore verification failed');
    }
    
  } catch (e) {
    // Restore from emergency backup if failed
    await _restoreFromEmergencyBackup();
    rethrow;
  }
}
```

### 6. FileManagementService

**Purpose:** จัดการไฟล์ backup และ storage

**Interface:**
```dart
class FileManagementService {
  Future<String> getBackupDirectory();
  Future<void> ensureBackupDirectoryExists();
  Future<List<String>> getBackupFiles();
  Future<void> deleteOldBackups(int maxDays);
  Future<bool> hasWritePermission();
  Future<void> requestWritePermission();
  Future<int> getAvailableStorageSpace();
}
```

## Data Models

### BackupSettings

```dart
class BackupSettings {
  final bool autoBackupEnabled;
  final DateTime? lastBackupTime;
  final int maxBackupDays;
  final String backupDirectory;
  
  BackupSettings({
    required this.autoBackupEnabled,
    this.lastBackupTime,
    this.maxBackupDays = 31,
    required this.backupDirectory,
  });
  
  Map<String, dynamic> toJson();
  factory BackupSettings.fromJson(Map<String, dynamic> json);
}
```

### BackupInfo

```dart
class BackupInfo {
  final String fileName;
  final DateTime createdAt;
  final int fileSize;
  final BackupType type;
  final bool isValid;
  
  BackupInfo({
    required this.fileName,
    required this.createdAt,
    required this.fileSize,
    required this.type,
    required this.isValid,
  });
}

enum BackupType { json, sql }
```

## Error Handling

### Exception Classes

```dart
class BackupException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  BackupException(this.message, {this.code, this.originalError});
}

class RestoreException extends BackupException {
  RestoreException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
}

class FilePermissionException extends BackupException {
  FilePermissionException(String message)
      : super(message, code: 'PERMISSION_DENIED');
}
```

### Error Handling Strategy

```dart
try {
  await backupService.exportToJson();
} on FilePermissionException catch (e) {
  // Show permission request dialog
  await _requestPermissions();
} on BackupException catch (e) {
  // Show user-friendly error message
  _showErrorDialog(e.message);
} catch (e) {
  // Log unexpected errors
  _logError('Unexpected backup error', e);
  _showErrorDialog('เกิดข้อผิดพลาดที่ไม่คาดคิด');
}
```

## Testing Strategy

### Unit Tests

1. **BackupService Tests**
   - Test JSON export functionality
   - Test SQL export functionality
   - Test auto backup scheduling
   - Test restore functionality

2. **FileManagementService Tests**
   - Test file creation and deletion
   - Test permission handling
   - Test storage space checking

3. **Data Validation Tests**
   - Test backup file validation
   - Test data integrity verification
   - Test error handling scenarios

### Integration Tests

1. **End-to-End Backup Flow**
   - Export → Restore → Verify data integrity
   - Auto backup → File cleanup → Verify files

2. **UI Integration Tests**
   - Test backup buttons functionality
   - Test progress indicators
   - Test error message display

### Performance Tests

1. **Large Dataset Tests**
   - Test export performance with 10,000+ records
   - Test restore performance with large SQL files
   - Test memory usage during operations

## Security Considerations

### Data Protection

1. **File Permissions**
   - Ensure backup files are created with appropriate permissions
   - Validate file paths to prevent directory traversal attacks

2. **Data Validation**
   - Validate all input data before processing
   - Sanitize SQL content before execution

3. **Emergency Recovery**
   - Always create emergency backup before destructive operations
   - Implement rollback mechanisms for failed operations

## Performance Optimization

### Database Operations

1. **Batch Processing**
   - Process large datasets in batches to avoid memory issues
   - Use transactions for multiple database operations

2. **Indexing**
   - Include proper indexes in SQL backup files
   - Optimize query performance for large datasets

### File Operations

1. **Streaming**
   - Use streaming for large file operations
   - Implement progress callbacks for long-running operations

2. **Compression**
   - Consider compressing backup files for storage efficiency
   - Implement decompression for restore operations

## Implementation Notes

### Platform-Specific Considerations

1. **Android**
   - Use scoped storage for backup files
   - Handle storage permissions properly
   - Consider using MediaStore for file access

2. **iOS**
   - Use app documents directory for backup files
   - Handle file sharing permissions

### Dependencies

```yaml
dependencies:
  path_provider: ^2.0.0  # For getting app directories
  permission_handler: ^10.0.0  # For handling permissions
  file_picker: ^5.0.0  # For file selection in restore
  sqflite: ^2.0.0  # For database operations
```

## Migration Strategy

### Existing Data Compatibility

1. **Database Schema Versioning**
   - Include schema version in backup files
   - Implement migration logic for different versions

2. **Backward Compatibility**
   - Support restoring from older backup formats
   - Provide upgrade paths for legacy data

This design provides a comprehensive, scalable, and maintainable backup system that meets all the specified requirements while ensuring data integrity and user experience.