import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../services/card_reader_service.dart';
import '../../widgets/registration_dialog.dart';

/// หน้าจอลงทะเบียนอัจฉริยะ
/// รองรับทั้ง 4 กรณีการใช้งาน:
/// 1. มาครั้งแรกพร้อมบัตรประชาชน
/// 2. มาครั้งที่ 2 ไม่พกบัตร
/// 3. มาครั้งแรกไม่ใช้บัตร
/// 4. มาครั้งต่อมาแล้วพกบัตรมาครั้งแรก
class SmartRegistrationScreen extends StatefulWidget {
  const SmartRegistrationScreen({super.key});

  @override
  State<SmartRegistrationScreen> createState() => _SmartRegistrationScreenState();
}

class _SmartRegistrationScreenState extends State<SmartRegistrationScreen> {
  final RegistrationService _registrationService = RegistrationService();
  final CardReaderService _cardReaderService = CardReaderService();
  
  // Controllers สำหรับฟอร์มกรอกข้อมูลแมนนวล
  final _idController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();

  CardReaderStatus _cardReaderStatus = CardReaderStatus.disconnected;
  RegData? _currentRegistration;
  bool _isCardReaderMode = false;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeCardReader();
    _setupCardReaderListeners();
  }

  @override
  void dispose() {
    _cardReaderService.stopReading();
    _cardReaderService.disconnect();
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  /// เริ่มต้นเครื่องอ่านบัตร
  void _initializeCardReader() async {
    final success = await _cardReaderService.initialize();
    if (success) {
      setState(() {
        _statusMessage = 'เครื่องอ่านบัตรพร้อมใช้งาน';
      });
    } else {
      setState(() {
        _statusMessage = 'ไม่สามารถเชื่อมต่อเครื่องอ่านบัตรได้';
      });
    }
  }

  /// ตั้งค่า listener สำหรับเครื่องอ่านบัตร
  void _setupCardReaderListeners() {
    // ติดตามสถานะเครื่องอ่านบัตร
    _cardReaderService.statusStream.listen((status) {
      setState(() {
        _cardReaderStatus = status;
        _statusMessage = _getStatusMessage(status);
      });
    });

    // รับข้อมูลจากบัตรประชาชน
    _cardReaderService.cardDataStream.listen((cardData) {
      _handleCardData(cardData);
    });

    // รับข้อความข้อผิดพลาด
    _cardReaderService.errorStream.listen((error) {
      _showErrorDialog('ข้อผิดพลาด', error);
    });
  }

  /// จัดการข้อมูลที่ได้จากการอ่านบัตร
  void _handleCardData(IdCardData cardData) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังประมวลผลข้อมูล...';
    });

    try {
      // ตรวจสอบว่ามีข้อมูลเดิมหรือไม่
      final existing = await _registrationService.findExistingRegistration(cardData.id);

      if (existing == null) {
        // กรณีที่ 1: มาครั้งแรกพร้อมบัตรประชาชน
        await _handleFirstTimeWithCard(cardData);
      } else if (existing.hasIdCard) {
        // กรณีที่ 2: มาครั้งที่ 2 ไม่พกบัตร (แต่เคยใช้บัตรแล้ว)
        await _handleReturningWithCard(existing);
      } else {
        // กรณีที่ 4: มาครั้งต่อมาแล้วพกบัตรมาครั้งแรก
        await _handleUpgradeToCard(cardData, existing);
      }
    } catch (e) {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถประมวลผลข้อมูลได้: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// กรณีที่ 1: มาครั้งแรกพร้อมบัตรประชาชน
  Future<void> _handleFirstTimeWithCard(IdCardData cardData) async {
    final regData = await _registrationService.registerWithIdCard(
      id: cardData.id,
      first: cardData.firstName,
      last: cardData.lastName,
      dob: cardData.dateOfBirth,
      addr: cardData.address,
      gender: cardData.gender,
      phone: '',
    );

    if (regData != null) {
      setState(() {
        _currentRegistration = regData;
        _statusMessage = 'ลงทะเบียนด้วยบัตรประชาชนสำเร็จ';
      });
      
      _showRegistrationDialog(regData, isFirstTime: true);
    } else {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถลงทะเบียนได้');
    }
  }

  /// กรณีที่ 2: มาครั้งที่ 2 ไม่พกบัตร (แต่เคยใช้บัตรแล้ว)
  Future<void> _handleReturningWithCard(RegData existing) async {
    setState(() {
      _currentRegistration = existing;
      _statusMessage = 'พบข้อมูลเดิม - ไม่สามารถแก้ไขได้';
    });

    _showRegistrationDialog(existing, isFirstTime: false);
  }

  /// กรณีที่ 4: มาครั้งต่อมาแล้วพกบัตรมาครั้งแรก
  Future<void> _handleUpgradeToCard(IdCardData cardData, RegData existing) async {
    final result = await _showUpgradeDialog(cardData, existing);
    
    if (result == true) {
      final updatedData = await _registrationService.upgradeToIdCard(
        id: cardData.id,
        first: cardData.firstName,
        last: cardData.lastName,
        dob: cardData.dateOfBirth,
        addr: cardData.address,
        gender: cardData.gender,
        phone: existing.phone,
      );

      if (updatedData != null) {
        setState(() {
          _currentRegistration = updatedData;
          _statusMessage = 'อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ';
        });

        _showRegistrationDialog(updatedData, isFirstTime: false);
      }
    } else {
      setState(() {
        _statusMessage = 'ยกเลิกการอัปเกรดข้อมูล';
      });
    }
  }

  /// เริ่มการอ่านบัตรประชาชน
  void _startCardReading() async {
    final success = await _cardReaderService.startReading();
    if (success) {
      setState(() {
        _isCardReaderMode = true;
      });
    } else {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถเริ่มอ่านบัตรได้');
    }
  }

  /// หยุดการอ่านบัตร
  void _stopCardReading() async {
    await _cardReaderService.stopReading();
    setState(() {
      _isCardReaderMode = false;
    });
  }

  /// ลงทะเบียนแบบ Manual (กรณีที่ 3)
  void _registerManually() async {
    if (!_validateManualForm()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังลงทะเบียน...';
    });

    try {
      final regData = await _registrationService.registerManual(
        id: _idController.text,
        first: _firstNameController.text,
        last: _lastNameController.text,
        dob: _dobController.text,
        phone: _phoneController.text,
        addr: _addressController.text,
        gender: _genderController.text,
      );

      if (regData != null) {
        setState(() {
          _currentRegistration = regData;
          _statusMessage = 'ลงทะเบียนแบบ Manual สำเร็จ';
        });

        _showRegistrationDialog(regData, isFirstTime: true);
      } else {
        _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถลงทะเบียนได้');
      }
    } catch (e) {
      _showErrorDialog('ข้อผิดพลาด', 'เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ค้นหาข้อมูลเดิม
  void _searchExisting() async {
    final id = _idController.text.trim();
    if (id.isEmpty) {
      _showErrorDialog('ข้อผิดพลาด', 'กรุณาใส่เลขบัตรประชาชน');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังค้นหาข้อมูล...';
    });

    try {
      final existing = await _registrationService.findExistingRegistration(id);
      
      if (existing != null) {
        setState(() {
          _currentRegistration = existing;
          _statusMessage = 'พบข้อมูลเดิม';
        });

        _fillFormWithExistingData(existing);
        _showRegistrationDialog(existing, isFirstTime: false);
      } else {
        _showErrorDialog('ไม่พบข้อมูล', 'ไม่พบข้อมูลการลงทะเบียน');
      }
    } catch (e) {
      _showErrorDialog('ข้อผิดพลาด', 'เกิดข้อผิดพลาดในการค้นหา: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// เติมข้อมูลเดิมในฟอร์ม
  void _fillFormWithExistingData(RegData regData) {
    _idController.text = regData.id;
    _firstNameController.text = regData.first;
    _lastNameController.text = regData.last;
    _dobController.text = regData.dob;
    _phoneController.text = regData.phone;
    _addressController.text = regData.addr;
    _genderController.text = regData.gender;
  }

  /// ตรวจสอบความถูกต้องของฟอร์ม Manual
  bool _validateManualForm() {
    if (_idController.text.trim().isEmpty) {
      _showErrorDialog('ข้อผิดพลาด', 'กรุณาใส่เลขบัตรประชาชน');
      return false;
    }
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorDialog('ข้อผิดพลาด', 'กรุณาใส่ชื่อ');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorDialog('ข้อผิดพลาด', 'กรุณาใส่นามสกุล');
      return false;
    }
    return true;
  }

  /// แสดง Dialog สำหรับการอัปเกรด
  Future<bool?> _showUpgradeDialog(IdCardData cardData, RegData existing) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อัปเกรดข้อมูลเป็นบัตรประชาชน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('พบข้อมูลเดิมที่กรอกแบบ Manual'),
            const SizedBox(height: 16),
            const Text('ข้อมูลจากบัตร:'),
            Text('ชื่อ-นามสกุล: ${cardData.firstName} ${cardData.lastName}'),
            Text('วันเกิด: ${cardData.dateOfBirth}'),
            const SizedBox(height: 16),
            const Text('ต้องการอัปเกรดข้อมูลหรือไม่?'),
            const Text('(หลังจากนี้จะไม่สามารถแก้ไขข้อมูลส่วนตัวได้)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('อัปเกรด'),
          ),
        ],
      ),
    );
  }

  /// แสดง Dialog การลงทะเบียน
  void _showRegistrationDialog(RegData regData, {required bool isFirstTime}) {
    showDialog(
      context: context,
      builder: (context) => RegistrationDialog(
        regData: regData,
        isFirstTime: isFirstTime,
        onCompleted: (additionalInfo) {
          setState(() {
            _statusMessage = 'ลงทะเบียนเสร็จสิ้น';
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// แสดง Dialog ข้อผิดพลาด
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  /// แปลงสถานะเป็นข้อความ
  String _getStatusMessage(CardReaderStatus status) {
    switch (status) {
      case CardReaderStatus.disconnected:
        return 'เครื่องอ่านบัตรไม่ได้เชื่อมต่อ';
      case CardReaderStatus.connected:
        return 'เครื่องอ่านบัตรพร้อมใช้งาน';
      case CardReaderStatus.waiting:
        return 'กรุณาใส่บัตรประชาชน';
      case CardReaderStatus.reading:
        return 'กำลังอ่านข้อมูลจากบัตร...';
      case CardReaderStatus.error:
        return 'เครื่องอ่านบัตรเกิดข้อผิดพลาด';
    }
  }

  /// ตรวจสอบว่าฟิลด์แก้ไขได้หรือไม่
  bool _canEditField(String fieldName) {
    if (_currentRegistration == null) return true;
    return _registrationService.canEditField(_currentRegistration!, fieldName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนผู้ปฏิบัติธรรม'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แสดงสถานะ
            Card(
              color: _cardReaderStatus == CardReaderStatus.connected
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _statusMessage ?? 'กำลังเริ่มต้นระบบ...',
                  style: TextStyle(
                    color: _cardReaderStatus == CardReaderStatus.connected
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ปุ่มเครื่องอ่านบัตร
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cardReaderStatus == CardReaderStatus.connected &&
                            !_isCardReaderMode
                        ? _startCardReading
                        : null,
                    icon: const Icon(Icons.credit_card),
                    label: const Text('อ่านบัตรประชาชน'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isCardReaderMode)
                  ElevatedButton(
                    onPressed: _stopCardReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('หยุด'),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 20),

            // ฟอร์มกรอกข้อมูลแบบ Manual
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'หรือกรอกข้อมูลเอง',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // เลขบัตรประชาชน
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'เลขบัตรประชาชน',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(13),
                      ],
                      enabled: _canEditField('id'),
                    ),
                    const SizedBox(height: 16),

                    // ชื่อ
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _canEditField('first'),
                    ),
                    const SizedBox(height: 16),

                    // นามสกุล
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'นามสกุล',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _canEditField('last'),
                    ),
                    const SizedBox(height: 16),

                    // วันเกิด
                    TextFormField(
                      controller: _dobController,
                      decoration: const InputDecoration(
                        labelText: 'วันเกิด (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _canEditField('dob'),
                    ),
                    const SizedBox(height: 16),

                    // เบอร์โทร
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: _canEditField('phone'),
                    ),
                    const SizedBox(height: 16),

                    // ที่อยู่
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'ที่อยู่',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: _canEditField('addr'),
                    ),
                    const SizedBox(height: 16),

                    // เพศ
                    TextFormField(
                      controller: _genderController,
                      decoration: const InputDecoration(
                        labelText: 'เพศ',
                        border: OutlineInputBorder(),
                      ),
                      enabled: _canEditField('gender'),
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มดำเนินการ
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _searchExisting,
                            child: const Text('ค้นหาข้อมูลเดิม'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerManually,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ลงทะเบียนใหม่'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}