import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_petchbumpen_register/white_robe_scaner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/sunmi_style.dart';

void main() => runApp(const DhammaReg());

class DhammaReg extends StatelessWidget {
  const DhammaReg({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'DhammaReg',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    home: const HomeScreen(),
  );
}

// ─────────────────────── Home (เมนู 5 ช่อง) ───────────────────────
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Menu('ลงทะเบียน', Icons.app_registration, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationMenu()),
        );
      }),
      _Menu('เบิกชุดขาว', Icons.checkroom,
     () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const WhiteRobeScanner()))),
      _Menu('จองที่พัก', Icons.bed_outlined, () {}),
      _Menu('ตารางกิจกรรม', Icons.event_note, () {}),
      _Menu('สรุปผลประจำวัน', Icons.bar_chart, () {}),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('บ้านเพชรบำเพ็ญ')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: items
            .map(
              (m) => InkWell(
                onTap: m.onTap,
                child: Card(
                  elevation: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, size: 48),
                      const SizedBox(height: 8),
                      Text(m.label),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Menu {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _Menu(this.label, this.icon, this.onTap);
}

// ─────────────────────── Registration menu ───────────────────────
class RegistrationMenu extends StatelessWidget {
  const RegistrationMenu({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ลงทะเบียน')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _OptionCard(
            icon: Icons.edit_note,
            title: 'กรอกเอง',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualForm()),
            ),
          ),
          const SizedBox(height: 24),
          _OptionCard(
            icon: Icons.camera_alt_rounded,
            title: 'ถ่ายรูปบัตรประชาชน',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaptureForm()),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Card(
    elevation: 4,
    child: ListTile(
      leading: Icon(icon, size: 40),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

// ─────────────────────── Manual form ───────────────────────
class ManualForm extends StatefulWidget {
  const ManualForm({super.key});
  @override
  State<ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<ManualForm> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('กรอกข้อมูล')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: idCtrl,
            decoration: const InputDecoration(
              labelText: 'เลขบัตรประชาชน',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'ชื่อ-นามสกุล',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final data = RegData(idCtrl.text, nameCtrl.text);
                PrinterService(context).printReceipt(data);
                Navigator.pop(context);
              },
              child: const Text('บันทึก & พิมพ์ใบเสร็จ'),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────── Capture form (stub OCR) ──────────────────
class CaptureForm extends StatefulWidget {
  const CaptureForm({super.key});
  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  Future<void> _takePhoto() async {
    // NOTE: stub – ใช้ image_picker เฉย ๆ แล้ว mock ข้อมูล
    await ImagePicker().pickImage(source: ImageSource.camera);
    setState(() {
      idCtrl.text = '1 2345 67890 12 3';
      nameCtrl.text = 'นาย สมชาย ใจดี';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('สแกนบัตรประชาชน')),
    floatingActionButton: FloatingActionButton(
      onPressed: _takePhoto,
      child: const Icon(Icons.camera_alt),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            readOnly: true,
            controller: idCtrl,
            decoration: const InputDecoration(labelText: 'เลขบัตรประชาชน'),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (idCtrl.text.isEmpty) return;
                final data = RegData(idCtrl.text, nameCtrl.text);
                PrinterService(context).printReceipt(data);
                Navigator.pop(context);
              },
              child: const Text('บันทึก & พิมพ์ใบเสร็จ'),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'กดปุ่มกล้องเพื่อลองสแกน (Demo mock ข้อมูล)',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────── Receipt data model ──────────────────────
class RegData {
  final String idCard;
  final String fullName;
  RegData(this.idCard, this.fullName);
}

// ─────────────────────── Printer service ─────────────────────────
class PrinterService {
  final BuildContext ctx;
  PrinterService(this.ctx);

  Future<void> printReceipt(RegData data) async {
    final bool bound = (await SunmiPrinter.bindingPrinter()) ?? false;

    if (!bound) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Print simulated (no Sunmi device)')),
      );
      debugPrint('--- Receipt ---\n${data.fullName}\n${data.idCard}');
      return;
    }

    await SunmiPrinter.initPrinter();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);

    await SunmiPrinter.printText(
      'บ้านเพชรบำเพ็ญ',
      style: SunmiStyle(bold: true, fontSize: SunmiFontSize.LG),
    );
    await SunmiPrinter.line();
    await SunmiPrinter.lineWrap(1);

    // ─── แสดงชื่อแบบตัวโต 1 บรรทัด ───
    await SunmiPrinter.printText(
      'ชื่อ: ${data.fullName}',
      style: SunmiStyle(bold: true),
    );
    await SunmiPrinter.lineWrap(1);

    // ─── แสดง QR แทนเลขบัตร ───
    // ปล.​ ใช้ idCard เป็น payload ไปก่อน ถ้าอยากใช้ UID อื่น ก็เซตได้ที่ data.qr
    await SunmiPrinter.printQRCode(data.idCard); // <── เปลี่ยนตรงนี้
    await SunmiPrinter.lineWrap(2);

    await SunmiPrinter.printText(
      'นำใบนี้ไปเบิกชุดขาว',
      style: SunmiStyle(bold: true),
    );
    await SunmiPrinter.lineWrap(3);

    await SunmiPrinter.cut();
    await SunmiPrinter.unbindingPrinter();
  }
}
