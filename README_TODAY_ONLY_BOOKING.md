# ระบบจำกัดการจองห้องพักเฉพาะวันปัจจุบัน

## 📋 ภาพรวม

ระบบนี้ถูกออกแบบมาเพื่อจำกัดสิทธิ์การจองห้องพักไว้เฉพาะ **วันปัจจุบัน (วันนี้)** เท่านั้น โดยไม่อนุญาตให้จองล่วงหน้าในวันพรุ่งนี้หรือวันต่อ ๆ ไป

## 🎯 ฟีเจอร์หลัก

### ✅ จำกัดการจองเฉพาะวันปัจจุบัน
- ไม่อนุญาตให้จองล่วงหน้า
- ตรวจสอบวันที่เลือกกับวันปัจจุบัน
- แสดงข้อความแจ้งเตือนเมื่อเลือกวันที่ที่ไม่ใช่วันปัจจุบัน

### ✅ UI ที่ชัดเจน
- แสดงสถานะวันที่ด้วยสีและไอคอน
- เปลี่ยนสีพื้นหลังตามสถานะวันที่
- แสดงข้อความ "วันนี้" เมื่อเลือกวันที่ปัจจุบัน

## 🔧 ฟังก์ชันหลัก

### 1. `isToday()`

```dart
bool isToday(DateTime selectedDate)
```

**หน้าที่:** ตรวจสอบว่าวันที่เลือกเป็นวันปัจจุบันหรือไม่

**Logic:**
- แปลงวันที่เป็นวันที่เท่านั้น (ตัดเวลา)
- เปรียบเทียบกับวันปัจจุบัน
- return `true` ถ้าเป็นวันเดียวกัน

**ตัวอย่าง:**
```dart
final today = DateTime.now();
final tomorrow = today.add(const Duration(days: 1));

print(isToday(today));     // true
print(isToday(tomorrow));  // false
```

### 2. `_showTodayOnlyBookingMessage()`

```dart
void _showTodayOnlyBookingMessage()
```

**หน้าที่:** แสดงข้อความแจ้งเตือนเมื่อเลือกวันที่ที่ไม่ใช่วันปัจจุบัน

**ข้อความ:**
- "ขออภัย ระบบไม่รองรับการจองล่วงหน้า"
- "กรุณาจองในวันที่เข้าพักเท่านั้น"

## 🚀 วิธีการใช้งาน

### การใช้งานพื้นฐาน

```dart
// ตรวจสอบวันที่
if (!isToday(_selectedDate)) {
  _showTodayOnlyBookingMessage();
  return;
}

// ดำเนินการจอง
await _showBookingDialog(room);
```

### การใช้งานในปุ่มจอง

```dart
Future<void> _onRoomTapped(Room room) async {
  if (room.status != RoomStatus.available) {
    await _showRoomManagementDialog(room);
    return;
  }

  // ตรวจสอบว่าวันที่เลือกเป็นวันปัจจุบันหรือไม่
  if (!isToday(_selectedDate)) {
    debugPrint('❌ ไม่สามารถจองได้ - เลือกวันที่ที่ไม่ใช่วันปัจจุบัน');
    _showTodayOnlyBookingMessage();
    return;
  }

  debugPrint('✅ สามารถจองได้ - เลือกวันที่ปัจจุบัน');
  await _showBookingDialog(room);
}
```

## 🎨 UI Components

### Date Status Display

```dart
Container(
  padding: const EdgeInsets.all(16),
  color: isToday(_selectedDate) ? Colors.green[50] : Colors.orange[50],
  child: Row(
    children: [
      Icon(
        isToday(_selectedDate) ? Icons.calendar_today : Icons.calendar_month,
        color: isToday(_selectedDate) ? Colors.green : Colors.orange,
      ),
      Text(
        DateFormat('dd/MM/yyyy', 'th').format(_selectedDate),
        style: TextStyle(
          color: isToday(_selectedDate) ? Colors.green[700] : Colors.orange[700],
        ),
      ),
      if (isToday(_selectedDate)) ...[
        Container(
          child: Text('วันนี้'),
        ),
      ],
    ],
  ),
)
```

### Instructions Display

```dart
Text(
  isToday(_selectedDate)
      ? 'คำแนะนำ: คลิกเลือกห้องสีเขียวเพื่อจอง'
      : '⚠️ ระบบจำกัดการจองเฉพาะวันปัจจุบันเท่านั้น',
  style: TextStyle(
    color: isToday(_selectedDate) ? Colors.blue : Colors.orange,
  ),
)
```

## 📊 ตัวอย่างสถานการณ์

### กรณีที่ 1: เลือกวันปัจจุบัน

**ข้อมูล:**
- วันนี้: 03/08/2025
- วันที่เลือก: 03/08/2025

**ผลลัพธ์:**
- ✅ สามารถจองได้
- สีพื้นหลัง: เขียว
- ไอคอน: calendar_today
- แสดงข้อความ: "วันนี้"

### กรณีที่ 2: เลือกวันพรุ่งนี้

**ข้อมูล:**
- วันนี้: 03/08/2025
- วันที่เลือก: 04/08/2025

**ผลลัพธ์:**
- ❌ ไม่สามารถจองได้
- สีพื้นหลัง: ส้ม
- ไอคอน: calendar_month
- แสดงข้อความแจ้งเตือน

## 🔍 การ Debug

ระบบมี debug logs ที่แสดงข้อมูลการทำงาน:

```
📅 isToday check:
   selectedDate: 2025-08-04 10:30:00.000
   today: 2025-08-03 10:30:00.000
   selectedDateOnly: 2025-08-04 00:00:00.000
   todayOnly: 2025-08-03 00:00:00.000
   isToday: false
```

## 📁 โครงสร้างไฟล์

```
lib/
├── screen/
│   └── accommodation_booking_screen.dart  # หน้าจองห้องพัก (อัพเดทแล้ว)
├── example_today_only_booking.dart        # ตัวอย่างการใช้งาน
└── README_TODAY_ONLY_BOOKING.md           # คู่มือการใช้งาน
```

## 🛠️ การปรับปรุงในอนาคต

1. **เพิ่มการจำกัดเวลา**
   - จำกัดการจองเฉพาะช่วงเวลาที่กำหนด
   - เช่น จองได้เฉพาะ 08:00-18:00

2. **เพิ่มการแจ้งเตือนล่วงหน้า**
   - แจ้งเตือนเมื่อใกล้ถึงวันจอง
   - แสดงจำนวนวันที่เหลือ

3. **เพิ่มการจองแบบ Walk-in**
   - อนุญาตการจองทันทีสำหรับผู้มาถึง
   - ไม่ต้องจองล่วงหน้า

## 📝 หมายเหตุ

- ฟังก์ชัน `isToday()` ใช้การเปรียบเทียบวันที่เท่านั้น (ตัดเวลา)
- ระบบรองรับภาษาไทยผ่าน `DateFormat`
- มีการตรวจสอบ `mounted` เพื่อป้องกัน memory leak
- UI แสดงสถานะที่ชัดเจนด้วยสีและไอคอน

## 🤝 การสนับสนุน

หากมีปัญหาหรือต้องการปรับปรุง กรุณาแจ้งผ่าน issue tracker ของโปรเจค 