import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ตัวอย่างการใช้งานระบบจำกัดการจองเฉพาะวันปัจจุบัน
class TodayOnlyBookingExample {
  /// ฟังก์ชันตรวจสอบว่าวันที่เลือกเป็นวันปัจจุบันหรือไม่
  static bool isToday(DateTime selectedDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    debugPrint('📅 isToday check:');
    debugPrint('   selectedDate: $selectedDate');
    debugPrint('   today: $today');
    debugPrint('   selectedDateOnly: $selectedDateOnly');
    debugPrint('   todayOnly: $todayOnly');
    debugPrint('   isToday: ${selectedDateOnly.isAtSameMomentAs(todayOnly)}');

    return selectedDateOnly.isAtSameMomentAs(todayOnly);
  }

  /// แสดงข้อความแจ้งเตือนเมื่อเลือกวันที่ที่ไม่ใช่วันปัจจุบัน
  static void showTodayOnlyBookingMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('ไม่สามารถจองได้'),
          ],
        ),
        content: const Text(
          'ขออภัย ระบบไม่รองรับการจองล่วงหน้า\nกรุณาจองในวันที่เข้าพักเท่านั้น',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }

  /// ตัวอย่างการใช้งานในปุ่มจองห้องพัก
  static void onBookRoomPressed(BuildContext context, DateTime selectedDate) {
    debugPrint('🔍 ตรวจสอบสิทธิ์การจอง...');
    debugPrint(
      '   วันที่เลือก: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
    );
    debugPrint('   วันนี้: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}');

    // ตรวจสอบว่าวันที่เลือกเป็นวันปัจจุบันหรือไม่
    if (!isToday(selectedDate)) {
      debugPrint('❌ ไม่สามารถจองได้ - เลือกวันที่ที่ไม่ใช่วันปัจจุบัน');
      showTodayOnlyBookingMessage(context);
      return;
    }

    debugPrint('✅ สามารถจองได้ - เลือกวันที่ปัจจุบัน');
    // ดำเนินการจองต่อไป...
    _proceedWithBooking(context);
  }

  /// ดำเนินการจองห้องพัก
  static void _proceedWithBooking(BuildContext context) {
    // ตัวอย่างการจอง
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จองห้องพัก'),
        content: const Text('ดำเนินการจองห้องพัก...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('จองห้องพักสำเร็จ'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  /// ตัวอย่างการทดสอบฟังก์ชัน isToday
  static void testIsTodayFunction() {
    debugPrint('🧪 ทดสอบฟังก์ชัน isToday');

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    debugPrint('\n📋 ผลการทดสอบ:');
    debugPrint(
      '   วันนี้: ${DateFormat('dd/MM/yyyy').format(today)} - isToday: ${isToday(today)}',
    );
    debugPrint(
      '   พรุ่งนี้: ${DateFormat('dd/MM/yyyy').format(tomorrow)} - isToday: ${isToday(tomorrow)}',
    );
    debugPrint(
      '   เมื่อวาน: ${DateFormat('dd/MM/yyyy').format(yesterday)} - isToday: ${isToday(yesterday)}',
    );
  }
}

/// ตัวอย่าง Widget สำหรับแสดงสถานะวันที่
class DateStatusWidget extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback? onDateChanged;

  const DateStatusWidget({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isTodaySelected = TodayOnlyBookingExample.isToday(selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTodaySelected ? Colors.green[50] : Colors.orange[50],
        border: Border.all(
          color: isTodaySelected ? Colors.green[200]! : Colors.orange[200]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTodaySelected ? Icons.calendar_today : Icons.calendar_month,
                color: isTodaySelected ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'วันที่เลือก: ${DateFormat('dd/MM/yyyy', 'th').format(selectedDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isTodaySelected
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
              if (isTodaySelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'วันนี้',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTodaySelected
                ? '✅ สามารถจองห้องพักได้'
                : '⚠️ ไม่สามารถจองห้องพักได้ (จำกัดเฉพาะวันปัจจุบัน)',
            style: TextStyle(
              color: isTodaySelected ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onDateChanged != null) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onDateChanged,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('เปลี่ยนวันที่'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTodaySelected ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ตัวอย่างการใช้งานใน Screen
class TodayOnlyBookingScreen extends StatefulWidget {
  const TodayOnlyBookingScreen({super.key});

  @override
  State<TodayOnlyBookingScreen> createState() => _TodayOnlyBookingScreenState();
}

class _TodayOnlyBookingScreenState extends State<TodayOnlyBookingScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบจองห้องพัก (เฉพาะวันปัจจุบัน)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดงสถานะวันที่
            DateStatusWidget(
              selectedDate: _selectedDate,
              onDateChanged: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('th'),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),

            const SizedBox(height: 24),

            // ตัวอย่างห้องพัก
            const Text(
              'ห้องพักตัวอย่าง:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ห้องว่าง
            _buildRoomCard('ห้อง 101', 'ว่าง', Colors.green, true),
            const SizedBox(height: 8),

            // ห้องไม่ว่าง
            _buildRoomCard('ห้อง 102', 'ไม่ว่าง', Colors.red, false),
            const SizedBox(height: 8),

            // ห้องว่าง
            _buildRoomCard('ห้อง 103', 'ว่าง', Colors.green, true),

            const Spacer(),

            // ปุ่มทดสอบ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => TodayOnlyBookingExample.testIsTodayFunction(),
                icon: const Icon(Icons.bug_report),
                label: const Text('ทดสอบฟังก์ชัน isToday'),
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

  Widget _buildRoomCard(
    String roomName,
    String status,
    Color color,
    bool isAvailable,
  ) {
    final canBook =
        isAvailable && TodayOnlyBookingExample.isToday(_selectedDate);

    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.hotel, color: Colors.white, size: 20),
        ),
        title: Text(roomName),
        subtitle: Text(
          '$status${canBook ? ' (คลิกเพื่อจอง)' : ' (ไม่สามารถจองได้)'}',
          style: TextStyle(
            color: canBook ? Colors.green[700] : Colors.grey[600],
            fontWeight: canBook ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: canBook
            ? const Icon(Icons.arrow_forward_ios, color: Colors.green)
            : const Icon(Icons.block, color: Colors.grey),
        onTap: canBook
            ? () => TodayOnlyBookingExample.onBookRoomPressed(
                context,
                _selectedDate,
              )
            : null,
      ),
    );
  }
}
