import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reg_data.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  List<RegData> _deletedRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedRecords();
  }

  Future<void> _loadDeletedRecords() async {
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DbHelper();
      final deletedRecords = await dbHelper.fetchDeletedRecords();
      
      setState(() {
        _deletedRecords = deletedRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showRestoreConfirmDialog(RegData record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการกู้คืนข้อมูล'),
        content: Text('ต้องการกู้คืนข้อมูลของ ${record.first} ${record.last} หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreRecord(record);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('กู้คืน'),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteConfirmDialog(RegData record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ยืนยันการลบถาวร'),
        content: Text(
          'ต้องการลบข้อมูลของ ${record.first} ${record.last} ออกจากฐานข้อมูลถาวรหรือไม่?\n\n'
          'หลังจากลบแล้วจะไม่สามารถกู้คืนได้อีก!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permanentDeleteRecord(record);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบถาวร'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreRecord(RegData record) async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.restoreRecord(record.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กู้คืนข้อมูลเรียบร้อยแล้ว')),
        );
      }
      
      _loadDeletedRecords(); // โหลดข้อมูลใหม่
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการกู้คืนข้อมูล: $e');
    }
  }

  Future<void> _permanentDeleteRecord(RegData record) async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.hardDelete(record.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลถาวรเรียบร้อยแล้ว')),
        );
      }
      
      _loadDeletedRecords(); // โหลดข้อมูลใหม่
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการลบข้อมูล: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.developer_mode, color: Colors.orange),
            SizedBox(width: 8),
            Text('Developer Settings'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🗑️ ข้อมูลที่ถูกลบ (Soft Delete)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'รายการข้อมูลที่ผู้ใช้ลบแล้ว แต่ยังคงเก็บไว้ในฐานข้อมูล',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'พบข้อมูลที่ถูกลบ ${_deletedRecords.length} รายการ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          // รายการข้อมูลที่ถูกลบ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _deletedRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_sweep,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ไม่มีข้อมูลที่ถูกลบ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _deletedRecords.length,
                        itemBuilder: (context, index) {
                          final record = _deletedRecords[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'ถูกลบ',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: record.hasIdCard ? Colors.blue[100] : Colors.green[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            record.hasIdCard ? 'มีบัตรฯ' : 'ไม่มีบัตรฯ',
                                            style: TextStyle(
                                              color: record.hasIdCard ? Colors.blue[700] : Colors.green[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    Text(
                                      '${record.first} ${record.last}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        const Icon(Icons.badge, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'ID: ${record.id}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'โทร: ${record.phone.isEmpty ? '-' : record.phone}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'ลบเมื่อ: ${_formatDate(record.updatedAt)}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _showRestoreConfirmDialog(record),
                                          icon: const Icon(Icons.restore, size: 18),
                                          label: const Text('กู้คืน'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _showPermanentDeleteConfirmDialog(record),
                                          icon: const Icon(Icons.delete_forever, size: 18),
                                          label: const Text('ลบถาวร'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}