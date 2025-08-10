import 'package:flutter/material.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import '../services/card_reader_service.dart';

/// Widget สำหรับแสดงสถานะการเชื่อมต่อเครื่องอ่านบัตร
class ConnectionStatusWidget extends StatelessWidget {
  final CardReaderService cardReaderService;
  
  const ConnectionStatusWidget({
    super.key,
    required this.cardReaderService,
  });

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
                        Icon(Icons.error_outline, 
                             color: Colors.red.shade600, 
                             size: 20),
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

  String _getStatusSubtitle(CardReaderConnectionStatus status, UsbDevice? device) {
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
  
  const CardReadingStatusWidget({
    super.key,
    required this.cardReaderService,
  });

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
        return const Icon(Icons.credit_card_off, color: Colors.orange, size: 24);
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
        final isReading = widget.cardReaderService.isReading || _isRecheckingManually;
        
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showRecheckErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('ไม่สามารถอ่านบัตรได้'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เกิดข้อผิดพลาด: $errorMessage',
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
  
  const CardDataDisplayWidget({
    super.key,
    required this.cardData,
  });

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
                  Icon(Icons.access_time, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'อ่านเมื่อ: ${_formatDateTime(cardData.readTimestamp)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
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
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 16),
            ),
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