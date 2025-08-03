import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ไฟล์ทดสอบการทำงานของการอัพเดตการจอง
void main() {
  runApp(TestBookingUpdateApp());
}

class TestBookingUpdateApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ทดสอบการอัพเดตการจอง',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TestBookingUpdateScreen(),
    );
  }
}

class TestBookingUpdateScreen extends StatefulWidget {
  @override
  _TestBookingUpdateScreenState createState() =>
      _TestBookingUpdateScreenState();
}

class _TestBookingUpdateScreenState extends State<TestBookingUpdateScreen> {
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  // ข้อมูลการจองจำลอง
  final Map<String, dynamic> mockOccupantInfo = {
    'id': 1,
    'room_id': 1,
    'visitor_id': 1,
    'check_in_date': '2025-08-03',
    'check_out_date': '2025-08-05',
  };

  // ข้อมูลการจองอื่นๆ ที่มีอยู่
  final List<Map<String, dynamic>> mockExistingBookings = [
    {'id': 2, 'check_in_date': '2025-08-06', 'check_out_date': '2025-08-08'},
    {'id': 3, 'check_in_date': '2025-08-01', 'check_out_date': '2025-08-02'},
  ];

  String testResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ทดสอบการอัพเดตการจอง')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ข้อมูลการจองปัจจุบัน:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('ID: ${mockOccupantInfo['id']}'),
            Text('ห้อง: ${mockOccupantInfo['room_id']}'),
            Text('วันที่เข้า: ${mockOccupantInfo['check_in_date']}'),
            Text('วันที่ออก: ${mockOccupantInfo['check_out_date']}'),

            SizedBox(height: 16),
            Text(
              'การจองอื่นๆ ที่มีอยู่:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...mockExistingBookings.map(
              (booking) => Text(
                'ID ${booking['id']}: ${booking['check_in_date']} - ${booking['check_out_date']}',
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testBookingUpdate,
              child: Text('ทดสอบการอัพเดตการจอง'),
            ),

            SizedBox(height: 16),
            Text(
              'ผลการทดสอบ:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                testResult.isEmpty ? 'ยังไม่ได้ทดสอบ' : testResult,
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _testBookingUpdate() {
    setState(() {
      testResult = 'เริ่มการทดสอบ...\n\n';

      // ทดสอบการอัพเดตวันที่ออกเป็นวันที่เดียวกัน
      final sameDate = DateTime.parse(mockOccupantInfo['check_out_date']);
      testResult +=
          '1. ทดสอบอัพเดตเป็นวันที่เดียวกัน (${dateFormat.format(sameDate)}):\n';
      testResult += _testDateUpdate(sameDate);

      // ทดสอบการอัพเดตวันที่ออกเป็นวันถัดไป
      final nextDate = sameDate.add(Duration(days: 1));
      testResult +=
          '\n2. ทดสอบอัพเดตเป็นวันถัดไป (${dateFormat.format(nextDate)}):\n';
      testResult += _testDateUpdate(nextDate);

      // ทดสอบการอัพเดตวันที่ออกเป็นวันก่อนหน้า
      final prevDate = sameDate.subtract(Duration(days: 1));
      testResult +=
          '\n3. ทดสอบอัพเดตเป็นวันก่อนหน้า (${dateFormat.format(prevDate)}):\n';
      testResult += _testDateUpdate(prevDate);

      // ทดสอบการอัพเดตวันที่ออกเป็นวันที่ขัดแย้ง
      final conflictDate = DateTime.parse('2025-08-07');
      testResult +=
          '\n4. ทดสอบอัพเดตเป็นวันที่ขัดแย้ง (${dateFormat.format(conflictDate)}):\n';
      testResult += _testDateUpdate(conflictDate);
    });
  }

  String _testDateUpdate(DateTime newEndDate) {
    final currentCheckIn = DateTime.parse(mockOccupantInfo['check_in_date']);
    final today = DateTime.now();

    // จำลองการตรวจสอบการจองที่ขัดแย้ง
    final conflictingBookings = _findConflictingBookings(
      currentCheckIn,
      newEndDate,
      mockExistingBookings,
      excludeBookingId: mockOccupantInfo['id'],
    );

    if (conflictingBookings.isEmpty) {
      return '✅ ไม่มีการจองที่ขัดแย้ง - สามารถอัพเดตได้\n';
    } else {
      return '❌ พบการจองที่ขัดแย้ง ${conflictingBookings.length} รายการ:\n' +
          conflictingBookings
              .map(
                (booking) =>
                    '   - ID ${booking['id']}: ${booking['check_in_date']} - ${booking['check_out_date']}',
              )
              .join('\n') +
          '\n';
    }
  }

  List<Map<String, dynamic>> _findConflictingBookings(
    DateTime startDate,
    DateTime endDate,
    List<Map<String, dynamic>> existingBookings, {
    int? excludeBookingId,
  }) {
    final conflictingBookings = <Map<String, dynamic>>[];

    for (final booking in existingBookings) {
      // ข้ามการจองที่ต้องการแยกออกไป
      if (excludeBookingId != null && booking['id'] == excludeBookingId) {
        continue;
      }

      final bookingStart = DateTime.parse(booking['check_in_date']);
      final bookingEnd = DateTime.parse(booking['check_out_date']);

      // ตรวจสอบการทับซ้อน
      final hasOverlap =
          !(bookingEnd.isBefore(startDate) || bookingStart.isAfter(endDate));

      if (hasOverlap) {
        conflictingBookings.add(booking);
      }
    }

    return conflictingBookings;
  }
}
