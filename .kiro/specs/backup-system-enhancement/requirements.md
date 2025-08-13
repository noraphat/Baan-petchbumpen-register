# Requirements Document - Backup System Enhancement

## Introduction

ปรับปรุงระบบสำรองข้อมูลในหน้า Developer Settings ให้มีความสามารถในการ Export ข้อมูลเป็น JSON และ SQL, Auto Backup รายวัน, และ Restore ข้อมูลจากไฟล์ backup พร้อมกับการจัดการไฟล์ backup อย่างมีประสิทธิภาพ

## Requirements

### Requirement 1: Export ข้อมูลเป็น JSON

**User Story:** As a system administrator, I want to export data as JSON format, so that I can have a complete readable backup file with all original data

#### Acceptance Criteria

1. WHEN user clicks "Export ข้อมูลเป็น JSON" button THEN system SHALL export all database data to JSON format
2. WHEN exporting JSON THEN system SHALL include all original data without masking ID card numbers or phone numbers
3. WHEN export is complete THEN system SHALL save file with timestamp format "backup_YYYY-MM-DD_HH-mm-ss.json"
4. WHEN export fails THEN system SHALL show error message with specific reason
5. WHEN export succeeds THEN system SHALL show success message with file location
6. WHEN JSON export includes all tables THEN system SHALL organize data by table structure for easy readability

### Requirement 2: Auto Backup รายวัน

**User Story:** As a system administrator, I want automatic daily backup, so that I don't lose data and don't need to manually backup every day

#### Acceptance Criteria

1. WHEN Auto Backup toggle is enabled THEN system SHALL perform daily backup automatically
2. WHEN performing daily backup THEN system SHALL check if backup file for current date already exists
3. IF backup file for current date exists THEN system SHALL skip backup for that day
4. WHEN creating daily backup THEN system SHALL export data as SQL format with filename "DD.sql" (e.g., "15.sql" for 15th day)
5. WHEN daily backup contains data THEN system SHALL include proper SQL indexes in the backup script
6. WHEN backup files exceed 31 days old THEN system SHALL automatically delete old backup files
7. WHEN auto backup fails THEN system SHALL log error but continue normal app operation
8. WHEN auto backup succeeds THEN system SHALL update last backup timestamp in settings

### Requirement 3: Restore ข้อมูลจากไฟล์

**User Story:** As a system administrator, I want to restore data from backup files, so that I can recover system state from previous backups

#### Acceptance Criteria

1. WHEN user clicks "Restore" button THEN system SHALL open file picker to select backup file
2. WHEN user selects SQL backup file THEN system SHALL validate file format and content
3. WHEN restore is initiated THEN system SHALL show confirmation dialog with warning about data loss
4. IF user confirms restore THEN system SHALL drop all existing tables
5. WHEN tables are dropped THEN system SHALL recreate tables from backup SQL file
6. WHEN restore is complete THEN system SHALL verify data integrity
7. WHEN restore succeeds THEN system SHALL show success message and restart app if needed
8. WHEN restore fails THEN system SHALL show error message and attempt to restore from emergency backup
9. WHEN restore process starts THEN system SHALL create emergency backup of current data first

### Requirement 4: การจัดการไฟล์ Backup

**User Story:** As a system administrator, I want efficient backup file management, so that storage space is used optimally

#### Acceptance Criteria

1. WHEN creating backup files THEN system SHALL request appropriate file write permissions
2. WHEN backup files are older than 31 days THEN system SHALL automatically delete them
3. WHEN backup file already exists for current date THEN system SHALL overwrite with user permission
4. WHEN backup directory doesn't exist THEN system SHALL create backup directory automatically
5. WHEN storage space is low THEN system SHALL warn user and suggest cleaning old backups
6. WHEN backup file is corrupted THEN system SHALL detect and mark file as invalid

### Requirement 5: เมนูและ UI ปรับปรุง

**User Story:** As a system administrator, I want clean and organized backup menu, so that I can easily access backup functions

#### Acceptance Criteria

1. WHEN user opens Developer Settings THEN system SHALL show updated backup section
2. WHEN backup section is displayed THEN system SHALL NOT show "Export รายงาน PDF" option
3. WHEN backup section is displayed THEN system SHALL NOT show "Import ข้อมูล" option
4. WHEN backup section is displayed THEN system SHALL show "Export ข้อมูลเป็น JSON" option
5. WHEN backup section is displayed THEN system SHALL show "Auto Backup รายวัน" toggle option
6. WHEN backup section is displayed THEN system SHALL show "Restore" option
7. WHEN Auto Backup is enabled THEN system SHALL show last backup date and time
8. WHEN backup operation is in progress THEN system SHALL show progress indicator

### Requirement 6: ความปลอดภัยและการจัดการข้อผิดพลาด

**User Story:** As a system administrator, I want secure and reliable backup operations, so that data is protected during backup and restore processes

#### Acceptance Criteria

1. WHEN performing any backup operation THEN system SHALL validate user permissions first
2. WHEN restore operation fails THEN system SHALL not leave database in corrupted state
3. WHEN backup file is selected for restore THEN system SHALL validate file integrity first
4. WHEN system detects backup corruption THEN system SHALL warn user and prevent restore
5. WHEN emergency backup is needed THEN system SHALL create it before any destructive operation
6. WHEN backup operations encounter errors THEN system SHALL log detailed error information
7. WHEN restore is successful THEN system SHALL verify all tables and indexes are properly created
8. WHEN JSON export is performed THEN system SHALL include complete original data for full backup capability
