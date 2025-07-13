import 'package:flutter/material.dart';
import 'package:flutter_petchbumpen_register/screen/white_robe_scaner.dart';
import '../widgets/menu_card.dart';
import 'registration/registration_menu.dart';
import '../services/db_helper.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showWip(BuildContext ctx) => ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(content: Text('ฟังก์ชันนี้อยู่ระหว่างการพัฒนา')),
  );

  Future<void> _clearDatabase(BuildContext context) async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ล้างข้อมูลฐานข้อมูลเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'ลงทะเบียน',
        'icon': Icons.app_registration,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationMenu()),
        ),
      },
      {
        'label': 'เบิกชุดขาว',
        'icon': Icons.checkroom,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WhiteRobeScanner()),
        ),
      },
      {
        'label': 'จองที่พัก',
        'icon': Icons.bed_outlined,
        'onTap': () => _showWip(context),
      },
      {
        'label': 'ตารางกิจกรรม',
        'icon': Icons.event_note,
        'onTap': () => _showWip(context),
      },
      {
        'label': 'สรุปผลประจำวัน',
        'icon': Icons.bar_chart,
        'onTap': () => _showWip(context),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7), // สีพื้นหลังอ่อน
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.spa,
              color: Colors.purple,
              size: 32,
            ), // เปลี่ยนเป็นสีม่วง
            const SizedBox(width: 8),
            const Text(
              'บ้านเพชรบำเพ็ญ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1.1,
                shrinkWrap: true,
                children: items.map((item) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: item['onTap'] as void Function(),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 40,
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // เพิ่มปุ่มทดสอบสำหรับ Debug
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bug_report),
                  label: const Text('ทดสอบระบบ'),
                  onPressed: () async {
                    final dbHelper = DbHelper();
                    await dbHelper.createTestData();
                    await dbHelper.debugPrintAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'สร้างข้อมูลทดสอบแล้ว ดู Console สำหรับรายละเอียด',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
