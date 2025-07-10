import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';
import 'package:intl/intl.dart';

class CaptureForm extends StatefulWidget {
  const CaptureForm({super.key});

  @override
  State<CaptureForm> createState() => _CaptureFormState();
}

class _CaptureFormState extends State<CaptureForm> {
  ThaiIDCard? _data;
  UsbDevice? _device;
  dynamic _card;
  String? _error;
  bool _isReading = false;

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

  void _clear() {
    setState(() {
      _data = null;
      _error = null;
    });
  }

  void _showErrorDialog() {
    if (_error != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('เกิดข้อผิดพลาด'),
          content: Text(_error!),
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
            if (_isReading) ...[
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('กำลังอ่านข้อมูล...', style: TextStyle(fontSize: 16)),
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