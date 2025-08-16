# 🧪 User Acceptance Testing Checklist - Backup System

## Overview

This checklist ensures that all backup system features work correctly from a user perspective and meet the specified requirements.

## 📋 Testing Environment Setup

### Prerequisites
- [ ] Flutter app installed and running
- [ ] Test data available in database (minimum 100 records recommended)
- [ ] Storage permissions granted
- [ ] Sufficient storage space available (minimum 100MB)
- [ ] File manager app available for file verification

### Test Data Preparation
- [ ] Create test registration records with various data types
- [ ] Include records with ID card numbers and phone numbers
- [ ] Create records with special characters and Thai text
- [ ] Ensure database has multiple tables with relationships
- [ ] Create some deleted records for comprehensive testing

## 🎯 Functional Testing

### 1. JSON Export Functionality

#### Test Case 1.1: Basic JSON Export
- [ ] Navigate to Developer Settings
- [ ] Tap "Export ข้อมูลเป็น JSON" button
- [ ] Verify progress indicator appears
- [ ] Verify success message displays with file location
- [ ] Check that JSON file is created with timestamp format `backup_YYYY-MM-DD_HH-mm-ss.json`
- [ ] Open JSON file and verify it contains readable data
- [ ] Verify all original data is present (no masking of ID cards/phone numbers)
- [ ] Verify JSON structure includes export_info and tables sections

#### Test Case 1.2: JSON Export Error Handling
- [ ] Revoke storage permissions
- [ ] Attempt JSON export
- [ ] Verify permission request dialog appears
- [ ] Grant permissions and verify export succeeds
- [ ] Fill storage to capacity
- [ ] Attempt export and verify appropriate error message

#### Test Case 1.3: JSON Export with Large Dataset
- [ ] Create database with 1000+ records
- [ ] Perform JSON export
- [ ] Verify operation completes within 30 seconds
- [ ] Verify progress updates are shown
- [ ] Verify all data is exported correctly

### 2. Auto Backup Functionality

#### Test Case 2.1: Enable Auto Backup
- [ ] Navigate to Developer Settings
- [ ] Locate "Auto Backup รายวัน" toggle
- [ ] Toggle auto backup ON
- [ ] Verify toggle state changes to enabled
- [ ] Verify last backup time is displayed (if available)
- [ ] Close and reopen app
- [ ] Verify auto backup remains enabled

#### Test Case 2.2: Daily Backup Creation
- [ ] Enable auto backup
- [ ] Restart app (simulates daily app launch)
- [ ] Verify daily backup file is created with format `DD.sql`
- [ ] Check file content contains SQL CREATE and INSERT statements
- [ ] Verify backup includes proper indexes
- [ ] Launch app again same day
- [ ] Verify no duplicate backup is created for same day

#### Test Case 2.3: Auto Backup File Management
- [ ] Enable auto backup
- [ ] Create multiple daily backups (simulate multiple days)
- [ ] Verify old files (>31 days) are automatically deleted
- [ ] Verify recent files are preserved
- [ ] Check that cleanup doesn't affect current day's backup

#### Test Case 2.4: Disable Auto Backup
- [ ] Enable auto backup first
- [ ] Toggle auto backup OFF
- [ ] Verify toggle state changes to disabled
- [ ] Restart app
- [ ] Verify no new backup files are created
- [ ] Verify existing backup files are preserved

### 3. Restore Functionality

#### Test Case 3.1: Basic Restore Operation
- [ ] Create a SQL backup file first
- [ ] Navigate to Developer Settings
- [ ] Tap "Restore" button
- [ ] Verify file picker opens
- [ ] Select valid SQL backup file
- [ ] Verify confirmation dialog appears with warning
- [ ] Confirm restore operation
- [ ] Verify progress indicator shows
- [ ] Verify success message appears
- [ ] Check that data is restored correctly
- [ ] Verify app restarts if needed

#### Test Case 3.2: Restore File Validation
- [ ] Attempt to restore invalid file (e.g., text file)
- [ ] Verify appropriate error message
- [ ] Attempt to restore corrupted SQL file
- [ ] Verify validation error message
- [ ] Attempt to restore with invalid file path
- [ ] Verify security error handling

#### Test Case 3.3: Emergency Backup Creation
- [ ] Note current data state
- [ ] Perform restore operation
- [ ] If restore fails, verify emergency backup was created
- [ ] Verify original data can be recovered from emergency backup
- [ ] Check that emergency backup has appropriate naming

#### Test Case 3.4: Restore Integrity Verification
- [ ] Create backup with known data
- [ ] Modify database (add/remove records)
- [ ] Restore from backup
- [ ] Verify all original data is restored correctly
- [ ] Verify no extra data remains
- [ ] Check that all table relationships are intact

### 4. File Management

#### Test Case 4.1: Backup Directory Management
- [ ] Perform any backup operation
- [ ] Use file manager to locate backup directory
- [ ] Verify directory is created automatically
- [ ] Verify appropriate permissions are set
- [ ] Check that directory is accessible

#### Test Case 4.2: Old File Cleanup
- [ ] Create multiple backup files with different dates
- [ ] Manually set some files to be >31 days old
- [ ] Trigger cleanup operation
- [ ] Verify only old files are deleted
- [ ] Verify recent files are preserved
- [ ] Check that cleanup operation completes successfully

#### Test Case 4.3: Storage Space Management
- [ ] Check available storage space
- [ ] Fill storage to near capacity
- [ ] Attempt backup operation
- [ ] Verify appropriate warning/error message
- [ ] Free up space and retry
- [ ] Verify operation succeeds

### 5. User Interface

#### Test Case 5.1: Developer Settings UI
- [ ] Navigate to Developer Settings
- [ ] Verify backup section is clearly visible
- [ ] Verify "Export รายงาน PDF" option is NOT present
- [ ] Verify "Import ข้อมูล" option is NOT present
- [ ] Verify "Export ข้อมูลเป็น JSON" option is present
- [ ] Verify "Auto Backup รายวัน" toggle is present
- [ ] Verify "Restore" option is present
- [ ] Check that UI is responsive and well-organized

#### Test Case 5.2: Progress Indicators
- [ ] Start JSON export operation
- [ ] Verify progress indicator appears immediately
- [ ] Verify progress messages are updated during operation
- [ ] Verify progress percentage increases
- [ ] Check that progress indicator disappears when complete
- [ ] Repeat for SQL export and restore operations

#### Test Case 5.3: Auto Backup Status Display
- [ ] Enable auto backup
- [ ] Perform daily backup
- [ ] Verify last backup date/time is displayed
- [ ] Verify display format is user-friendly
- [ ] Disable auto backup
- [ ] Verify status display updates appropriately

#### Test Case 5.4: Confirmation Dialogs
- [ ] Attempt restore operation
- [ ] Verify confirmation dialog appears
- [ ] Verify dialog clearly warns about data loss
- [ ] Test "Cancel" button functionality
- [ ] Test "Confirm" button functionality
- [ ] Check dialog text is clear and in appropriate language

## 🔒 Security Testing

### Test Case 6.1: File Path Security
- [ ] Attempt to restore from system directory (e.g., /etc/passwd)
- [ ] Verify security error is shown
- [ ] Attempt to use relative paths (../)
- [ ] Verify path validation prevents access
- [ ] Test with various malicious file paths

### Test Case 6.2: Backup File Validation
- [ ] Create malicious SQL file with DROP DATABASE commands
- [ ] Attempt restore
- [ ] Verify security validation prevents execution
- [ ] Test with SQL injection attempts
- [ ] Verify all malicious content is blocked

### Test Case 6.3: Permission Handling
- [ ] Revoke storage permissions
- [ ] Attempt backup operation
- [ ] Verify permission request appears
- [ ] Grant permissions
- [ ] Verify operation continues successfully
- [ ] Test with various permission scenarios

## ⚡ Performance Testing

### Test Case 7.1: Large Dataset Export
- [ ] Create database with 10,000+ records
- [ ] Perform JSON export
- [ ] Verify completion within 30 seconds
- [ ] Monitor memory usage during operation
- [ ] Verify app remains responsive
- [ ] Check that progress updates are smooth

### Test Case 7.2: Large Dataset Restore
- [ ] Create large SQL backup file (10,000+ records)
- [ ] Perform restore operation
- [ ] Verify completion within 45 seconds
- [ ] Monitor memory usage
- [ ] Verify app remains responsive
- [ ] Check data integrity after restore

### Test Case 7.3: Background Operations
- [ ] Enable auto backup
- [ ] Use app normally while backup runs
- [ ] Verify UI remains responsive
- [ ] Verify backup completes successfully
- [ ] Check that user experience is not impacted

## 🔄 Integration Testing

### Test Case 8.1: App Lifecycle Integration
- [ ] Enable auto backup
- [ ] Close app completely
- [ ] Reopen app next day
- [ ] Verify daily backup is triggered
- [ ] Check that backup completes automatically
- [ ] Verify app functions normally after backup

### Test Case 8.2: Database Integration
- [ ] Create various types of records
- [ ] Perform backup
- [ ] Clear database
- [ ] Restore from backup
- [ ] Verify all record types are restored correctly
- [ ] Check that relationships are maintained

### Test Case 8.3: Cross-Platform Testing
- [ ] Test on Android device
- [ ] Test on iOS device (if available)
- [ ] Verify file operations work on both platforms
- [ ] Check that UI displays correctly
- [ ] Verify permissions work appropriately

## 🐛 Error Handling Testing

### Test Case 9.1: Network/Storage Errors
- [ ] Disconnect from network during backup
- [ ] Verify appropriate error handling
- [ ] Remove storage device during operation
- [ ] Check error recovery mechanisms
- [ ] Test with corrupted storage

### Test Case 9.2: Database Errors
- [ ] Lock database file during backup
- [ ] Verify error handling
- [ ] Corrupt database during restore
- [ ] Check recovery mechanisms
- [ ] Test with missing database

### Test Case 9.3: User Interruption
- [ ] Start backup operation
- [ ] Force close app during backup
- [ ] Reopen app
- [ ] Verify system recovers gracefully
- [ ] Check that partial files are handled correctly

## 📊 Acceptance Criteria Verification

### Requirement 1: JSON Export ✅
- [ ] JSON export creates timestamped files
- [ ] All original data exported without masking
- [ ] Success/error messages displayed appropriately
- [ ] File format is valid JSON with proper structure

### Requirement 2: Auto Backup ✅
- [ ] Auto backup toggle works correctly
- [ ] Daily backup creates DD.sql files
- [ ] Only one backup per day is created
- [ ] Old files are cleaned up automatically
- [ ] Last backup time is displayed

### Requirement 3: Restore ✅
- [ ] File picker integration works
- [ ] SQL file validation prevents invalid restores
- [ ] Confirmation dialog warns about data loss
- [ ] Tables are dropped and recreated correctly
- [ ] Data integrity is verified after restore
- [ ] Emergency backup is created before restore

### Requirement 4: File Management ✅
- [ ] File permissions are handled correctly
- [ ] Backup directory is created automatically
- [ ] Old files (>31 days) are deleted automatically
- [ ] Storage space is monitored
- [ ] File operations are secure

### Requirement 5: UI Updates ✅
- [ ] Developer Settings shows updated backup section
- [ ] Removed "Export รายงาน PDF" and "Import ข้อมูล" options
- [ ] Added new backup options
- [ ] Progress indicators work for all operations
- [ ] Auto backup status is displayed

### Requirement 6: Security ✅
- [ ] File path validation prevents security issues
- [ ] Backup file validation prevents malicious content
- [ ] Emergency backup protects against data loss
- [ ] Error logging captures security events
- [ ] Permission validation works correctly

## 📝 Test Results Summary

### Test Execution Summary
- [ ] Total test cases: ___
- [ ] Passed: ___
- [ ] Failed: ___
- [ ] Blocked: ___
- [ ] Not executed: ___

### Critical Issues Found
- [ ] Issue 1: ________________
- [ ] Issue 2: ________________
- [ ] Issue 3: ________________

### Performance Results
- [ ] JSON export (10k records): ___ seconds
- [ ] SQL export (10k records): ___ seconds
- [ ] Restore (10k records): ___ seconds
- [ ] Auto backup impact: Minimal/Moderate/High

### User Experience Rating
- [ ] Excellent (5/5)
- [ ] Good (4/5)
- [ ] Average (3/5)
- [ ] Poor (2/5)
- [ ] Unacceptable (1/5)

### Final Acceptance Decision
- [ ] ✅ ACCEPTED - All requirements met, ready for production
- [ ] ⚠️ CONDITIONALLY ACCEPTED - Minor issues to be addressed
- [ ] ❌ REJECTED - Major issues require fixes before acceptance

### Sign-off
- Tester Name: ________________
- Date: ________________
- Signature: ________________

---

## 📋 Notes and Comments

Use this section to record any additional observations, suggestions, or issues discovered during testing:

```
[Add your notes here]
```

---

*This checklist ensures comprehensive user acceptance testing of the backup system enhancement and verifies all requirements are met from an end-user perspective.*