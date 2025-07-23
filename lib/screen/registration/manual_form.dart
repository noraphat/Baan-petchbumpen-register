import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import '../../models/reg_data.dart';
import '../../services/db_helper.dart';
import '../../services/address_service.dart';
import '../../services/menu_settings_service.dart';
import '../../services/printer_service.dart';
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
  final List<String> _genders = [
    'พระ',
    'สามเณร',
    'แม่ชี',
    'ชาย',
    'หญิง',
    'อื่นๆ',
  ];
  bool _found = true;
  bool _loaded = false;
  final _formKey = GlobalKey<FormState>();
  final _firstFocus = FocusNode();

  DateTime? _selectedDob;

  // Thai National ID validation
  String? _idValidationMessage;
  bool _isIdValid = true;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    await AddressService().init();
    setState(() {});
  }

  // Thai National ID validation algorithm
  bool _validateThaiNationalId(String id) {
    if (id.length != 13) return false;

    // ตรวจสอบว่าเป็นตัวเลขทั้งหมด
    if (!RegExp(r'^\d{13}$').hasMatch(id)) return false;

    // คำนวณ checksum
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(id[i]) * (13 - i);
    }

    int remainder = sum % 11;
    int checkDigit = (11 - remainder) % 10;

    return checkDigit == int.parse(id[12]);
  }

  void _validateIdWithDelay(String value) {
    _validationTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _idValidationMessage = null;
        _isIdValid = true;
      });
      return;
    }

    _validationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final isValid = _validateThaiNationalId(value);
        setState(() {
          _isIdValid = isValid;
          _idValidationMessage = isValid
              ? null
              : 'โปรดตรวจสอบหมายเลขบัตรประชาชนอีกครั้ง';
        });
      }
    });
  }

  Future<void> _search() async {
    final q = searchCtrl.text.trim();
    if (q.length < 5) return;

    // ตรวจสอบความถูกต้องของหมายเลขบัตรประชาชนก่อนค้นหา
    if (!_validateThaiNationalId(q)) {
      setState(() {
        _isIdValid = false;
        _idValidationMessage = 'โปรดตรวจสอบหมายเลขบัตรประชาชนอีกครั้ง';
        _found = true; // บล็อกการแก้ไขฟอร์ม
        _loaded = true;
        // เคลียร์ข้อมูลในฟอร์ม
        firstCtrl.clear();
        lastCtrl.clear();
        dobCtrl.clear();
        phoneCtrl.clear();
        addrCtrl.clear();
        _gender = 'ชาย';
        _selProvId = _selDistId = _selSubId = null;
        _selectedDob = null;
      });

      // แสดง AlertDialog เตือนผู้ใช้
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'หมายเลขบัตรประชาชนไม่ถูกต้อง',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
            content: const Text(
              'กรุณาตรวจสอบหมายเลขบัตรประชาชน\nให้ถูกต้องตามรูปแบบมาตรฐาน (13 หลัก)',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
      return;
    }

    // ถ้าหมายเลขถูกต้อง ให้ดำเนินการค้นหาต่อ
    setState(() {
      _isIdValid = true;
      _idValidationMessage = null;
    });

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
      if (mounted) {
        FocusScope.of(context).requestFocus(_firstFocus);
      }
    } else {
      setState(() {
        _found = true;
        _loaded = true;
        firstCtrl.text = old.first;
        lastCtrl.text = old.last;
        // แก้ไขการ parse dob ให้ robust
        try {
          _selectedDob = DateFormat('d MMMM yyyy', 'th_TH').parse(old.dob);
        } catch (e) {
          _selectedDob = null;
        }
        dobCtrl.text = old.dob;
        phoneCtrl.text = old.phone.trim();

        final addrParts = old.addr.split(RegExp(r',\s*'));
        if (addrParts.length >= 3) {
          final provinceName = addrParts[0].trim();
          final prov = AddressService().provinces.firstWhere(
            (p) => p.nameTh.trim() == provinceName,
            orElse: () {
              debugPrint('ไม่พบจังหวัด: $provinceName ใน AddressService');
              return AddressService().provinces.first;
            },
          );
          _selProvId = prov.id;

          final districtName = addrParts[1].trim();
          final dist = AddressService()
              .districtsOf(prov.id)
              .firstWhere(
                (d) => d.nameTh.trim() == districtName,
                orElse: () => AddressService().districtsOf(prov.id).first,
              );
          _selDistId = dist.id;

          final subDistrictName = addrParts[2].trim();
          final sub = AddressService()
              .subsOf(dist.id)
              .firstWhere(
                (s) => s.nameTh.trim() == subDistrictName,
                orElse: () => AddressService().subsOf(dist.id).first,
              );
          _selSubId = sub.id;

          addrCtrl.text = addrParts.length > 3
              ? addrParts.sublist(3).join(', ')
              : '';
        } else {
          final prov = AddressService().provinces.firstWhere(
            (p) => old.addr.contains(p.nameTh),
            orElse: () => AddressService().provinces.first,
          );
          _selProvId = prov.id;

          final dist = AddressService()
              .districtsOf(prov.id)
              .firstWhere(
                (d) => old.addr.contains(d.nameTh),
                orElse: () => AddressService().districtsOf(prov.id).first,
              );
          _selDistId = dist.id;

          final sub = AddressService()
              .subsOf(dist.id)
              .firstWhere(
                (s) => old.addr.contains(s.nameTh),
                orElse: () => AddressService().subsOf(dist.id).first,
              );
          _selSubId = sub.id;

          addrCtrl.text = '';
        }

        _gender = old.gender;
      });
      await _showAdditionalInfoDialog(old.id);
    }
  }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: searchCtrl,
                  maxLength: 13,
                  enabled: true, // ให้สามารถใส่ค่าได้เสมอ
                  decoration: InputDecoration(
                    labelText: 'หมายเลขประชาชน (ค้นหา)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      tooltip: 'ค้นหา',
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      onPressed: _search,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isIdValid
                            ? Colors.grey
                            : Colors.orange.shade300,
                        width: _isIdValid ? 1.0 : 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isIdValid
                            ? Colors.grey
                            : Colors.orange.shade300,
                        width: _isIdValid ? 1.0 : 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _isIdValid
                            ? Colors.blue
                            : Colors.orange.shade400,
                        width: 2.0,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (_) => _search(),
                  onChanged: _validateIdWithDelay,
                ),
                if (_idValidationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _idValidationMessage!,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'ชื่อ',
              controller: firstCtrl,
              enabled: !_found,
              mandatory: true,
              focus: _firstFocus,
            ),
            _buildField(
              label: 'นามสกุล',
              controller: lastCtrl,
              enabled: !_found,
              mandatory: true,
            ),
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
                                    dobCtrl.text =
                                        '${date.day} '
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
            _buildField(
              label: 'เบอร์โทรศัพท์',
              controller: phoneCtrl,
              enabled: true,
              keyboard: TextInputType.phone,
              onChanged: null,
            ),
            DropdownButtonFormField<int>(
              value: _selProvId,
              decoration: const InputDecoration(labelText: 'จังหวัด'),
              items: AddressService().provinces
                  .map(
                    (p) => DropdownMenuItem(value: p.id, child: Text(p.nameTh)),
                  )
                  .toList(),
              onChanged: _found
                  ? null
                  : (v) => setState(() {
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
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.nameTh),
                          ),
                        )
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
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nameTh),
                          ),
                        )
                        .toList(),
              onChanged: (_selDistId == null || _found)
                  ? null
                  : (v) => setState(() => _selSubId = v),
            ),
            const SizedBox(height: 12),
            _buildField(
              label: 'ที่อยู่เพิ่มเติม (บ้านเลขที่ ฯลฯ)',
              controller: addrCtrl,
              lines: 2,
              enabled: !_found,
            ),
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
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
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
                  child: Text(
                    _found ? 'ลงทะเบียน' : 'ดำเนินการต่อ',
                    key: ValueKey<bool>(_found),
                  ),
                ),
                onPressed: _onSave,
              ),
            ),
          ],
        ),
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
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
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
            : (mandatory
                  ? (v) => (v == null || v.isEmpty) ? 'ระบุ $label' : null
                  : null),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _onSave() async {
    // ถ้ายังไม่ได้ค้นหา ให้ทำการค้นหาแทน
    if (!_loaded) {
      await _search();
      return;
    }

    // ตรวจสอบความถูกต้องของหมายเลขบัตรประชาชนก่อนบันทึก
    final q = searchCtrl.text.trim();
    if (!_validateThaiNationalId(q)) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ไม่สามารถบันทึกได้',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
          content: const Text(
            'กรุณาตรวจสอบหมายเลขบัตรประชาชน\nให้ถูกต้องก่อนบันทึกข้อมูล',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      return;
    }

    // ถ้าเป็นกรณีใหม่ (ไม่มีข้อมูลเดิม) ให้ตรวจสอบ validation
    if (!_found) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedDob == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกวันเกิด')));
        return;
      }
      if (_selProvId == null || _selDistId == null || _selSubId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือก จังหวัด / อำเภอ / ตำบล')),
        );
        return;
      }
    }

    // ถ้าเป็นกรณีใหม่ ให้บันทึกข้อมูลก่อน
    if (!_found) {
      final data = RegData.manual(
        id: searchCtrl.text.trim(),
        first: firstCtrl.text.trim(),
        last: lastCtrl.text.trim(),
        dob: dobCtrl.text,
        phone: phoneCtrl.text.trim(),
        addr:
            '${AddressService().provinces.firstWhere((p) => p.id == _selProvId!).nameTh}, '
            '${AddressService().districtsOf(_selProvId!).firstWhere((d) => d.id == _selDistId!).nameTh}, '
            '${AddressService().subsOf(_selDistId!).firstWhere((s) => s.id == _selSubId!).nameTh}'
            '${addrCtrl.text.trim().isNotEmpty ? ', ${addrCtrl.text.trim()}' : ''}',
        gender: _gender,
      );

      await DbHelper().insert(data);
      await _showAdditionalInfoDialog(data.id);
      // ไม่ต้อง pop context ซ้ำที่นี่
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _showAdditionalInfoDialog(String regId) async {
    if (!mounted) return;

    // ตรวจสอบสถานะการเข้าพักปัจจุบัน
    final stayStatus = await DbHelper().checkStayStatus(regId);
    final latestStay = stayStatus['latestStay'] as StayRecord?;
    final canCreateNew = stayStatus['canCreateNew'] as bool;

    // โหลดข้อมูลเพิ่มเติมที่มีอยู่แล้ว (equipment info)
    final existingInfo = await DbHelper().fetchAdditionalInfo(regId);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _AdditionalInfoDialog(
        regId: regId,
        existingInfo: existingInfo,
        latestStay: latestStay,
        canCreateNew: canCreateNew,
      ),
    );
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
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

class _AdditionalInfoDialog extends StatefulWidget {
  final String regId;
  final RegAdditionalInfo? existingInfo;
  final StayRecord? latestStay;
  final bool canCreateNew;

  const _AdditionalInfoDialog({
    required this.regId,
    this.existingInfo,
    this.latestStay,
    this.canCreateNew = true,
  });

  @override
  State<_AdditionalInfoDialog> createState() => _AdditionalInfoDialogState();
}

class _AdditionalInfoDialogState extends State<_AdditionalInfoDialog> {
  DateTime? startDate;
  DateTime? endDate;
  late final TextEditingController shirtCtrl;
  late final TextEditingController pantsCtrl;
  late final TextEditingController matCtrl;
  late final TextEditingController pillowCtrl;
  late final TextEditingController blanketCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController childrenCtrl;
  bool withChildren = false;

  @override
  void initState() {
    super.initState();

    // สร้าง controllers
    shirtCtrl = TextEditingController();
    pantsCtrl = TextEditingController();
    matCtrl = TextEditingController();
    pillowCtrl = TextEditingController();
    blanketCtrl = TextEditingController();
    locationCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    childrenCtrl = TextEditingController();

    // โหลดข้อมูลการเข้าพัก - อ่านจาก stays table เสมอ
    if (widget.latestStay != null && !widget.canCreateNew) {
      // กรณีแก้ไขการเข้าพักที่มีอยู่ - ใช้ข้อมูลจาก stays table
      final stay = widget.latestStay!;
      startDate = stay.startDate;
      endDate = stay.endDate;
      notesCtrl.text = stay.note ?? '';
    } else {
      // กรณีสร้างการเข้าพักใหม่ - ตั้งค่าเริ่มต้นเป็นวันเดียวกัน
      final today = DateTime.now();
      startDate = today;
      endDate = today; // เริ่มต้นเป็นวันเดียวกัน (1 วัน)
    }

    // โหลดข้อมูลอุปกรณ์ที่มีอยู่แล้ว
    if (widget.existingInfo != null) {
      final info = widget.existingInfo!;
      shirtCtrl.text = info.shirtCount?.toString() ?? '0';
      pantsCtrl.text = info.pantsCount?.toString() ?? '0';
      matCtrl.text = info.matCount?.toString() ?? '0';
      pillowCtrl.text = info.pillowCount?.toString() ?? '0';
      blanketCtrl.text = info.blanketCount?.toString() ?? '0';
      locationCtrl.text = info.location ?? '';
      withChildren = info.withChildren;
      childrenCtrl.text = info.childrenCount?.toString() ?? '0';

      // หมายเหตุ: ถ้าไม่มี stays record ให้ใช้จาก additional_info
      if (notesCtrl.text.isEmpty && info.notes?.isNotEmpty == true) {
        notesCtrl.text = info.notes!;
      }
    } else {
      // ตั้งค่าเริ่มต้น
      shirtCtrl.text = '0';
      pantsCtrl.text = '0';
      matCtrl.text = '0';
      pillowCtrl.text = '0';
      blanketCtrl.text = '0';
      childrenCtrl.text = '1'; // ค่าเริ่มต้นเป็น 1
    }
  }

  @override
  void dispose() {
    shirtCtrl.dispose();
    pantsCtrl.dispose();
    matCtrl.dispose();
    pillowCtrl.dispose();
    blanketCtrl.dispose();
    locationCtrl.dispose();
    notesCtrl.dispose();
    childrenCtrl.dispose();
    super.dispose();
  }

  void _updateNumberField(
    TextEditingController controller,
    int change, {
    int min = 0,
    int max = 9,
  }) {
    final currentValue = int.tryParse(controller.text) ?? min;
    final newValue = (currentValue + change).clamp(min, max);
    setState(() {
      controller.text = newValue.toString();
    });
  }

  // ตรวจสอบความถูกต้องของวันที่
  String? _validateDates() {
    if (startDate == null || endDate == null) {
      return 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateOnly = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);

    // 1. วันที่เริ่มต้น ต้องไม่มากกว่าวันที่ปัจจุบัน
    if (startDateOnly.isAfter(today)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่ปัจจุบัน';
    }

    // 2. วันที่เริ่มต้น ต้องไม่มากกว่าวันที่สิ้นสุด (สามารถเป็นวันเดียวกันได้)
    if (startDateOnly.isAfter(endDateOnly)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่สิ้นสุด';
    }

    // 3. วันที่สิ้นสุด ต้องไม่น้อยกว่าวันที่ปัจจุบัน (ถ้าเป็นการสร้างใหม่หรือแก้ไข active stay)
    if (!widget.canCreateNew || (widget.latestStay?.isActive ?? false)) {
      if (endDateOnly.isBefore(today)) {
        return 'วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่ปัจจุบัน';
      }
    }

    return null;
  }

  // บันทึกข้อมูล
  Future<void> _saveStayData() async {
    final dateValidation = _validateDates();
    if (dateValidation != null) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text('ข้อผิดพลาด', style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Text(dateValidation, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      // บันทึกหรืออัพเดต Stay record
      StayRecord? stayRecordForPrint;
      if (widget.canCreateNew) {
        // สร้าง Stay ใหม่
        final newStay = StayRecord.create(
          visitorId: widget.regId,
          startDate: startDate!,
          endDate: endDate!,
          note: notesCtrl.text.trim(),
        );
        await DbHelper().insertStay(newStay);
        stayRecordForPrint = newStay;
      } else if (widget.latestStay != null) {
        // อัพเดต Stay ที่มีอยู่
        final updatedStay = widget.latestStay!.copyWith(
          startDate: startDate,
          endDate: endDate,
          note: notesCtrl.text.trim(),
        );
        await DbHelper().updateStay(updatedStay);
        stayRecordForPrint = updatedStay;
      }

      // บันทึกข้อมูลอุปกรณ์ (ไม่เก็บ startDate/endDate ใน additional_info เพราะย้ายไป stays table แล้ว)
      final additionalInfo = RegAdditionalInfo.create(
        regId: widget.regId,
        startDate: null, // ไม่เก็บในนี้แล้ว ให้อ่านจาก stays table
        endDate: null, // ไม่เก็บในนี้แล้ว ให้อ่านจาก stays table
        shirtCount: int.tryParse(shirtCtrl.text) ?? 0,
        pantsCount: int.tryParse(pantsCtrl.text) ?? 0,
        matCount: int.tryParse(matCtrl.text) ?? 0,
        pillowCount: int.tryParse(pillowCtrl.text) ?? 0,
        blanketCount: int.tryParse(blanketCtrl.text) ?? 0,
        location: locationCtrl.text.trim(),
        withChildren: withChildren,
        childrenCount: withChildren
            ? (int.tryParse(childrenCtrl.text) ?? 0)
            : null,
        notes: '', // หมายเหตุย้ายไป stays table แล้ว
      );

      await DbHelper().insertAdditionalInfo(additionalInfo);

      // ตรวจสอบสถานะเมนูเบิกชุดขาว
      final isWhiteRobeEnabled = await MenuSettingsService().isWhiteRobeEnabled;

      if (isWhiteRobeEnabled) {
        // สร้าง QR Code จากข้อมูลการเข้าพัก และพิมพ์ใบเสร็จ
        final regData = await DbHelper().fetchById(widget.regId);
        if (regData != null) {
          await PrinterService().printReceipt(
            regData,
            additionalInfo: additionalInfo,
            stayRecord: stayRecordForPrint,
          );
        }
      }
      // ถ้าเมนูเบิกชุดขาวปิดอยู่ ไม่ต้องพิมพ์ใบเสร็จ

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'เกิดข้อผิดพลาด',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            content: Text(
              'ไม่สามารถบันทึกข้อมูลได้: $e',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // ปุ่มลดค่า (-)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onDecrease,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.remove, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Field แสดงตัวเลข
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              readOnly: true,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // ปุ่มเพิ่มค่า (+)
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: onIncrease,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.canCreateNew ? 'ลงทะเบียนเข้าพักใหม่' : 'แก้ไขข้อมูลการเข้าพัก',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9, // กำหนดความกว้าง
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // เพิ่ม padding รอบๆ
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // วันที่เริ่มต้น
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่เริ่มต้น',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                startDate == null
                                    ? 'เลือกวันที่'
                                    : DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(startDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // วันที่สิ้นสุด
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        setState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วันที่สิ้นสุด',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                endDate == null
                                    ? 'เลือกวันที่'
                                    : DateFormat('dd/MM/yyyy').format(endDate!),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ส่วนของอุปกรณ์
                _buildNumberField(
                  label: 'จำนวนเสื้อขาว',
                  controller: shirtCtrl,
                  onDecrease: () => _updateNumberField(shirtCtrl, -1),
                  onIncrease: () => _updateNumberField(shirtCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนกางเกงขาว',
                  controller: pantsCtrl,
                  onDecrease: () => _updateNumberField(pantsCtrl, -1),
                  onIncrease: () => _updateNumberField(pantsCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนเสื่อ',
                  controller: matCtrl,
                  onDecrease: () => _updateNumberField(matCtrl, -1),
                  onIncrease: () => _updateNumberField(matCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนหมอน',
                  controller: pillowCtrl,
                  onDecrease: () => _updateNumberField(pillowCtrl, -1),
                  onIncrease: () => _updateNumberField(pillowCtrl, 1),
                ),
                _buildNumberField(
                  label: 'จำนวนผ้าห่ม',
                  controller: blanketCtrl,
                  onDecrease: () => _updateNumberField(blanketCtrl, -1),
                  onIncrease: () => _updateNumberField(blanketCtrl, 1),
                ),
                // ข้อมูลเพิ่มเติม
                const SizedBox(height: 8),
                TextFormField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ห้อง/ศาลา/สถานที่พัก',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: withChildren,
                      onChanged: (v) =>
                          setState(() => withChildren = v ?? false),
                    ),
                    const Text('มากับเด็ก'),
                  ],
                ),
                if (withChildren) ...[
                  const SizedBox(height: 8),
                  _buildNumberField(
                    label: 'จำนวนเด็ก',
                    controller: childrenCtrl,
                    onDecrease: () =>
                        _updateNumberField(childrenCtrl, -1, min: 1, max: 9),
                    onIncrease: () =>
                        _updateNumberField(childrenCtrl, 1, min: 1, max: 9),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'หมายเหตุ',
                    hintText: 'โรคประจำตัว, ไม่ทานเนื้อสัตว์ ฯลฯ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saveStayData, child: const Text('บันทึก')),
        TextButton(
          onPressed: () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
