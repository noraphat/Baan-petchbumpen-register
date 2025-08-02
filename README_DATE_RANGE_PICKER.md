# 📅 DateRangePicker ที่จำกัดช่วงวันที่ตามข้อมูลการลงทะเบียน

## 🎯 วัตถุประสงค์

สร้าง DateRangePicker ใน Flutter ที่จำกัดให้ผู้ใช้เลือกได้เฉพาะช่วงวันที่ที่อนุญาตเท่านั้น โดยใช้ข้อมูลจากฐานข้อมูลการลงทะเบียน

## ✅ เงื่อนไขที่ต้องการ

- `firstDate = startDate` (จากข้อมูลการลงทะเบียน)
- `lastDate = endDate` (จากข้อมูลการลงทะเบียน)
- ไม่อนุญาตให้เลือกวันนอกช่วงนี้

## 🚀 วิธีการใช้งาน

### 1. การเตรียมข้อมูล

```dart
// ข้อมูลตัวอย่างจากฐานข้อมูล (ข้อมูลการลงทะเบียน)
final Map<String, dynamic> registrationData = {
  'startDate': '2024-01-15', // วันเริ่มต้นที่ลงทะเบียน
  'endDate': '2024-01-20',   // วันสิ้นสุดที่ลงทะเบียน
};
```

### 2. การเรียกใช้ DateRangePicker

```dart
Future<void> _showDateRangePicker() async {
  // ตรวจสอบว่ามีข้อมูลวันที่ลงทะเบียนหรือไม่
  if (registrationData['startDate'] == null || 
      registrationData['endDate'] == null) {
    _showErrorDialog('ไม่พบข้อมูลช่วงเวลาเข้าพักที่ลงทะเบียนไว้');
    return;
  }

  // แปลงข้อมูลวันที่จาก String เป็น DateTime
  final DateTime startDate = DateTime.parse(registrationData['startDate']);
  final DateTime endDate = DateTime.parse(registrationData['endDate']);

  // ✅ กำหนดช่วงวันที่ที่อนุญาตให้เลือกได้
  // ตามเงื่อนไขที่ต้องการ: firstDate = startDate, lastDate = endDate
  final DateTime firstDate = startDate;
  final DateTime lastDate = endDate;
  
  // กำหนดช่วงเริ่มต้น (initial range) เป็นช่วงเต็มที่ลงทะเบียนไว้
  final DateTimeRange initialRange = DateTimeRange(
    start: startDate,
    end: endDate,
  );

  // แสดง DateRangePicker
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: firstDate,        // ✅ จำกัดวันแรก = startDate
    lastDate: lastDate,          // ✅ จำกัดวันสุดท้าย = endDate
    initialDateRange: initialRange,
    locale: const Locale('th'),
    // ... การตั้งค่าอื่นๆ
  );

  if (picked != null) {
    // ตรวจสอบความถูกต้องของช่วงวันที่ที่เลือก
    final bool isValid = _validateDateRange(picked, startDate, endDate);
    
    if (isValid) {
      // บันทึกข้อมูล
      setState(() {
        selectedRange = picked;
      });
    } else {
      // แสดงข้อความ error
      final String errorMessage = _getErrorMessage(picked, startDate, endDate);
      _showErrorDialog(errorMessage);
    }
  }
}
```

### 3. ฟังก์ชันตรวจสอบความถูกต้อง

```dart
bool _validateDateRange(
  DateTimeRange selectedRange,
  DateTime startDate,
  DateTime endDate,
) {
  // ตรวจสอบว่าวันเริ่มต้นต้องไม่ก่อนวันที่ลงทะเบียน
  final bool startValid = selectedRange.start.isAtSameMomentAs(startDate) ||
                         selectedRange.start.isAfter(startDate);

  // ตรวจสอบว่าวันสิ้นสุดต้องไม่หลังวันที่ลงทะเบียน
  final bool endValid = selectedRange.end.isAtSameMomentAs(endDate) ||
                       selectedRange.end.isBefore(endDate);

  // ตรวจสอบว่าวันเริ่มต้นไม่หลังวันสิ้นสุด
  final bool rangeValid = selectedRange.start.isBefore(selectedRange.end) ||
                         _isSameDay(selectedRange.start, selectedRange.end);

  return startValid && endValid && rangeValid;
}
```

### 4. ฟังก์ชันสร้างข้อความ Error

```dart
String _getErrorMessage(
  DateTimeRange selectedRange,
  DateTime startDate,
  DateTime endDate,
) {
  final String selectedStart = _formatDate(selectedRange.start);
  final String selectedEnd = _formatDate(selectedRange.end);
  final String regStart = _formatDate(startDate);
  final String regEnd = _formatDate(endDate);

  String errorMessage = '❌ **ไม่สามารถเลือกวันเกินช่วงที่ลงทะเบียนไว้ได้**\n\n';

  // ตรวจสอบว่าวันเริ่มต้นหรือวันสิ้นสุดที่เกิน
  if (selectedRange.start.isBefore(startDate)) {
    errorMessage += '• วันเริ่มต้น ($selectedStart) ต้องไม่ก่อนวันที่ลงทะเบียน ($regStart)\n';
  }

  if (selectedRange.end.isAfter(endDate)) {
    errorMessage += '• วันสิ้นสุด ($selectedEnd) ต้องไม่หลังวันที่ลงทะเบียน ($regEnd)\n';
  }

  errorMessage += '\n**ช่วงที่เลือก:** $selectedStart - $selectedEnd\n';
  errorMessage += '**ช่วงที่ลงทะเบียน:** $regStart - $regEnd\n\n';
  errorMessage += '⚠️ กรุณาเลือกวันที่ระหว่าง $regStart ถึง $regEnd เท่านั้น';

  return errorMessage;
}
```

## 🔧 การตั้งค่าเพิ่มเติม

### การตั้งค่า Theme

```dart
builder: (context, child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.blue,
      ),
    ),
    child: child!,
  );
},
```

### การตั้งค่าภาษาไทย

```dart
locale: const Locale('th'),
helpText: 'เลือกช่วงวันที่เข้าพัก',
cancelText: 'ยกเลิก',
confirmText: 'ยืนยัน',
saveText: 'บันทึก',
errorFormatText: 'รูปแบบวันที่ไม่ถูกต้อง',
errorInvalidText: 'วันที่ไม่ถูกต้อง',
errorInvalidRangeText: 'ช่วงวันที่ไม่ถูกต้อง',
fieldStartHintText: 'วันเริ่มต้น',
fieldEndHintText: 'วันสิ้นสุด',
```

## 📋 ตัวอย่างการใช้งานในโปรเจคจริง

ดูไฟล์ `SAMPLE_IMPLEMENTATION.dart` สำหรับตัวอย่างการใช้งานที่สมบูรณ์

## ✨ ข้อดีของวิธีนี้

1. **จำกัดช่วงวันที่ได้อย่างเคร่งครัด** - ผู้ใช้ไม่สามารถเลือกวันนอกช่วงได้
2. **มีการตรวจสอบความถูกต้อง** - ตรวจสอบทั้งใน DateRangePicker และในโค้ด
3. **แสดงข้อความ error ที่ชัดเจน** - แจ้งให้ผู้ใช้ทราบว่าทำไมไม่สามารถเลือกได้
4. **รองรับภาษาไทย** - ใช้ Locale และข้อความภาษาไทย
5. **ใช้งานง่าย** - เรียกใช้เพียงฟังก์ชันเดียว
6. **ปรับแต่งได้** - สามารถปรับแต่ง Theme และข้อความได้

## 🚨 ข้อควรระวัง

1. **ตรวจสอบข้อมูลก่อนใช้งาน** - ต้องแน่ใจว่ามีข้อมูล startDate และ endDate
2. **จัดการ Error** - ต้องจัดการกรณีที่ข้อมูลไม่ถูกต้อง
3. **ตรวจสอบ mounted** - ใช้ mounted เพื่อป้องกัน error หลังจาก widget ถูก dispose
4. **การแปลงข้อมูล** - ตรวจสอบการแปลง String เป็น DateTime

## 📝 สรุป

วิธีนี้จะช่วยให้คุณสร้าง DateRangePicker ที่จำกัดช่วงวันที่ได้ตามต้องการ โดยใช้ข้อมูลจากฐานข้อมูลการลงทะเบียนเป็นตัวกำหนดขอบเขตการเลือกวันที่ 