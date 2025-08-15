import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../services/menu_settings_service.dart';
import '../services/backup_service.dart';
import '../widgets/backup_settings_widget.dart';
import 'developer_settings.dart';
import 'data_management_screen.dart';
import 'map_management_screen.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  // Menu visibility toggles
  bool _whiteRobeEnabled = false; // ค่าเริ่มต้นปิด
  bool _bookingEnabled = false; // ค่าเริ่มต้นปิด
  bool _debugRoomMenuEnabled = false; // ค่าเริ่มต้นปิด

  // Backup service
  BackupService get _backupService => BackupService.instance;

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
    final debugRoomMenuEnabled = await menuService.isDebugRoomMenuEnabled;

    setState(() {
      _whiteRobeEnabled = whiteRobeEnabled;
      _bookingEnabled = bookingEnabled;
      _debugRoomMenuEnabled = debugRoomMenuEnabled;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการทดสอบ: $e')));
      }
    }
  }



  @visibleForTesting
  Future<bool> showDestructiveOperationConfirmation({
    required String title,
    required String message,
    String confirmText = 'ยืนยัน',
    String cancelText = 'ยกเลิก',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, size: 24, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
          Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMenuToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isLocked = false,
  }) {
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

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
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
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
                    content: Text(
                      value
                          ? 'เปิดเมนู "เบิกชุดขาว" แล้ว'
                          : 'ปิดเมนู "เบิกชุดขาว" แล้ว',
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
                    content: Text(
                      value
                          ? 'เปิดเมนู "จองที่พัก" แล้ว'
                          : 'ปิดเมนู "จองที่พัก" แล้ว',
                    ),
                  ),
                );
              }
            }),
            _buildMenuToggle('Debug จองที่พัก', _debugRoomMenuEnabled, (
              value,
            ) async {
              debugPrint('Setting Debug Room Menu to: $value');
              setState(() => _debugRoomMenuEnabled = value);
              await MenuSettingsService().setDebugRoomMenuEnabled(value);
              debugPrint('Debug Room Menu setting saved: $value');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'เปิด Debug Menu จองที่พักแล้ว'
                          : 'ปิด Debug Menu จองที่พักแล้ว',
                    ),
                  ),
                );
              }
            }),
            _buildMenuToggle('ตารางกิจกรรม', true, (value) {}, isLocked: true),
            _buildMenuToggle(
              'สรุปผลประจำวัน',
              true,
              (value) {},
              isLocked: true,
            ),

            // Data Management Section
            _buildSectionHeader('จัดการข้อมูล', Icons.storage),
            _buildActionButton('จัดการข้อมูล', Icons.storage, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataManagementScreen(),
                ),
              );
            }),
            _buildActionButton('จัดการแผนที่และห้องพัก', Icons.map, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MapManagementScreen(),
                ),
              );
            }),
            _buildActionButton('ทดสอบระบบ', Icons.science, _runSystemTest),

            // Backup Section
            _buildSectionHeader('สำรองข้อมูล', Icons.save),
            BackupSettingsWidget(backupService: _backupService),

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
                    _buildInfoRow(
                      'พื้นที่ DB:',
                      '${_dbSizeKB.toStringAsFixed(1)} MB',
                    ),
                  ],
                ),
              ),
            ),

            // Developer Tools Section
            _buildSectionHeader('Developer Tools', Icons.developer_mode),
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_sweep,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Soft Delete Management',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('จัดการข้อมูลที่ถูกลบ (กู้คืน/ลบถาวร)'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeveloperSettingsScreen(),
                    ),
                  );
                },
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
