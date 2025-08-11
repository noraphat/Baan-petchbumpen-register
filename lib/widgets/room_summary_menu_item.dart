import 'package:flutter/material.dart';
import '../screen/room_usage_summary_screen.dart';
import '../services/menu_settings_service.dart';

/// Widget สำหรับเพิ่มรายการเมนู "สรุปผลประจำวัน - ห้องพัก" 
/// ลงในเมนูหลักของแอป
class RoomSummaryMenuItem extends StatelessWidget {
  const RoomSummaryMenuItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.assessment,
            color: Colors.green[700],
            size: 24,
          ),
        ),
        title: Text(
          'สรุปผลประจำวัน - ห้องพัก',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'ตรวจสอบสถานะและการใช้งานห้องพักในช่วงเวลาต่าง ๆ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[500],
        ),
        onTap: () async {
          // ตรวจสอบสถานะเมนู "จองห้องพัก" ก่อนเข้าหน้า
          final menuSettings = MenuSettingsService();
          final isBookingEnabled = await menuSettings.isBookingEnabled;
          
          if (!isBookingEnabled && context.mounted) {
            // แสดง dialog เตือนก่อนเข้าหน้า
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('เตือน')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เมนู "จองห้องพัก" ถูกปิดใช้งาน'),
                    SizedBox(height: 8),
                    Text(
                      'Tab ห้องพักจะไม่สามารถแสดงข้อมูลได้อย่างสมบูรณ์ เนื่องจากระบบการจองห้องไม่ได้เปิดใช้งาน',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ต้องการดำเนินการต่อหรือไม่?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('ดำเนินการต่อ'),
                  ),
                ],
              ),
            );
            
            if (proceed != true) return;
          }
          
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomUsageSummaryScreen(),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Widget แบบ Tile เรียบง่าย สำหรับใส่ใน Drawer หรือ ListView
class SimpleRoomSummaryTile extends StatelessWidget {
  final bool showIcon;
  final bool showSubtitle;

  const SimpleRoomSummaryTile({
    super.key,
    this.showIcon = true,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showIcon
          ? Icon(Icons.assessment, color: Colors.green[700])
          : null,
      title: Text('สรุปผลประจำวัน - ห้องพัก'),
      subtitle: showSubtitle
          ? Text('สถานะและการใช้งานห้องพัก')
          : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomUsageSummaryScreen(),
          ),
        );
      },
    );
  }
}

/// Widget แบบ GridTile สำหรับใส่ในเมนูแบบ Grid
class RoomSummaryGridTile extends StatelessWidget {
  const RoomSummaryGridTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () async {
          // ตรวจสอบสถานะเมนู "จองห้องพัก" ก่อนเข้าหน้า
          final menuSettings = MenuSettingsService();
          final isBookingEnabled = await menuSettings.isBookingEnabled;
          
          if (!isBookingEnabled && context.mounted) {
            // แสดง dialog เตือนก่อนเข้าหน้า
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('เตือน')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เมนู "จองห้องพัก" ถูกปิดใช้งาน'),
                    SizedBox(height: 8),
                    Text(
                      'Tab ห้องพักจะไม่สามารถแสดงข้อมูลได้อย่างสมบูรณ์ เนื่องจากระบบการจองห้องไม่ได้เปิดใช้งาน',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ต้องการดำเนินการต่อหรือไม่?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('ดำเนินการต่อ'),
                  ),
                ],
              ),
            );
            
            if (proceed != true) return;
          }
          
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomUsageSummaryScreen(),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment,
                size: 48,
                color: Colors.green[700],
              ),
              SizedBox(height: 12),
              Text(
                'สรุปผลประจำวัน',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'ห้องพัก',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ตัวอย่างการใช้งานในเมนูหลัก
class ExampleUsageInMainMenu extends StatelessWidget {
  const ExampleUsageInMainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตัวอย่างการใช้งานในเมนูหลัก'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แบบ Card ใหญ่
            Text(
              'แบบ Card ใหญ่:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            RoomSummaryMenuItem(),
            
            SizedBox(height: 24),
            
            // แบบ List Tile
            Text(
              'แบบ List Tile:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: SimpleRoomSummaryTile(),
            ),
            
            SizedBox(height: 24),
            
            // แบบ Grid
            Text(
              'แบบ Grid (2 คอลัมน์):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  RoomSummaryGridTile(),
                  // เพิ่มเมนูอื่น ๆ ได้ที่นี่
                  Card(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel, size: 48, color: Colors.blue[700]),
                          SizedBox(height: 8),
                          Text('เมนูอื่น'),
                        ],
                      ),
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
}