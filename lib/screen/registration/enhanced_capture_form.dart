import 'package:flutter/material.dart';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../services/card_reader_service.dart';
import '../../widgets/card_reader_widgets.dart';
import '../../widgets/shared_registration_dialog.dart';

/// Enhanced version ของ CaptureForm ที่ใช้ CardReaderService
class EnhancedCaptureForm extends StatefulWidget {
  const EnhancedCaptureForm({super.key});

  @override
  State<EnhancedCaptureForm> createState() => _EnhancedCaptureFormState();
}

class _EnhancedCaptureFormState extends State<EnhancedCaptureForm>
    with WidgetsBindingObserver {
  final RegistrationService _registrationService = RegistrationService();
  late final CardReaderService _cardReaderService;

  RegData? _currentRegistration;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // เริ่มต้น CardReaderService
    _cardReaderService = CardReaderService();
    _initializeCardReader();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // จัดการ lifecycle ของแอป
    switch (state) {
      case AppLifecycleState.resumed:
        // แอปกลับมาทำงาน - ตรวจสอบการเชื่อมต่อ
        _cardReaderService.checkConnection();
        break;
      case AppLifecycleState.paused:
        // แอปถูกพัก - ไม่ต้องทำอะไร
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // แอปไม่ active - ไม่ต้องทำอะไร
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// เริ่มต้น CardReaderService
  Future<void> _initializeCardReader() async {
    try {
      await _cardReaderService.initialize();
      debugPrint('✅ EnhancedCaptureForm: CardReaderService initialized');
    } catch (e) {
      debugPrint(
        '❌ EnhancedCaptureForm: Failed to initialize CardReaderService - $e',
      );
    }
  }

  /// จัดการเมื่ออ่านบัตรสำเร็จ
  Future<void> _onCardRead(ThaiIdCardData cardData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint(
        '📋 EnhancedCaptureForm: Processing card data for ${cardData.fullNameTH}',
      );

      // ประมวลผลข้อมูลบัตรตาม business logic
      await _processCardData(cardData);
    } catch (e) {
      debugPrint('❌ EnhancedCaptureForm: Error processing card data - $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการประมวลผลข้อมูล: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// ประมวลผลข้อมูลบัตรประชาชนตาม business logic
  Future<void> _processCardData(ThaiIdCardData cardData) async {
    try {
      final id = cardData.cid;
      final firstName = cardData.firstnameTH ?? '';
      final lastName = cardData.lastnameTH ?? '';
      final dateOfBirth = cardData.birthdate ?? '';
      final address = cardData.address ?? '';
      final gender = cardData.genderText;

      // ตรวจสอบข้อมูลเดิมในฐานข้อมูล
      final existingReg = await _registrationService.findExistingRegistration(
        id,
      );

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
        // เงื่อนไขที่ 2: มาครั้งที่ 2 พร้อมบัตร (แต่เคยใช้บัตรแล้ว)
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
      throw Exception('ไม่สามารถประมวลผลข้อมูลบัตรได้: $e');
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

      _showSuccessSnackBar('ลงทะเบียนด้วยบัตรประชาชนสำเร็จ');
      _showRegistrationDialog(regData, isFirstTime: true);
    } else {
      throw Exception('ไม่สามารถลงทะเบียนได้');
    }
  }

  /// เงื่อนไขที่ 2: มาครั้งที่ 2 พร้อมบัตร (แต่เคยใช้บัตรแล้ว)
  Future<void> _handleReturningWithCard(RegData existingReg) async {
    setState(() {
      _currentRegistration = existingReg;
    });

    _showSuccessSnackBar('พบข้อมูลเดิม - ข้อมูลไม่สามารถแก้ไขได้');
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

        _showSuccessSnackBar('อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ');
        _showRegistrationDialog(updatedReg, isFirstTime: false);
      } else {
        throw Exception('ไม่สามารถอัปเกรดข้อมูลได้');
      }
    }
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
            Text(
              'ชื่อ-นามสกุล: ${cardData['firstName']} ${cardData['lastName']}',
            ),
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

  /// แสดง Registration Dialog
  void _showRegistrationDialog(RegData regData, {required bool isFirstTime}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SharedRegistrationDialog(
        regId: regData.id,
        existingInfo: null, // ID Card registration มักเป็นใหม่
        latestStay: null, // ID Card registration มักเป็นใหม่
        canCreateNew: true, // สร้างใหม่เสมอ
        onCompleted: () {
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

  /// แสดงข้อความสำเร็จ
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// แสดงข้อความข้อผิดพลาด
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'ปิด',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// รีเซ็ตการเชื่อมต่อเครื่องอ่านบัตร
  Future<void> _resetCardReader() async {
    try {
      await _cardReaderService.resetConnection();
      _showSuccessSnackBar('รีเซ็ตการเชื่อมต่อสำเร็จ');
    } catch (e) {
      _showErrorSnackBar('ไม่สามารถรีเซ็ตการเชื่อมต่อได้: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อ่านบัตรประชาชน (Enhanced)'),
        centerTitle: true,
        actions: [
          // ปุ่มรีเซ็ต
          IconButton(
            onPressed: _resetCardReader,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเซ็ตการเชื่อมต่อ',
          ),

          // ปุ่มดูสถิติ
          IconButton(
            onPressed: _showUsageStats,
            icon: const Icon(Icons.info_outline),
            tooltip: 'สถิติการใช้งาน',
          ),
        ],
      ),


      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // สถานะการเชื่อมต่อ
              ConnectionStatusWidget(cardReaderService: _cardReaderService),

              const SizedBox(height: 16),

              // สถานะการอ่านบัตร
              CardReadingStatusWidget(cardReaderService: _cardReaderService),

              const SizedBox(height: 16),

              // ปุ่มตรวจสอบบัตรอีกครั้ง
              RecheckCardButton(
                cardReaderService: _cardReaderService,
                onCardRead: _onCardRead,
                onError: _showErrorSnackBar,
              ),

              const SizedBox(height: 16),

              // แสดงสถานะการประมวลผล
              if (_isProcessing) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'กำลังประมวลผลข้อมูล...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // แสดงข้อมูลบัตรล่าสุด
              Builder(
                builder: (context) {
                  final lastReadData = _cardReaderService.lastReadData;

                  if (lastReadData != null) {
                    return CardDataDisplayWidget(cardData: lastReadData);
                  }

                  return const SizedBox.shrink();
                },
              ),

              // แสดงสถานะการลงทะเบียนปัจจุบัน
              if (_currentRegistration != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'ชื่อ-นามสกุล: ${_currentRegistration!.first} ${_currentRegistration!.last}',
                        ),
                        Text('เลขบัตรประชาชน: ${_currentRegistration!.id}'),
                        Text(
                          'สถานะบัตร: ${_currentRegistration!.hasIdCard ? "ใช้บัตรประชาชน" : "ลงทะเบียนแบบ Manual"}',
                        ),
                        Text(
                          'การแก้ไข: ${_currentRegistration!.hasIdCard ? "ห้ามแก้ไขข้อมูลส่วนตัว" : "สามารถแก้ไขได้"}',
                          style: TextStyle(
                            color: _currentRegistration!.hasIdCard
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// แสดงสถิติการใช้งาน
  void _showUsageStats() {
    final stats = _cardReaderService.getUsageStats();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('สถิติการใช้งาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สถานะการเชื่อมต่อ: ${stats['connectionStatus']}'),
            Text('สถานะการอ่าน: ${stats['readingStatus']}'),
            Text('มีเครื่องอ่าน: ${stats['hasDevice'] ? 'ใช่' : 'ไม่'}'),
            if (stats['deviceName'] != null)
              Text('ชื่ออุปกรณ์: ${stats['deviceName']}'),
            if (stats['lastReadTime'] != null)
              Text('อ่านล่าสุด: ${stats['lastReadTime']}'),
            if (stats['lastError'] != null)
              Text('ข้อผิดพลาดล่าสุด: ${stats['lastError']}'),
          ],
        ),
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
