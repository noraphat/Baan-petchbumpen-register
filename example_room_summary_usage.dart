import 'package:flutter/material.dart';
import 'lib/screen/room_usage_summary_screen.dart';
import 'lib/services/booking_service.dart';

/// ตัวอย่างการใช้งานเมนูสรุปผลประจำวันสำหรับห้องพัก
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Usage Summary Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Kanit', // ใช้ฟอนต์ไทย
      ),
      home: DemoMainScreen(),
    );
  }
}

class DemoMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตัวอย่างการใช้งาน'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment,
              size: 80,
              color: Colors.blue[600],
            ),
            SizedBox(height: 24),
            Text(
              'สรุปผลประจำวัน - ห้องพัก',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'ตรวจสอบสถานะและการใช้งานห้องพักในช่วงเวลาต่าง ๆ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomUsageSummaryScreen(),
                  ),
                );
              },
              icon: Icon(Icons.hotel),
              label: Text('เปิดสรุปผลห้องพัก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showQuickExample(context),
              icon: Icon(Icons.play_circle_outline),
              label: Text('ทดสอบ API'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// แสดงตัวอย่างการเรียกใช้ API
  Future<void> _showQuickExample(BuildContext context) async {
    final bookingService = BookingService();
    
    // แสดงผล loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังโหลดข้อมูลตัวอย่าง...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // ทดสอบดึงข้อมูลวันนี้
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      
      final summaryData = await bookingService.getRoomUsageSummary(
        startDate: todayOnly,
        endDate: todayOnly,
      );

      Navigator.pop(context); // ปิด loading

      // แสดงผลลัพธ์
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ผลลัพธ์การทดสอบ'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('วันที่: ${todayOnly.day}/${todayOnly.month}/${todayOnly.year}'),
                SizedBox(height: 8),
                Text('พบห้องพัก: ${summaryData.length} ห้อง'),
                SizedBox(height: 12),
                if (summaryData.isNotEmpty) ...[
                  Text(
                    'ตัวอย่างข้อมูล:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...summaryData.take(5).map((summary) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${summary.roomName}: ${summary.dailyStatus}',
                      style: TextStyle(fontSize: 14),
                    ),
                  )),
                  if (summaryData.length > 5)
                    Text('... และอีก ${summaryData.length - 5} ห้อง'),
                ] else
                  Text(
                    'ไม่พบข้อมูลห้องพัก\nกรุณาตรวจสอบการตั้งค่าฐานข้อมูล',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ตกลง'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // ปิด loading

      // แสดง error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('เกิดข้อผิดพลาด'),
          content: Text('ไม่สามารถโหลดข้อมูลได้: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ตกลง'),
            ),
          ],
        ),
      );
    }
  }
}

/// คำแนะนำการใช้งาน
class UsageInstructions {
  static const String instructions = '''
## วิธีการใช้งาน Room Usage Summary

### 1. เพิ่มเมนูในแอปหลัก
```dart
// ในหน้าเมนูหลัก
ListTile(
  leading: Icon(Icons.assessment),
  title: Text('สรุปผลประจำวัน - ห้องพัก'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomUsageSummaryScreen(),
      ),
    );
  },
),
```

### 2. การใช้งาน API โดยตรง
```dart
final bookingService = BookingService();

// สำหรับวันเดียว (แสดงสถานะรายวัน)
final todaySummary = await bookingService.getRoomUsageSummary(
  startDate: DateTime.now(),
  endDate: DateTime.now(),
);

// สำหรับหลายวัน (แสดงจำนวนวันที่ใช้งาน)
final weeklySummary = await bookingService.getRoomUsageSummary(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
```

### 3. ข้อมูลที่ได้รับ
- **วันเดียว**: สถานะห้อง, ชื่อผู้เข้าพัก
- **หลายวัน**: จำนวนวันที่ใช้งาน, อัตราการใช้งาน

### 4. Features ที่รองรับ
- ✅ เลือกช่วงเวลาแบบ preset (วันนี้, สัปดาห์นี้, เดือนนี้, etc.)
- ✅ เลือกช่วงเวลาแบบ custom
- ✅ แสดงตารางพร้อม scroll
- ✅ สถิติการใช้งาน
- ✅ UI สวยงามและใช้งานง่าย
- ✅ Responsive design
''';
}