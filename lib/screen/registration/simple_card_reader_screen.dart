import 'package:flutter/material.dart';
import 'dart:async';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import '../../services/card_reader_service.dart';
import '../../widgets/card_reader_widgets.dart';
import '../../widgets/unified_registration_dialog.dart';
import '../../models/reg_data.dart';

/// หน้าอ่านบัตรประชาชนแบบง่าย (Simple)
/// จัดการ lifecycle และ permission ได้ดีขึ้น
class SimpleCardReaderScreen extends StatefulWidget {
  const SimpleCardReaderScreen({super.key});

  @override
  State<SimpleCardReaderScreen> createState() => _SimpleCardReaderScreenState();
}

class _SimpleCardReaderScreenState extends State<SimpleCardReaderScreen>
    with WidgetsBindingObserver {
  final CardReaderService _cardReaderService = CardReaderService();

  UsbDevice? _device;
  ThaiIDCard? _cardData;
  String? _error;
  bool _isReading = false;
  bool _isProcessing = false;
  RegData? _currentRegistration;

  // Stream subscriptions
  StreamSubscription? _deviceSubscription;
  StreamSubscription? _cardSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCardReader();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deviceSubscription?.cancel();
    _cardSubscription?.cancel();
    _cardReaderService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(
          '🔄 SimpleCardReaderScreen: App resumed - ตรวจสอบการเชื่อมต่อใหม่',
        );
        _checkConnectionOnResume();
        break;
      case AppLifecycleState.paused:
        debugPrint('⏸️ SimpleCardReaderScreen: App paused');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// ตรวจสอบการเชื่อมต่อเมื่อ app resume
  Future<void> _checkConnectionOnResume() async {
    try {
      debugPrint(
        '🔍 SimpleCardReaderScreen: ตรวจสอบการเชื่อมต่อเมื่อ resume...',
      );

      // รอสักครู่ให้ระบบทำงานเสร็จ
      await Future.delayed(const Duration(milliseconds: 500));

      // ตรวจสอบการเชื่อมต่อ
      final isConnected = await _cardReaderService.ensureConnection();

      if (isConnected) {
        debugPrint('✅ SimpleCardReaderScreen: การเชื่อมต่อยังใช้งานได้');
        setState(() {
          _error = null;
        });
      } else {
        debugPrint('❌ SimpleCardReaderScreen: การเชื่อมต่อขาดหายไป');
        setState(() {
          _error = 'การเชื่อมต่อขาดหายไป กรุณาตรวจสอบเครื่องอ่านบัตร';
        });
      }
    } catch (e) {
      debugPrint('❌ SimpleCardReaderScreen: ตรวจสอบการเชื่อมต่อล้มเหลว - $e');
    }
  }

  /// เริ่มต้นเครื่องอ่านบัตร
  Future<void> _initializeCardReader() async {
    try {
      debugPrint('🔧 SimpleCardReaderScreen: เริ่มต้นเครื่องอ่านบัตร...');

      // เริ่มต้น CardReaderService
      await _cardReaderService.initialize();

      // ตั้งค่า stream listeners
      _setupStreamListeners();

      // ตรวจสอบ device ที่มีอยู่แล้ว
      await _checkExistingConnection();

      debugPrint('✅ SimpleCardReaderScreen: เริ่มต้นสำเร็จ');
    } catch (e) {
      debugPrint('❌ SimpleCardReaderScreen: เริ่มต้นล้มเหลว - $e');
      setState(() {
        _error = 'ไม่สามารถเริ่มต้นเครื่องอ่านบัตรได้: $e';
      });
    }
  }

  /// ตั้งค่า stream listeners
  void _setupStreamListeners() {
    // Device events
    _deviceSubscription = ThaiIdcardReaderFlutter.deviceHandlerStream.listen(
      _onDeviceEvent,
      onError: _onDeviceError,
    );

    // Card events
    _cardSubscription = ThaiIdcardReaderFlutter.cardHandlerStream.listen(
      _onCardEvent,
      onError: _onCardError,
    );
  }

  /// ตรวจสอบการเชื่อมต่อที่มีอยู่แล้ว
  Future<void> _checkExistingConnection() async {
    try {
      debugPrint('🔍 SimpleCardReaderScreen: ตรวจสอบการเชื่อมต่อที่มีอยู่...');

      // รอให้ stream listeners ทำงานเสร็จ
      await Future.delayed(const Duration(milliseconds: 800));

      // ลองอ่านบัตรเพื่อตรวจสอบการเชื่อมต่อ
      try {
        await ThaiIdcardReaderFlutter.read();
        debugPrint('✅ SimpleCardReaderScreen: พบการเชื่อมต่อที่มีอยู่');
      } catch (e) {
        debugPrint('⚠️ SimpleCardReaderScreen: ไม่พบการเชื่อมต่อ (ปกติ) - $e');
        // นี่เป็นเรื่องปกติหากไม่มี device หรือ card
      }
    } catch (e) {
      debugPrint('❌ SimpleCardReaderScreen: ตรวจสอบการเชื่อมต่อล้มเหลว - $e');
    }
  }

  /// จัดการ device events
  void _onDeviceEvent(UsbDevice device) {
    debugPrint(
      '📱 SimpleCardReaderScreen: Device event - ${device.productName} (hasPermission: ${device.hasPermission}, isAttached: ${device.isAttached})',
    );

    setState(() {
      _device = device;
      _error = null;
    });

    if (device.hasPermission && device.isAttached) {
      debugPrint('✅ SimpleCardReaderScreen: Device เชื่อมต่อและมี Permission');
    } else if (device.isAttached && !device.hasPermission) {
      debugPrint(
        '⚠️ SimpleCardReaderScreen: Device เชื่อมต่อแต่ไม่มี Permission',
      );
      setState(() {
        _error = 'ไม่ได้รับสิทธิ์การเข้าถึง กรุณากดปุ่มขอสิทธิ์';
      });
    } else {
      debugPrint('❌ SimpleCardReaderScreen: Device ไม่ได้เชื่อมต่อ');
      setState(() {
        _error = 'ไม่พบเครื่องอ่านบัตร กรุณาเสียบ USB';
      });
    }
  }

  /// จัดการ device errors
  void _onDeviceError(dynamic error) {
    debugPrint('❌ SimpleCardReaderScreen: Device error - $error');
    setState(() {
      _error = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $error';
    });
  }

  /// จัดการ card events
  void _onCardEvent(dynamic cardEvent) {
    debugPrint('💳 SimpleCardReaderScreen: Card event - ${cardEvent.isReady}');

    if (cardEvent.isReady && !_isReading) {
      _readCard();
    }
  }

  /// จัดการ card errors
  void _onCardError(dynamic error) {
    debugPrint('❌ SimpleCardReaderScreen: Card error - $error');
    setState(() {
      _error = 'เกิดข้อผิดพลาดในการอ่านบัตร: $error';
    });
  }

  /// อ่านบัตร
  Future<void> _readCard() async {
    if (_isReading) return;

    setState(() {
      _isReading = true;
      _error = null;
    });

    try {
      debugPrint('📖 SimpleCardReaderScreen: เริ่มอ่านบัตร...');

      final result = await ThaiIdcardReaderFlutter.read();

      setState(() {
        _cardData = result;
        _error = null;
      });

      debugPrint('✅ SimpleCardReaderScreen: อ่านบัตรสำเร็จ');

      // ประมวลผลข้อมูลบัตร
      await _processCardData(result);
    } catch (e) {
      debugPrint('❌ SimpleCardReaderScreen: อ่านบัตรล้มเหลว - $e');
      setState(() {
        _error = 'ไม่สามารถอ่านบัตรได้: $e';
      });
    } finally {
      setState(() {
        _isReading = false;
      });
    }
  }

  /// ประมวลผลข้อมูลบัตร
  Future<void> _processCardData(ThaiIDCard cardData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('🔄 SimpleCardReaderScreen: ประมวลผลข้อมูลบัตร...');

      // แปลงข้อมูลเป็น RegData
      final regData = RegData.fromIdCard(
        id: cardData.cid ?? '',
        first: cardData.firstnameTH ?? '',
        last: cardData.lastnameTH ?? '',
        dob: cardData.birthdate ?? '',
        addr: cardData.address ?? '',
        gender: cardData.gender == 1 ? 'ชาย' : 'หญิง',
        phone: '',
      );

      setState(() {
        _currentRegistration = regData;
      });

      // แสดง dialog ลงทะเบียน
      _showRegistrationDialog(regData);
    } catch (e) {
      debugPrint('❌ SimpleCardReaderScreen: ประมวลผลข้อมูลล้มเหลว - $e');
      setState(() {
        _error = 'ไม่สามารถประมวลผลข้อมูลได้: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// แสดง dialog ลงทะเบียน
  void _showRegistrationDialog(RegData regData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnifiedRegistrationDialog(
        regData: regData,
        isEditMode: false,
        onCompleted: (additionalInfo) {
          Navigator.pop(context);

          // แสดงข้อความสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ลงทะเบียนเสร็จสิ้น'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // ล้างข้อมูล
          setState(() {
            _cardData = null;
            _currentRegistration = null;
          });
        },
      ),
    );
  }

  /// ขอ Permission
  Future<void> _requestPermission() async {
    try {
      debugPrint('🔐 SimpleCardReaderScreen: ขอ Permission...');

      final success = await _cardReaderService.requestPermission();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ได้รับสิทธิ์การเข้าถึงแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่ได้รับสิทธิ์การเข้าถึง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อ่านบัตรประชาชน'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // สถานะการเชื่อมต่อ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _device?.hasPermission == true
                          ? Icons.usb
                          : Icons.usb_off,
                      color: _device?.hasPermission == true
                          ? Colors.green
                          : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _device?.hasPermission == true
                                ? 'เชื่อมต่อแล้ว'
                                : 'ไม่ได้เชื่อมต่อ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _device?.hasPermission == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          if (_device != null) ...[
                            Text(
                              '${_device!.manufacturerName} ${_device!.productName}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              _device!.hasPermission
                                  ? 'มีสิทธิ์การเข้าถึง'
                                  : 'ไม่มีสิทธิ์การเข้าถึง',
                              style: TextStyle(
                                fontSize: 12,
                                color: _device!.hasPermission
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_device?.isAttached == true &&
                        _device?.hasPermission != true)
                      ElevatedButton.icon(
                        onPressed: _requestPermission,
                        icon: const Icon(Icons.security),
                        label: const Text('ขอสิทธิ์'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ข้อผิดพลาด
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ปุ่มอ่านบัตร
            if (_device?.hasPermission == true) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isReading || _isProcessing) ? null : _readCard,
                  icon: (_isReading || _isProcessing)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.credit_card),
                  label: Text(
                    (_isReading || _isProcessing)
                        ? 'กำลังอ่านบัตร...'
                        : 'อ่านบัตรประชาชน',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ข้อมูลบัตร
            if (_cardData != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'ข้อมูลบัตรประชาชน',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Chip(
                            label: const Text(
                              'ถูกต้อง',
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ],
                      ),
                      const Divider(),
                      if (_cardData!.cid != null)
                        _buildInfoRow('เลขบัตร', _cardData!.cid!),
                      if (_cardData!.firstnameTH != null)
                        _buildInfoRow(
                          'ชื่อ-นามสกุล',
                          '${_cardData!.firstnameTH} ${_cardData!.lastnameTH ?? ''}',
                        ),
                      if (_cardData!.gender != null)
                        _buildInfoRow(
                          'เพศ',
                          _cardData!.gender == 1 ? 'ชาย' : 'หญิง',
                        ),
                      if (_cardData!.birthdate != null)
                        _buildInfoRow('วันเกิด', _cardData!.birthdate!),
                      if (_cardData!.address != null)
                        _buildInfoRow('ที่อยู่', _cardData!.address!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // คำแนะนำ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'คำแนะนำการใช้งาน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• ตรวจสอบให้แน่ใจว่าเครื่องอ่านบัตรประชาชนเสียบอยู่',
                  ),
                  const Text('• หากไม่ได้รับสิทธิ์ ให้กดปุ่ม "ขอสิทธิ์"'),
                  const Text('• บัตรประชาชนต้องไม่ชำรุดหรือสกปรก'),
                  const Text('• อย่าถอดบัตรออกขณะกำลังอ่านข้อมูล'),
                ],
              ),
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
            child: SelectableText(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
