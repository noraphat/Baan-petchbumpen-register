import 'package:flutter/material.dart';
import '../../services/card_reader_service.dart';
import '../../widgets/card_reader_widgets.dart';
import '../../widgets/unified_registration_dialog.dart';
import '../../models/reg_data.dart';

/// หน้าอ่านบัตรประชาชนแบบปรับปรุง (Enhanced)
class EnhancedCaptureForm extends StatefulWidget {
  const EnhancedCaptureForm({super.key});

  @override
  State<EnhancedCaptureForm> createState() => _EnhancedCaptureFormState();
}

class _EnhancedCaptureFormState extends State<EnhancedCaptureForm> {
  final CardReaderService _cardReaderService = CardReaderService();
  ThaiIdCardData? _lastReadData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCardReader();
  }

  @override
  void dispose() {
    _cardReaderService.dispose();
    super.dispose();
  }

  /// เริ่มต้นเครื่องอ่านบัตร
  Future<void> _initializeCardReader() async {
    try {
      await _cardReaderService.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเริ่มต้นเครื่องอ่านบัตรได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// จัดการเมื่ออ่านบัตรสำเร็จ
  void _onCardReadSuccess(ThaiIdCardData cardData) {
    setState(() {
      _lastReadData = cardData;
      _isProcessing = false;
    });

    // แสดง dialog ลงทะเบียน
    _showRegistrationDialog(cardData);
  }

  /// จัดการเมื่อเกิดข้อผิดพลาด
  void _onCardReadError(String error) {
    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เกิดข้อผิดพลาด: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// แสดง dialog ลงทะเบียน
  void _showRegistrationDialog(ThaiIdCardData cardData) {
    // แปลงข้อมูลจาก ThaiIdCardData เป็น RegData
    final regData = RegData.fromIdCard(
      id: cardData.cid,
      first: cardData.firstnameTH ?? '',
      last: cardData.lastnameTH ?? '',
      dob: cardData.birthdate ?? '',
      addr: cardData.address ?? '',
      gender: cardData.genderText,
      phone: '',
    );

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

          // ล้างข้อมูลล่าสุด
          setState(() {
            _lastReadData = null;
          });
        },
      ),
    );
  }

  /// เริ่มอ่านบัตร
  Future<void> _startReadingCard() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cardData = await _cardReaderService.readCard();
      if (cardData != null) {
        _onCardReadSuccess(cardData);
      } else {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบบัตรประชาชน กรุณาเสียบบัตร'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _onCardReadError(e.toString());
    }
  }

  /// จัดการเมื่อการเชื่อมต่อฟื้นฟู
  void _onConnectionRestored() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.usb, color: Colors.white),
            SizedBox(width: 8),
            Text('เชื่อมต่อเครื่องอ่านบัตรสำเร็จ'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
            // ใช้ EnhancedConnectionChecker เพื่อตรวจสอบการเชื่อมต่อ
            EnhancedConnectionChecker(
              cardReaderService: _cardReaderService,
              onConnectionRestored: _onConnectionRestored,
              builder: (isConnected, statusMessage) {
                return Column(
                  children: [
                    // แสดงสถานะการเชื่อมต่อ
                    ConnectionStatusWidget(
                      cardReaderService: _cardReaderService,
                    ),

                    const SizedBox(height: 16),

                    // แสดง Permission Manager
                    PermissionManagerWidget(
                      cardReaderService: _cardReaderService,
                      onPermissionGranted: () {
                        setState(() {
                          // อัปเดตสถานะเมื่อได้รับ permission
                        });
                      },
                      onPermissionDenied: () {
                        setState(() {
                          // อัปเดตสถานะเมื่อไม่ได้รับ permission
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // แสดงสถานะการอ่านบัตร
                    CardReadingStatusWidget(
                      cardReaderService: _cardReaderService,
                    ),

                    const SizedBox(height: 16),

                    // ปุ่มควบคุม
                    if (isConnected) ...[
                      // ปุ่มอ่านบัตร
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _startReadingCard,
                          icon: _isProcessing
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
                            _isProcessing
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
                            elevation: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ปุ่มตรวจสอบบัตรอีกครั้ง
                      RecheckCardButton(
                        cardReaderService: _cardReaderService,
                        onCardRead: _onCardReadSuccess,
                        onError: _onCardReadError,
                      ),

                      const SizedBox(height: 24),

                      // ปุ่มรีเซ็ตแบบขั้นสูง
                      AdvancedResetButton(
                        cardReaderService: _cardReaderService,
                        onResetComplete: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('รีเซ็ตการเชื่อมต่อสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        onResetFailed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('รีเซ็ตการเชื่อมต่อล้มเหลว'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // แสดงข้อความเมื่อไม่ได้เชื่อมต่อ
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.usb_off,
                              size: 48,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบเครื่องอ่านบัตรประชาชน',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'กรุณาเสียบเครื่องอ่านบัตรประชาชนผ่าน USB port',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ขั้นตอนการเชื่อมต่อ:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. เสียบเครื่องอ่านบัตรประชาชนเข้ากับ USB port',
                            ),
                            const Text('2. รอให้ระบบตรวจพบเครื่องอ่านบัตร'),
                            const Text('3. กดปุ่ม "อ่านบัตรประชาชน"'),
                            const Text(
                              '4. เสียบบัตรประชาชนเข้ากับเครื่องอ่านบัตร',
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // แสดงข้อมูลบัตรล่าสุด
                    if (_lastReadData != null) ...[
                      CardDataDisplayWidget(cardData: _lastReadData!),
                      const SizedBox(height: 16),
                    ],

                    // ข้อมูลเพิ่มเติม
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
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade600,
                              ),
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
                            style: TextStyle(fontSize: 14),
                          ),
                          const Text(
                            '• บัตรประชาชนต้องไม่ชำรุดหรือสกปรก',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Text(
                            '• อย่าถอดบัตรออกขณะกำลังอ่านข้อมูล',
                            style: TextStyle(fontSize: 14),
                          ),
                          const Text(
                            '• หากมีปัญหา ให้ลองรีเซ็ตการเชื่อมต่อ',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
