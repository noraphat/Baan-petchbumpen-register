import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../services/enhanced_card_reader_service.dart';
import '../../services/card_reader_service.dart';
import '../../services/db_helper.dart';
import '../../widgets/shared_registration_dialog.dart';
import '../../utils/privacy_utils.dart';

class CaptureForm extends StatefulWidget {
  const CaptureForm({super.key});

  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  final RegistrationService _registrationService = RegistrationService();
  final EnhancedCardReaderService _enhancedCardReader = EnhancedCardReaderService();
  
  ThaiIDCard? _data;
  UsbDevice? _device;
  dynamic _card;
  String? _error;
  bool _isReading = false;
  bool _isProcessing = false;
  bool _isManualReading = false;
  RegData? _currentRegistration;

  // Enhanced card reader state
  CardReaderStatus _enhancedStatus = CardReaderStatus.disconnected;
  String _statusMessage = 'กำลังเริ่มต้นระบบ...';
  bool _autoDetectionEnabled = true;
  String? _lastProcessedCardId;
  DateTime? _lastProcessedTime;

  // Stream subscriptions for enhanced card reader
  StreamSubscription<CardReaderEvent>? _eventSubscription;
  StreamSubscription<String?>? _errorSubscription;
  StreamSubscription<CardReaderStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to USB device events
    ThaiIdcardReaderFlutter.deviceHandlerStream.listen(_onUSB);
    // Check for already connected devices
    _checkExistingConnection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ตรวจสอบการเชื่อมต่อเมื่อกลับมาหน้า
    _checkConnectionOnPageReturn();
  }

  /// Check if there's already a connected USB device when the screen starts
  Future<void> _checkExistingConnection() async {
    try {
      // Small delay to let the stream listener initialize first
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Try to perform a card read to trigger device detection
      try {
        debugPrint('🔍 CaptureForm: Checking for existing card reader connection...');
        await ThaiIdcardReaderFlutter.read();
        debugPrint('✅ CaptureForm: Card reader connection detected');
      } catch (e) {
        debugPrint('⚠️ CaptureForm: No card reader or card detected (this is normal) - $e');
        // This is expected if no device is connected or no card is inserted
      }
      
    } catch (e) {
      debugPrint('⚠️ CaptureForm: Could not check existing connection - $e');
      // This is not a critical error, just log it
    }
  }

  /// ตรวจสอบการเชื่อมต่อเมื่อกลับมาหน้า
  Future<void> _checkConnectionOnPageReturn() async {
    // รอให้ widget ทำงานเสร็จก่อน
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      debugPrint('🔄 CaptureForm: ตรวจสอบการเชื่อมต่อเมื่อกลับมาหน้า...');

      try {
        // ตรวจสอบว่ามี device อยู่แล้วหรือไม่
        if (_device != null && _device!.hasPermission && _device!.isAttached) {
          debugPrint('✅ CaptureForm: Device ยังเชื่อมต่ออยู่ - ไม่ต้องทำอะไร');
          return;
        }

        // ใช้ CardReaderService เพื่อตรวจสอบการเชื่อมต่อแบบแข็งแกร่ง
        final cardReaderService = CardReaderService();
        final isConnected = await cardReaderService.ensureConnection();

        if (isConnected) {
          debugPrint('✅ CaptureForm: ตรวจพบเครื่องอ่านบัตรที่เสียบอยู่แล้ว');
          
          // แสดงข้อความแจ้งเตือนว่าพบเครื่องอ่านบัตร (เฉพาะเมื่อไม่มี device)
          if (mounted && (_device == null || !_device!.hasPermission)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.usb, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ตรวจพบเครื่องอ่านบัตรที่เสียบอยู่แล้ว - พร้อมใช้งาน',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // รีเซ็ต stream listener เพื่อให้แน่ใจว่าจะได้รับ events
          _reinitializeStreamListeners();
        } else {
          debugPrint('❌ CaptureForm: ไม่พบเครื่องอ่านบัตร');
        }
      } catch (e) {
        debugPrint('❌ CaptureForm: เกิดข้อผิดพลาดในการตรวจสอบการเชื่อมต่อ - $e');
      }
    }
  }

  /// รีเซ็ต stream listeners เพื่อให้แน่ใจว่าจะได้รับ USB events
  void _reinitializeStreamListeners() {
    try {
      debugPrint('🔄 CaptureForm: รีเซ็ต stream listeners...');
      
      // ไม่เพิ่ม listener ใหม่ เพราะจะทำให้เกิด duplicate
      // แค่ log ว่าได้ทำการตรวจสอบแล้ว
      debugPrint('✅ CaptureForm: Stream listeners ยังทำงานอยู่');
    } catch (e) {
      debugPrint('❌ CaptureForm: รีเซ็ต stream listeners ล้มเหลว - $e');
    }
  }

  /// ตรวจสอบการเชื่อมต่อด้วยตนเอง (สำหรับปุ่มสีเขียว)
  Future<void> _manualCheckConnection() async {
    if (mounted) {
      debugPrint('🔍 CaptureForm: ตรวจสอบการเชื่อมต่อด้วยตนเอง...');

      // แสดง loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('กำลังตรวจสอบเครื่องอ่านบัตร...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // ใช้ CardReaderService เพื่อตรวจสอบการเชื่อมต่อ
        final cardReaderService = CardReaderService();
        final isConnected = await cardReaderService.ensureConnection();

        if (isConnected) {
          debugPrint('✅ CaptureForm: พบเครื่องอ่านบัตร');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'พบเครื่องอ่านบัตรแล้ว - พร้อมใช้งาน',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // ลองอ่านบัตรทันทีหากมีบัตรเสียบอยู่
          await _tryReadCardIfPresent();
        } else {
          debugPrint('❌ CaptureForm: ไม่พบเครื่องอ่านบัตร');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ไม่พบเครื่องอ่านบัตร - กรุณาตรวจสอบการเสียบ USB',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ CaptureForm: เกิดข้อผิดพลาดในการตรวจสอบ - $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เกิดข้อผิดพลาด: $e',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// ลองอ่านบัตรหากมีบัตรเสียบอยู่
  Future<void> _tryReadCardIfPresent() async {
    try {
      debugPrint('🔍 CaptureForm: ลองอ่านบัตรหากมีบัตรเสียบอยู่...');
      
      // ลองอ่านบัตรแบบไม่ blocking
      final result = await ThaiIdcardReaderFlutter.read().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Timeout reading card', const Duration(seconds: 3)),
      );
      
      if (result.cid != null && result.cid!.isNotEmpty) {
        debugPrint('✅ CaptureForm: พบบัตรประชาชน - เริ่มประมวลผล');
        
        setState(() {
          _data = result;
          _error = null;
        });
        
        // ประมวลผลข้อมูลบัตรประชาชน
        await _processCardData(result);
      } else {
        debugPrint('⚠️ CaptureForm: ไม่พบบัตรประชาชนในเครื่องอ่าน');
      }
    } catch (e) {
      debugPrint('⚠️ CaptureForm: ไม่สามารถอ่านบัตรได้ (อาจไม่มีบัตรเสียบ) - $e');
      // ไม่แสดง error เพราะเป็นเรื่องปกติที่อาจไม่มีบัตรเสียบ
    }
  }

  void _onUSB(usbEvent) {
    try {
      debugPrint('📱 CaptureForm: USB Event - ${usbEvent.productName} (hasPermission: ${usbEvent.hasPermission}, isAttached: ${usbEvent.isAttached})');
      
      if (usbEvent.hasPermission && usbEvent.isAttached) {
        debugPrint('✅ CaptureForm: Device เชื่อมต่อและมี Permission');
        
        // Listen to card events when device has permission
        // ใช้ listen แบบไม่ซ้ำ
        ThaiIdcardReaderFlutter.cardHandlerStream.listen(_onData);
        
        // แสดงข้อความแจ้งเตือนว่าพร้อมใช้งาน (เฉพาะครั้งแรกที่เชื่อมต่อ)
        if (mounted && _device?.hasPermission != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เครื่องอ่านบัตร ${usbEvent.productName} พร้อมใช้งาน',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (usbEvent.isAttached && !usbEvent.hasPermission) {
        debugPrint('⚠️ CaptureForm: Device เชื่อมต่อแต่ไม่มี Permission');
        
        // Clear data when no permission
        _clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ไม่ได้รับอนุญาตใช้งานเครื่องอ่านบัตร - กรุณากด OK'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('❌ CaptureForm: Device ไม่ได้เชื่อมต่อ');
        _clear();
      }
      
      setState(() {
        _device = usbEvent;
      });
    } catch (e) {
      debugPrint('❌ CaptureForm: USB Event Error - $e');
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

  /// Manual card reading function triggered by button
  Future<void> _recheckCard() async {
    if (_isManualReading || _isReading || _isProcessing) return;
    
    setState(() {
      _isManualReading = true;
      _error = null;
      _data = null; // Clear previous data
      _currentRegistration = null; // Clear previous registration
    });

    try {
      // Add a small delay to ensure card reader is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Try to read the card directly
      var result = await ThaiIdcardReaderFlutter.read();
      
      if (result.cid != null) {
        setState(() {
          _data = result;
          _error = null;
        });
        
        // Process the card data
        await _processCardData(result);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อ่านบัตรประชาชนสำเร็จ'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('ไม่พบข้อมูลบัตรประชาชน');
      }
      
    } catch (e) {
      setState(() {
        _error = 'ไม่สามารถอ่านบัตรประชาชนได้: $e';
      });
      
      // Show error dialog or snackbar
      if (mounted) {
        _showRecheckErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isManualReading = false;
      });
    }
  }

  /// รีเซ็ตการเชื่อมต่อเครื่องอ่านบัตร
  Future<void> _resetConnection() async {
    setState(() {
      _error = null;
      _data = null;
      _currentRegistration = null;
    });

    try {
      // ล้าง stream subscriptions
      if (_eventSubscription != null) {
        await _eventSubscription!.cancel();
        _eventSubscription = null;
      }
      if (_errorSubscription != null) {
        await _errorSubscription!.cancel();
        _errorSubscription = null;
      }
      if (_statusSubscription != null) {
        await _statusSubscription!.cancel();
        _statusSubscription = null;
      }

      // ใช้ CardReaderService สำหรับรีเซ็ตแบบขั้นสูง
      try {
        final cardReaderService = CardReaderService();
        await cardReaderService.resetConnection();
        
        // ตรวจสอบว่าต้องใช้การรีเซ็ต USB จริงหรือไม่
        if (cardReaderService.shouldUsePhysicalReset()) {
          _showPhysicalResetDialog(cardReaderService);
          return;
        }
        
      } catch (e) {
        debugPrint('Enhanced card reader reset failed: $e');
        // แสดง dialog คำแนะนำการรีเซ็ต USB จริง
        _showPhysicalResetDialog(CardReaderService());
        return;
      }

      // เริ่มต้น device handler stream ใหม่
      await Future.delayed(const Duration(milliseconds: 500));
      ThaiIdcardReaderFlutter.deviceHandlerStream.listen(_onUSB);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รีเซ็ตการเชื่อมต่อเรียบร้อย - ลองอ่านบัตรประชาชนได้เลย'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Connection reset failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถรีเซ็ตการเชื่อมต่อได้: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// แสดง dialog คำแนะนำการรีเซ็ต USB จริง
  void _showPhysicalResetDialog(CardReaderService cardReaderService) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.usb_off, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ต้องรีเซ็ต USB จริง',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'ระบบไม่สามารถรีเซ็ต USB ได้',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Plugin thai_idcard_reader_flutter ไม่รองรับการรีเซ็ต USB ระดับฮาร์ดแวร์',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                cardReaderService.getPhysicalResetInstructions(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              // ลองรีเซ็ตแบบเร็วอีกครั้งหลังจากผู้ใช้ทำตามคำแนะนำ
              await Future.delayed(const Duration(seconds: 2));
              await cardReaderService.quickResetConnection();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('รีเซ็ตเสร็จแล้ว - ลองอ่านบัตรประชาชนได้เลย'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('ทำตามคำแนะนำแล้ว'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog for recheck card failures
  void _showRecheckErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'อ่านบัตรไม่สำเร็จ',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('เกิดข้อผิดพลาด: $errorMessage'),
            const SizedBox(height: 16),
            const Text(
              'กรุณาตรวจสอบ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• บัตรประชาชนเสียบอยู่ในเครื่องอ่านบัตร'),
            const Text('• บัตรไม่ชำรุดหรือสกปรก'),
            const Text('• เครื่องอ่านบัตรเชื่อมต่ออยู่'),
            const Text('• ลองถอดและเสียบบัตรใหม่อีกครั้ง'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Try again after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                _recheckCard();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
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

  /// แสดง Dialog การลงทะเบียนพร้อมตรวจสอบข้อมูลเดิม
  Future<void> _showRegistrationDialog(RegData regData, {required bool isFirstTime}) async {
    try {
      // ตรวจสอบข้อมูลเพิ่มเติมที่อาจมีอยู่แล้ว
      final additionalInfo = await DbHelper().fetchAdditionalInfo(regData.id);
      
      // ตรวจสอบสถานะการเข้าพัก
      final stayStatus = await DbHelper().checkStayStatus(regData.id);
      final latestStay = stayStatus['latestStay'] as StayRecord?;
      final canCreateNew = stayStatus['canCreateNew'] as bool;
      
      if (additionalInfo != null) {
        debugPrint('📦 พบข้อมูลอุปกรณ์เดิม: ${additionalInfo.visitId}');
      }
      
      if (latestStay != null) {
        debugPrint('📅 พบ stay record: ${latestStay.id}');
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => SharedRegistrationDialog(
          regId: regData.id,
          existingInfo: additionalInfo,
          latestStay: latestStay,
          canCreateNew: canCreateNew,
          onCompleted: () {
            Navigator.pop(ctx); // ปิด registration dialog
            Navigator.pop(context); // กลับไปหน้าเมนู
            
            // แสดงข้อความสำเร็จ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(canCreateNew ? 'ลงทะเบียนเสร็จสิ้น' : 'อัปเดตข้อมูลเรียบร้อยแล้ว'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการโหลดข้อมูลเพิ่มเติม: $e');
      
      // ถ้าเกิดข้อผิดพลาด ให้แสดง dialog แบบเดิม
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => SharedRegistrationDialog(
            regId: regData.id,
            existingInfo: null,
            latestStay: null,
            canCreateNew: true,
            onCompleted: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              
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
    }
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
        actions: [
          // ปุ่ม Reset Connection
          IconButton(
            onPressed: _resetConnection,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเซ็ตการเชื่อมต่อเครื่องอ่านบัตร',
          ),
        ],
      ),
      floatingActionButton: _device != null && _device!.hasPermission && !(_isReading || _isProcessing || _isManualReading)
          ? FloatingActionButton.extended(
              onPressed: _recheckCard,
              icon: const Icon(Icons.refresh),
              label: const Text('ตรวจสอบบัตร'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              tooltip: 'ตรวจสอบบัตรประชาชนอีกครั้ง',
            )
          : null,
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

            // Reset Connection Button - เด่นกว่า Recheck Card เมื่อไม่มีอุปกรณ์
            if (_device == null || !_device!.hasPermission) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _resetConnection,
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: const Text(
                    '🔄 รีเซ็ตการเชื่อมต่อเครื่องอ่านบัตร',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // ปุ่มตรวจสอบการเชื่อมต่อแบบเร็ว
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _manualCheckConnection,
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text(
                    'ตรวจหาเครื่องอ่านบัตรที่เสียบอยู่',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              Text(
                'หากเครื่องอ่านบัตรเสียบอยู่แล้วแต่ระบบไม่พบ ให้กดปุ่มสีเขียวก่อน\nหากยังไม่ได้ผล ให้กดปุ่มสีน้ำเงินเพื่อรีเซ็ตการเชื่อมต่อ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Recheck Card Button
            if (_device != null && _device!.hasPermission && !(_isReading || _isProcessing || _isManualReading)) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton.icon(
                  onPressed: _recheckCard,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'ตรวจสอบบัตรอีกครั้ง',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'หากบัตรเสียบอยู่แล้วแต่ระบบไม่อ่าน กดปุ่มนี้เพื่อลองอ่านอีกครั้ง',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Reading indicator
            if (_isReading || _isProcessing || _isManualReading) ...[
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
                        _isManualReading 
                          ? 'กำลังตรวจสอบบัตร...' 
                          : (_isReading ? 'กำลังอ่านข้อมูล...' : 'กำลังประมวลผล...'),
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
                      Text('เลขบัตรประชาชน: ${PrivacyUtils.maskThaiIdCard(_currentRegistration!.id)}'),
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
                      if (_data!.cid != null) _buildInfoRow('เลขบัตรประชาชน', PrivacyUtils.maskThaiIdCard(_data!.cid!)),
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