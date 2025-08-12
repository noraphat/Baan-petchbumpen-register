import 'package:flutter/material.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import '../services/card_reader_service.dart';

/// Widget สำหรับแสดงสถานะการเชื่อมต่อเครื่องอ่านบัตร
class ConnectionStatusWidget extends StatelessWidget {
  final CardReaderService cardReaderService;

  const ConnectionStatusWidget({super.key, required this.cardReaderService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cardReaderService,
      builder: (context, child) {
        final status = cardReaderService.connectionStatus;
        final device = cardReaderService.currentDevice;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatusIcon(status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(status),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStatusSubtitle(status, device),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // แสดงข้อผิดพลาด
                if (cardReaderService.lastError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cardReaderService.lastError!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(CardReaderConnectionStatus status) {
    switch (status) {
      case CardReaderConnectionStatus.connected:
        return const Icon(Icons.usb, color: Colors.green, size: 32);
      case CardReaderConnectionStatus.connecting:
        return const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case CardReaderConnectionStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 32);
      case CardReaderConnectionStatus.disconnected:
      default:
        return const Icon(Icons.usb_off, color: Colors.grey, size: 32);
    }
  }

  String _getStatusTitle(CardReaderConnectionStatus status) {
    switch (status) {
      case CardReaderConnectionStatus.connected:
        return 'เชื่อมต่อแล้ว';
      case CardReaderConnectionStatus.connecting:
        return 'กำลังเชื่อมต่อ...';
      case CardReaderConnectionStatus.error:
        return 'เกิดข้อผิดพลาด';
      case CardReaderConnectionStatus.disconnected:
      default:
        return 'ไม่ได้เชื่อมต่อ';
    }
  }

  String _getStatusSubtitle(
    CardReaderConnectionStatus status,
    UsbDevice? device,
  ) {
    switch (status) {
      case CardReaderConnectionStatus.connected:
        return device != null
            ? '${device.manufacturerName} ${device.productName}'
            : 'เครื่องอ่านบัตรพร้อมใช้งาน';
      case CardReaderConnectionStatus.connecting:
        return 'กำลังตรวจหาเครื่องอ่านบัตร...';
      case CardReaderConnectionStatus.error:
        return 'โปรดตรวจสอบการเชื่อมต่อ';
      case CardReaderConnectionStatus.disconnected:
      default:
        return 'กรุณาเชื่อมต่อเครื่องอ่านบัตร USB';
    }
  }
}

/// Widget สำหรับแสดงสถานะการอ่านบัตร
class CardReadingStatusWidget extends StatelessWidget {
  final CardReaderService cardReaderService;

  const CardReadingStatusWidget({super.key, required this.cardReaderService});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cardReaderService,
      builder: (context, child) {
        final readingStatus = cardReaderService.readingStatus;

        if (readingStatus == CardReadingStatus.idle) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildReadingIcon(readingStatus),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getReadingTitle(readingStatus),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getReadingSubtitle(readingStatus),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadingIcon(CardReadingStatus status) {
    switch (status) {
      case CardReadingStatus.reading:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case CardReadingStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green, size: 24);
      case CardReadingStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 24);
      case CardReadingStatus.noCard:
        return const Icon(
          Icons.credit_card_off,
          color: Colors.orange,
          size: 24,
        );
      case CardReadingStatus.cardDamaged:
        return const Icon(Icons.warning, color: Colors.amber, size: 24);
      case CardReadingStatus.idle:
      default:
        return const Icon(Icons.credit_card, color: Colors.grey, size: 24);
    }
  }

  String _getReadingTitle(CardReadingStatus status) {
    switch (status) {
      case CardReadingStatus.reading:
        return 'กำลังอ่านบัตร...';
      case CardReadingStatus.success:
        return 'อ่านบัตรสำเร็จ';
      case CardReadingStatus.failed:
        return 'อ่านบัตรไม่สำเร็จ';
      case CardReadingStatus.noCard:
        return 'ไม่พบบัตรประชาชน';
      case CardReadingStatus.cardDamaged:
        return 'บัตรไม่สมบูรณ์';
      case CardReadingStatus.idle:
      default:
        return 'พร้อมอ่านบัตร';
    }
  }

  String _getReadingSubtitle(CardReadingStatus status) {
    switch (status) {
      case CardReadingStatus.reading:
        return 'โปรดอย่าถอดบัตรออก...';
      case CardReadingStatus.success:
        return 'ข้อมูลบัตรถูกต้อง';
      case CardReadingStatus.failed:
        return 'กรุณาลองอีกครั้ง';
      case CardReadingStatus.noCard:
        return 'กรุณาเสียบบัตรประชาชน';
      case CardReadingStatus.cardDamaged:
        return 'ข้อมูลบัตรไม่ครบถ้วน';
      case CardReadingStatus.idle:
      default:
        return 'เสียบบัตรเพื่อเริ่มต้น';
    }
  }
}

/// ปุ่มตรวจสอบบัตรอีกครั้ง
class RecheckCardButton extends StatefulWidget {
  final CardReaderService cardReaderService;
  final Function(ThaiIdCardData)? onCardRead;
  final Function(String)? onError;

  const RecheckCardButton({
    super.key,
    required this.cardReaderService,
    this.onCardRead,
    this.onError,
  });

  @override
  State<RecheckCardButton> createState() => _RecheckCardButtonState();
}

class _RecheckCardButtonState extends State<RecheckCardButton> {
  bool _isRecheckingManually = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cardReaderService,
      builder: (context, child) {
        final isConnected = widget.cardReaderService.isConnected;
        final isReading =
            widget.cardReaderService.isReading || _isRecheckingManually;

        return Column(
          children: [
            // ปุ่มหลัก
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isConnected && !isReading) ? _recheckCard : null,
                icon: _isRecheckingManually
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
                    : const Icon(Icons.refresh),
                label: Text(
                  _isRecheckingManually
                      ? 'กำลังตรวจสอบ...'
                      : 'ตรวจสอบบัตรอีกครั้ง',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

            // ข้อความคำแนะนำ
            if (isConnected && !isReading) ...[
              const SizedBox(height: 8),
              Text(
                'หากบัตรเสียบอยู่แล้วแต่ระบบไม่อ่าน กดปุ่มนี้เพื่อลองอ่านอีกครั้ง',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _recheckCard() async {
    if (_isRecheckingManually || widget.cardReaderService.isReading) return;

    setState(() {
      _isRecheckingManually = true;
    });

    try {
      // ลองอ่านบัตร
      final cardData = await widget.cardReaderService.readCard();

      if (cardData != null) {
        // แสดงข้อความสำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('อ่านบัตรประชาชนสำเร็จ'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // เรียก callback
        widget.onCardRead?.call(cardData);
      }
    } catch (e) {
      // จัดการ error
      final errorMessage = e is CardReaderException
          ? e.message
          : 'เกิดข้อผิดพลาดในการอ่านบัตร: $e';

      widget.onError?.call(errorMessage);

      if (mounted) {
        _showRecheckErrorDialog(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecheckingManually = false;
        });
      }
    }
  }

  String _getUserFriendlyErrorMessage(String errorMessage) {
    // แปลงข้อความ error ให้เป็นมิตรกับผู้ใช้
    if (errorMessage.contains('FormatException')) {
      return 'ข้อมูลบัตรประชาชนไม่ถูกต้อง กรุณาตรวจสอบบัตร';
    } else if (errorMessage.contains('timeout') ||
        errorMessage.contains('Timeout')) {
      return 'การอ่านบัตรใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
    } else if (errorMessage.contains('connection') ||
        errorMessage.contains('Connection')) {
      return 'ไม่สามารถเชื่อมต่อกับเครื่องอ่านบัตรได้';
    } else if (errorMessage.contains('permission') ||
        errorMessage.contains('Permission')) {
      return 'ไม่มีสิทธิ์ในการเข้าถึงเครื่องอ่านบัตร';
    } else if (errorMessage.contains('device') ||
        errorMessage.contains('Device')) {
      return 'ไม่พบเครื่องอ่านบัตร กรุณาตรวจสอบการเชื่อมต่อ';
    } else if (errorMessage.contains('card') || errorMessage.contains('Card')) {
      return 'ไม่สามารถอ่านข้อมูลจากบัตรได้ กรุณาตรวจสอบบัตร';
    } else {
      return 'เกิดข้อผิดพลาดในการอ่านบัตร กรุณาลองใหม่อีกครั้ง';
    }
  }

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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getUserFriendlyErrorMessage(errorMessage),
                style: const TextStyle(fontSize: 14),
                softWrap: true,
              ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ลองอีกครั้งหลังจากปิด dialog
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) _recheckCard();
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
}

/// Widget สำหรับแสดงข้อมูลบัตรที่อ่านได้
class CardDataDisplayWidget extends StatelessWidget {
  final ThaiIdCardData cardData;

  const CardDataDisplayWidget({super.key, required this.cardData});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: const Text('ถูกต้อง', style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green.shade100,
                ),
              ],
            ),
            const Divider(),

            // ข้อมูลพื้นฐาน
            _buildInfoRow('เลขบัตร', cardData.cid),
            _buildInfoRow('ชื่อ-นามสกุล (ไทย)', cardData.fullNameTH),
            if (cardData.fullNameEN.isNotEmpty)
              _buildInfoRow('ชื่อ-นามสกุล (อังกฤษ)', cardData.fullNameEN),
            _buildInfoRow('เพศ', cardData.genderText),
            if (cardData.birthdate != null)
              _buildInfoRow('วันเกิด', cardData.birthdate!),
            if (cardData.address != null)
              _buildInfoRow('ที่อยู่', cardData.address!),

            const SizedBox(height: 12),

            // เวลาที่อ่านบัตร
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'อ่านเมื่อ: ${_formatDateTime(cardData.readTimestamp)}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget สำหรับตรวจสอบการเชื่อมต่อที่แข็งแกร่ง (Enhanced Connection Checker)
class EnhancedConnectionChecker extends StatefulWidget {
  final CardReaderService cardReaderService;
  final Widget Function(bool isConnected, String statusMessage) builder;
  final VoidCallback? onConnectionRestored;

  const EnhancedConnectionChecker({
    super.key,
    required this.cardReaderService,
    required this.builder,
    this.onConnectionRestored,
  });

  @override
  State<EnhancedConnectionChecker> createState() =>
      _EnhancedConnectionCheckerState();
}

class _EnhancedConnectionCheckerState extends State<EnhancedConnectionChecker> {
  bool _isConnected = false;
  String _statusMessage = 'กำลังตรวจสอบการเชื่อมต่อ...';
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionOnInit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ตรวจสอบการเชื่อมต่อเมื่อ dependencies เปลี่ยน (เช่น เมื่อกลับมาหน้า)
    _checkConnectionOnPageReturn();
  }

  /// ตรวจสอบการเชื่อมต่อเมื่อเริ่มต้น
  Future<void> _checkConnectionOnInit() async {
    await _performConnectionCheck();
  }

  /// ตรวจสอบการเชื่อมต่อเมื่อกลับมาหน้า
  Future<void> _checkConnectionOnPageReturn() async {
    // รอให้ widget ทำงานเสร็จก่อน
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      await _performConnectionCheck();
    }
  }

  /// ดำเนินการตรวจสอบการเชื่อมต่อ
  Future<void> _performConnectionCheck() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _statusMessage = 'กำลังตรวจสอบการเชื่อมต่อ...';
    });

    try {
      // ตรวจสอบการเชื่อมต่อแบบแข็งแกร่ง
      final isConnected = await widget.cardReaderService.ensureConnection();

      if (mounted) {
        setState(() {
          _isConnected = isConnected;
          _statusMessage = isConnected
              ? 'เครื่องอ่านบัตรพร้อมใช้งาน'
              : 'ไม่พบเครื่องอ่านบัตร - กรุณาเสียบ USB';
        });

        // แจ้งเตือนเมื่อการเชื่อมต่อฟื้นฟู
        if (isConnected && !_isConnected) {
          widget.onConnectionRestored?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'เกิดข้อผิดพลาดในการตรวจสอบ: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// ตรวจสอบการเชื่อมต่อด้วยตนเอง
  Future<void> _manualCheckConnection() async {
    await _performConnectionCheck();
  }

  /// ตรวจสอบ Permission
  Future<void> _checkPermission() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _statusMessage = 'กำลังตรวจสอบสิทธิ์การเข้าถึง...';
    });

    try {
      final hasPermission = await widget.cardReaderService.ensurePermission();

      if (mounted) {
        setState(() {
          _isConnected = hasPermission;
          _statusMessage = hasPermission
              ? 'ได้รับสิทธิ์การเข้าถึงแล้ว'
              : 'ไม่ได้รับสิทธิ์การเข้าถึง';
        });

        if (hasPermission) {
          widget.onConnectionRestored?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'เกิดข้อผิดพลาดในการตรวจสอบสิทธิ์: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // แสดงสถานะการเชื่อมต่อ
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.usb : Icons.usb_off,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'เชื่อมต่อแล้ว' : 'ไม่ได้เชื่อมต่อ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        _statusMessage,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (_isChecking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _manualCheckConnection,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'ตรวจสอบการเชื่อมต่อใหม่',
                      ),
                      IconButton(
                        onPressed: _checkPermission,
                        icon: const Icon(Icons.security),
                        tooltip: 'ตรวจสอบสิทธิ์การเข้าถึง',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // แสดงเนื้อหาหลัก
        widget.builder(_isConnected, _statusMessage),
      ],
    );
  }
}

/// ปุ่มรีเซ็ตการเชื่อมต่อแบบขั้นสูง
class AdvancedResetButton extends StatefulWidget {
  final CardReaderService cardReaderService;
  final VoidCallback? onResetComplete;
  final VoidCallback? onResetFailed;

  const AdvancedResetButton({
    super.key,
    required this.cardReaderService,
    this.onResetComplete,
    this.onResetFailed,
  });

  @override
  State<AdvancedResetButton> createState() => _AdvancedResetButtonState();
}

class _AdvancedResetButtonState extends State<AdvancedResetButton> {
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ปุ่มรีเซ็ต
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isResetting ? null : _performAdvancedReset,
            icon: _isResetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.restart_alt),
            label: Text(
              _isResetting ? 'กำลังรีเซ็ต...' : 'รีเซ็ตการเชื่อมต่อแบบขั้นสูง',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),
        ),

        // ข้อความคำแนะนำ
        if (!_isResetting) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.purple.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'รีเซ็ตแบบขั้นสูง',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• รีเซ็ตการเชื่อมต่อทั้งหมด\n'
                  '• ตรวจสอบ USB device ใหม่\n'
                  '• แก้ไขปัญหาการเชื่อมต่อที่ซับซ้อน\n'
                  '• ใช้เวลาประมาณ 5-10 วินาที',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _performAdvancedReset() async {
    if (_isResetting) return;

    setState(() {
      _isResetting = true;
    });

    try {
      // แสดง dialog ยืนยัน
      final confirmed = await _showResetConfirmDialog();

      if (confirmed == true) {
        // ดำเนินการรีเซ็ต
        await widget.cardReaderService.resetConnection();

        // รอสักครู่
        await Future.delayed(const Duration(seconds: 2));

        // ตรวจสอบผลลัพธ์
        final isConnected = await widget.cardReaderService.checkConnection();

        if (mounted) {
          if (isConnected) {
            widget.onResetComplete?.call();
            _showSuccessSnackBar('รีเซ็ตการเชื่อมต่อสำเร็จ');
          } else {
            widget.onResetFailed?.call();
            _showResetFailedDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onResetFailed?.call();
        _showErrorSnackBar('รีเซ็ตการเชื่อมต่อล้มเหลว: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<bool?> _showResetConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.restart_alt, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            const Text('ยืนยันการรีเซ็ต'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการรีเซ็ตการเชื่อมต่อแบบขั้นสูงหรือไม่?'),
            SizedBox(height: 12),
            Text(
              'การดำเนินการนี้จะ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• หยุดการเชื่อมต่อทั้งหมด'),
            Text('• ตรวจสอบ USB device ใหม่'),
            Text('• เริ่มต้นระบบใหม่'),
            SizedBox(height: 8),
            Text(
              'ใช้เวลาประมาณ 5-10 วินาที',
              style: TextStyle(fontStyle: FontStyle.italic),
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
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('รีเซ็ต'),
          ),
        ],
      ),
    );
  }

  void _showResetFailedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Text('รีเซ็ตไม่สำเร็จ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ไม่สามารถรีเซ็ตการเชื่อมต่อได้'),
            const SizedBox(height: 16),
            const Text(
              'กรุณาลอง:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• ถอดและเสียบ USB ใหม่'),
            const Text('• ตรวจสอบสาย USB'),
            const Text('• ลองใช้ USB port อื่น'),
            const Text('• รีสตาร์ทแอปพลิเคชัน'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'หากยังไม่สามารถแก้ไขได้ กรุณาติดต่อผู้ดูแลระบบ',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Widget สำหรับจัดการ Permission
class PermissionManagerWidget extends StatefulWidget {
  final CardReaderService cardReaderService;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionManagerWidget({
    super.key,
    required this.cardReaderService,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<PermissionManagerWidget> createState() =>
      _PermissionManagerWidgetState();
}

class _PermissionManagerWidgetState extends State<PermissionManagerWidget> {
  bool _isRequestingPermission = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.cardReaderService,
      builder: (context, child) {
        final device = widget.cardReaderService.currentDevice;
        final hasPermission = device?.hasPermission ?? false;
        final isAttached = device?.isAttached ?? false;

        if (!isAttached) {
          return const SizedBox.shrink();
        }

        if (hasPermission) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.orange.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ต้องการสิทธิ์ในการเข้าถึง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ระบบต้องการสิทธิ์ในการเข้าถึงเครื่องอ่านบัตรประชาชน',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRequestingPermission
                        ? null
                        : _requestPermission,
                    icon: _isRequestingPermission
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
                        : const Icon(Icons.security),
                    label: Text(
                      _isRequestingPermission
                          ? 'กำลังขอสิทธิ์...'
                          : 'ขอสิทธิ์การเข้าถึง',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'คำแนะนำ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• ระบบจะแสดง dialog ขอสิทธิ์การเข้าถึง USB device',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '• กรุณากด "อนุญาต" หรือ "Allow" เพื่อให้ระบบทำงานได้',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '• หากไม่ได้รับสิทธิ์ ให้ลองเสียบ USB ใหม่',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final success = await widget.cardReaderService.requestPermission();

      if (success) {
        widget.onPermissionGranted?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ได้รับสิทธิ์การเข้าถึงแล้ว'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        widget.onPermissionDenied?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ไม่ได้รับสิทธิ์การเข้าถึง'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      widget.onPermissionDenied?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('เกิดข้อผิดพลาด: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPermission = false;
        });
      }
    }
  }
}
