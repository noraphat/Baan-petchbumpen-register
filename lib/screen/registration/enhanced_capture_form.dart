import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../services/enhanced_card_reader_service.dart';
import '../../widgets/registration_dialog.dart';

/// Enhanced ID card capture form with automatic detection and processing
class EnhancedCaptureForm extends StatefulWidget {
  const EnhancedCaptureForm({super.key});

  @override
  State<EnhancedCaptureForm> createState() => _EnhancedCaptureFormState();
}

class _EnhancedCaptureFormState extends State<EnhancedCaptureForm> {
  final RegistrationService _registrationService = RegistrationService();
  final EnhancedCardReaderService _enhancedCardReader = EnhancedCardReaderService();
  
  // Original Thai ID Card Reader components (fallback)
  ThaiIDCard? _data;
  UsbDevice? _device;
  dynamic _card;
  String? _error;
  bool _isReading = false;
  bool _isProcessing = false;
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
    _initializeSystems();
  }

  @override
  void dispose() {
    _cleanupEnhancedReader();
    super.dispose();
  }

  /// Initialize both card reader systems
  Future<void> _initializeSystems() async {
    // Initialize original Thai ID Card Reader
    _initializeOriginalReader();
    
    // Initialize enhanced card reader
    await _initializeEnhancedReader();
  }

  /// Initialize original Thai ID Card Reader (existing system)
  void _initializeOriginalReader() {
    // Listen to USB device events
    ThaiIdcardReaderFlutter.deviceHandlerStream.listen(_onUSB);
  }

  /// Initialize enhanced card reader system
  Future<void> _initializeEnhancedReader() async {
    try {
      _setupEnhancedReaderListeners();
      
      final initialized = await _enhancedCardReader.initialize();
      if (initialized && _autoDetectionEnabled) {
        await _enhancedCardReader.startMonitoring();
        setState(() {
          _statusMessage = 'ระบบตรวจสอบบัตรอัตโนมัติพร้อมใช้งาน';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'ไม่สามารถเริ่มระบบตรวจสอบอัตโนมัติได้: $e';
      });
    }
  }

  /// Setup listeners for enhanced card reader
  void _setupEnhancedReaderListeners() {
    _eventSubscription = _enhancedCardReader.eventStream.listen(_handleEnhancedCardEvent);
    _errorSubscription = _enhancedCardReader.errorStream.listen(_handleEnhancedCardError);
    _statusSubscription = _enhancedCardReader.statusStream.listen(_handleEnhancedStatusChange);
  }

  /// Cleanup enhanced card reader
  void _cleanupEnhancedReader() {
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();
    _statusSubscription?.cancel();
    _enhancedCardReader.dispose();
  }

  /// Handle enhanced card reader events
  void _handleEnhancedCardEvent(CardReaderEvent event) {
    switch (event.type) {
      case CardReaderEventType.cardDetected:
        if (event.cardData != null && !_isProcessing) {
          _processEnhancedCardData(event.cardData!);
        }
        break;
      case CardReaderEventType.cardRemoved:
        setState(() {
          _statusMessage = 'รอการใส่บัตรประชาชน';
        });
        break;
      case CardReaderEventType.error:
        _showErrorSnackBar('เกิดข้อผิดพลาดในระบบตรวจสอบอัตโนมัติ');
        break;
    }
  }

  /// Handle enhanced card reader errors
  void _handleEnhancedCardError(String? error) {
    if (error != null) {
      _showErrorSnackBar('ระบบตรวจสอบอัตโนมัติ: $error');
    }
  }

  /// Handle enhanced card reader status changes
  void _handleEnhancedStatusChange(CardReaderStatus status) {
    setState(() {
      _enhancedStatus = status;
    });
  }

  /// Process card data from enhanced reader
  Future<void> _processEnhancedCardData(IdCardData cardData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'กำลังประมวลผลข้อมูลจากระบบอัตโนมัติ...';
      _lastProcessedCardId = cardData.id;
      _lastProcessedTime = DateTime.now();
    });

    try {
      // Convert enhanced card data to ThaiIDCard format for consistency
      final mockThaiIDCard = _createMockThaiIDCard(cardData);
      
      // Process using existing logic
      await _processCardData(mockThaiIDCard);
    } catch (e) {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถประมวลผลข้อมูลอัตโนมัติได้: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Create mock ThaiIDCard from enhanced card data for compatibility
  ThaiIDCard _createMockThaiIDCard(IdCardData cardData) {
    // This is a simplified conversion - in real implementation,
    // you would properly map all fields from IdCardData to ThaiIDCard
    return ThaiIDCard(
      cid: cardData.id,
      titleTH: cardData.title,
      firstnameTH: cardData.firstName,
      lastnameTH: cardData.lastName,
      birthdate: cardData.dateOfBirth,
      gender: cardData.gender == 'ชาย' ? 1 : 2,
      address: cardData.address,
      photo: [], // Enhanced reader might not have photo
      issueDate: null,
      expireDate: null,
      titleEN: null,
      firstnameEN: null,
      lastnameEN: null,
    );
  }

  // === ORIGINAL THAI ID CARD READER METHODS (preserved) ===

  void _onUSB(usbEvent) {
    try {
      if (usbEvent.hasPermission) {
        ThaiIdcardReaderFlutter.cardHandlerStream.listen(_onData);
      } else {
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

  /// Process card data using existing logic (works with both systems)
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

      final existingReg = await _registrationService.findExistingRegistration(id);

      if (existingReg == null) {
        await _handleFirstTimeWithCard(
          id: id,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
          address: address,
          gender: gender,
        );
      } else if (existingReg.hasIdCard) {
        await _handleReturningWithCard(existingReg);
      } else {
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

  // === REGISTRATION LOGIC (preserved from original) ===

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
        _statusMessage = 'ลงทะเบียนด้วยบัตรประชาชนสำเร็จ';
      });

      _showSuccessMessage('ลงทะเบียนด้วยบัตรประชาชนสำเร็จ');
      _showRegistrationDialog(regData, isFirstTime: true);
    } else {
      _showErrorDialog('ไม่สามารถลงทะเบียนได้');
    }
  }

  Future<void> _handleReturningWithCard(RegData existingReg) async {
    setState(() {
      _currentRegistration = existingReg;
      _statusMessage = 'พบข้อมูลเดิม - ข้อมูลไม่สามารถแก้ไขได้';
    });

    _showSuccessMessage('พบข้อมูลเดิม - ข้อมูลไม่สามารถแก้ไขได้');
    _showRegistrationDialog(existingReg, isFirstTime: false);
  }

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
          _statusMessage = 'อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ';
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

  // === UI HELPER METHODS ===

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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลงทะเบียนเสร็จสิ้น'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear enhanced reader cache for next use
          _enhancedCardReader.clearCache();
        },
      ),
    );
  }

  // === ENHANCED CARD READER CONTROLS ===

  void _toggleAutoDetection() {
    setState(() {
      _autoDetectionEnabled = !_autoDetectionEnabled;
    });

    if (_autoDetectionEnabled) {
      _enhancedCardReader.startMonitoring();
      setState(() {
        _statusMessage = 'เปิดระบบตรวจสอบอัตโนมัติ';
      });
    } else {
      _enhancedCardReader.stopMonitoring();
      setState(() {
        _statusMessage = 'ปิดระบบตรวจสอบอัตโนมัติ';
      });
    }
  }

  void _manualCardCheck() {
    _enhancedCardReader.manualCardCheck();
    _showSuccessMessage('กำลังตรวจสอบบัตรด้วยตนเอง...');
  }

  void _clearEnhancedCache() {
    _enhancedCardReader.clearCache();
    setState(() {
      _lastProcessedCardId = null;
      _lastProcessedTime = null;
    });
    _showSuccessMessage('ล้างแคชระบบอัตโนมัติแล้ว');
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

  // === UI BUILD METHOD ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อ่านบัตรประชาชนอัจฉริยะ'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleAutoDetection,
            icon: Icon(_autoDetectionEnabled ? Icons.auto_fix_high : Icons.auto_fix_off),
            tooltip: _autoDetectionEnabled ? 'ปิดระบบอัตโนมัติ' : 'เปิดระบบอัตโนมัติ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Enhanced System Status Card
            Card(
              color: _getEnhancedStatusColor().withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getEnhancedStatusIcon(),
                          size: 32,
                          color: _getEnhancedStatusColor(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ระบบตรวจสอบอัตโนมัติ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getEnhancedStatusColor(),
                                ),
                              ),
                              Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _getEnhancedStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_autoDetectionEnabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AUTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Enhanced cache information
                    if (_lastProcessedCardId != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.history, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'บัตรล่าสุด: ${_lastProcessedCardId!.substring(0, 4)}****${_lastProcessedCardId!.substring(_lastProcessedCardId!.length - 4)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (_lastProcessedTime != null)
                            Text(
                              ' (${_lastProcessedTime!.toString().substring(11, 19)})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Enhanced Controls
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _manualCardCheck,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ตรวจสอบด้วยตนเอง'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (_lastProcessedCardId != null)
                  ElevatedButton.icon(
                    onPressed: _clearEnhancedCache,
                    icon: const Icon(Icons.clear),
                    label: const Text('ล้างแคช'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Original System Status (fallback)
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
                subtitle: 'กรุณาเชื่อมต่อเครื่องอ่านบัตรประชาชน (สำรอง)',
                color: Colors.orange,
              ),
            ] else if (_data == null && (_device != null && _device!.hasPermission)) ...[
              _buildStatusCard(
                icon: Icons.credit_card,
                title: 'เสียบบัตรประชาชน',
                subtitle: 'กรุณาเสียบบัตรประชาชนเพื่อเริ่มอ่านข้อมูล (สำรอง)',
                color: Colors.blue,
              ),
            ],

            // Processing indicator
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

            // Original Card Data Display (preserved)
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

  Color _getEnhancedStatusColor() {
    switch (_enhancedStatus) {
      case CardReaderStatus.connected:
      case CardReaderStatus.monitoring:
        return Colors.green;
      case CardReaderStatus.cardPresent:
        return Colors.blue;
      case CardReaderStatus.disconnected:
        return Colors.orange;
      case CardReaderStatus.error:
        return Colors.red;
    }
  }

  IconData _getEnhancedStatusIcon() {
    switch (_enhancedStatus) {
      case CardReaderStatus.connected:
        return Icons.check_circle;
      case CardReaderStatus.monitoring:
        return Icons.visibility;
      case CardReaderStatus.cardPresent:
        return Icons.credit_card;
      case CardReaderStatus.disconnected:
        return Icons.warning;
      case CardReaderStatus.error:
        return Icons.error;
    }
  }
}