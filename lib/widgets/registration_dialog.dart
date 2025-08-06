import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reg_data.dart';

/// Dialog สำหรับเลือกอุปกรณ์และวันที่เข้าพัก
class RegistrationDialog extends StatefulWidget {
  final RegData regData;
  final bool isFirstTime;
  final Function(RegAdditionalInfo) onCompleted;

  const RegistrationDialog({
    super.key,
    required this.regData,
    required this.isFirstTime,
    required this.onCompleted,
  });

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers สำหรับวันที่
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  // ตัวแปรสำหรับอุปกรณ์
  int _shirtCount = 0;
  int _pantsCount = 0;
  int _matCount = 0;
  int _pillowCount = 0;
  int _blanketCount = 0;
  bool _withChildren = false;
  int _childrenCount = 0;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// ตั้งค่าเริ่มต้น
  void _initializeDefaults() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate!.add(const Duration(days: 7));
    
    _startDateController.text = _formatDate(_startDate!);
    _endDateController.text = _formatDate(_endDate!);
    
    // ค่าเริ่มต้นของอุปกรณ์
    _shirtCount = 1;
    _pantsCount = 1;
    _matCount = 1;
    _pillowCount = 1;
    _blanketCount = 1;
  }

  /// จัดรูปแบบวันที่
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// แปลงวันที่จากข้อความเป็น DateTime
  DateTime? _parseDate(String dateText) {
    try {
      final parts = dateText.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }

  /// เลือกวันที่
  Future<void> _selectDate(bool isStartDate) async {
    final currentDate = isStartDate ? _startDate : _endDate;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          _startDateController.text = _formatDate(selectedDate);
          
          // อัปเดตวันสิ้นสุดให้อยู่หลังวันเริ่มต้น
          if (_endDate != null && _endDate!.isBefore(selectedDate)) {
            _endDate = selectedDate.add(const Duration(days: 1));
            _endDateController.text = _formatDate(_endDate!);
          }
        } else {
          if (selectedDate.isBefore(_startDate!)) {
            _showErrorSnackBar('วันสิ้นสุดต้องอยู่หลังวันเริ่มต้น');
            return;
          }
          _endDate = selectedDate;
          _endDateController.text = _formatDate(selectedDate);
        }
      });
    }
  }

  /// แสดงข้อความข้อผิดพลาด
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// บันทึกข้อมูล
  void _saveRegistration() {
    if (!_formKey.currentState!.validate()) return;

    // ตรวจสอบวันที่
    if (_startDate == null || _endDate == null) {
      _showErrorSnackBar('กรุณาเลือกวันที่เข้าพักและออก');
      return;
    }

    if (_endDate!.isBefore(_startDate!) || _endDate!.isAtSameMomentAs(_startDate!)) {
      _showErrorSnackBar('วันออกต้องอยู่หลังวันเข้าพัก');
      return;
    }

    // สร้างข้อมูลเพิ่มเติม
    final additionalInfo = RegAdditionalInfo.create(
      regId: widget.regData.id,
      startDate: _startDate!,
      endDate: _endDate!,
      shirtCount: _shirtCount,
      pantsCount: _pantsCount,
      matCount: _matCount,
      pillowCount: _pillowCount,
      blanketCount: _blanketCount,
      location: _locationController.text.trim(),
      withChildren: _withChildren,
      childrenCount: _withChildren ? _childrenCount : 0,
      notes: _notesController.text.trim(),
    );

    widget.onCompleted(additionalInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.regData.hasIdCard ? Icons.credit_card : Icons.person,
                    color: widget.regData.hasIdCard ? Colors.blue : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ลงทะเบียนเข้าพัก',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // ข้อมูลผู้ลงทะเบียน
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลผู้ลงทะเบียน',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ชื่อ-นามสกุล: ${widget.regData.first} ${widget.regData.last}'),
                      Text('เลขบัตร/โทร: ${widget.regData.id}'),
                      Row(
                        children: [
                          Text('สถานะบัตร: '),
                          Chip(
                            label: Text(
                              widget.regData.hasIdCard ? 'มีบัตรประชาชน' : 'ไม่มีบัตร',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: widget.regData.hasIdCard 
                                ? Colors.green.shade100 
                                : Colors.orange.shade100,
                          ),
                        ],
                      ),
                      if (!widget.regData.hasIdCard)
                        const Text(
                          '* สามารถแก้ไขข้อมูลส่วนตัวได้ภายหลัง',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // วันที่เข้าพัก
                      Text(
                        'ระยะเวลาการพัก',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              decoration: const InputDecoration(
                                labelText: 'วันเข้าพัก',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณาเลือกวันเข้าพัก';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateController,
                              decoration: const InputDecoration(
                                labelText: 'วันออก',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(false),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณาเลือกวันออก';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // เสื้อผ้าชุดขาว
                      Text(
                        'เสื้อผ้าชุดขาว',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildCounterRow('เสื้อขาว', _shirtCount, (value) {
                                setState(() {
                                  _shirtCount = value;
                                });
                              }),
                              _buildCounterRow('กางเกงขาว', _pantsCount, (value) {
                                setState(() {
                                  _pantsCount = value;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // อุปกรณ์การนอน
                      Text(
                        'อุปกรณ์การนอน',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildCounterRow('เสื่อ', _matCount, (value) {
                                setState(() {
                                  _matCount = value;
                                });
                              }),
                              _buildCounterRow('หมอน', _pillowCount, (value) {
                                setState(() {
                                  _pillowCount = value;
                                });
                              }),
                              _buildCounterRow('ผ้าห่ม', _blanketCount, (value) {
                                setState(() {
                                  _blanketCount = value;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ข้อมูลเพิ่มเติม
                      Text(
                        'ข้อมูลเพิ่มเติม',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // สถานที่พัก
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'ห้อง/ศาลา/สถานที่พัก',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // มาพร้อมเด็ก
                      CheckboxListTile(
                        title: const Text('มาพร้อมเด็ก'),
                        value: _withChildren,
                        onChanged: (value) {
                          setState(() {
                            _withChildren = value ?? false;
                            if (!_withChildren) {
                              _childrenCount = 0;
                            }
                          });
                        },
                      ),

                      if (_withChildren) ...[
                        const SizedBox(height: 8),
                        _buildCounterRow('จำนวนเด็ก', _childrenCount, (value) {
                          setState(() {
                            _childrenCount = value;
                          });
                        }),
                      ],

                      const SizedBox(height: 16),

                      // หมายเหตุ
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุ',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ปุ่มบันทึก
              ElevatedButton(
                onPressed: _saveRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ยืนยันการลงทะเบียน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// สร้างแถวนับจำนวน
  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 10 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}