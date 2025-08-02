import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ตัวอย่างการใช้งาน DateRangePicker ที่จำกัดช่วงวันที่ตามข้อมูลการลงทะเบียน
///
/// ✅ เงื่อนไขที่ต้องการ:
/// - firstDate = startDate (จากข้อมูลการลงทะเบียน)
/// - lastDate = endDate (จากข้อมูลการลงทะเบียน)
/// - ไม่อนุญาตให้เลือกวันนอกช่วงนี้
class DateRangePickerExample extends StatefulWidget {
  const DateRangePickerExample({super.key});

  @override
  State<DateRangePickerExample> createState() => _DateRangePickerExampleState();
}

class _DateRangePickerExampleState extends State<DateRangePickerExample> {
  DateTimeRange? selectedRange;

  // ข้อมูลตัวอย่างจากฐานข้อมูล (ข้อมูลการลงทะเบียน)
  final Map<String, dynamic> registrationData = {
    'startDate': '2024-01-15', // วันเริ่มต้นที่ลงทะเบียน
    'endDate': '2024-01-20', // วันสิ้นสุดที่ลงทะเบียน
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตัวอย่าง DateRangePicker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงข้อมูลการลงทะเบียน
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📅 ข้อมูลการลงทะเบียน:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('วันเริ่มต้น: ${registrationData['startDate']}'),
                    Text('วันสิ้นสุด: ${registrationData['endDate']}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่มเลือกช่วงวันที่
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.date_range),
                label: const Text('เลือกช่วงวันที่เข้าพัก'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // แสดงผลลัพธ์
            if (selectedRange != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ ช่วงวันที่ที่เลือก:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('วันเริ่มต้น: ${_formatDate(selectedRange!.start)}'),
                      Text('วันสิ้นสุด: ${_formatDate(selectedRange!.end)}'),
                      Text(
                        'จำนวนวัน: ${selectedRange!.duration.inDays + 1} วัน',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // คำแนะนำ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 คำแนะนำ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• ระบบจะจำกัดให้เลือกได้เฉพาะช่วงวันที่ที่ลงทะเบียนไว้เท่านั้น',
                  ),
                  Text('• หากเลือกวันนอกช่วง ระบบจะไม่อนุญาตให้บันทึก'),
                  Text('• ช่วงเริ่มต้นจะถูกตั้งเป็นช่วงเต็มที่ลงทะเบียนไว้'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดง DateRangePicker ที่จำกัดช่วงวันที่ตามข้อมูลการลงทะเบียน
  Future<void> _showDateRangePicker() async {
    try {
      // ตรวจสอบว่ามีข้อมูลวันที่ลงทะเบียนหรือไม่
      if (registrationData['startDate'] == null ||
          registrationData['endDate'] == null) {
        _showErrorDialog('ไม่พบข้อมูลช่วงเวลาเข้าพักที่ลงทะเบียนไว้');
        return;
      }

      // แปลงข้อมูลวันที่จาก String เป็น DateTime
      final DateTime startDate = DateTime.parse(registrationData['startDate']);
      final DateTime endDate = DateTime.parse(registrationData['endDate']);

      debugPrint('📅 Registration Date Range:');
      debugPrint('   startDate: $startDate');
      debugPrint('   endDate: $endDate');

      // ✅ กำหนดช่วงวันที่ที่อนุญาตให้เลือกได้
      // ตามเงื่อนไขที่ต้องการ: firstDate = startDate, lastDate = endDate
      final DateTime firstDate = startDate;
      final DateTime lastDate = endDate;

      // กำหนดช่วงเริ่มต้น (initial range) เป็นช่วงเต็มที่ลงทะเบียนไว้
      final DateTimeRange initialRange = DateTimeRange(
        start: startDate,
        end: endDate,
      );

      debugPrint('📅 DateRangePicker Configuration:');
      debugPrint('   firstDate: $firstDate');
      debugPrint('   lastDate: $lastDate');
      debugPrint(
        '   initialRange: ${initialRange.start} - ${initialRange.end}',
      );

      // แสดง DateRangePicker
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: firstDate, // ✅ จำกัดวันแรก = startDate
        lastDate: lastDate, // ✅ จำกัดวันสุดท้าย = endDate
        initialDateRange: initialRange,
        locale: const Locale('th'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: Colors.blue),
            ),
            child: child!,
          );
        },
        helpText: 'เลือกช่วงวันที่เข้าพัก',
        cancelText: 'ยกเลิก',
        confirmText: 'ยืนยัน',
        saveText: 'บันทึก',
        errorFormatText: 'รูปแบบวันที่ไม่ถูกต้อง',
        errorInvalidText: 'วันที่ไม่ถูกต้อง',
        errorInvalidRangeText: 'ช่วงวันที่ไม่ถูกต้อง',
        fieldStartHintText: 'วันเริ่มต้น',
        fieldEndHintText: 'วันสิ้นสุด',
      );

      if (picked != null && mounted) {
        // ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก
        final bool isValid = _validateDateRange(picked, startDate, endDate);

        if (isValid) {
          setState(() {
            selectedRange = picked;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'เลือกช่วงวันที่สำเร็จ: ${_formatDate(picked.start)} - ${_formatDate(picked.end)}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // แสดงข้อความ error หากเลือกวันที่ไม่ถูกต้อง
          final String errorMessage = _getErrorMessage(
            picked,
            startDate,
            endDate,
          );
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      debugPrint('Error showing date range picker: $e');
      if (mounted) {
        _showErrorDialog('เกิดข้อผิดพลาดในการเปิดปฏิทิน: $e');
      }
    }
  }

  /// ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก
  bool _validateDateRange(
    DateTimeRange selectedRange,
    DateTime startDate,
    DateTime endDate,
  ) {
    debugPrint('🔍 Validating date range:');
    debugPrint('   Selected: ${selectedRange.start} - ${selectedRange.end}');
    debugPrint('   Allowed: $startDate - $endDate');

    // ตรวจสอบว่าวันเริ่มต้นต้องไม่ก่อนวันที่ลงทะเบียน
    final bool startValid =
        selectedRange.start.isAtSameMomentAs(startDate) ||
        selectedRange.start.isAfter(startDate);

    // ตรวจสอบว่าวันสิ้นสุดต้องไม่หลังวันที่ลงทะเบียน
    final bool endValid =
        selectedRange.end.isAtSameMomentAs(endDate) ||
        selectedRange.end.isBefore(endDate);

    // ตรวจสอบว่าวันเริ่มต้นไม่หลังวันสิ้นสุด
    final bool rangeValid =
        selectedRange.start.isBefore(selectedRange.end) ||
        _isSameDay(selectedRange.start, selectedRange.end);

    debugPrint('   Start valid: $startValid');
    debugPrint('   End valid: $endValid');
    debugPrint('   Range valid: $rangeValid');

    return startValid && endValid && rangeValid;
  }

  /// สร้างข้อความ error สำหรับช่วงวันที่ที่ไม่ถูกต้อง
  String _getErrorMessage(
    DateTimeRange selectedRange,
    DateTime startDate,
    DateTime endDate,
  ) {
    final String selectedStart = _formatDate(selectedRange.start);
    final String selectedEnd = _formatDate(selectedRange.end);
    final String regStart = _formatDate(startDate);
    final String regEnd = _formatDate(endDate);

    String errorMessage =
        '❌ **ไม่สามารถเลือกวันเกินช่วงที่ลงทะเบียนไว้ได้**\n\n';

    // ตรวจสอบว่าวันเริ่มต้นหรือวันสิ้นสุดที่เกิน
    if (selectedRange.start.isBefore(startDate)) {
      errorMessage +=
          '• วันเริ่มต้น ($selectedStart) ต้องไม่ก่อนวันที่ลงทะเบียน ($regStart)\n';
    }

    if (selectedRange.end.isAfter(endDate)) {
      errorMessage +=
          '• วันสิ้นสุด ($selectedEnd) ต้องไม่หลังวันที่ลงทะเบียน ($regEnd)\n';
    }

    errorMessage += '\n**ช่วงที่เลือก:** $selectedStart - $selectedEnd\n';
    errorMessage += '**ช่วงที่ลงทะเบียน:** $regStart - $regEnd\n\n';
    errorMessage += '⚠️ กรุณาเลือกวันที่ระหว่าง $regStart ถึง $regEnd เท่านั้น';

    return errorMessage;
  }

  /// ตรวจสอบว่าเป็นวันเดียวกันหรือไม่
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// จัดรูปแบบวันที่
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'th').format(date);
  }

  /// แสดง Dialog ข้อความ error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อผิดพลาด'),
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
}

/// วิธีการใช้งาน:
/// 
/// 1. สร้าง StatefulWidget ที่มีข้อมูลการลงทะเบียน
/// 2. ใช้ showDateRangePicker() พร้อมกำหนด:
///    - firstDate = startDate (จากข้อมูลการลงทะเบียน)
///    - lastDate = endDate (จากข้อมูลการลงทะเบียน)
///    - initialDateRange = ช่วงเต็มที่ลงทะเบียนไว้
/// 3. ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก
/// 4. แสดงข้อความ error หากเลือกวันที่ไม่ถูกต้อง
/// 
/// ข้อดี:
/// ✅ จำกัดช่วงวันที่ได้อย่างเคร่งครัด
/// ✅ ผู้ใช้ไม่สามารถเลือกวันนอกช่วงได้
/// ✅ มีการตรวจสอบความถูกต้อง
/// ✅ แสดงข้อความ error ที่ชัดเจน
/// ✅ รองรับภาษาไทย