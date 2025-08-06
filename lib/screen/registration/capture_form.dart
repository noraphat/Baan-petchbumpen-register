import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../widgets/registration_dialog.dart';

class CaptureForm extends StatefulWidget {
  const CaptureForm({super.key});

  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  final RegistrationService _registrationService = RegistrationService();
  
  ThaiIDCard? _data;
  UsbDevice? _device;
  dynamic _card;
  String? _error;
  bool _isReading = false;
  bool _isProcessing = false;
  RegData? _currentRegistration;

  @override
  void initState() {
    super.initState();
    // Listen to USB device events
    ThaiIdcardReaderFlutter.deviceHandlerStream.listen(_onUSB);
  }

  void _onUSB(usbEvent) {
    try {
      if (usbEvent.hasPermission) {
        // Listen to card events when device has permission
        ThaiIdcardReaderFlutter.cardHandlerStream.listen(_onData);
      } else {
        // Clear data when no permission
        _clear();
      }
      setState(() {
        _device = usbEvent;
      });
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อเครื่องอ่านบัตร: $e';
      });
      _showErrorDialog();
    }
  }

  void _onData(readerEvent) {
    try {
      setState(() {
        _card = readerEvent;
      });

      if (readerEvent.isReady && !_isReading) {
        _readCard();
      } else {
        _clear();
      }
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาดในการอ่านข้อมูล: $e';
      });
      _showErrorDialog();
    }
  }

  Future<void> _readCard() async {
    if (_isReading) return;
    
    setState(() {
      _isReading = true;
      _error = null;
    });

    try {
      var result = await ThaiIdcardReaderFlutter.read();
      setState(() {
        _data = result;
        _error = null;
      });
      
      // ประมวลผลข้อมูลบัตรประชาชนตาม Logic ที่กำหนด
      await _processCardData(result);
      
    } catch (e) {
      setState(() {
        _error = 'ไม่สามารถอ่านข้อมูลจากบัตรประชาชนได้: $e';
      });
      _showErrorDialog();
    } finally {
      setState(() {
        _isReading = false;
      });
    }
  }

  /// ประมวลผลข้อมูลบัตรประชาชนตามเงื่อนไข Logic
  Future<void> _processCardData(ThaiIDCard cardData) async {
    if (cardData.cid == null) {
      _showErrorDialog('ไม่พบเลขบัตรประชาชน');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final id = cardData.cid!;
      final firstName = cardData.firstnameTH ?? '';
      final lastName = cardData.lastnameTH ?? '';
      final dateOfBirth = cardData.birthdate ?? '';
      final address = cardData.address ?? '';
      final gender = cardData.gender == 1 ? 'ชาย' : 'หญิง';

      // ตรวจสอบข้อมูลเดิมในฐานข้อมูล
      final existingReg = await _registrationService.findExistingRegistration(id);

      if (existingReg == null) {
        // เงื่อนไขที่ 1: มาครั้งแรกพร้อมบัตรประชาชน
        await _handleFirstTimeWithCard(
          id: id,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          address: address,
          gender: gender,
        );
      } else if (existingReg.hasIdCard) {
        // เงื่อนไขที่ 2: มาครั้งที่ 2 ไม่พกบัตร (แต่เคยใช้บัตรแล้ว)
        await _handleReturningWithCard(existingReg);
      } else {
        // เงื่อนไขที่ 4: มาครั้งต่อมาพกบัตรมาครั้งแรก
        await _handleUpgradeToCard(
          existingReg: existingReg,
          id: id,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          address: address,
          gender: gender,
        );
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการประมวลผล: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// เงื่อนไขที่ 1: มาครั้งแรกพร้อมบัตรประชาชน
  Future<void> _handleFirstTimeWithCard({
    required String id,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String address,
    required String gender,
  }) async {
    final regData = await _registrationService.registerWithIdCard(
      id: id,
      first: firstName,
      last: lastName,
      dob: dateOfBirth,
      addr: address,
      gender: gender,
      phone: '',
    );

    if (regData != null) {
      setState(() {
        _currentRegistration = regData;
      });

      _showSuccessMessage('ลงทะเบียนด้วยบัตรประชาชนสำเร็จ');
      _showRegistrationDialog(regData, isFirstTime: true);
    } else {
      _showErrorDialog('ไม่สามารถลงทะเบียนได้');
    }
  }

  /// เงื่อนไขที่ 2: มาครั้งที่ 2 ไม่พกบัตร (แต่เคยใช้บัตรแล้ว)
  Future<void> _handleReturningWithCard(RegData existingReg) async {
    setState(() {
      _currentRegistration = existingReg;
    });

    _showSuccessMessage('พบข้อมูลเดิม - ข้อมูลไม่สามารถแก้ไขได้');
    _showRegistrationDialog(existingReg, isFirstTime: false);
  }

  /// เงื่อนไขที่ 4: มาครั้งต่อมาพกบัตรมาครั้งแรก
  Future<void> _handleUpgradeToCard({
    required RegData existingReg,
    required String id,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String address,
    required String gender,
  }) async {
    final confirmed = await _showUpgradeConfirmDialog(existingReg, {
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'gender': gender,
    });

    if (confirmed == true) {
      final updatedReg = await _registrationService.upgradeToIdCard(
        id: id,
        first: firstName,
        last: lastName,
        dob: dateOfBirth,
        addr: address,
        gender: gender,
        phone: existingReg.phone,
      );

      if (updatedReg != null) {
        setState(() {
          _currentRegistration = updatedReg;
        });

        _showSuccessMessage('อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ');
        _showRegistrationDialog(updatedReg, isFirstTime: false);
      } else {
        _showErrorDialog('ไม่สามารถอัปเกรดข้อมูลได้');
      }
    }
  }

  void _clear() {
    setState(() {
      _data = null;
      _error = null;
    });
  }

  void _showErrorDialog([String? customMessage]) {
    final message = customMessage ?? _error;
    if (message != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    }
  }

  /// แสดงข้อความสำเร็จ
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// แสดง Dialog ยืนยันการอัปเกรด
  Future<bool?> _showUpgradeConfirmDialog(
    RegData existingReg, 
    Map<String, String> cardData,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('อัปเกรดข้อมูลเป็นบัตรประชาชน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'พบข้อมูลเดิมที่ลงทะเบียนแบบ Manual',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text('ข้อมูลเดิม:'),
            Text('ชื่อ-นามสกุล: ${existingReg.first} ${existingReg.last}'),
            Text('วันเกิด: ${existingReg.dob}'),
            Text('เพศ: ${existingReg.gender}'),
            const SizedBox(height: 12),
            
            const Text('ข้อมูลจากบัตร:'),
            Text('ชื่อ-นามสกุล: ${cardData['firstName']} ${cardData['lastName']}'),
            Text('วันเกิด: ${cardData['dateOfBirth']}'),
            Text('เพศ: ${cardData['gender']}'),
            const SizedBox(height: 16),
            
            const Text(
              'ต้องการอัปเดตข้อมูลจากบัตรประชาชนหรือไม่?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              '(หลังจากนี้จะไม่สามารถแก้ไขข้อมูลส่วนตัวได้)',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
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
      barrierDismissible: false,
      builder: (ctx) => RegistrationDialog(
        regData: regData,
        isFirstTime: isFirstTime,
        onCompleted: (additionalInfo) {
          Navigator.pop(ctx); // ปิด registration dialog
          Navigator.pop(context); // กลับไปหน้าเมนู
          
          // แสดงข้อความสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลงทะเบียนเสร็จสิ้น'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy', 'th_TH').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อ่านบัตรประชาชน'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // USB Device Status
            if (_device != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.usb, size: 32),
                  title: Text('${_device!.manufacturerName} ${_device!.productName}'),
                  subtitle: Text(_device!.identifier ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _device!.hasPermission ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _device!.hasPermission ? 'เชื่อมต่อแล้ว' : (_device!.isAttached ? 'เชื่อมต่อ' : 'ไม่เชื่อมต่อ'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Status Messages
            if (_device == null || !_device!.isAttached) ...[
              _buildStatusCard(
                icon: Icons.usb,
                title: 'เสียบเครื่องอ่านบัตร',
                subtitle: 'กรุณาเชื่อมต่อเครื่องอ่านบัตรประชาชน',
                color: Colors.orange,
              ),
            ] else if (_data == null && (_device != null && _device!.hasPermission)) ...[
              _buildStatusCard(
                icon: Icons.credit_card,
                title: 'เสียบบัตรประชาชน',
                subtitle: 'กรุณาเสียบบัตรประชาชนเพื่อเริ่มอ่านข้อมูล',
                color: Colors.blue,
              ),
            ],

            // Reading indicator
            if (_isReading || _isProcessing) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Text(
                        _isReading ? 'กำลังอ่านข้อมูล...' : 'กำลังประมวลผล...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Registration Status Display
            if (_currentRegistration != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentRegistration!.hasIdCard 
                                ? Icons.verified_user 
                                : Icons.person,
                            color: _currentRegistration!.hasIdCard 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'สถานะการลงทะเบียน',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('ชื่อ-นามสกุล: ${_currentRegistration!.first} ${_currentRegistration!.last}'),
                      Text('เลขบัตรประชาชน: ${_currentRegistration!.id}'),
                      Text('สถานะบัตร: ${_currentRegistration!.hasIdCard ? "ใช้บัตรประชาชน" : "ลงทะเบียนแบบ Manual"}'),
                      Text(
                        'การแก้ไข: ${_currentRegistration!.hasIdCard ? "ห้ามแก้ไขข้อมูลส่วนตัว" : "สามารถแก้ไขได้"}',
                        style: TextStyle(
                          color: _currentRegistration!.hasIdCard ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Card Data Display
            if (_data != null) ...[
              const SizedBox(height: 16),
              
              // Photo
              if (_data!.photo.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('รูปภาพ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.memory(
                            Uint8List.fromList(_data!.photo),
                            width: 150,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Personal Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ข้อมูลส่วนตัว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      if (_data!.cid != null) _buildInfoRow('เลขบัตรประชาชน', _data!.cid!),
                      if (_data!.titleTH != null && _data!.firstnameTH != null)
                        _buildInfoRow('ชื่อ-นามสกุล (ไทย)', '${_data!.titleTH} ${_data!.firstnameTH} ${_data!.lastnameTH ?? ''}'),
                      if (_data!.titleEN != null && _data!.firstnameEN != null)
                        _buildInfoRow('ชื่อ-นามสกุล (อังกฤษ)', '${_data!.titleEN} ${_data!.firstnameEN} ${_data!.lastnameEN ?? ''}'),
                      if (_data!.gender != null)
                        _buildInfoRow('เพศ', _data!.gender == 1 ? 'ชาย' : 'หญิง'),
                      if (_data!.birthdate != null)
                        _buildInfoRow('วันเกิด', _formatDate(_data!.birthdate)),
                      if (_data!.address != null)
                        _buildInfoRow('ที่อยู่', _data!.address!),
                      if (_data!.issueDate != null)
                        _buildInfoRow('วันออกบัตร', _formatDate(_data!.issueDate)),
                      if (_data!.expireDate != null)
                        _buildInfoRow('วันหมดอายุ', _formatDate(_data!.expireDate)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}