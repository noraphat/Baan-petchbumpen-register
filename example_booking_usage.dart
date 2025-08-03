import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'lib/utils/booking_date_utils.dart';

/// ตัวอย่างการใช้งานฟังก์ชันการจัดการวันที่สำหรับการจองห้องพัก
class BookingDateExample {
  /// ตัวอย่างการใช้งาน showDateRangePicker พร้อมการป้องกันการจองย้อนหลัง
  static Future<void> showBookingDateRangePicker(
    BuildContext context,
    DateTime registrationStartDate,
    DateTime registrationEndDate,
  ) async {
    // ใช้ฟังก์ชันใหม่เพื่อกำหนดช่วงวันที่ที่อนุญาต
    final firstDate = BookingDateUtils.getFirstAvailableBookingDate(
      registrationStartDate,
    );
    final lastDate = BookingDateUtils.getLastAvailableBookingDate(
      registrationEndDate,
    );

    // สร้างช่วงวันที่เริ่มต้น
    final initialRange = BookingDateUtils.getInitialDateRange(
      firstDate,
      lastDate,
    );

    debugPrint('📅 ตัวอย่างการใช้งาน:');
    debugPrint(
      '   ข้อมูลการลงทะเบียน: $registrationStartDate - $registrationEndDate',
    );
    debugPrint('   ช่วงวันที่ที่อนุญาต: $firstDate - $lastDate');
    debugPrint('   ช่วงเริ่มต้น: ${initialRange.start} - ${initialRange.end}');

    // แสดง DateRangePicker
    final result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
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

    if (result != null) {
      // ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก
      final isValid = BookingDateUtils.validateBookingDateRange(
        result,
        registrationStartDate,
        registrationEndDate,
      );

      if (isValid) {
        debugPrint(
          '✅ ช่วงวันที่ที่เลือกถูกต้อง: ${result.start} - ${result.end}',
        );
        // ดำเนินการจองต่อไป...
      } else {
        debugPrint('❌ ช่วงวันที่ที่เลือกไม่ถูกต้อง');
        // แสดงข้อความ error
        final errorMessage = BookingDateUtils.getDateRangeErrorMessage(
          result,
          registrationStartDate,
          registrationEndDate,
          (dateStr) =>
              DateFormat('dd/MM/yyyy', 'th').format(DateTime.parse(dateStr)),
        );

        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ช่วงวันที่ไม่ถูกต้อง'),
              content: Text(errorMessage),
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
    }
  }

  /// ตัวอย่างการทดสอบฟังก์ชันต่างๆ
  static void testBookingDateFunctions() {
    debugPrint('🧪 ทดสอบฟังก์ชันการจัดการวันที่');

    // ตัวอย่างที่ 1: ลงทะเบียนไว้ 02-06/08/2025, วันนี้คือ 03/08/2025
    final registrationStart1 = DateTime(2025, 8, 2);
    final registrationEnd1 = DateTime(2025, 8, 6);
    final today = DateTime(2025, 8, 3);

    debugPrint('\n📋 ตัวอย่างที่ 1:');
    debugPrint(
      '   ลงทะเบียน: ${DateFormat('dd/MM/yyyy').format(registrationStart1)} - ${DateFormat('dd/MM/yyyy').format(registrationEnd1)}',
    );
    debugPrint('   วันนี้: ${DateFormat('dd/MM/yyyy').format(today)}');

    final firstDate1 = BookingDateUtils.getFirstAvailableBookingDate(
      registrationStart1,
    );
    final lastDate1 = BookingDateUtils.getLastAvailableBookingDate(
      registrationEnd1,
    );

    debugPrint('   firstDate: ${DateFormat('dd/MM/yyyy').format(firstDate1)}');
    debugPrint('   lastDate: ${DateFormat('dd/MM/yyyy').format(lastDate1)}');

    // ตัวอย่างที่ 2: ลงทะเบียนไว้ 05-10/08/2025, วันนี้คือ 03/08/2025
    final registrationStart2 = DateTime(2025, 8, 5);
    final registrationEnd2 = DateTime(2025, 8, 10);

    debugPrint('\n📋 ตัวอย่างที่ 2:');
    debugPrint(
      '   ลงทะเบียน: ${DateFormat('dd/MM/yyyy').format(registrationStart2)} - ${DateFormat('dd/MM/yyyy').format(registrationEnd2)}',
    );
    debugPrint('   วันนี้: ${DateFormat('dd/MM/yyyy').format(today)}');

    final firstDate2 = BookingDateUtils.getFirstAvailableBookingDate(
      registrationStart2,
    );
    final lastDate2 = BookingDateUtils.getLastAvailableBookingDate(
      registrationEnd2,
    );

    debugPrint('   firstDate: ${DateFormat('dd/MM/yyyy').format(firstDate2)}');
    debugPrint('   lastDate: ${DateFormat('dd/MM/yyyy').format(lastDate2)}');

    // ทดสอบการตรวจสอบความถูกต้อง
    final testRange1 = DateTimeRange(
      start: DateTime(2025, 8, 3),
      end: DateTime(2025, 8, 5),
    );

    final isValid1 = BookingDateUtils.validateBookingDateRange(
      testRange1,
      registrationStart1,
      registrationEnd1,
    );

    debugPrint('\n🔍 ทดสอบการตรวจสอบความถูกต้อง:');
    debugPrint(
      '   ช่วงทดสอบ: ${DateFormat('dd/MM/yyyy').format(testRange1.start)} - ${DateFormat('dd/MM/yyyy').format(testRange1.end)}',
    );
    debugPrint('   ผลลัพธ์: ${isValid1 ? "✅ ถูกต้อง" : "❌ ไม่ถูกต้อง"}');
  }
}

/// ตัวอย่างการใช้งานใน Widget
class BookingDatePickerWidget extends StatefulWidget {
  final DateTime registrationStartDate;
  final DateTime registrationEndDate;
  final Function(DateTimeRange) onDateRangeSelected;

  const BookingDatePickerWidget({
    super.key,
    required this.registrationStartDate,
    required this.registrationEndDate,
    required this.onDateRangeSelected,
  });

  @override
  State<BookingDatePickerWidget> createState() =>
      _BookingDatePickerWidgetState();
}

class _BookingDatePickerWidgetState extends State<BookingDatePickerWidget> {
  DateTimeRange? selectedRange;

  @override
  Widget build(BuildContext context) {
    // ใช้ฟังก์ชันใหม่เพื่อกำหนดช่วงวันที่ที่อนุญาต
    final firstDate = BookingDateUtils.getFirstAvailableBookingDate(
      widget.registrationStartDate,
    );
    final lastDate = BookingDateUtils.getLastAvailableBookingDate(
      widget.registrationEndDate,
    );
    final initialRange = BookingDateUtils.getInitialDateRange(
      firstDate,
      lastDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'เลือกช่วงวันที่เข้าพัก',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () async {
              final result = await showDateRangePicker(
                context: context,
                firstDate: firstDate,
                lastDate: lastDate,
                initialDateRange: selectedRange ?? initialRange,
                locale: const Locale('th'),
              );

              if (result != null) {
                setState(() {
                  selectedRange = result;
                });

                // ตรวจสอบความถูกต้อง
                final isValid = BookingDateUtils.validateBookingDateRange(
                  result,
                  widget.registrationStartDate,
                  widget.registrationEndDate,
                );

                if (isValid) {
                  widget.onDateRangeSelected(result);
                } else {
                  // แสดงข้อความ error
                  final errorMessage =
                      BookingDateUtils.getDateRangeErrorMessage(
                        result,
                        widget.registrationStartDate,
                        widget.registrationEndDate,
                        (dateStr) => DateFormat(
                          'dd/MM/yyyy',
                          'th',
                        ).format(DateTime.parse(dateStr)),
                      );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              }
            },
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedRange == null
                        ? 'กดเพื่อเลือกช่วงวันที่'
                        : '${DateFormat('dd/MM/yyyy', 'th').format(selectedRange!.start)} - ${DateFormat('dd/MM/yyyy', 'th').format(selectedRange!.end)}',
                    style: TextStyle(
                      color: selectedRange == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selectedRange != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'จำนวนวันที่เลือก: ${selectedRange!.duration.inDays + 1} วัน',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
