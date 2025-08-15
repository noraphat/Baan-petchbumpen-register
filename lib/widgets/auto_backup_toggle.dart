import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/backup_error_handler.dart';


class AutoBackupToggle extends StatefulWidget {
  final BackupService backupService;
  final VoidCallback? onToggleChanged;

  const AutoBackupToggle({
    super.key,
    required this.backupService,
    this.onToggleChanged,
  });

  @override
  State<AutoBackupToggle> createState() => _AutoBackupToggleState();
}

class _AutoBackupToggleState extends State<AutoBackupToggle> {
  bool _isEnabled = false;
  DateTime? _lastBackupTime;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await widget.backupService.getBackupSettings();
      setState(() {
        _isEnabled = settings.autoBackupEnabled;
        _lastBackupTime = settings.lastBackupTime;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      if (value) {
        await widget.backupService.enableAutoBackup();
      } else {
        await widget.backupService.disableAutoBackup();
      }

      // Reload settings to get updated values
      await _loadSettings();
      
      widget.onToggleChanged?.call();

      if (mounted) {
        if (value) {
          BackupErrorHandler.instance.showSuccess(
            context,
            'เปิดใช้งานสำรองข้อมูลอัตโนมัติแล้ว',
            icon: Icons.check_circle,
          );
        } else {
          BackupErrorHandler.instance.showWarning(
            context,
            'ปิดใช้งานสำรองข้อมูลอัตโนมัติแล้ว',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Handle error using error handler with retry option
        BackupErrorHandler.instance.handleError(
          context,
          e,
          operation: 'Auto Backup Toggle',
          onRetry: () => _toggleAutoBackup(value),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
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

  String _getDetailedLastBackupTime(DateTime? lastBackupTime) {
    if (lastBackupTime == null) return '';
    
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    
    final day = lastBackupTime.day;
    final month = months[lastBackupTime.month - 1];
    final year = lastBackupTime.year + 543;
    final hour = lastBackupTime.hour.toString().padLeft(2, '0');
    final minute = lastBackupTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year เวลา $hour:$minute น.';
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _isEnabled
              ? LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey[50]!, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEnabled ? Colors.green[200] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isEnabled ? Icons.schedule : Icons.schedule_outlined,
                    color: _isEnabled ? Colors.green[700] : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สำรองข้อมูลอัตโนมัติรายวัน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnabled 
                            ? 'ระบบจะสำรองข้อมูลอัตโนมัติทุกวัน'
                            : 'ปิดใช้งานการสำรองข้อมูลอัตโนมัติ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isUpdating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _isEnabled,
                    onChanged: _toggleAutoBackup,
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green[200],
                  ),
              ],
            ),
            
            if (_isEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'สำรองข้อมูลล่าสุด',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_lastBackupTime != null) ...[
                      Text(
                        _formatLastBackupTime(_lastBackupTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDetailedLastBackupTime(_lastBackupTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'ยังไม่เคยสำรองข้อมูล',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ระบบจะสำรองข้อมูลในครั้งถัดไป',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ไฟล์สำรองข้อมูลจะถูกสร้างเป็น DD.sql และลบอัตโนมัติหลัง 31 วัน',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}