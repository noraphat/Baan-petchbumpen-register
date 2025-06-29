import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/reg_data.dart';
import '../../services/printer_service.dart';

class CaptureForm extends StatefulWidget {
  const CaptureForm({super.key});

  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  final idCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  File? _preview;                               // แสดงรูปที่ถ่าย

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;

    setState(() => _preview = File(file.path));

    // ---------- TODO: ใส่ OCR จริงตรงนี้ ----------
    // ตอนนี้ mock ข้อมูลเพื่อเดโม
    idCtrl.text = '1 2345 67890 12 3';
    nameCtrl.text = 'นาย สมชาย ใจดี';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('สแกนบัตรประชาชน')),
        floatingActionButton:
            FloatingActionButton(onPressed: _takePhoto, child: const Icon(Icons.camera_alt)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // --- รูปตัวอย่าง / กล่องว่าง ---
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  image: _preview != null
                      ? DecorationImage(image: FileImage(_preview!), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: _preview == null
                    ? const Text('กดปุ่มกล้องเพื่อถ่ายบัตร', style: TextStyle(color: Colors.grey))
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // --- ฟิลด์อ่านอย่างเดียว ---
            TextField(
              controller: idCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'เลขบัตรประชาชน (OCR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล (OCR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('บันทึก & พิมพ์ใบเสร็จ'),
                onPressed: () async {
                  if (idCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ยังไม่มีข้อมูล OCR')),
                    );
                    return;
                  }

                  // ----- แยกชื่อเต็มเป็น first / last ง่าย ๆ -----
                  final parts = nameCtrl.text.trim().split(' ');
                  final first = parts.isNotEmpty ? parts.first : '';
                  final last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';

                  // ----- สร้าง RegData ด้วย named parameters ให้ครบ 7 ช่อง -----
                  final data = RegData(
                    id:     idCtrl.text.trim(),
                    first:  first,
                    last:   last,
                    dob:    '',          // ยังไม่มีวันเกิดจาก OCR → เว้นไว้ก่อน
                    phone:  '',          // ยังไม่มี
                    addr:   '',
                    gender: '',
                  );

                  // (1) บันทึกลง Sqflite ถ้าต้องการ
                  await DbHelper().insert(data);

                  // (2) พิมพ์ใบเสร็จ (PrinterService ใช้แค่ id + first + last ก็ได้)
                  await PrinterService(context).printReceipt(data);

                  if (mounted) Navigator.pop(context);
                },

              ),
            ),
          ]),
        ),
      );

  @override
  void dispose() {
    idCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }
}
