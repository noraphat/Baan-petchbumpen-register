import 'package:flutter/material.dart';
import 'package:flutter_petchbumpen_register/screen/white_robe_scaner.dart';
import '../widgets/menu_card.dart';
import 'registration/registration_menu.dart';
import '../services/db_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showWip(BuildContext ctx) =>
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('ฟังก์ชันนี้อยู่ระหว่างการพัฒนา')));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('ลงทะเบียน', Icons.app_registration, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationMenu()));
      }),
      ('เบิกชุดขาว', Icons.checkroom, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WhiteRobeScanner()));
      }),
      ('จองที่พัก', Icons.bed_outlined, () => _showWip(context)),
      ('ตารางกิจกรรม', Icons.event_note, () => _showWip(context)),
      ('สรุปผลประจำวัน', Icons.bar_chart, () => _showWip(context)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('บ้านเพชรบำเพ็ญ'),
        actions: [
          // แสดงปุ่ม Clear เฉพาะใน Debug Mode
          if (const bool.fromEnvironment('dart.vm.product') == false)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'ล้างข้อมูลฐานข้อมูล (Debug)',
              onPressed: () => _showClearConfirmDialog(context),
            ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final m in items) MenuCard(label: m.$1, icon: m.$2, onTap: m.$3),
        ],
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการล้างข้อมูล'),
        content: const Text('คุณต้องการล้างข้อมูลทั้งหมดในฐานข้อมูลหรือไม่?\n\nการดำเนินการนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearDatabase(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ล้างข้อมูล'),
          ),
        ],
      ),
    );
  }
}
