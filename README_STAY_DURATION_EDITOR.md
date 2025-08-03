# ระบบปรับปรุงวันที่เข้าพัก (Stay Duration Editor)

## 📋 ภาพรวม

ระบบนี้ถูกออกแบบมาเพื่อให้ผู้ใช้สามารถ **เพิ่มหรือลด** วันเข้าพักได้อย่างยืดหยุ่น โดยเปลี่ยนจากเดิมที่สามารถ "ขยายวันพัก" ได้เท่านั้น เป็น "ปรับปรุงวันที่เข้าพัก" ที่รองรับทั้งการเพิ่มและลดวัน

## 🎯 ฟีเจอร์หลัก

### ✅ รองรับการเพิ่มและลดวันเข้าพัก
- เพิ่มวันเข้าพัก (ขยายวันพัก)
- ลดวันเข้าพัก (ย่นวันพัก)
- ตรวจสอบความถูกต้องตามเงื่อนไข

### ✅ การตรวจสอบความถูกต้อง
- ไม่อนุญาตให้ลดวันไปก่อนวันปัจจุบัน
- ไม่อนุญาตให้วันสิ้นสุดก่อนวันเริ่มต้น
- ตรวจสอบการจองที่ขัดแย้ง

### ✅ UI ที่ชัดเจน
- แสดงการเปลี่ยนแปลงด้วยสีและไอคอน
- แสดงข้อความแจ้งเตือนที่ชัดเจน
- แสดงสรุปการเปลี่ยนแปลง

## 🔧 ฟังก์ชันหลัก

### 1. `validateUpdatedStayDate()`

```dart
ValidationResult validateUpdatedStayDate({
  required DateTime startDate,
  required DateTime newEndDate,
  required List<DateTimeRange> existingBookings,
  required DateTime today,
})
```

**หน้าที่:** ตรวจสอบความถูกต้องของการปรับปรุงวันที่เข้าพัก

**เงื่อนไขการตรวจสอบ:**
1. `newEndDate` ต้องไม่ก่อนวันปัจจุบัน
2. `newEndDate` ต้องไม่ก่อน `startDate`
3. ไม่มีการจองที่ขัดแย้งกับช่วงวันที่ใหม่

### 2. `ValidationResult`

```dart
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;
}
```

**ประเภทของข้อผิดพลาด:**
- `endDateBeforeToday` - วันสิ้นสุดก่อนวันปัจจุบัน
- `endDateBeforeStartDate` - วันสิ้นสุดก่อนวันเริ่มต้น
- `conflictingBookings` - มีการจองที่ขัดแย้ง
- `invalidDateRange` - ช่วงวันที่ไม่ถูกต้อง

## 🚀 วิธีการใช้งาน

### การใช้งานพื้นฐาน

```dart
// ตรวจสอบความถูกต้อง
final result = StayDurationValidator.validateUpdatedStayDate(
  startDate: currentCheckIn,
  newEndDate: newCheckOut,
  existingBookings: existingBookings,
  today: DateTime.now(),
);

if (result.isValid) {
  // ดำเนินการบันทึก
  await updateStayDuration(newCheckOut);
} else {
  // แสดงข้อความ error
  showErrorDialog(result.errorMessage!);
}
```

### การใช้งานใน Dialog

```dart
Future<void> _showEditStayDurationDialog(Map<String, dynamic> occupantInfo) async {
  final currentCheckOut = DateTime.parse(occupantInfo['check_out_date']);
  DateTime? newCheckOutDate = currentCheckOut;

  final result = await showDialog<DateTime>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('ปรับปรุงวันที่เข้าพักสำหรับ ${occupantInfo['first_name']}'),
      content: Column(
        children: [
          Text('คุณสามารถเพิ่มหรือลดวันเข้าพักได้ตามต้องการ'),
          // DatePicker และ validation
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final validationResult = await _validateUpdatedStayDate(
              occupantInfo,
              newCheckOutDate!,
            );
            
            if (validationResult.isValid) {
              Navigator.pop(context, newCheckOutDate);
            } else {
              showErrorDialog(validationResult.errorMessage!);
            }
          },
          child: Text('บันทึก'),
        ),
      ],
    ),
  );

  if (result != null) {
    await _updateCheckOutDate(occupantInfo, result);
  }
}
```

## 📊 ตัวอย่างสถานการณ์

### กรณีที่ 1: เพิ่มวันเข้าพัก (ถูกต้อง)

**ข้อมูล:**
- วันเริ่มต้น: 03/08/2025
- วันสิ้นสุดเดิม: 05/08/2025
- วันสิ้นสุดใหม่: 07/08/2025
- วันปัจจุบัน: 03/08/2025

**ผลลัพธ์:**
- ✅ ผ่านการตรวจสอบ
- เพิ่ม 2 วัน
- บันทึกสำเร็จ

### กรณีที่ 2: ลดวันเข้าพัก (ถูกต้อง)

**ข้อมูล:**
- วันเริ่มต้น: 03/08/2025
- วันสิ้นสุดเดิม: 05/08/2025
- วันสิ้นสุดใหม่: 04/08/2025
- วันปัจจุบัน: 03/08/2025

**ผลลัพธ์:**
- ✅ ผ่านการตรวจสอบ
- ลด 1 วัน
- บันทึกสำเร็จ

### กรณีที่ 3: ลดวันเกินไป (ผิด)

**ข้อมูล:**
- วันเริ่มต้น: 03/08/2025
- วันสิ้นสุดเดิม: 05/08/2025
- วันสิ้นสุดใหม่: 02/08/2025
- วันปัจจุบัน: 03/08/2025

**ผลลัพธ์:**
- ❌ ไม่ผ่านการตรวจสอบ
- ข้อความ: "ไม่สามารถลดวันเข้าพักให้เลยวันปัจจุบันได้"

### กรณีที่ 4: ขัดแย้งกับการจอง (ผิด)

**ข้อมูล:**
- วันเริ่มต้น: 03/08/2025
- วันสิ้นสุดเดิม: 05/08/2025
- วันสิ้นสุดใหม่: 07/08/2025
- มีการจองในวันที่ 06-08/08/2025

**ผลลัพธ์:**
- ❌ ไม่ผ่านการตรวจสอบ
- ข้อความ: "ไม่สามารถลดช่วงวันเข้าพักได้ เพราะมีการจองห้องในวันดังกล่าว"

## 🎨 UI Components

### Date Status Display

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: dayDifference > 0 ? Colors.green.shade50 : Colors.orange.shade50,
    border: Border.all(
      color: dayDifference > 0 ? Colors.green.shade200 : Colors.orange.shade200,
    ),
  ),
  child: Row(
    children: [
      Icon(
        dayDifference > 0 ? Icons.trending_up : Icons.trending_down,
        color: dayDifference > 0 ? Colors.green : Colors.orange,
      ),
      Text(
        dayDifference > 0 
            ? 'เพิ่ม $dayDifference วัน'
            : 'ลด ${dayDifference.abs()} วัน',
      ),
    ],
  ),
)
```

### Validation Result Display

```dart
Container(
  decoration: BoxDecoration(
    color: validationResult.isValid ? Colors.green.shade50 : Colors.red.shade50,
    border: Border.all(
      color: validationResult.isValid ? Colors.green.shade200 : Colors.red.shade200,
    ),
  ),
  child: Row(
    children: [
      Icon(
        validationResult.isValid ? Icons.check_circle : Icons.error,
        color: validationResult.isValid ? Colors.green : Colors.red,
      ),
      Text(validationResult.errorMessage ?? 'การเปลี่ยนแปลงถูกต้อง'),
    ],
  ),
)
```

## 📁 โครงสร้างไฟล์

```
lib/
├── utils/
│   └── stay_duration_validator.dart     # ฟังก์ชัน validation หลัก
├── screen/
│   └── accommodation_booking_screen.dart # หน้าจองห้องพัก (อัพเดทแล้ว)
├── example_stay_duration_editor.dart     # ตัวอย่างการใช้งาน
└── README_STAY_DURATION_EDITOR.md       # คู่มือการใช้งาน
```

## 🔍 การ Debug

ระบบมี debug logs ที่แสดงข้อมูลการทำงาน:

```
🔍 ตรวจสอบการปรับปรุงวันที่เข้าพัก:
   startDate: 2025-08-03 00:00:00.000
   newEndDate: 2025-08-07 00:00:00.000
   today: 2025-08-03 10:30:00.000
   existingBookings: 2 รายการ
   ✅ การปรับปรุงวันที่เข้าพักถูกต้อง
```

## 🛠️ การปรับปรุงในอนาคต

1. **เพิ่มการปรับวันเริ่มต้น**
   - อนุญาตให้ปรับวันเริ่มต้นได้
   - ตรวจสอบการจองที่ขัดแย้ง

2. **เพิ่มการแจ้งเตือนล่วงหน้า**
   - แจ้งเตือนเมื่อใกล้ถึงวันสิ้นสุด
   - แสดงจำนวนวันที่เหลือ

3. **เพิ่มการประวัติการเปลี่ยนแปลง**
   - บันทึกประวัติการปรับปรุง
   - แสดงรายการการเปลี่ยนแปลง

## 📝 หมายเหตุ

- ฟังก์ชันทั้งหมดใช้ `DateTime` ที่ตัดเวลา (เวลาเป็น 00:00:00)
- ระบบรองรับภาษาไทยผ่าน `DateFormat`
- มีการตรวจสอบ `mounted` เพื่อป้องกัน memory leak
- UI แสดงสถานะที่ชัดเจนด้วยสีและไอคอน

## 🤝 การสนับสนุน

หากมีปัญหาหรือต้องการปรับปรุง กรุณาแจ้งผ่าน issue tracker ของโปรเจค 