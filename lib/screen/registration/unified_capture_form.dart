import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/reg_data.dart';
import '../../services/registration_service.dart';
import '../../services/stay_service.dart';
import '../../services/db_helper.dart';
import '../../widgets/shared_registration_dialog.dart';

/// Unified ID card registration form that uses the new service architecture
/// This implements the core requirement for unified registration logic
class UnifiedCaptureForm extends StatefulWidget {
  const UnifiedCaptureForm({super.key});

  @override
  State<UnifiedCaptureForm> createState() => _UnifiedCaptureFormState();
}

class _UnifiedCaptureFormState extends State<UnifiedCaptureForm> {
  final RegistrationService _registrationService = RegistrationService();
  
  ThaiIDCard? _data;
  UsbDevice? _device;
  String? _error;
  bool _isReading = false;
  bool _isProcessing = false;
  bool _isManualReading = false;
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
      
      // Process card data using unified logic
      await _processCardDataUnified(result);
      
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
      _data = null;
      _currentRegistration = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      var result = await ThaiIdcardReaderFlutter.read();
      
      if (result.cid != null) {
        setState(() {
          _data = result;
          _error = null;
        });
        
        await _processCardDataUnified(result);
        
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
      
      if (mounted) {
        _showRecheckErrorDialog(e.toString());
      }
    } finally {
      setState(() {
        _isManualReading = false;
      });
    }
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

  /// Process card data using unified logic
  /// This is the core implementation of the unified requirements
  Future<void> _processCardDataUnified(ThaiIDCard cardData) async {
    if (cardData.cid == null) {
      _showErrorDialog('ไม่พบเลขบัตรประชาชน');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final cid = cardData.cid!;
      debugPrint('🆔 Processing ID card: $cid');

      // Step 1: Check if user exists
      final existingReg = await _registrationService.findExistingRegistration(cid);
      
      // Step 2: Get latest stay using unified service
      final latestStay = await StayService.getLatestStay(cid);
      
      // Step 3: Determine mode (CREATE vs EDIT)
      final stayStatus = await StayService.getStayStatus(cid);
      final isEditMode = stayStatus['isEditMode'] as bool;

      debugPrint('🔍 Stay status: $stayStatus');
      debugPrint('📝 Edit mode: $isEditMode');
      debugPrint('📅 Latest stay: ${latestStay?.id}');

      RegData regData;

      if (existingReg == null) {
        // First time registration with ID card
        debugPrint('✨ First time registration');
        regData = await _handleFirstTimeWithCard(cardData);
      } else if (existingReg.hasIdCard) {
        // Returning user with ID card (data locked)
        debugPrint('🔄 Returning user with locked data');
        regData = existingReg;
      } else {
        // Upgrade manual registration to ID card
        debugPrint('⬆️ Upgrading manual to ID card');
        final confirmed = await _showUpgradeConfirmDialog(existingReg, cardData);
        if (confirmed != true) return;
        
        regData = await _handleUpgradeToCard(existingReg, cardData);
      }

      setState(() {
        _currentRegistration = regData;
      });

      // Step 4: Load existing additional info if in edit mode
      RegAdditionalInfo? existingAdditionalInfo;
      if (isEditMode && latestStay != null) {
        existingAdditionalInfo = await StayService.getAdditionalInfoForStay(cid, latestStay);
        debugPrint('📦 Loaded existing additional info: ${existingAdditionalInfo?.visitId}');
      }

      // Step 5: Show unified registration dialog
      if (mounted) {
        _showUnifiedRegistrationDialog(
          regData: regData,
          isEditMode: isEditMode,
          existingStay: latestStay,
          existingAdditionalInfo: existingAdditionalInfo,
        );
      }

    } catch (e) {
      debugPrint('❌ Error processing card: $e');
      _showErrorDialog('เกิดข้อผิดพลาดในการประมวลผล: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Handle first time registration with ID card
  Future<RegData> _handleFirstTimeWithCard(ThaiIDCard cardData) async {
    final regData = await _registrationService.registerWithIdCard(
      id: cardData.cid!,
      first: cardData.firstnameTH ?? '',
      last: cardData.lastnameTH ?? '',
      dob: cardData.birthdate ?? '',
      addr: cardData.address ?? '',
      gender: cardData.gender == 1 ? 'ชาย' : 'หญิง',
      phone: '',
    );

    if (regData == null) {
      throw Exception('ไม่สามารถลงทะเบียนได้');
    }

    _showSuccessMessage('ลงทะเบียนด้วยบัตรประชาชนสำเร็จ');
    return regData;
  }

  /// Handle upgrade from manual to ID card
  Future<RegData> _handleUpgradeToCard(RegData existingReg, ThaiIDCard cardData) async {
    final updatedReg = await _registrationService.upgradeToIdCard(
      id: cardData.cid!,
      first: cardData.firstnameTH ?? '',
      last: cardData.lastnameTH ?? '',
      dob: cardData.birthdate ?? '',
      addr: cardData.address ?? '',
      gender: cardData.gender == 1 ? 'ชาย' : 'หญิง',
      phone: existingReg.phone,
    );

    if (updatedReg == null) {
      throw Exception('ไม่สามารถอัปเกรดข้อมูลได้');
    }

    _showSuccessMessage('อัปเกรดข้อมูลเป็นบัตรประชาชนสำเร็จ');
    return updatedReg;
  }

  /// Show upgrade confirmation dialog
  Future<bool?> _showUpgradeConfirmDialog(RegData existingReg, ThaiIDCard cardData) {
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
            Text('ชื่อ-นามสกุล: ${cardData.firstnameTH} ${cardData.lastnameTH}'),
            Text('วันเกิด: ${cardData.birthdate}'),
            Text('เพศ: ${cardData.gender == 1 ? 'ชาย' : 'หญิง'}'),
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

  /// Show unified registration dialog with existing data check
  Future<void> _showUnifiedRegistrationDialog({
    required RegData regData,
    required bool isEditMode,
    required StayRecord? existingStay,
    required RegAdditionalInfo? existingAdditionalInfo,
  }) async {
    // ตรวจสอบข้อมูลเพิ่มเติมและ stay record ที่อาจไม่ได้ส่งมา
    RegAdditionalInfo? finalExistingInfo = existingAdditionalInfo;
    StayRecord? finalLatestStay = existingStay;
    bool finalCanCreateNew = !isEditMode;

    try {
      // ถ้าไม่มีข้อมูลเพิ่มเติม ให้ลองค้นหาใหม่
      if (finalExistingInfo == null) {
        final additionalInfo = await DbHelper().fetchAdditionalInfo(regData.id);
        if (additionalInfo != null) {
          finalExistingInfo = additionalInfo;
          debugPrint('📦 โหลดข้อมูลอุปกรณ์: ${additionalInfo.visitId}');
        }
      }

      // ถ้าไม่มี stay record ให้ตรวจสอบสถานะการเข้าพัก
      if (finalLatestStay == null) {
        final stayStatus = await DbHelper().checkStayStatus(regData.id);
        finalLatestStay = stayStatus['latestStay'] as StayRecord?;
        finalCanCreateNew = stayStatus['canCreateNew'] as bool;
        
        if (finalLatestStay != null) {
          debugPrint('📅 โหลด stay record: ${finalLatestStay?.id}');
        }
      }

    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการโหลดข้อมูลเพิ่มเติม: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SharedRegistrationDialog(
        regId: regData.id,
        existingInfo: finalExistingInfo,
        latestStay: finalLatestStay,
        canCreateNew: finalCanCreateNew,
        onCompleted: () {
          Navigator.pop(ctx); // Close registration dialog
          Navigator.pop(context); // Return to menu
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(finalCanCreateNew ? 'ลงทะเบียนเสร็จสิ้น' : 'อัปเดตข้อมูลเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _clear() {
    setState(() {
      _data = null;
      _error = null;
      _currentRegistration = null;
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

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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
        title: const Text('อ่านบัตรประชาชน (Unified)'),
        centerTitle: true,
      ),
      floatingActionButton: _device != null && 
          _device!.hasPermission && 
          !(_isReading || _isProcessing || _isManualReading)
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