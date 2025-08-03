# ระบบจัดการวันที่สำหรับการจองห้องพัก

## 📋 ภาพรวม

ระบบนี้ถูกออกแบบมาเพื่อจัดการวันที่ในการจองห้องพักของผู้ปฏิบัติธรรม โดยมีฟีเจอร์หลักคือ **การป้องกันการจองย้อนหลัง** และ **การจำกัดช่วงวันที่ตามข้อมูลการลงทะเบียน**

## 🎯 ฟีเจอร์หลัก

### ✅ ป้องกันการจองย้อนหลัง
- หากวันที่เริ่มต้นที่ลงทะเบียนไว้เป็นวันย้อนหลัง ระบบจะใช้วันปัจจุบันแทน
- ผู้ใช้ไม่สามารถเลือกวันที่ย้อนหลังได้

### ✅ จำกัดช่วงวันที่ตามการลงทะเบียน
- วันสิ้นสุดจะไม่เกินวันที่สิ้นสุดที่ลงทะเบียนไว้
- ระบบจะตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก

## 📁 โครงสร้างไฟล์

```
lib/
├── utils/
│   └── booking_date_utils.dart          # ฟังก์ชัน utility หลัก
├── screen/
│   └── accommodation_booking_screen.dart # หน้าจองห้องพัก (อัพเดทแล้ว)
└── example_booking_usage.dart           # ตัวอย่างการใช้งาน
```

## 🔧 ฟังก์ชันหลัก

### 1. `getFirstAvailableBookingDate()`

```dart
DateTime getFirstAvailableBookingDate(DateTime registrationStartDate)
```

**หน้าที่:** กำหนดวันเริ่มต้นที่สามารถจองได้

**Logic:**
- ถ้า `registrationStartDate < วันนี้` → return วันนี้
- ไม่งั้น → return `registrationStartDate`

**ตัวอย่าง:**
```dart
// ลงทะเบียนไว้ 02/08/2025, วันนี้คือ 03/08/2025
final startDate = DateTime(2025, 8, 2);
final firstDate = getFirstAvailableBookingDate(startDate);
// ผลลัพธ์: 03/08/2025 (ใช้วันปัจจุบันแทน)
```

### 2. `getLastAvailableBookingDate()`

```dart
DateTime getLastAvailableBookingDate(DateTime registrationEndDate)
```

**หน้าที่:** กำหนดวันสิ้นสุดที่สามารถจองได้

**Logic:**
- return `registrationEndDate` (ใช้วันที่สิ้นสุดที่ลงทะเบียนไว้)

### 3. `getInitialDateRange()`

```dart
DateTimeRange getInitialDateRange(DateTime firstDate, DateTime lastDate)
```

**หน้าที่:** สร้างช่วงวันที่เริ่มต้นสำหรับ DateRangePicker

**Logic:**
- ตรวจสอบว่า `firstDate` ไม่เกิน `lastDate`
- สร้าง `DateTimeRange` จาก `firstDate` ถึง `lastDate`

### 4. `validateBookingDateRange()`

```dart
bool validateBookingDateRange(
  DateTimeRange selectedRange,
  DateTime registrationStartDate,
  DateTime registrationEndDate,
)
```

**หน้าที่:** ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก

**Logic:**
- ตรวจสอบว่าวันเริ่มต้นไม่ก่อนวันที่อนุญาต
- ตรวจสอบว่าวันสิ้นสุดไม่หลังวันที่อนุญาต
- ตรวจสอบว่าวันเริ่มต้นไม่หลังวันสิ้นสุด

## 🚀 วิธีการใช้งาน

### การใช้งานพื้นฐาน

```dart
import 'package:flutter/material.dart';
import 'lib/utils/booking_date_utils.dart';

// ข้อมูลการลงทะเบียน
final registrationStartDate = DateTime(2025, 8, 2);
final registrationEndDate = DateTime(2025, 8, 6);

// ใช้ฟังก์ชันใหม่
final firstDate = BookingDateUtils.getFirstAvailableBookingDate(registrationStartDate);
final lastDate = BookingDateUtils.getLastAvailableBookingDate(registrationEndDate);
final initialRange = BookingDateUtils.getInitialDateRange(firstDate, lastDate);

// แสดง DateRangePicker
final result = await showDateRangePicker(
  context: context,
  firstDate: firstDate,
  lastDate: lastDate,
  initialDateRange: initialRange,
  locale: const Locale('th'),
);
```

### การตรวจสอบความถูกต้อง

```dart
if (result != null) {
  final isValid = BookingDateUtils.validateBookingDateRange(
    result,
    registrationStartDate,
    registrationEndDate,
  );
  
  if (isValid) {
    // ดำเนินการจอง
    print('ช่วงวันที่ถูกต้อง');
  } else {
    // แสดงข้อความ error
    final errorMessage = BookingDateUtils.getDateRangeErrorMessage(
      result,
      registrationStartDate,
      registrationEndDate,
      (dateStr) => DateFormat('dd/MM/yyyy', 'th').format(DateTime.parse(dateStr)),
    );
    print(errorMessage);
  }
}
```

## 📊 ตัวอย่างสถานการณ์

### ตัวอย่างที่ 1: การจองย้อนหลัง

**ข้อมูล:**
- ลงทะเบียนไว้: 02-06/08/2025
- วันนี้: 03/08/2025

**ผลลัพธ์:**
- `firstDate`: 03/08/2025 (ใช้วันปัจจุบัน)
- `lastDate`: 06/08/2025 (ใช้วันที่สิ้นสุดที่ลงทะเบียน)
- ผู้ใช้ไม่สามารถเลือกวันที่ 02/08/2025 ได้

### ตัวอย่างที่ 2: การจองปกติ

**ข้อมูล:**
- ลงทะเบียนไว้: 05-10/08/2025
- วันนี้: 03/08/2025

**ผลลัพธ์:**
- `firstDate`: 05/08/2025 (ใช้วันที่เริ่มต้นที่ลงทะเบียน)
- `lastDate`: 10/08/2025 (ใช้วันที่สิ้นสุดที่ลงทะเบียน)
- ผู้ใช้สามารถเลือกวันที่ 05-10/08/2025 ได้

## 🔍 การ Debug

ระบบมี debug logs ที่แสดงข้อมูลการทำงาน:

```
📅 getFirstAvailableBookingDate:
   registrationStartDate: 2025-08-02 00:00:00.000
   today: 2025-08-03 10:30:00.000
   startDateOnly: 2025-08-02 00:00:00.000
   todayOnly: 2025-08-03 00:00:00.000
   → ใช้วันปัจจุบัน (ป้องกันการจองย้อนหลัง)
```

## 🛠️ การปรับปรุงในอนาคต

1. **เพิ่มการรองรับ Timezone**
2. **เพิ่มการตรวจสอบวันหยุด**
3. **เพิ่มการจำกัดจำนวนวันสูงสุด**
4. **เพิ่มการรองรับการจองแบบต่อเนื่อง**

## 📝 หมายเหตุ

- ฟังก์ชันทั้งหมดใช้ `DateTime` ที่ตัดเวลา (เวลาเป็น 00:00:00)
- ระบบรองรับภาษาไทยผ่าน `Locale('th')`
- ข้อความ error แสดงเป็นภาษาไทย
- มีการตรวจสอบ `mounted` เพื่อป้องกัน memory leak

## 🤝 การสนับสนุน

หากมีปัญหาหรือต้องการปรับปรุง กรุณาแจ้งผ่าน issue tracker ของโปรเจค 