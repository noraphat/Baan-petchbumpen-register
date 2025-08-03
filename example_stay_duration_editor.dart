import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'lib/utils/stay_duration_validator.dart';

/// ตัวอย่างการใช้งานระบบปรับปรุงวันที่เข้าพัก
class StayDurationEditorExample {
  /// ตัวอย่างการตรวจสอบการปรับปรุงวันที่เข้าพัก
  static void testStayDurationValidation() {
    debugPrint('🧪 ทดสอบการตรวจสอบการปรับปรุงวันที่เข้าพัก');

    final today = DateTime.now();
    final startDate = DateTime(2025, 8, 3);
    final originalEndDate = DateTime(2025, 8, 5);

    // ตัวอย่างการจองที่มีอยู่
    final existingBookings = [
      DateTimeRange(start: DateTime(2025, 8, 6), end: DateTime(2025, 8, 8)),
      DateTimeRange(start: DateTime(2025, 8, 10), end: DateTime(2025, 8, 12)),
    ];

    debugPrint('\n📋 ข้อมูลการทดสอบ:');
    debugPrint('   วันนี้: ${DateFormat('dd/MM/yyyy').format(today)}');
    debugPrint(
      '   วันที่เริ่มต้น: ${DateFormat('dd/MM/yyyy').format(startDate)}',
    );
    debugPrint(
      '   วันที่สิ้นสุดเดิม: ${DateFormat('dd/MM/yyyy').format(originalEndDate)}',
    );
    debugPrint('   การจองที่มีอยู่: ${existingBookings.length} รายการ');

    // ทดสอบกรณีต่างๆ
    _testValidationCase(
      'เพิ่มวันพัก (ถูกต้อง)',
      startDate,
      DateTime(2025, 8, 7),
      existingBookings,
      today,
    );

    _testValidationCase(
      'ลดวันพัก (ถูกต้อง)',
      startDate,
      DateTime(2025, 8, 4),
      existingBookings,
      today,
    );

    _testValidationCase(
      'ลดวันพักเกินไป (ผิด)',
      startDate,
      DateTime(2025, 8, 2),
      existingBookings,
      today,
    );

    _testValidationCase(
      'เพิ่มวันพักจนขัดแย้ง (ผิด)',
      startDate,
      DateTime(2025, 8, 9),
      existingBookings,
      today,
    );
  }

  /// ทดสอบกรณีการตรวจสอบ
  static void _testValidationCase(
    String caseName,
    DateTime startDate,
    DateTime newEndDate,
    List<DateTimeRange> existingBookings,
    DateTime today,
  ) {
    debugPrint('\n🔍 ทดสอบ: $caseName');
    debugPrint(
      '   วันที่สิ้นสุดใหม่: ${DateFormat('dd/MM/yyyy').format(newEndDate)}',
    );

    final result = StayDurationValidator.validateUpdatedStayDate(
      startDate: startDate,
      newEndDate: newEndDate,
      existingBookings: existingBookings,
      today: today,
    );

    if (result.isValid) {
      debugPrint('   ✅ ผ่านการตรวจสอบ');
    } else {
      debugPrint('   ❌ ไม่ผ่านการตรวจสอบ');
      debugPrint('   ข้อความ: ${result.errorMessage}');
      debugPrint('   ประเภท: ${result.errorType}');
    }
  }

  /// ตัวอย่างการสร้างข้อความสรุปการเปลี่ยนแปลง
  static void testChangeSummary() {
    debugPrint('\n📝 ทดสอบการสร้างข้อความสรุปการเปลี่ยนแปลง');

    final originalStartDate = DateTime(2025, 8, 3);
    final originalEndDate = DateTime(2025, 8, 5);
    final newStartDate = DateTime(2025, 8, 3);
    final newEndDate = DateTime(2025, 8, 7);

    final summary = StayDurationValidator.generateChangeSummary(
      originalStartDate: originalStartDate,
      originalEndDate: originalEndDate,
      newStartDate: newStartDate,
      newEndDate: newEndDate,
    );

    debugPrint(summary);
  }
}

/// ตัวอย่าง Widget สำหรับแก้ไขวันที่เข้าพัก
class StayDurationEditorWidget extends StatefulWidget {
  final DateTime originalStartDate;
  final DateTime originalEndDate;
  final Function(DateTime newEndDate) onDateChanged;
  final List<DateTimeRange> existingBookings;

  const StayDurationEditorWidget({
    super.key,
    required this.originalStartDate,
    required this.originalEndDate,
    required this.onDateChanged,
    required this.existingBookings,
  });

  @override
  State<StayDurationEditorWidget> createState() =>
      _StayDurationEditorWidgetState();
}

class _StayDurationEditorWidgetState extends State<StayDurationEditorWidget> {
  DateTime? newEndDate;
  ValidationResult? validationResult;

  @override
  void initState() {
    super.initState();
    newEndDate = widget.originalEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dayDifference = newEndDate != null
        ? newEndDate!.difference(widget.originalEndDate).inDays
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แสดงข้อมูลปัจจุบัน
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ข้อมูลการเข้าพักปัจจุบัน:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'วันที่เริ่มต้น: ${DateFormat('dd/MM/yyyy', 'th').format(widget.originalStartDate)}',
              ),
              Text(
                'วันที่สิ้นสุด: ${DateFormat('dd/MM/yyyy', 'th').format(widget.originalEndDate)}',
              ),
              Text(
                'จำนวนวัน: ${StayDurationValidator.calculateDaysDifference(widget.originalStartDate, widget.originalEndDate) + 1} วัน',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // เลือกวันที่ใหม่
        const Text(
          'เลือกวันที่สิ้นสุดใหม่:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showDatePicker(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  newEndDate != null
                      ? DateFormat('dd/MM/yyyy', 'th').format(newEndDate!)
                      : 'เลือกวันที่',
                ),
              ],
            ),
          ),
        ),

        // แสดงการเปลี่ยนแปลง
        if (newEndDate != null && dayDifference != 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dayDifference > 0
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              border: Border.all(
                color: dayDifference > 0
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  dayDifference > 0 ? Icons.trending_up : Icons.trending_down,
                  color: dayDifference > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  dayDifference > 0
                      ? 'เพิ่ม $dayDifference วัน'
                      : 'ลด ${dayDifference.abs()} วัน',
                  style: TextStyle(
                    color: dayDifference > 0
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],

        // แสดงผลการตรวจสอบ
        if (validationResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: validationResult!.isValid
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              border: Border.all(
                color: validationResult!.isValid
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  validationResult!.isValid ? Icons.check_circle : Icons.error,
                  color: validationResult!.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    validationResult!.isValid
                        ? 'การเปลี่ยนแปลงถูกต้อง'
                        : validationResult!.errorMessage!,
                    style: TextStyle(
                      color: validationResult!.isValid
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // ปุ่มบันทึก
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                newEndDate != null && (validationResult?.isValid ?? false)
                ? () => widget.onDateChanged(newEndDate!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('บันทึกการเปลี่ยนแปลง'),
          ),
        ),
      ],
    );
  }

  /// แสดง DatePicker
  Future<void> _showDatePicker() async {
    final today = DateTime.now();
    final firstDate = widget.originalStartDate;
    final lastDate = today.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: newEndDate ?? widget.originalEndDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('th'),
    );

    if (picked != null) {
      setState(() {
        newEndDate = picked;
      });

      // ตรวจสอบความถูกต้อง
      _validateNewDate(picked);
    }
  }

  /// ตรวจสอบความถูกต้องของวันที่ใหม่
  void _validateNewDate(DateTime newEndDate) {
    final today = DateTime.now();

    final result = StayDurationValidator.validateUpdatedStayDate(
      startDate: widget.originalStartDate,
      newEndDate: newEndDate,
      existingBookings: widget.existingBookings,
      today: today,
    );

    setState(() {
      validationResult = result;
    });
  }
}

/// ตัวอย่างการใช้งานใน Screen
class StayDurationEditorScreen extends StatefulWidget {
  const StayDurationEditorScreen({super.key});

  @override
  State<StayDurationEditorScreen> createState() =>
      _StayDurationEditorScreenState();
}

class _StayDurationEditorScreenState extends State<StayDurationEditorScreen> {
  DateTime _originalStartDate = DateTime(2025, 8, 3);
  DateTime _originalEndDate = DateTime(2025, 8, 5);
  DateTime? _newEndDate;

  final List<DateTimeRange> _existingBookings = [
    DateTimeRange(start: DateTime(2025, 8, 6), end: DateTime(2025, 8, 8)),
    DateTimeRange(start: DateTime(2025, 8, 10), end: DateTime(2025, 8, 12)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปรับปรุงวันที่เข้าพัก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงข้อมูลการเข้าพัก
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อมูลการเข้าพัก',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('ผู้เข้าพัก: ตัวอย่าง ผู้ใช้'),
                    Text('ห้อง: ห้อง 101'),
                    Text(
                      'วันที่เริ่มต้น: ${DateFormat('dd/MM/yyyy', 'th').format(_originalStartDate)}',
                    ),
                    Text(
                      'วันที่สิ้นสุด: ${DateFormat('dd/MM/yyyy', 'th').format(_originalEndDate)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // แก้ไขวันที่
            StayDurationEditorWidget(
              originalStartDate: _originalStartDate,
              originalEndDate: _originalEndDate,
              existingBookings: _existingBookings,
              onDateChanged: (newEndDate) {
                setState(() {
                  _newEndDate = newEndDate;
                });

                // แสดงข้อความสำเร็จ
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'ปรับปรุงวันที่เข้าพักสำเร็จ: ${DateFormat('dd/MM/yyyy', 'th').format(newEndDate)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            const Spacer(),

            // ปุ่มทดสอบ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    StayDurationEditorExample.testStayDurationValidation(),
                icon: const Icon(Icons.bug_report),
                label: const Text('ทดสอบการตรวจสอบ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
