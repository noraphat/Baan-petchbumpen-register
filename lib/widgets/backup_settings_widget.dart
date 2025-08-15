import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../models/backup_settings.dart';

class BackupSettingsWidget extends StatefulWidget {
  final BackupService backupService;
  final VoidCallback? onSettingsChanged;

  const BackupSettingsWidget({
    super.key,
    required this.backupService,
    this.onSettingsChanged,
  });

  @override
  State<BackupSettingsWidget> createState() => _BackupSettingsWidgetState();
}

class _BackupSettingsWidgetState extends State<BackupSettingsWidget> {
  BackupSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await widget.backupService.getBackupSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(BackupSettings newSettings) async {
    try {
      await widget.backupService.saveBackupSettings(newSettings);
      setState(() {
        _settings = newSettings;
      });
      widget.onSettingsChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกการตั้งค่า: $e')),
        );
      }
    }
  }

  String _formatLastBackupTime(DateTime? lastBackupTime) {
    if (lastBackupTime == null) return 'ยังไม่เคยสำรองข้อมูล';
    
    final now = DateTime.now();
    final difference = now.difference(lastBackupTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เมื่อสักครู่';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_settings == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('ไม่สามารถโหลดการตั้งค่าได้'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.backup,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'การตั้งค่าสำรองข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Auto Backup Toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _settings!.autoBackupEnabled 
                    ? Colors.green[50] 
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _settings!.autoBackupEnabled 
                      ? Colors.green[200]! 
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _settings!.autoBackupEnabled 
                            ? Icons.schedule 
                            : Icons.schedule_outlined,
                        color: _settings!.autoBackupEnabled 
                            ? Colors.green[600] 
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'สำรองข้อมูลอัตโนมัติรายวัน',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _settings!.autoBackupEnabled,
                        onChanged: (value) {
                          final newSettings = BackupSettings(
                            autoBackupEnabled: value,
                            lastBackupTime: _settings!.lastBackupTime,
                            maxBackupDays: _settings!.maxBackupDays,
                            backupDirectory: _settings!.backupDirectory,
                          );
                          _updateSettings(newSettings);
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  if (_settings!.autoBackupEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'สำรองข้อมูลล่าสุด: ${_formatLastBackupTime(_settings!.lastBackupTime)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Backup Directory Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ตำแหน่งไฟล์สำรองข้อมูล',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _settings!.backupDirectory,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Max Backup Days Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_delete,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ไฟล์สำรองข้อมูลจะถูกลบอัตโนมัติหลังจาก ${_settings!.maxBackupDays} วัน',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}