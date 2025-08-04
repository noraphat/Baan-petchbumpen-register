# 📊 Room Usage Summary Feature

เมนู "สรุปผลประจำวัน" สำหรับระบบจัดการห้องพัก ที่พัฒนาด้วย Flutter + SQLite

## ✅ Features ที่ทำเสร็จ

### 🔧 Backend Functions
- **`getRoomUsageSummary()`** - ฟังก์ชันหลักในการดึงข้อมูลสรุปการใช้งานห้อง
- **`_getDailyRoomStatus()`** - สำหรับแสดงสถานะห้องรายวัน
- **`_getMultiDayRoomUsage()`** - สำหรับคำนวณจำนวนวันที่ใช้งาน
- **`RoomUsageSummary`** - คลาสสำหรับเก็บข้อมูลผลลัพธ์

### 🎨 Frontend UI
- **`RoomUsageSummaryScreen`** - หน้าจอหลักสำหรับแสดงสรุปผล
- **Period Selector** - เครื่องมือเลือกช่วงเวลา (Dropdown + DatePicker)
- **Summary Table** - ตารางแสดงผลที่รองรับ scroll
- **Statistics Cards** - แสดงสถิติการใช้งานโดยรวม
- **Menu Integration Widgets** - Component สำหรับเพิ่มเข้าเมนูหลัก

## 📅 ตัวเลือกช่วงเวลา

| ตัวเลือก | ผลลัพธ์ |
|---------|---------|
| **วันนี้** | สถานะห้องรายวัน (ว่าง/จองแล้ว/มีผู้เข้าพัก/ปิดปรับปรุง) |
| **วันที่ผ่านมา** | สถานะห้องของวันที่เลือก |
| **สัปดาห์นี้** | จำนวนวันที่แต่ละห้องถูกใช้งาน + อัตราการใช้งาน% |
| **เดือนนี้** | จำนวนวันที่แต่ละห้องถูกใช้งาน + อัตราการใช้งาน% |
| **3/6 เดือนย้อนหลัง** | จำนวนวันที่แต่ละห้องถูกใช้งาน + อัตราการใช้งาน% |
| **1 ปีย้อนหลัง** | จำนวนวันที่แต่ละห้องถูกใช้งาน + อัตราการใช้งาน% |
| **กำหนดช่วงเอง** | รองรับการเลือกช่วงวันที่แบบ custom |

## 🗂️ Files ที่สร้างใหม่

```
lib/
├── services/
│   └── booking_service.dart          # เพิ่ม getRoomUsageSummary + RoomUsageSummary class
├── screen/
│   └── room_usage_summary_screen.dart # หน้าจอหลัก
└── widgets/
    └── room_summary_menu_item.dart    # Widget สำหรับเพิ่มเข้าเมนู

example_room_summary_usage.dart       # ตัวอย่างการใช้งาน
ROOM_SUMMARY_README.md                # เอกสารนี้
```

## 🚀 วิธีการใช้งาน

### 1. เพิ่มเมนูในแอปหลัก

```dart
import 'lib/widgets/room_summary_menu_item.dart';

// ในหน้าเมนูหลัก
Column(
  children: [
    RoomSummaryMenuItem(), // แบบ Card ใหญ่
    // หรือ
    SimpleRoomSummaryTile(), // แบบ List Tile
    // หรือ
    RoomSummaryGridTile(), // แบบ Grid
  ],
)
```

### 2. เรียกใช้หน้าจอโดยตรง

```dart
import 'lib/screen/room_usage_summary_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RoomUsageSummaryScreen(),
  ),
);
```

### 3. ใช้ API โดยตรง

```dart
import 'lib/services/booking_service.dart';

final bookingService = BookingService();

// วันเดียว - แสดงสถานะรายวัน
final todaySummary = await bookingService.getRoomUsageSummary(
  startDate: DateTime.now(),
  endDate: DateTime.now(),
);

// หลายวัน - แสดงจำนวนวันที่ใช้งาน
final weeklySummary = await bookingService.getRoomUsageSummary(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// แสดงผลลัพธ์
for (final summary in todaySummary) {
  if (summary.isSingleDay) {
    print('${summary.roomName}: ${summary.dailyStatus}');
    if (summary.guestName.isNotEmpty) {
      print('  ผู้เข้าพัก: ${summary.guestName}');
    }
  } else {
    print('${summary.roomName}: ใช้งาน ${summary.usageDays} วัน');
  }
}
```

## 📊 ตัวอย่างผลลัพธ์

### รายวัน (Single Day)
```
ห้อง A01: ว่าง
ห้อง A02: จองแล้ว - สมชาย ใจดี
ห้อง A03: มีผู้เข้าพัก - สมศรี รักษ์ธรรม
ห้อง B01: ปิดปรับปรุง
```

### หลายวัน (Multi-Day)
```
ห้องพัก    วันที่ใช้งาน    อัตราการใช้งาน
A01       12 วัน         80%
A02       5 วัน          33%
A03       0 วัน          0%
B01       15 วัน         100%
```

## 🎯 Logic การทำงาน

### สำหรับ Single Day (วันเดียว)
```sql
SELECT r.*, 
  CASE 
    WHEN rb.id IS NOT NULL THEN 'จองแล้ว'
    WHEN r.status = 'occupied' THEN 'มีผู้เข้าพัก'
    WHEN r.status = 'available' THEN 'ว่าง'
    WHEN r.status = 'maintenance' THEN 'ปิดปรับปรุง'
    ELSE 'ไม่ทราบสถานะ'
  END as daily_status
FROM rooms r
LEFT JOIN room_bookings rb ON r.id = rb.room_id 
  AND rb.status != 'cancelled'
  AND date >= rb.check_in_date 
  AND date <= rb.check_out_date
```

### สำหรับ Multi-Day (หลายวัน)
```sql
SELECT r.*, 
  COALESCE(SUM(
    CASE 
      WHEN rb.check_out_date <= end_date THEN 
        julianday(rb.check_out_date) - julianday(MAX(rb.check_in_date, start_date)) + 1
      WHEN rb.check_in_date >= start_date THEN
        julianday(MIN(rb.check_out_date, end_date)) - julianday(rb.check_in_date) + 1
      ELSE
        julianday(end_date) - julianday(start_date) + 1
    END
  ), 0) as usage_days
FROM rooms r
LEFT JOIN room_bookings rb ON r.id = rb.room_id
WHERE rb.status != 'cancelled'
  AND NOT (rb.check_out_date < start_date OR rb.check_in_date > end_date)
```

## 🔧 Database Schema ที่ใช้

```sql
-- ตาราง rooms
CREATE TABLE rooms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  size TEXT NOT NULL,
  capacity INTEGER NOT NULL,
  status TEXT DEFAULT 'available', -- available, occupied, maintenance
  current_occupant TEXT,
  -- ...
);

-- ตาราง room_bookings  
CREATE TABLE room_bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id INTEGER NOT NULL,
  visitor_id TEXT NOT NULL,
  check_in_date TEXT NOT NULL,   -- YYYY-MM-DD format
  check_out_date TEXT NOT NULL,  -- YYYY-MM-DD format
  status TEXT DEFAULT 'pending', -- pending, active, cancelled
  -- ...
);
```

## 🎨 UI Components

### RoomUsageSummaryScreen
- **Period Selector**: Dropdown + Custom DatePicker
- **Data Table**: แสดงผลลัพธ์แบบตาราง พร้อม scroll
- **Statistics**: การ์ดสถิติแสดงภาพรวม
- **Loading State**: Spinner ขณะโหลดข้อมูล
- **Empty State**: หน้าจอเมื่อไม่มีข้อมูล

### Menu Integration
- **RoomSummaryMenuItem**: Card แบบใหญ่พร้อมรายละเอียด
- **SimpleRoomSummaryTile**: ListTile เรียบง่าย
- **RoomSummaryGridTile**: แบบ Grid เหมาะสำหรับเมนูหลัก

## 🧪 การทดสอบ

รันไฟล์ `example_room_summary_usage.dart` เพื่อทดสอบ:

```bash
flutter run example_room_summary_usage.dart
```

## 📝 Notes

1. **Performance**: ใช้ SQLite indexes สำหรับการ query ที่เร็ว
2. **Date Handling**: รองรับ timezone และ date formatting ภาษาไทย
3. **Responsive**: UI ปรับตัวได้ทั้งมือถือและแท็บเล็ต
4. **Error Handling**: จัดการ error และแสดงข้อความที่เหมาะสม
5. **Accessibility**: รองรับ screen reader และ keyboard navigation

## 🔄 Future Enhancements

- [ ] Export เป็น PDF/Excel
- [ ] Filtering ตามขนาดห้อง/สถานะ
- [ ] Charts/Graphs visualization
- [ ] Push notifications สำหรับรายงานประจำวัน
- [ ] Comparison กับช่วงเวลาก่อนหน้า

---

**พัฒนาเสร็จสิ้น** ✅ พร้อมใช้งานในระบบจริง