import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../models/reg_data.dart';
import '../../services/db_helper.dart';
import '../../services/address_service.dart';
import '../../services/menu_settings_service.dart';
import '../../services/printer_service.dart';
import '../../widgets/buddhist_calendar_picker.dart';
import '../../widgets/shared_registration_dialog.dart';
import '../../utils/phone_validator.dart';

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

  // ข้อมูลชั่วคราวสำหรับการลงทะเบียนใหม่
  RegAdditionalInfo? _tempAdditionalInfo;
  bool _hasCompletedStayDialog = false;

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
      debugPrint(
        '❌ ไม่พบข้อมูลผู้ลงทะเบียน: $q - แสดงฟอร์มสำหรับลงทะเบียนใหม่',
      );
      setState(() {
        _found = false;
        _loaded = true;
        _hasCompletedStayDialog = false; // รีเซ็ตสถานะ
        _tempAdditionalInfo = null; // รีเซ็ตข้อมูลชั่วคราว
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
      debugPrint('✅ พบข้อมูลผู้ลงทะเบียน: ${old.first} ${old.last}');

      // เติมข้อมูลพื้นฐานในฟอร์ม
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

      // ตรวจสอบข้อมูลการเข้าพักที่มีอยู่
      await _checkAndShowStayDialog(old.id);
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
              onChanged: (value) => setState(() {}),
            ),
            _buildField(
              label: 'นามสกุล',
              controller: lastCtrl,
              enabled: !_found,
              mandatory: true,
              onChanged: (value) => setState(() {}),
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
                                        '${date.day.toString().padLeft(2, '0')}/'
                                        '${date.month.toString().padLeft(2, '0')}/'
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
              keyboard: TextInputType.number,
              validator: PhoneValidator.validatePhone,
              inputFormatters: PhoneValidator.getPhoneInputFormatters(),
              onChanged: (value) => setState(() {}),
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
              onChanged: (value) => setState(() {}),
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
                    _getButtonText(),
                    key: ValueKey<String>(_getButtonText()),
                  ),
                ),
                onPressed: _canProceed() ? _onSave : null,
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
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        focusNode: focus,
        maxLines: lines,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(labelText: label),
        validator:
            validator ??
            (mandatory && !enabled
                ? null
                : (mandatory
                      ? (v) => (v == null || v.isEmpty) ? 'ระบุ $label' : null
                      : null)),
        onChanged: onChanged,
      ),
    );
  }

  // ฟังก์ชันสำหรับกำหนดข้อความปุ่ม
  String _getButtonText() {
    if (_found) {
      return 'ลงทะเบียน';
    } else if (_hasCompletedStayDialog) {
      return 'ลงทะเบียน';
    } else {
      return 'ดำเนินการต่อ';
    }
  }

  bool _canProceed() {
    if (_found) {
      return true; // ผู้ลงทะเบียนที่มีอยู่แล้ว
    } else {
      // ผู้ลงทะเบียนใหม่ ต้องกรอกข้อมูลครบและโหลดข้อมูลเสร็จแล้ว
      return _loaded && _isFormValid();
    }
  }

  // ตรวจสอบความถูกต้องของฟอร์มสำหรับผู้ลงทะเบียนใหม่
  bool _isFormValid() {
    // ตรวจสอบว่ากรอกข้อมูลครบทุกฟิลด์ที่จำเป็น
    final hasName = firstCtrl.text.trim().isNotEmpty;
    final hasLastName = lastCtrl.text.trim().isNotEmpty;
    final hasDob = dobCtrl.text.trim().isNotEmpty && _selectedDob != null;
    final hasAddress =
        _selProvId != null && _selDistId != null && _selSubId != null;

    // ตรวจสอบความถูกต้องของหมายเลขบัตรประชาชน
    final isValidId = _validateThaiNationalId(searchCtrl.text.trim());

    return hasName && hasLastName && hasDob && hasAddress && isValidId;
  }

  // ตรวจสอบข้อมูลการเข้าพักและแสดง Dialog
  Future<void> _checkAndShowStayDialog(String regId) async {
    try {
      debugPrint('🔍 ตรวจสอบข้อมูลการเข้าพักสำหรับ: $regId');

      // ตรวจสอบในฐานข้อมูลว่า มี Record ที่ endDate มากกว่าวันปัจจุบันหรือไม่
      final db = await DbHelper().db;
      final currentDate = DateTime.now();
      final currentDateStr = DateFormat('yyyy-MM-dd').format(currentDate);

      debugPrint('📅 วันที่ปัจจุบัน: $currentDateStr');

      // ค้นหา Stay record ที่ยังไม่หมดอายุ (endDate >= วันปัจจุบัน)
      final activeStaysResult = await db.rawQuery(
        '''
        SELECT s.*
        FROM stays s
        WHERE s.visitor_id = ? 
        AND s.end_date >= ? 
        AND s.status = 'active'
        ORDER BY s.end_date DESC
        LIMIT 1
      ''',
        [regId, currentDateStr],
      );

      if (activeStaysResult.isNotEmpty) {
        debugPrint('✅ พบข้อมูลการเข้าพักที่ยังไม่หมดอายุ');
        final stayData = activeStaysResult.first;

        // แสดง Dialog พร้อมข้อมูลที่มีอยู่
        await _showStayDialogWithExistingData(regId, stayData);
      } else {
        debugPrint('ℹ️ ไม่พบข้อมูลการเข้าพักที่ยังไม่หมดอายุ แสดงฟอร์มเปล่า');
        // แสดง Dialog แบบค่าเริ่มต้น
        await _showAdditionalInfoDialog(regId);
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการตรวจสอบข้อมูลการเข้าพัก: $e');
      // ในกรณีมีปัญหา ให้แสดง Dialog แบบค่าเริ่มต้น
      await _showAdditionalInfoDialog(regId);
    }
  }

  // แสดง Dialog สำหรับกรอกข้อมูลการเข้าพักใหม่
  Future<void> _showStayDialogForNewRegistration() async {
    debugPrint('📋 เปิด Dialog สำหรับกรอกข้อมูลการเข้าพักใหม่');

    if (!mounted) return;

    try {
      // บันทึกข้อมูลผู้ลงทะเบียนก่อน
      debugPrint('💾 บันทึกข้อมูลผู้ลงทะเบียน');
      await _saveCompleteRegistration();

      // เปิด Dialog สำหรับกรอกข้อมูลการเข้าพัก
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => SharedRegistrationDialog(
          regId: searchCtrl.text.trim(), // ใช้หมายเลขบัตรประชาชนเป็น regId
          existingInfo: null, // ไม่มีข้อมูลเดิม
          latestStay: null, // ไม่มี stay record
          canCreateNew: true, // สร้างใหม่
        ),
      );

      debugPrint('✅ Dialog การเข้าพักถูกปิดแล้ว');

      // กลับไปยังหน้าเมนูลงทะเบียน
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการแสดง Dialog: $e');
      // แสดงข้อความแจ้งเตือน
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการแสดงฟอร์ม: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // บันทึกข้อมูลการลงทะเบียนใหม่ทั้งหมด
  Future<void> _saveCompleteRegistration() async {
    try {
      debugPrint('💾 เริ่มบันทึกข้อมูลการลงทะเบียนใหม่ทั้งหมด');

      // สร้างข้อมูลผู้ลงทะเบียน
      final regData = RegData.manual(
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

      // บันทึกข้อมูลผู้ลงทะเบียน
      await DbHelper().insert(regData);
      debugPrint('✅ บันทึกข้อมูลผู้ลงทะเบียนสำเร็จ');

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลผู้ลงทะเบียนสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // แสดง Dialog พร้อมข้อมูลการเข้าพักที่มีอยู่
  Future<void> _showStayDialogWithExistingData(
    String regId,
    Map<String, dynamic> stayData,
  ) async {
    debugPrint('📋 แสดง Dialog พร้อมข้อมูลที่มีอยู่');
    debugPrint(
      '📅 ข้อมูล Stay: ${stayData['start_date']} - ${stayData['end_date']}',
    );

    try {
      // ดึงข้อมูล reg_additional_info ที่เกี่ยวข้อง
      final db = await DbHelper().db;

      // ค้นหา additional info ที่เกี่ยวข้องกับ stay นี้
      final additionalInfoResult = await db.rawQuery(
        '''
        SELECT ai.*
        FROM reg_additional_info ai
        WHERE ai.regId = ?
        ORDER BY ai.createdAt DESC
        LIMIT 1
      ''',
        [regId],
      );

      RegAdditionalInfo? existingInfo;
      if (additionalInfoResult.isNotEmpty) {
        existingInfo = RegAdditionalInfo.fromMap(additionalInfoResult.first);
        debugPrint(
          '📦 ข้อมูลอุปกรณ์: ${existingInfo.shirtCount} เสื้อ, ${existingInfo.pantsCount} กางเกง',
        );
      } else {
        debugPrint('ℹ️ ไม่พบข้อมูลอุปกรณ์');
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => SharedRegistrationDialog(
          regId: regId,
          existingInfo: existingInfo,
          latestStay: StayRecord.fromMap(stayData),
          canCreateNew: false, // แก้ไขข้อมูลที่มีอยู่
        ),
      );
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการดึงข้อมูลอุปกรณ์: $e');
      // แสดง Dialog แบบค่าเริ่มต้น
      await _showAdditionalInfoDialog(regId);
    }
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

    // กรณีผู้ลงทะเบียนใหม่
    if (!_found) {
      // ตรวจสอบ validation ของฟอร์ม
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

      // เปิด Dialog สำหรับกรอกข้อมูลการเข้าพัก
      debugPrint('📋 เปิด Dialog สำหรับกรอกข้อมูลการเข้าพัก');
      await _showStayDialogForNewRegistration();
      return;
    }

    // กรณีผู้ลงทะเบียนที่มีอยู่แล้ว
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
      builder: (dialogContext) => SharedRegistrationDialog(
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

