import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/backup_service.dart';
import '../services/backup_error_handler.dart';

class RestoreButton extends StatefulWidget {
  final BackupService backupService;
  final VoidCallback? onRestoreComplete;

  const RestoreButton({
    super.key,
    required this.backupService,
    this.onRestoreComplete,
  });

  @override
  State<RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends State<RestoreButton>
    with SingleTickerProviderStateMixin {
  bool _isRestoring = false;
  String? _selectedFilePath;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['sql', 'json'],
        dialogTitle: 'เลือกไฟล์สำรองข้อมูล',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        BackupErrorHandler.instance.handleError(
          context,
          e,
          operation: 'File Selection',
          onRetry: _pickFile,
        );
      }
    }
  }

  Future<void> _showRestoreConfirmDialog() async {
    if (_selectedFilePath == null) return;

    final fileName = _selectedFilePath!.split('/').last;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('⚠️ ยืนยันการกู้คืนข้อมูล'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'การกู้คืนข้อมูลจะมีผลกระทบดังนี้:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ข้อมูลปัจจุบันจะถูกลบทั้งหมด',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• ข้อมูลการลงทะเบียนทั้งหมด\n'
                      '• ข้อมูลการเข้าพัก\n'
                      '• การตั้งค่าต่างๆ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restore,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ข้อมูลจากไฟล์จะถูกกู้คืน',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ไฟล์: $fileName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.backup,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ระบบจะสร้างไฟล์สำรองข้อมูลปัจจุบันก่อนการกู้คืน',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performRestore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันการกู้คืน'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRestore() async {
    if (_selectedFilePath == null || _isRestoring) return;

    setState(() {
      _isRestoring = true;
    });

    _animationController.repeat();

    try {
      await widget.backupService.restoreFromFile(_selectedFilePath!);
      
      _animationController.stop();
      _animationController.reset();

      if (mounted) {
        setState(() {
          _isRestoring = false;
          _selectedFilePath = null;
        });

        BackupErrorHandler.instance.showSuccess(
          context,
          'กู้คืนข้อมูลเรียบร้อยแล้ว',
          details: 'แอปจะรีสตาร์ทเพื่อโหลดข้อมูลใหม่',
          duration: const Duration(seconds: 3),
        );

        widget.onRestoreComplete?.call();
      }
    } catch (e) {
      _animationController.stop();
      _animationController.reset();

      if (mounted) {
        setState(() {
          _isRestoring = false;
        });

        BackupErrorHandler.instance.handleError(
          context,
          e,
          operation: 'Restore',
          onRetry: _performRestore,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isRestoring ? Colors.orange[100] : Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _isRestoring ? _animation.value * 2 * 3.14159 : 0,
                        child: Icon(
                          _isRestoring ? Icons.sync : Icons.restore,
                          color: _isRestoring ? Colors.orange[600] : Colors.purple[600],
                          size: 24,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRestoring ? 'กำลังกู้คืนข้อมูล...' : 'กู้คืนข้อมูลจากไฟล์',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isRestoring 
                            ? 'กรุณารอสักครู่...'
                            : 'เลือกไฟล์สำรองข้อมูลเพื่อกู้คืน',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_selectedFilePath != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.insert_drive_file,
                          color: Colors.blue[600],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ไฟล์ที่เลือก',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedFilePath!.split('/').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRestoring ? null : _pickFile,
                    icon: const Icon(Icons.folder_open),
                    label: Text(_selectedFilePath == null ? 'เลือกไฟล์' : 'เปลี่ยนไฟล์'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_selectedFilePath != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isRestoring ? null : _showRestoreConfirmDialog,
                      icon: _isRestoring 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.restore),
                      label: Text(_isRestoring ? 'กำลังกู้คืน...' : 'กู้คืนข้อมูล'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'การกู้คืนจะลบข้อมูลปัจจุบันทั้งหมด กรุณาตรวจสอบไฟล์ให้แน่ใจ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
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