import 'package:flutter/material.dart';
import 'package:flutter_petchbumpen_register/screen/white_robe_scaner.dart';
import '../widgets/menu_card.dart';
import 'registration/registration_menu.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showWip(BuildContext ctx) =>
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('ฟังก์ชันนี้อยู่ระหว่างการพัฒนา')));

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
      appBar: AppBar(title: const Text('บ้านเพชรบำเพ็ญ')),
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
}
