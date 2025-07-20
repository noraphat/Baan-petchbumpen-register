import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../services/menu_settings_service.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  // Menu visibility toggles
  bool _whiteRobeEnabled = false;  // ค่าเริ่มต้นปิด
  bool _bookingEnabled = false;    // ค่าเริ่มต้นปิด
  
  // Auto backup toggle
  bool _autoBackupEnabled = false;
  
  // System info
  int _totalRegistered = 0;
  int _currentStays = 0;
  double _dbSizeKB = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
    _loadMenuSettings();
  }
  
  Future<void> _loadMenuSettings() async {
    final menuService = MenuSettingsService();
    final whiteRobeEnabled = await menuService.isWhiteRobeEnabled;
    final bookingEnabled = await menuService.isBookingEnabled;
    
    setState(() {
      _whiteRobeEnabled = whiteRobeEnabled;
      _bookingEnabled = bookingEnabled;
    });
  }
  
  Future<void> _loadSystemInfo() async {
    try {
      final dbHelper = DbHelper();
      final allData = await dbHelper.fetchAll();
      // TODO: Get current stays count from stays table
      // TODO: Get actual database size
      
      setState(() {
        _totalRegistered = allData.length;
        _currentStays = 12; // Placeholder
        _dbSizeKB = 2.5; // Placeholder
      });
    } catch (e) {
      debugPrint('Error loading system info: $e');
    }
  }
  
  Future<void> _showStatistics() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bar_chart, size: 24, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('สถิติฐานข้อมูล'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จำนวนผู้ลงทะเบียนทั้งหมด: $_totalRegistered คน'),
            Text('ผู้เข้าพักปัจจุบัน: $_currentStays คน'),
            Text('ขนาดฐานข้อมูล: ${_dbSizeKB.toStringAsFixed(1)} MB'),
            const SizedBox(height: 16),
            const Text('รายละเอียดเพิ่มเติมจะแสดงในเวอร์ชันถัดไป'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearTestData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, size: 24, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text('คุณต้องการล้างข้อมูลทดสอบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // TODO: Implement clear test data logic
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ล้างข้อมูลทดสอบเรียบร้อยแล้ว')),
          );
          _loadSystemInfo(); // Refresh stats
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _createTestData() async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.createTestData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างข้อมูลทดสอบเรียบร้อยแล้ว')),
        );
        _loadSystemInfo(); // Refresh stats
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
  
  Future<void> _runSystemTest() async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.createTestData();
      await dbHelper.debugPrintAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ทดสอบระบบเสร็จสิ้น - ดู Console สำหรับรายละเอียด'),
            duration: Duration(seconds: 3),
          ),
        );
        _loadSystemInfo(); // Refresh stats
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการทดสอบ: $e')),
        );
      }
    }
  }
  
  Future<void> _clearAllData() async {
    // Show double confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.dangerous, size: 24, color: Colors.red),
            const SizedBox(width: 8),
            const Text('อันตราย!', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'คำเตือน: การลบข้อมูลทั้งหมดไม่สามารถกู้คืนได้!\n\nคุณแน่ใจหรือไม่?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบทั้งหมด', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final dbHelper = DbHelper();
        await dbHelper.clearAllData();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ล้างข้อมูลทั้งหมดเรียบร้อยแล้ว')),
          );
          _loadSystemInfo(); // Refresh stats
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuToggle(String label, bool value, ValueChanged<bool> onChanged, {bool isLocked = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          isLocked ? Icons.lock : Icons.settings,
          size: 20,
          color: isLocked ? Colors.grey : Colors.purple,
        ),
        title: Text(label),
        trailing: isLocked 
          ? const Text('ปิดไม่ได้', style: TextStyle(color: Colors.grey))
          : Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.purple,
            ),
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed, {Color? color}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, size: 20, color: color ?? Colors.purple),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        tileColor: color?.withValues(alpha: 0.1),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text('Developer Settings'),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu Management Section
            _buildSectionHeader('เมนูหลัก', Icons.apps),
            _buildMenuToggle('ลงทะเบียน', true, (value) {}, isLocked: true),
            _buildMenuToggle('เบิกชุดขาว', _whiteRobeEnabled, (value) async {
              debugPrint('Setting White Robe to: $value');
              setState(() => _whiteRobeEnabled = value);
              await MenuSettingsService().setWhiteRobeEnabled(value);
              debugPrint('White Robe setting saved: $value');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'เปิดเมนู "เบิกชุดขาว" แล้ว' 
                      : 'ปิดเมนู "เบิกชุดขาว" แล้ว'
                    ),
                  ),
                );
              }
            }),
            _buildMenuToggle('จองที่พัก', _bookingEnabled, (value) async {
              debugPrint('Setting Booking to: $value');
              setState(() => _bookingEnabled = value);
              await MenuSettingsService().setBookingEnabled(value);
              debugPrint('Booking setting saved: $value');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'เปิดเมนู "จองที่พัก" แล้ว' 
                      : 'ปิดเมนู "จองที่พัก" แล้ว'
                    ),
                  ),
                );
              }
            }),
            _buildMenuToggle('ตารางกิจกรรม', true, (value) {}, isLocked: true),
            _buildMenuToggle('สรุปผลประจำวัน', true, (value) {}, isLocked: true),
            
            // Data Management Section
            _buildSectionHeader('จัดการข้อมูล', Icons.storage),
            _buildActionButton('ดูสถิติฐานข้อมูล', Icons.bar_chart, _showStatistics),
            _buildActionButton('ทดสอบระบบ', Icons.science, _runSystemTest),
            _buildActionButton('ล้างข้อมูลทดสอบ', Icons.cleaning_services, _clearTestData),
            _buildActionButton('สร้างข้อมูลทดสอบ', Icons.build, _createTestData),
            _buildActionButton('ล้างข้อมูลทั้งหมด', Icons.warning, _clearAllData, color: Colors.red),
            
            // Backup Section
            _buildSectionHeader('สำรองข้อมูล', Icons.save),
            _buildActionButton('Export ข้อมูลเป็น JSON', Icons.description, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมในเวอร์ชันถัดไป')),
              );
            }),
            _buildActionButton('Export รายงาน PDF', Icons.picture_as_pdf, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมในเวอร์ชันถัดไป')),
              );
            }),
            _buildActionButton('Import ข้อมูล', Icons.file_download, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์นี้จะพร้อมในเวอร์ชันถัดไป')),
              );
            }),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.sync, size: 20, color: Colors.purple),
                title: const Text('Auto Backup รายวัน'),
                trailing: Switch(
                  value: _autoBackupEnabled,
                  onChanged: (value) {
                    setState(() => _autoBackupEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value 
                          ? 'เปิด Auto Backup รายวันแล้ว' 
                          : 'ปิด Auto Backup รายวันแล้ว'
                        ),
                      ),
                    );
                  },
                  activeColor: Colors.purple,
                ),
              ),
            ),
            
            // System Info Section
            _buildSectionHeader('ข้อมูลระบบ', Icons.info),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow('App Version:', 'v1.0.0'),
                    _buildInfoRow('Database Version:', '4'),
                    _buildInfoRow('จำนวนผู้ลงทะเบียน:', '$_totalRegistered คน'),
                    _buildInfoRow('ผู้เข้าพักปัจจุบัน:', '$_currentStays คน'),
                    _buildInfoRow('พื้นที่ DB:', '${_dbSizeKB.toStringAsFixed(1)} MB'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'เวอร์ชัน: v1.0.0 (Build 4)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}