import 'package:flutter/material.dart';
import '../services/db_helper.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isLoading = false;
  Map<String, int>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DbHelper().getDatabaseStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาดในการโหลดสถิติ: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showDatabaseStatistics() async {
    await _loadStatistics();
    
    if (_statistics == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text('สถิติฐานข้อมูล'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              icon: Icons.people,
              label: 'จำนวนผู้ปฏิบัติธรรมทั้งหมด',
              value: '${_statistics!['totalVisitors']} คน',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.assignment,
              label: 'จำนวนข้อมูลการเข้าปฏิบัติธรรมทั้งหมด',
              value: '${_statistics!['totalAdditionalInfo']} รายการ',
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.hotel,
              label: 'จำนวนประวัติการพัก',
              value: '${_statistics!['totalStays']} รายการ',
              color: Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              icon: Icons.delete_outline,
              label: 'จำนวนข้อมูลที่ถูกลบ',
              value: '${_statistics!['deletedVisitors']} คน',
              color: Colors.red,
            ),
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearTestData() async {
    final confirmed = await _showConfirmDialog(
      title: 'ล้างข้อมูลทดสอบ',
      content: 'คุณต้องการลบข้อมูลทดสอบทั้งหมดหรือไม่?\n\n'
          '⚠️ ข้อมูลที่จะถูกลบ:\n'
          '• ชื่อที่มีคำว่า "ทดสอบ"\n'
          '• เบอร์โทรที่ขึ้นต้นด้วย "000"\n'
          '• หมายเหตุที่มีคำว่า "ทดสอบ"\n\n'
          'ข้อมูลจริงของผู้ใช้จะไม่ถูกลบ',
      confirmText: 'ลบข้อมูลทดสอบ',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      final deletedCount = await DbHelper().clearTestData();
      setState(() => _isLoading = false);
      
      await _loadStatistics(); // รีเฟรชสถิติ
      
      _showSnackBar('ล้างข้อมูลทดสอบเรียบร้อยแล้ว (ลบ $deletedCount รายการ)');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _createTestData() async {
    final confirmed = await _showConfirmDialog(
      title: 'สร้างข้อมูลทดสอบ',
      content: 'คุณต้องการสร้างข้อมูลทดสอบหรือไม่?\n\n'
          '📦 ข้อมูลที่จะสร้าง:\n'
          '• ผู้ปฏิบัติธรรม 5 คน\n'
          '• แต่ละคนมีประวัติ 1-3 ครั้ง\n'
          '• ข้อมูลอุปกรณ์ครบถ้วน\n'
          '• ข้อมูลการพักที่แตกต่างกัน',
      confirmText: 'สร้างข้อมูลทดสอบ',
      isDestructive: false,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      await DbHelper().createMultipleTestData();
      setState(() => _isLoading = false);
      
      await _loadStatistics(); // รีเฟรชสถิติ
      
      _showSnackBar('สร้างข้อมูลทดสอบเรียบร้อยแล้ว');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _clearAllData() async {
    final firstConfirm = await _showConfirmDialog(
      title: '⚠️ ล้างข้อมูลทั้งหมด',
      content: 'คุณต้องการลบข้อมูลทั้งหมดในระบบหรือไม่?\n\n'
          '🚨 การกระทำนี้จะ:\n'
          '• ลบข้อมูลผู้ปฏิบัติธรรมทั้งหมด\n'
          '• ลบประวัติการเข้าพักทั้งหมด\n'
          '• ลบข้อมูลอุปกรณ์ทั้งหมด\n'
          '• รีเซตการตั้งค่าเป็นค่าเริ่มต้น\n\n'
          '⚠️ ไม่สามารถย้อนกลับได้!',
      confirmText: 'ดำเนินการต่อ',
      isDestructive: true,
    );

    if (firstConfirm != true) return;

    // ยืนยันครั้งที่ 2
    final secondConfirm = await _showConfirmDialog(
      title: '🚨 ยืนยันอีกครั้ง',
      content: 'คุณแน่ใจหรือไม่ที่จะลบข้อมูลทั้งหมด?\n\n'
          'หลังจากนี้ระบบจะกลับมาเป็นเหมือนเพิ่งติดตั้งใหม่\n\n'
          'กรุณาพิมพ์ "DELETE" เพื่อยืนยัน',
      confirmText: 'ลบทั้งหมด',
      isDestructive: true,
      requireTextConfirmation: true,
    );

    if (secondConfirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      await DbHelper().clearAllData();
      setState(() => _isLoading = false);
      
      await _loadStatistics(); // รีเฟรชสถิติ
      
      _showSnackBar('ล้างข้อมูลทั้งหมดเรียบร้อยแล้ว ระบบพร้อมใช้งานใหม่อีกครั้ง');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required bool isDestructive,
    bool requireTextConfirmation = false,
  }) async {
    final textController = TextEditingController();
    bool isTextValid = !requireTextConfirmation;

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content),
              if (requireTextConfirmation) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    hintText: 'พิมพ์ "DELETE" เพื่อยืนยัน',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      isTextValid = value.trim().toUpperCase() == 'DELETE';
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: isTextValid
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : null,
                foregroundColor: isDestructive ? Colors.white : null,
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการข้อมูล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // สถิติฐานข้อมูล
                  _buildMenuCard(
                    icon: Icons.analytics,
                    title: 'ดูสถิติฐานข้อมูล',
                    subtitle: 'แสดงจำนวน record ของแต่ละตารางหลัก',
                    color: Colors.blue,
                    onTap: _showDatabaseStatistics,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ล้างข้อมูลทดสอบ
                  _buildMenuCard(
                    icon: Icons.cleaning_services,
                    title: 'ล้างข้อมูลทดสอบ',
                    subtitle: 'ลบเฉพาะข้อมูลที่สร้างเพื่อทดสอบ (ปลอดภัย)',
                    color: Colors.orange,
                    onTap: _clearTestData,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // สร้างข้อมูลทดสอบ
                  _buildMenuCard(
                    icon: Icons.add_box,
                    title: 'สร้างข้อมูลทดสอบ',
                    subtitle: 'สร้างผู้ใช้จำลอง 5-10 คน พร้อมประวัติครบถ้วน',
                    color: Colors.green,
                    onTap: _createTestData,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ล้างข้อมูลทั้งหมด
                  _buildMenuCard(
                    icon: Icons.delete_forever,
                    title: 'ล้างข้อมูลทั้งหมด',
                    subtitle: '⚠️ ทำลายทุกข้อมูลในระบบ (อันตราย)',
                    color: Colors.red,
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}