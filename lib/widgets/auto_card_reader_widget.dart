import 'package:flutter/material.dart';
import 'dart:async';
import '../services/enhanced_card_reader_service.dart';
import '../services/registration_service.dart';
import '../widgets/registration_dialog.dart';
import '../models/reg_data.dart';

/// Widget that automatically detects and processes ID cards
class AutoCardReaderWidget extends StatefulWidget {
  final bool autoStart;
  final VoidCallback? onRegistrationComplete;

  const AutoCardReaderWidget({
    super.key,
    this.autoStart = true,
    this.onRegistrationComplete,
  });

  @override
  State<AutoCardReaderWidget> createState() => _AutoCardReaderWidgetState();
}

class _AutoCardReaderWidgetState extends State<AutoCardReaderWidget> {
  final EnhancedCardReaderService _cardReaderService = EnhancedCardReaderService();
  final RegistrationService _registrationService = RegistrationService();
  
  late StreamSubscription _eventSubscription;
  late StreamSubscription _errorSubscription;
  late StreamSubscription _statusSubscription;

  CardReaderStatus _currentStatus = CardReaderStatus.disconnected;
  String _statusMessage = 'กำลังเริ่มต้นระบบ...';
  bool _isProcessing = false;
  String? _lastProcessedCardId;
  DateTime? _lastProcessedTime;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializeCardReader();
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    _errorSubscription.cancel();
    _statusSubscription.cancel();
    _cardReaderService.dispose();
    super.dispose();
  }

  /// Setup stream listeners
  void _setupListeners() {
    // Listen to card reader events
    _eventSubscription = _cardReaderService.eventStream.listen(_handleCardReaderEvent);
    
    // Listen to errors
    _errorSubscription = _cardReaderService.errorStream.listen(_handleCardReaderError);
    
    // Listen to status changes
    _statusSubscription = _cardReaderService.statusStream.listen(_handleStatusChange);
  }

  /// Initialize card reader
  Future<void> _initializeCardReader() async {
    final success = await _cardReaderService.initialize();
    
    if (success && widget.autoStart) {
      await _startMonitoring();
    }
  }

  /// Start card monitoring
  Future<void> _startMonitoring() async {
    final success = await _cardReaderService.startMonitoring();
    if (success) {
      setState(() {
        _statusMessage = 'กำลังตรวจสอบบัตรประชาชน...';
      });
    }
  }

  /// Stop card monitoring
  void _stopMonitoring() {
    _cardReaderService.stopMonitoring();
    setState(() {
      _statusMessage = 'หยุดการตรวจสอบบัตร';
    });
  }

  /// Handle card reader events
  void _handleCardReaderEvent(CardReaderEvent event) async {
    switch (event.type) {
      case CardReaderEventType.cardDetected:
        if (event.cardData != null && !_isProcessing) {
          await _processNewCard(event.cardData!);
        }
        break;
      case CardReaderEventType.cardRemoved:
        _handleCardRemoved();
        break;
      case CardReaderEventType.error:
        _showErrorSnackBar('เกิดข้อผิดพลาดในการอ่านบัตร');
        break;
    }
  }

  /// Process newly detected card
  Future<void> _processNewCard(IdCardData cardData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'กำลังประมวลผลข้อมูลบัตรประชาชน...';
      _lastProcessedCardId = cardData.id;
      _lastProcessedTime = DateTime.now();
    });

    try {
      // Check if registration already exists
      final existingReg = await _registrationService.findExistingRegistration(cardData.id);

      if (existingReg == null) {
        // Scenario 1: First time with ID card
        await _handleFirstTimeWithCard(cardData);
      } else if (existingReg.hasIdCard) {
        // Scenario 2: Returning with card (already has ID card data)
        await _handleReturningWithCard(existingReg);
      } else {
        // Scenario 4: Upgrade from manual to ID card
        await _handleUpgradeToCard(cardData, existingReg);
      }
    } catch (e) {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถประมวลผลข้อมูลได้: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Handle first time registration with ID card
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
        _statusMessage = 'ลงทะเบียนด้วยบัตรประชาชนสำเร็จ';
      });
      
      _showRegistrationDialog(regData, isFirstTime: true);
    } else {
      _showErrorDialog('ข้อผิดพลาด', 'ไม่สามารถลงทะเบียนได้');
    }
  }

  /// Handle returning visitor with ID card
  Future<void> _handleReturningWithCard(RegData existingReg) async {
    setState(() {
      _statusMessage = 'พบข้อมูลเดิม - ข้อมูลไม่สามารถแก้ไขได้';
    });

    _showRegistrationDialog(existingReg, isFirstTime: false);
  }

  /// Handle upgrade from manual to ID card
  Future<void> _handleUpgradeToCard(IdCardData cardData, RegData existingReg) async {
    final confirmed = await _showUpgradeConfirmDialog(cardData, existingReg);
    
    if (confirmed == true) {
      final updatedReg = await _registrationService.upgradeToIdCard(
        id: cardData.id,
        first: cardData.firstName,
        last: cardData.lastName,
        dob: cardData.dateOfBirth,
        addr: cardData.address,
        gender: cardData.gender,
        phone: existingReg.phone,
      );

      if (updatedReg != null) {
        setState(() {
          _statusMessage = 'อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ';
        });

        _showRegistrationDialog(updatedReg, isFirstTime: false);
      }
    } else {
      setState(() {
        _statusMessage = 'ยกเลิกการอัปเกรด - รอบัตรใหม่';
      });
    }
  }

  /// Handle card removed
  void _handleCardRemoved() {
    setState(() {
      _statusMessage = 'รอการใส่บัตรประชาชน';
    });
  }

  /// Handle card reader errors
  void _handleCardReaderError(String? error) {
    if (error != null) {
      _showErrorSnackBar(error);
    }
  }

  /// Handle status changes
  void _handleStatusChange(CardReaderStatus status) {
    setState(() {
      _currentStatus = status;
      _statusMessage = _getStatusMessage(status);
    });
  }

  /// Get status message from status
  String _getStatusMessage(CardReaderStatus status) {
    switch (status) {
      case CardReaderStatus.disconnected:
        return 'เครื่องอ่านบัตรไม่ได้เชื่อมต่อ';
      case CardReaderStatus.connected:
        return 'เครื่องอ่านบัตรพร้อมใช้งาน';
      case CardReaderStatus.monitoring:
        return 'กรุณาใส่บัตรประชาชน';
      case CardReaderStatus.cardPresent:
        return 'ตรวจพบบัตรประชาชน';
      case CardReaderStatus.error:
        return 'เครื่องอ่านบัตรเกิดข้อผิดพลาด';
    }
  }

  /// Show registration dialog
  void _showRegistrationDialog(RegData regData, {required bool isFirstTime}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RegistrationDialog(
        regData: regData,
        isFirstTime: isFirstTime,
        onCompleted: (additionalInfo) {
          Navigator.pop(context);
          
          setState(() {
            _statusMessage = 'ลงทะเบียนเสร็จสิ้น - พร้อมรับบัตรใหม่';
          });

          _showSuccessSnackBar('ลงทะเบียนเสร็จสิ้น');
          
          if (widget.onRegistrationComplete != null) {
            widget.onRegistrationComplete!();
          }

          // Clear cache to allow processing the same card again if needed
          _cardReaderService.clearCache();
        },
      ),
    );
  }

  /// Show upgrade confirmation dialog
  Future<bool?> _showUpgradeConfirmDialog(IdCardData cardData, RegData existingReg) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อัปเกรดข้อมูลเป็นบัตรประชาชน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('พบข้อมูลเดิมที่ลงทะเบียนแบบ Manual'),
            const SizedBox(height: 16),
            
            const Text('ข้อมูลเดิม:'),
            Text('ชื่อ-นามสกุล: ${existingReg.first} ${existingReg.last}'),
            Text('วันเกิด: ${existingReg.dob}'),
            Text('เพศ: ${existingReg.gender}'),
            const SizedBox(height: 12),
            
            const Text('ข้อมูลจากบัตร:'),
            Text('ชื่อ-นามสกุล: ${cardData.firstName} ${cardData.lastName}'),
            Text('วันเกิด: ${cardData.dateOfBirth}'),
            Text('เพศ: ${cardData.gender}'),
            const SizedBox(height: 16),
            
            const Text('ต้องการอัปเดตข้อมูลจากบัตรประชาชนหรือไม่?'),
            const Text(
              '(หลังจากนี้จะไม่สามารถแก้ไขข้อมูลส่วนตัวได้)',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

  /// Show error dialog
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

  /// Show error snack bar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show success snack bar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Manual card check
  void _manualCardCheck() {
    _cardReaderService.manualCardCheck();
  }

  /// Clear cache
  void _clearCache() {
    _cardReaderService.clearCache();
    setState(() {
      _lastProcessedCardId = null;
      _lastProcessedTime = null;
    });
    _showSuccessSnackBar('ล้างแคชข้อมูลเรียบร้อย');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 32,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ระบบอ่านบัตรประชาชนอัตโนมัติ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Status indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getDetailedStatusMessage(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cache information
            if (_lastProcessedCardId != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'บัตรล่าสุดที่ประมวลผล:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ID: ${_lastProcessedCardId!.substring(0, 4)}****${_lastProcessedCardId!.substring(_lastProcessedCardId!.length - 4)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (_lastProcessedTime != null)
                      Text(
                        'เวลา: ${_lastProcessedTime!.toString().substring(11, 19)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Control buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_currentStatus == CardReaderStatus.connected)
                  ElevatedButton.icon(
                    onPressed: _startMonitoring,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('เริ่มตรวจสอบ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (_currentStatus == CardReaderStatus.monitoring)
                  ElevatedButton.icon(
                    onPressed: _stopMonitoring,
                    icon: const Icon(Icons.stop),
                    label: const Text('หยุดตรวจสอบ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _manualCardCheck,
                  icon: const Icon(Icons.refresh),
                  label: const Text('ตรวจสอบด้วยตนเอง'),
                ),

                if (_lastProcessedCardId != null)
                  ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.clear),
                    label: const Text('ล้างแคช'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor() {
    switch (_currentStatus) {
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

  /// Get status icon
  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case CardReaderStatus.connected:
        return Icons.usb;
      case CardReaderStatus.monitoring:
        return Icons.visibility;
      case CardReaderStatus.cardPresent:
        return Icons.credit_card;
      case CardReaderStatus.disconnected:
        return Icons.usb_off;
      case CardReaderStatus.error:
        return Icons.error;
    }
  }

  /// Get detailed status message
  String _getDetailedStatusMessage() {
    switch (_currentStatus) {
      case CardReaderStatus.disconnected:
        return 'กรุณาเสียบเครื่องอ่านบัตรประชาชน';
      case CardReaderStatus.connected:
        return 'เครื่องอ่านบัตรพร้อมใช้งาน - กดเริ่มตรวจสอบ';
      case CardReaderStatus.monitoring:
        return 'กำลังตรวจสอบบัตรประชาชนอัตโนมัติ';
      case CardReaderStatus.cardPresent:
        return 'ตรวจพบบัตรประชาชน - กำลังประมวลผล';
      case CardReaderStatus.error:
        return 'เครื่องอ่านบัตรเกิดข้อผิดพลาด';
    }
  }
}