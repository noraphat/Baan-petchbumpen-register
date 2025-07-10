import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reg_data.dart';
import '../../services/db_helper.dart';
import '../../services/address_service.dart';
import '../../widgets/buddhist_calendar_picker.dart';

class ManualForm extends StatefulWidget {
  const ManualForm({super.key});

  @override
  State<ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<ManualForm> {
  final searchCtrl = TextEditingController();
  final firstCtrl = TextEditingController();
  final lastCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addrCtrl = TextEditingController();

  int? _selProvId, _selDistId, _selSubId;

  String _gender = 'ชาย';
  final List<String> _genders = ['พระ', 'สามเณร', 'แม่ชี', 'ชาย', 'หญิง', 'อื่นๆ'];
  bool _found = false;
  bool _loaded = false;
  final _formKey = GlobalKey<FormState>();
  final _firstFocus = FocusNode();

  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    AddressService().init();
  }

  Future<void> _search() async {
    final q = searchCtrl.text.trim();
    if (q.length < 5) return;

    final old = await DbHelper().fetchById(q);
    if (old == null) {
      setState(() {
        _found = false;
        _loaded = true;
        firstCtrl.clear();
        lastCtrl.clear();
        dobCtrl.clear();
        phoneCtrl.clear();
        addrCtrl.clear();
        _gender = 'ชาย';
        _selProvId = _selDistId = _selSubId = null;
        _selectedDob = null;
      });
      FocusScope.of(context).requestFocus(_firstFocus);
    } else {
      setState(() {
        _found = true;
        _loaded = true;
        firstCtrl.text = old.first;
        lastCtrl.text = old.last;
        dobCtrl.text = old.dob;
        _selectedDob = DateFormat('d MMMM yyyy', 'th_TH').parse(old.dob.replaceAll(RegExp(r'[\u0E00-\u0E7F\s]+'), ''));
        phoneCtrl.text = old.phone;

        final prov = AddressService().provinces.firstWhere(
            (p) => old.addr.contains(p.nameTh),
            orElse: () => AddressService().provinces.first);
        _selProvId = prov.id;

        final dist = AddressService()
            .districtsOf(prov.id)
            .firstWhere((d) => old.addr.contains(d.nameTh), orElse: () => AddressService().districtsOf(prov.id).first);
        _selDistId = dist.id;

        final sub = AddressService()
            .subsOf(dist.id)
            .firstWhere((s) => old.addr.contains(s.nameTh), orElse: () => AddressService().subsOf(dist.id).first);
        _selSubId = sub.id;

        final parts = old.addr.split(', ');
        addrCtrl.text = parts.isNotEmpty ? parts.last : '';

        _gender = old.gender;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ลงทะเบียน')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextFormField(
                controller: searchCtrl,
                maxLength: 13,
                decoration: InputDecoration(
                  labelText: 'หมายเลขประชาชน / เบอร์โทร (ค้นหา)',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'ค้นหา',
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    onPressed: _search,
                  ),
                ),
                keyboardType: TextInputType.number,
                onFieldSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              _buildField(label: 'ชื่อ', controller: firstCtrl, enabled: !_found, mandatory: true, focus: _firstFocus),
              _buildField(label: 'นามสกุล', controller: lastCtrl, enabled: !_found, mandatory: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: _found
                      ? null
                      : () async {
                          await showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: BuddhistCalendarPicker(
                                  initialDate: _selectedDob,
                                  onDateSelected: (date) {
                                    setState(() {
                                      _selectedDob = date;
                                      dobCtrl.text = '${date.day} '
                                        '${DateFormat.MMMM('th_TH').format(date)} '
                                        '${date.year + 543}';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                  child: AbsorbPointer(
                    child: _buildField(
                      label: 'วันเดือนปีเกิด (พ.ศ.)',
                      controller: dobCtrl,
                      enabled: !_found,
                      mandatory: true,
                    ),
                  ),
                ),
              ),
              _buildField(label: 'เบอร์โทรศัพท์', controller: phoneCtrl, enabled: !_found, keyboard: TextInputType.phone),
              DropdownButtonFormField<int>(
                value: _selProvId,
                decoration: const InputDecoration(labelText: 'จังหวัด'),
                items: AddressService()
                    .provinces
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nameTh)))
                    .toList(),
                onChanged: _found ? null : (v) => setState(() {
                  _selProvId = v;
                  _selDistId = _selSubId = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selDistId,
                decoration: const InputDecoration(labelText: 'อำเภอ'),
                items: _selProvId == null
                    ? []
                    : AddressService()
                        .districtsOf(_selProvId!)
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nameTh)))
                        .toList(),
                onChanged: (_selProvId == null || _found)
                    ? null
                    : (v) => setState(() {
                          _selDistId = v;
                          _selSubId = null;
                        }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selSubId,
                decoration: const InputDecoration(labelText: 'ตำบล'),
                items: _selDistId == null
                    ? []
                    : AddressService()
                        .subsOf(_selDistId!)
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameTh)))
                        .toList(),
                onChanged: (_selDistId == null || _found) ? null : (v) => setState(() => _selSubId = v),
              ),
              const SizedBox(height: 12),
              _buildField(label: 'ที่อยู่เพิ่มเติม (บ้านเลขที่ ฯลฯ)', controller: addrCtrl, lines: 2, enabled: !_found),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'เพศ',
                    border: OutlineInputBorder(),
                  ),
                  items: _genders
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ))
                      .toList(),
                  onChanged: _found ? null : (v) => setState(() => _gender = v!),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(_found ? 'ลงทะเบียน' : 'บันทึก', key: ValueKey<bool>(_found)),
                  ),
                  onPressed: !_loaded ? null : _onSave,
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    bool mandatory = false,
    int lines = 1,
    FocusNode? focus,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          focusNode: focus,
          maxLines: lines,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
          validator: mandatory && !enabled
              ? null
              : (mandatory ? (v) => (v == null || v.isEmpty) ? 'ระบุ $label' : null : null),
        ),
      );

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกวันเกิด')));
      return;
    }
    if (_selProvId == null || _selDistId == null || _selSubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือก จังหวัด / อำเภอ / ตำบล')));
      return;
    }

    final data = RegData.manual(
      id: searchCtrl.text.trim(),
      first: firstCtrl.text.trim(),
      last: lastCtrl.text.trim(),
      dob: dobCtrl.text,
      phone: phoneCtrl.text.trim(),
      addr: '${AddressService().provinces.firstWhere((p) => p.id == _selProvId!).nameTh}, '
            '${AddressService().districts.firstWhere((d) => d.id == _selDistId!).nameTh}, '
            '${AddressService().subs.firstWhere((s) => s.id == _selSubId!).nameTh}, '
            '${addrCtrl.text.trim()}',
      gender: _gender,
    );

    await DbHelper().insert(data);
    await _showAdditionalInfoDialog(data.id); // ส่ง id ไปด้วย
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showAdditionalInfoDialog(String regId) async {
    DateTime? startDate;
    DateTime? endDate;
    final shirtCtrl = TextEditingController();
    final pantsCtrl = TextEditingController();
    final matCtrl = TextEditingController();
    final pillowCtrl = TextEditingController();
    final blanketCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool withChildren = false;
    final childrenCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('ข้อมูลเพิ่มเติม'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => startDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'วันที่เริ่มต้น'),
                          child: Text(startDate == null
                              ? 'เลือกวันที่'
                              : DateFormat('dd/MM/yyyy').format(startDate!)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => endDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'วันที่สิ้นสุด'),
                          child: Text(endDate == null
                              ? 'เลือกวันที่'
                              : DateFormat('dd/MM/yyyy').format(endDate!)),
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(controller: shirtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนเสื้อขาว')),
                TextFormField(controller: pantsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนกางเกงขาว')),
                TextFormField(controller: matCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนเสื่อ')),
                TextFormField(controller: pillowCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนหมอน')),
                TextFormField(controller: blanketCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวนผ้าห่ม')),
                TextFormField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'ห้อง/ศาลา/สถานที่พัก')),
                Row(
                  children: [
                    Checkbox(
                      value: withChildren,
                      onChanged: (v) => setState(() => withChildren = v!),
                    ),
                    const Text('มากับเด็ก'),
                    if (withChildren)
                      Expanded(
                        child: TextFormField(
                          controller: childrenCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'จำนวนเด็ก'),
                        ),
                      ),
                  ],
                ),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ',
                    hintText: 'โรคประจำตัว, ไม่ทานเนื้อสัตว์ ฯลฯ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // TODO: save to DB (ใช้ regId เป็น key เชื่อมกับข้อมูลหลัก)
                // ตัวอย่าง: await DbHelper().insertAdditionalInfo(...);
                Navigator.of(context).pop();
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
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