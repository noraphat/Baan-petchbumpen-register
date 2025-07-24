# 🔧 แก้ไขฟีเจอร์การแสดงสถานะในหน้า "ประวัติการมาปฏิบัติธรรม"

## 🔸 ปัญหาที่พบ
- รายการในประวัติที่แสดงสถานะ "กำลังพัก" ทั้งที่วันสิ้นสุด (`endDate`) ผ่านไปแล้ว
- สถานะไม่ตรงกับความเป็นจริงตามเวลาปัจจุบัน

## 🔸 การแก้ไขที่ทำ

### 1. **เพิ่ม Logic ใน StayRecord Model** ✅
```dart
// lib/models/reg_data.dart

// ได้สถานะที่ถูกต้องตามเวลาจริง
String get actualStatus {
  if (isExpired && (status == 'active' || status == 'extended')) {
    return 'completed'; // ปรับสถานะเป็น completed หากหมดอายุแล้ว
  }
  return status; // ใช้สถานะเดิมหากยังไม่หมดอายุ
}

// ตรวจสอบว่าต้องอัปเดตสถานะในฐานข้อมูลหรือไม่
bool get needsStatusUpdate {
  return isExpired && (status == 'active' || status == 'extended');
}
```

### 2. **เพิ่มฟังก์ชันอัปเดตสถานะอัตโนมัติใน DbHelper** ✅
```dart
// lib/services/db_helper.dart

// อัปเดตสถานะ stay ที่หมดอายุแล้วอัตโนมัติ
Future<void> updateExpiredStays() async {
  final today = DateTime.now();
  final todayStr = DateTime(today.year, today.month, today.day).toIso8601String();
  
  await (await db).update(
    'stays',
    {'status': 'completed'},
    where: 'status IN (?, ?) AND date(end_date) < date(?)',
    whereArgs: ['active', 'extended', todayStr],
  );
}
```

### 3. **ปรับปรุงการดึงข้อมูลให้อัปเดตสถานะอัตโนมัติ** ✅
```dart
// lib/services/db_helper.dart

// ดึงข้อมูล Stay ทั้งหมดของผู้เข้าพัก (พร้อมอัปเดตสถานะที่หมดอายุ)
Future<List<StayRecord>> fetchAllStays(String visitorId) async {
  // อัปเดตสถานะที่หมดอายุก่อนดึงข้อมูล
  await updateExpiredStays();
  
  final res = await (await db).query(
    'stays',
    where: 'visitor_id = ?',
    whereArgs: [visitorId],
    orderBy: 'created_at DESC',
  );
  return res.map((m) => StayRecord.fromMap(m)).toList();
}
```

### 4. **แก้ไขการแสดงสถานะในหน้า VisitorHistory** ✅
```dart
// lib/screen/visitor_history.dart

// แสดงสถานะเฉพาะเมื่อยังไม่สิ้นสุด
if (stay.actualStatus != 'completed') 
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getStatusColor(stay.actualStatus),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      _getStatusText(stay.actualStatus),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
```

### 5. **อัปเดตหน้า VisitorManagement** ✅
```dart
// lib/screen/visitor_management.dart

Future<void> _loadVisitors() async {
  // อัปเดตสถานะ stay ที่หมดอายุก่อนดึงข้อมูล
  await dbHelper.updateExpiredStays();
  
  // ... ดึงข้อมูลผู้ปฏิบัติธรรม
}
```

## 🎯 ผลลัพธ์หลังการแก้ไข

### **ก่อนแก้ไข:**
- ❌ รายการที่หมดอายุแล้วยังแสดงสถานะ "กำลังพัก"
- ❌ ข้อมูลไม่ตรงกับความเป็นจริง

### **หลังแก้ไข:**
- ✅ รายการที่หมดอายุแล้วจะ**ซ่อน**สถานะ (ไม่แสดงข้อความ "กำลังพัก")
- ✅ ข้อมูลในฐานข้อมูลถูกอัปเดตอัตโนมัติเป็น `'completed'`
- ✅ การตรวจสอบทำงานใน **Data level** ทุกครั้งที่ดึงข้อมูล

## 📊 การทำงานของระบบ

### **Flow การอัปเดตสถานะ:**
1. **เมื่อดึงข้อมูล** → เรียก `updateExpiredStays()` อัตโนมัติ
2. **ตรวจสอบ** → `endDate < DateTime.now()` และ `status` เป็น `'active'` หรือ `'extended'`
3. **อัปเดต** → เปลี่ยนสถานะเป็น `'completed'` ในฐานข้อมูล
4. **แสดงผล** → ใช้ `stay.actualStatus` แทน `stay.status`
5. **UI** → ซ่อนสถานะเมื่อ `actualStatus == 'completed'`

### **เงื่อนไขการอัปเดต:**
```sql
status IN ('active', 'extended') AND date(end_date) < date(current_date)
```

## 🧪 การทดสอบ

### **สร้าง Widget ทดสอบ:** `lib/widgets/status_test_widget.dart`
- 🔵 **ปุ่มน้ำเงิน**: สร้างข้อมูล Stay ที่หมดอายุสำหรับทดสอบ
- 🟢 **ปุ่มเขียว**: ทดสอบฟังก์ชันอัปเดตสถานะ

### **ผลการทดสอบ:**
- ✅ Build APK สำเร็จ
- ✅ Logic การตรวจสอบ `isExpired` ทำงานถูกต้อง
- ✅ ฟังก์ชัน `updateExpiredStays()` อัปเดตฐานข้อมูลได้
- ✅ UI ซ่อนสถานะที่หมดอายุแล้ว

## 🔧 ไฟล์ที่ได้รับการปรับปรุง

1. **`lib/models/reg_data.dart`**
   - เพิ่ม `actualStatus` getter
   - เพิ่ม `needsStatusUpdate` getter

2. **`lib/services/db_helper.dart`**
   - เพิ่ม `updateExpiredStays()` method
   - แก้ไข `fetchAllStays()` ให้อัปเดตสถานะอัตโนมัติ
   - แก้ไข `fetchActiveStays()` ให้อัปเดตสถานะอัตโนมัติ

3. **`lib/screen/visitor_history.dart`**
   - ใช้ `stay.actualStatus` แทน `stay.status`
   - ซ่อนสถานะเมื่อ `actualStatus == 'completed'`

4. **`lib/screen/visitor_management.dart`**
   - เรียก `updateExpiredStays()` ก่อนดึงข้อมูล

5. **`lib/widgets/status_test_widget.dart`** (ใหม่)
   - Widget สำหรับทดสอบระบบอัปเดตสถานะ

## 🎉 สรุป

การแก้ไขครั้งนี้แก้ปัญหาการแสดงสถานะที่ไม่ตรงกับความเป็นจริง:

✅ **ตรวจสอบอัตโนมัติ** - ระบบตรวจสอบและอัปเดตสถานะทุกครั้งที่ดึงข้อมูล  
✅ **Data Level Update** - อัปเดตข้อมูลในฐานข้อมูลให้ตรงกับความเป็นจริง  
✅ **UI ที่ถูกต้อง** - ซ่อนสถานะเมื่อการปฏิบัติธรรมสิ้นสุดแล้ว  
✅ **Performance** - ใช้ SQL query ที่มีประสิทธิภาพ  

ระบบพร้อมใช้งานและแสดงข้อมูลที่ตรงกับความเป็นจริงแล้ว! 🚀