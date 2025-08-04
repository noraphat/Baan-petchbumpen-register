# คู่มือการทดสอบระบบ Baan Petchbumpen Register

## โครงสร้างการทดสอบ

ระบบการทดสอบถูกแบ่งออกเป็น 4 ประเภทหลัก:

### 1. Unit Tests (`test/unit/`)
ทดสอบฟังก์ชันและคลาสแต่ละตัวแยกกัน
- `registration_menu_test.dart` - ทดสอบเมนูลงทะเบียน
- `daily_summary_test.dart` - ทดสอบเมนูสรุปผลประจำวัน
- `accommodation_booking_test.dart` - ทดสอบเมนูจองที่พัก
- `visitor_management_test.dart` - ทดสอบเมนูข้อมูลผู้ปฏิบัติธรรม
- `developer_settings_test.dart` - ทดสอบ Developer Setting
- `models_test.dart` - ทดสอบโมเดลข้อมูล
- `services_test.dart` - ทดสอบเซอร์วิส

### 2. Widget Tests (`test/widget/`)
ทดสอบการแสดงผลของ Widget แต่ละตัว
- `registration_menu_widget_test.dart`
- `daily_summary_widget_test.dart`
- `accommodation_booking_widget_test.dart`
- `visitor_management_widget_test.dart`
- `developer_settings_widget_test.dart`

### 3. Integration Tests (`test/integration/`)
ทดสอบการทำงานร่วมกันของหลายส่วน
- `daily_summary_integration_test.dart`
- `accommodation_booking_integration_test.dart`
- `visitor_management_integration_test.dart`
- `developer_settings_integration_test.dart`

### 4. Golden Tests (`test/golden/`)
ทดสอบการแสดงผล UI เปรียบเทียบกับภาพอ้างอิง
- `registration_menu_golden_test.dart`
- `daily_summary_golden_test.dart`
- `accommodation_booking_golden_test.dart`
- `visitor_management_golden_test.dart`
- `developer_settings_golden_test.dart`

## วิธีการรันการทดสอบ

### รันการทดสอบทั้งหมด
```bash
./test_runner.sh
```

### รันเฉพาะ Unit Tests
```bash
flutter test test/unit/
```

### รันเฉพาะ Widget Tests
```bash
flutter test test/widget/
```

### รันเฉพาะ Integration Tests
```bash
flutter test test/integration/
```

### รันเฉพาะ Golden Tests
```bash
flutter test test/golden/
```

### รันการทดสอบพร้อม Coverage
```bash
flutter test --coverage
```

## การตั้งค่า Golden Tests

Golden Tests ต้องการการตั้งค่าเพิ่มเติม:

1. สร้างโฟลเดอร์สำหรับเก็บภาพอ้างอิง:
```bash
mkdir -p test/golden/images
```

2. รัน Golden Tests ครั้งแรกเพื่อสร้างภาพอ้างอิง:
```bash
flutter test test/golden/ --update-goldens
```

3. รัน Golden Tests ปกติ:
```bash
flutter test test/golden/
```

## การทดสอบที่ครอบคลุม

### เมนูลงทะเบียน
- ✅ การแสดงผลเมนู 2 ตัวเลือก (กรอกเอง, ถ่ายรูปบัตรประชาชน)
- ✅ การนำทางไปยังหน้าต่างๆ
- ✅ การตรวจสอบ UI elements

### เมนูสรุปผลประจำวัน
- ✅ การแสดงผล TabBar และ TabBarView
- ✅ การเลือกช่วงเวลา (วันนี้, สัปดาห์, เดือน)
- ✅ การเลือกวันที่
- ✅ การ refresh ข้อมูล

### เมนูจองที่พัก
- ✅ การแสดงผลหน้าจองที่พัก
- ✅ การเลือกวันที่
- ✅ การแสดงข้อมูลห้องพัก
- ✅ การเลือกห้องพัก

### เมนูข้อมูลผู้ปฏิบัติธรรม
- ✅ การแสดงรายชื่อผู้ปฏิบัติธรรม
- ✅ การค้นหาด้วยเลขบัตรประชาชนหรือเบอร์โทร
- ✅ การกรองตามเพศ
- ✅ การเรียงลำดับข้อมูล
- ✅ การแก้ไขข้อมูล

### Developer Setting
- ✅ การแสดงข้อมูลที่ถูกลบ
- ✅ การกู้คืนข้อมูล
- ✅ การลบถาวร
- ✅ การนำทางไปยังจัดการแผนที่

## การบำรุงรักษา

### การอัปเดตการทดสอบ
เมื่อมีการเปลี่ยนแปลงโค้ด ควรอัปเดตการทดสอบที่เกี่ยวข้อง:

1. ตรวจสอบ Unit Tests ว่ายังครอบคลุมฟังก์ชันใหม่
2. อัปเดต Widget Tests หากมีการเปลี่ยนแปลง UI
3. ปรับปรุง Integration Tests หากมีการเปลี่ยนแปลง flow
4. อัปเดต Golden Tests หากมีการเปลี่ยนแปลงการแสดงผล

### การแก้ไขปัญหา
- หาก Golden Tests ล้มเหลว ให้ตรวจสอบภาพอ้างอิงและอัปเดตหากจำเป็น
- หาก Integration Tests ล้มเหลว ให้ตรวจสอบการเปลี่ยนแปลงใน flow
- หาก Unit Tests ล้มเหลว ให้ตรวจสอบการเปลี่ยนแปลงในฟังก์ชัน

## หมายเหตุสำคัญ

⚠️ **ห้ามทำให้ test เดิม (เช่น flow การลงทะเบียนเดิม) ใช้งานไม่ได้เด็ดขาด**

การทดสอบเดิมใน `integration_test/` ยังคงใช้งานได้และไม่ควรถูกเปลี่ยนแปลง:
- `registration_flow_test.dart`
- `white_robe_flow_test.dart`
