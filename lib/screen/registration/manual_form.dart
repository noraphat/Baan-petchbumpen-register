import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reg_data.dart';
import '../../services/db_helper.dart';
import '../../services/printer_service.dart';

class ManualForm extends StatefulWidget {
  const ManualForm({super.key});
  @override
  State<ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<ManualForm> {
  // --- controller ทุกช่อง ---
  final searchCtrl = TextEditingController();
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addrCtrl = TextEditingController();

  String _gender = 'ชาย';
  bool _found = false; // มีในระบบ?
  bool _loaded = false; // กดค้นหาหรือยัง

  final _formKey = GlobalKey<FormState>();

  // ---------- ฟังก์ชันค้นหา ----------
  Future<void> _search() async {
    final q = searchCtrl.text.trim();
    if (q.length < 5) return; // กรองคร่าว ๆ

    final old = await DbHelper().fetchById(q);
    if (old == null) {
      // ไม่พบ → Enable form
      setState(() {
        _found = false;
        _loaded = true;
        firstCtrl.clear();
        lastCtrl.clear();
        dobCtrl.clear();
        phoneCtrl.clear();
        addrCtrl.clear();
        _gender = 'ชาย';
      });
      FocusScope.of(context).requestFocus(_firstFocus);
    } else {
      // พบ → แสดง & Lock
      setState(() {
        _found = true;
        _loaded = true;
        firstCtrl.text = old.first;
        lastCtrl.text = old.last;
        dobCtrl.text = old.dob;
        phoneCtrl.text = old.phone;
        addrCtrl.text = old.addr;
        _gender = old.gender;
      });
    }
  }

  // ---------- FocusNode เพื่อโฟกัสชื่อทันที ----------
  final _firstFocus = FocusNode();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ลงทะเบียน')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────── ช่องค้นหา + ปุ่มสวย ๆ ─────────
            TextFormField(
              controller: searchCtrl,
              maxLength: 13,
              decoration: InputDecoration(
                labelText: 'หมายเลขประชาชน / เบอร์โทรศัพท์',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              keyboardType: TextInputType.number,
              onFieldSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),

            // ───────── ฟิลด์ข้อมูล ─────────
            _buildField(
              label: 'ชื่อ',
              controller: firstCtrl,
              enabled: !_found,
              focus: _firstFocus,
              mandatory: true,
            ),
            _buildField(
              label: 'นามสกุล',
              controller: lastCtrl,
              enabled: !_found,
              mandatory: true,
            ),

            // วันเกิด
            GestureDetector(
              onTap: _found ? null : _pickDate,
              child: AbsorbPointer(
                child: _buildField(
                  label: 'วันเดือนปีเกิด (พ.ศ.)',
                  controller: dobCtrl,
                  enabled: !_found,
                  mandatory: true,
                ),
              ),
            ),

            // เบอร์
            _buildField(
              label: 'เบอร์โทรศัพท์',
              controller: phoneCtrl,
              enabled: !_found,
              keyboard: TextInputType.phone,
            ),

            // ที่อยู่
            _buildField(
              label: 'ที่อยู่ (จังหวัด, อำเภอ, ตำบล, บ้านเลขที่…)',
              controller: addrCtrl,
              enabled: !_found,
              lines: 2,
            ),

            // เพศ
            Row(
              children: [
                const Text('เพศ:'),
                const SizedBox(width: 16),
                for (final g in ['ชาย', 'หญิง', 'อื่น ๆ'])
                  Row(
                    children: [
                      Radio<String>(
                        value: g,
                        groupValue: _gender,
                        onChanged: _found
                            ? null
                            : (v) => setState(() => _gender = v!),
                      ),
                      Text(g),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // ───────── ปุ่มบันทึก / ลงทะเบียน ─────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !_loaded
                    ? null
                    : () async {
                        if (_found) {
                          Navigator.pop(context); // แค่ลงทะเบียนเข้าเรียน
                          return;
                        }
                        if (!_formKey.currentState!.validate()) return;
                        final data = RegData(
                          id: searchCtrl.text.trim(), // หมายเลขประชาชน/โทร
                          first: firstCtrl.text.trim(),
                          last: lastCtrl.text.trim(),
                          dob: dobCtrl.text, //  dd/MM/พ.ศ.
                          phone: phoneCtrl.text.trim(),
                          addr: addrCtrl.text.trim(),
                          gender: _gender,
                        );
                        await DbHelper().insert(data);
                        await PrinterService(context).printReceipt(
                          RegData(
                            id: data.id,
                            first: data.first,
                            last: data.last,
                            dob: '',
                            phone: '',
                            addr: '',
                            gender: '',
                          ),
                        );

                        if (mounted) Navigator.pop(context);
                      },
                child: Text(_found ? 'ลงทะเบียน' : 'บันทึก & พิมพ์ใบเสร็จ'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ---------- widget helper ----------
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool mandatory = false,
    int lines = 1,
    FocusNode? focus,
    TextInputType keyboard = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      focusNode: focus,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: mandatory && !enabled
          ? null
          : (mandatory
                ? (v) => (v == null || v.isEmpty) ? 'ระบุ $label' : null
                : null),
    ),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      locale: const Locale('th', 'TH'),
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (d != null) {
      final buddhistYear = d.year + 543;
      dobCtrl.text = DateFormat('dd/MM/').format(d) + buddhistYear.toString();
      setState(() {});
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    firstCtrl.dispose();
    lastCtrl.dispose();
    dobCtrl.dispose();
    phoneCtrl.dispose();
    addrCtrl.dispose();
    _firstFocus.dispose();
    super.dispose();
  }
}
