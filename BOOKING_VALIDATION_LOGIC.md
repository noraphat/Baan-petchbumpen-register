# Logic การตรวจสอบการจองห้องพัก

## 🎯 **เป้าหมาย**
เพิ่ม logic การตรวจสอบเพื่อป้องกันความสับสนในการจัดการห้องพัก

## ✅ **ข้อ 1: การยกเลิกห้องพัก**

### เงื่อนไข
- **ห้ามยกเลิก** หากผู้ใช้เริ่มเข้าพักมาแล้วอย่างน้อย 1 วัน
- **อนุญาต** ให้ใช้ "ปรับปรุงวันที่เข้าพัก" แทน

### Logic การตรวจสอบ
```dart
Future<BookingValidationResult> canCancelBooking({
  required int bookingId,
  required String visitorId,
}) async {
  // 1. ดึงข้อมูลการจอง
  final booking = await getBookingById(bookingId);
  
  // 2. เปรียบเทียบวันที่เข้า vs วันปัจจุบัน
  final checkInDate = DateTime.parse(booking['check_in_date']);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  
  // 3. ตรวจสอบเงื่อนไข
  if (checkInDate.isBefore(todayOnly)) {
    // เริ่มเข้าพักมาแล้ว - ห้ามยกเลิก
    return BookingValidationResult.error(
      'ไม่สามารถยกเลิกการจองได้ เนื่องจากเริ่มเข้าพักมาแล้ว\n'
      'กรุณาใช้ "ปรับปรุงวันที่เข้าพัก" แทน'
    );
  }
  
  if (checkInDate.isAtSameMomentAs(todayOnly)) {
    // เริ่มเข้าพักวันนี้แล้ว - ห้ามยกเลิก
    return BookingValidationResult.error(
      'ไม่สามารถยกเลิกการจองได้ เนื่องจากเริ่มเข้าพักวันนี้แล้ว\n'
      'กรุณาใช้ "ปรับปรุงวันที่เข้าพัก" แทน'
    );
  }
  
  // 4. อนุญาตยกเลิก
  return BookingValidationResult.success();
}
```

### ตัวอย่างการทำงาน
```
กรณีที่ 1: จอง 03/08/2025 - 05/08/2025, วันนี้ 04/08/2025
❌ ห้ามยกเลิก - เริ่มเข้าพักมาแล้ว 1 วัน

กรณีที่ 2: จอง 04/08/2025 - 06/08/2025, วันนี้ 04/08/2025
❌ ห้ามยกเลิก - เริ่มเข้าพักวันนี้แล้ว

กรณีที่ 3: จอง 05/08/2025 - 07/08/2025, วันนี้ 04/08/2025
✅ อนุญาตยกเลิก - ยังไม่เริ่มเข้าพัก
```

## ✅ **ข้อ 2: การเปลี่ยนห้องพัก**

### เงื่อนไข
- **ห้ามเปลี่ยนห้อง** หากห้องปลายทางมีวันใดวันหนึ่งไม่ว่าง
- ต้องตรวจสอบว่าห้องปลายทางว่างครบทุกวันในช่วงที่จะย้าย

### Logic การตรวจสอบ
```dart
Future<BookingValidationResult> canTransferRoom({
  required int currentBookingId,
  required int targetRoomId,
  required String visitorId,
}) async {
  // 1. ดึงข้อมูลการจองปัจจุบัน
  final booking = await getBookingById(currentBookingId);
  final checkInDate = DateTime.parse(booking['check_in_date']);
  final checkOutDate = DateTime.parse(booking['check_out_date']);
  
  // 2. ตรวจสอบการจองที่ขัดแย้งในห้องปลายทาง
  final conflicts = await getExistingRoomBookings(
    roomId: targetRoomId,
    startDate: checkInDate,
    endDate: checkOutDate,
    excludeBookingId: currentBookingId, // ไม่รวมการจองปัจจุบัน
  );
  
  // 3. ตรวจสอบเงื่อนไข
  if (conflicts.isNotEmpty) {
    // มีการจองที่ขัดแย้ง
    final conflictDates = conflicts.map((c) {
      final start = DateTime.parse(c['check_in_date']);
      final end = DateTime.parse(c['check_out_date']);
      return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
    }).join(', ');
    
    return BookingValidationResult.error(
      'ไม่สามารถเปลี่ยนห้องได้ เนื่องจากห้องปลายทางไม่ว่างในช่วงวันที่:\n$conflictDates'
    );
  }
  
  // 4. อนุญาตเปลี่ยนห้อง
  return BookingValidationResult.success();
}
```

### ตัวอย่างการทำงาน
```
กรณีที่ 1: ย้ายจากห้อง A ไปห้อง B
ห้อง A: 03/08/2025 - 05/08/2025
ห้อง B: 04/08/2025 - 06/08/2025 (มีคนอื่นจอง)
❌ ห้ามเปลี่ยน - ห้อง B ไม่ว่างวันที่ 04-05/08/2025

กรณีที่ 2: ย้ายจากห้อง A ไปห้อง B
ห้อง A: 03/08/2025 - 05/08/2025
ห้อง B: ว่าง
✅ อนุญาตเปลี่ยน - ห้อง B ว่างครบทุกวัน

กรณีที่ 3: ย้ายจากห้อง A ไปห้อง B
ห้อง A: 03/08/2025 - 05/08/2025
ห้อง B: 06/08/2025 - 08/08/2025 (มีคนอื่นจอง)
✅ อนุญาตเปลี่ยน - ห้อง B ว่างในช่วงวันที่ต้องการ
```

## 🔧 **การใช้งาน**

### 1. ตรวจสอบการยกเลิก
```dart
final bookingService = BookingService();
final validation = await bookingService.canCancelBooking(
  bookingId: bookingId,
  visitorId: visitorId,
);

if (!validation.isValid) {
  // แสดงข้อความ error
  showErrorDialog(validation.errorMessage!);
  return;
}

// ดำเนินการยกเลิก
await bookingService.cancelBooking(
  bookingId: bookingId,
  visitorId: visitorId,
);
```

### 2. ตรวจสอบการเปลี่ยนห้อง
```dart
final bookingService = BookingService();
final validation = await bookingService.canTransferRoom(
  currentBookingId: currentBookingId,
  targetRoomId: targetRoomId,
  visitorId: visitorId,
);

if (!validation.isValid) {
  // แสดงข้อความ error
  showErrorDialog(validation.errorMessage!);
  return;
}

// ดำเนินการเปลี่ยนห้อง
await bookingService.transferRoom(
  currentBookingId: currentBookingId,
  targetRoomId: targetRoomId,
  visitorId: visitorId,
);
```

## 📋 **ไฟล์ที่เกี่ยวข้อง**

### ไฟล์ใหม่
1. `lib/services/booking_service.dart` - เพิ่มฟังก์ชันตรวจสอบ
2. `BookingValidationResult` class - ผลลัพธ์การตรวจสอบ

### ไฟล์ที่แก้ไข
1. `lib/widgets/booking_info_widget.dart` - ใช้ฟังก์ชันตรวจสอบใหม่
2. `lib/screen/accommodation_booking_screen.dart` - ใช้ฟังก์ชันตรวจสอบใหม่

## 🎨 **UI/UX**

### 1. การยกเลิกการจอง
```
┌─────────────────────────────────────┐
│ ❌ ไม่สามารถยกเลิกการจองได้         │
├─────────────────────────────────────┤
│ ไม่สามารถยกเลิกการจองได้ เนื่องจาก  │
│ เริ่มเข้าพักมาแล้ว                   │
│                                     │
│ กรุณาใช้ "ปรับปรุงวันที่เข้าพัก" แทน  │
├─────────────────────────────────────┤
│ [ตกลง]                              │
└─────────────────────────────────────┘
```

### 2. การเปลี่ยนห้อง
```
┌─────────────────────────────────────┐
│ ❌ ไม่สามารถเปลี่ยนห้องได้           │
├─────────────────────────────────────┤
│ ไม่สามารถเปลี่ยนห้องได้ เนื่องจาก    │
│ ห้องปลายทางไม่ว่างในช่วงวันที่:      │
│ 04/08/2025 - 06/08/2025             │
├─────────────────────────────────────┤
│ [ตกลง]                              │
└─────────────────────────────────────┘
```

## ✅ **ข้อดีของ Logic ใหม่**

1. **ป้องกันความสับสน**: ห้ามยกเลิกการจองที่เริ่มเข้าพักแล้ว
2. **ป้องกันการทับซ้อน**: ตรวจสอบห้องปลายทางก่อนเปลี่ยน
3. **ชัดเจน**: แสดงข้อความ error ที่เข้าใจง่าย
4. **ปลอดภัย**: มีการตรวจสอบก่อนดำเนินการ
5. **ยืดหยุ่น**: ยังสามารถปรับปรุงวันที่ได้

## 🔮 **อนาคต**

1. **เพิ่มการแจ้งเตือน**: แจ้งเตือนเมื่อใกล้ถึงวันเข้าพัก
2. **เพิ่มการยืนยัน**: ยืนยันการเปลี่ยนแปลงที่สำคัญ
3. **เพิ่มประวัติ**: บันทึกประวัติการเปลี่ยนแปลง
4. **เพิ่มรายงาน**: รายงานการใช้งานห้องพัก 