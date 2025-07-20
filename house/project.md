# ระบบลงทะเบียนสถานปฏิบัติธรรม บ้านเพชรบำเพ็ญ

## 📋 ภาพรวมโปรเจ็กต์
**ชื่อแอป:** flutter_petchbumpen_register  
**วัตถุประสงค์:** สร้างแอปพลิเคชัน Desktop/Mobile สำหรับเจ้าหน้าที่ในการลงทะเบียนผู้มาปฏิบัติธรรม จัดการข้อมูลส่วนตัว การยืม-คืนอุปกรณ์ และสรุปรายงานสถิติ

## 🛠️ เทคโนโลยี
- **Frontend:** Flutter 3.8.1+ (Material Design 3)
- **Database:** SQLite + sqflite
- **Localization:** Thai (th_TH) + English (en_US)
- **Platform:** Desktop (Windows/macOS/Linux) + Mobile (Android/iOS)

## 📦 Dependencies หลัก
```yaml
dependencies:
  flutter_localizations: sdk
  sqflite: ^2.3.2+1
  thai_idcard_reader_flutter: ^0.0.7  # อ่านบัตรประชาชน
  mobile_scanner: ^4.0.1              # QR Code Scanner
  sunmi_printer_plus: ^2.1.01         # เครื่องปริ้นเตอร์
  path_provider: ^2.1.2               # จัดการไฟล์
  intl: ^0.20.2                       # Thai Calendar
```

## 🎯 ฟีเจอร์หลัก

### 1. ระบบลงทะเบียน (Registration System)
- **Manual Registration:** กรอกข้อมูลด้วยตนเอง (ฟอร์มแบบเต็ม)
- **ID Card Reading:** อ่านบัตรประชาชนด้วย SmartCard Reader
- **Address Management:** ระบบที่อยู่แบบ Dropdown (จังหวัด/อำเภอ/ตำบล)
- **Buddhist Calendar:** ปฏิทินพุทธศักราช สำหรับเลือกวันเกิด

### 2. การจัดการข้อมูลส่วนตัว
- **Member Search:** ค้นหาสมาชิกด้วยเลขบัตร/เบอร์โทร
- **Data Validation:** ตรวจสอบข้อมูลเดิม/ใหม่
- **Editable Fields:** แก้ไขข้อมูลได้บางส่วน (เบอร์โทร) สำหรับผู้มีบัตร

### 3. ระบบจัดการที่พักและอุปกรณ์
- **Stay Information:** วันที่เริ่ม-สิ้นสุด, ห้องพัก, จำนวนเด็ก
- **Equipment Management:** ชุดขาว, กางเกงขาว, เสื่อ, หมอน, ผ้าห่ม
- **Counter Interface:** ปุ่ม +/- สำหรับเพิ่ม-ลดจำนวนอุปกรณ์

### 4. เบิกชุดขาว (White Robe Distribution)
- **QR Scanner:** สแกน QR Code จากใบเสร็จ
- **ID Validation:** ตรวจสอบรูปแบบเลขบัตรประชาชน
- **Quick Approval:** อนุมัติการรับชุดขาวทันที

## 🗄️ โครงสร้างฐานข้อมูล

### ตาราง `regs` (ข้อมูลผู้ลงทะเบียน)
```sql
CREATE TABLE regs (
  id TEXT PRIMARY KEY,          -- เลขบัตร/เบอร์โทร
  first TEXT,                   -- ชื่อ
  last TEXT,                    -- นามสกุล
  dob TEXT,                     -- วันเกิด (Thai format)
  phone TEXT,                   -- เบอร์โทรศัพท์
  addr TEXT,                    -- ที่อยู่เต็ม
  gender TEXT,                  -- เพศ (พระ/สามเณร/แม่ชี/ชาย/หญิง/อื่นๆ)
  hasIdCard INTEGER,            -- มีบัตรประชาชน (1/0)
  createdAt TEXT,               -- วันที่สร้าง
  updatedAt TEXT                -- วันที่แก้ไขล่าสุด
)
```

### ตาราง `reg_additional_info` (ข้อมูลการพัก)
```sql
CREATE TABLE reg_additional_info (
  regId TEXT PRIMARY KEY,       -- FK → regs.id
  startDate TEXT,               -- วันเริ่มพัก
  endDate TEXT,                 -- วันสิ้นสุด
  shirtCount INTEGER,           -- จำนวนเสื้อขาว
  pantsCount INTEGER,           -- จำนวนกางเกงขาว
  matCount INTEGER,             -- จำนวนเสื่อ
  pillowCount INTEGER,          -- จำนวนหมอน
  blanketCount INTEGER,         -- จำนวนผ้าห่ม
  location TEXT,                -- ห้อง/ศาลา/สถานที่พัก
  withChildren INTEGER,         -- มากับเด็ก (1/0)
  childrenCount INTEGER,        -- จำนวนเด็ก
  notes TEXT,                   -- หมายเหตุ
  createdAt TEXT,
  updatedAt TEXT
)
```

## 🎨 UI/UX Design

### การออกแบบ
- **Color Scheme:** สีม่วง (Purple) เป็นสีหลัก
- **Material Design 3:** ใช้ Material 3 components
- **Responsive Layout:** รองรับทั้ง Desktop และ Mobile
- **Thai Fonts:** รองรับการแสดงผลภาษาไทยที่สวยงาม

### Navigation Structure
```
Home Screen
├── ลงทะเบียน (Registration Menu)
│   ├── กรอกเอง (Manual Form)
│   └── ถ่ายรูปบัตรประชาชน (ID Card Reader)
├── เบิกชุดขาว (White Robe Scanner)
├── จองที่พัก (WIP)
├── ตารางกิจกรรม (WIP)
└── สรุปผลประจำวัน (WIP)
```

## 🔧 คลาสและโมดูลหลัก

### Models
- **`RegData`** - โมเดลข้อมูลผู้ลงทะเบียน
- **`RegAdditionalInfo`** - ข้อมูลการพักและอุปกรณ์
- **`AddressInfo`** - จัดการที่อยู่แยกส่วน

### Services
- **`DbHelper`** - จัดการฐานข้อมูล SQLite
- **`AddressService`** - โหลดข้อมูลที่อยู่จาก JSON
- **`PrinterService`** - จัดการเครื่องพิมพ์

### Widgets
- **`BuddhistCalendarPicker`** - ปฏิทินพุทธศักราช
- **`MenuCard`** - การ์ดเมนูหลัก

### Screens
- **`HomeScreen`** - หน้าจอหลัก
- **`RegistrationMenu`** - เมนูลงทะเบียน
- **`ManualForm`** - ฟอร์มกรอกด้วยตนเอง
- **`CaptureForm`** - อ่านบัตรประชาชน
- **`WhiteRobeScanner`** - สแกน QR เบิกชุดขาว

## 🔄 User Flows

### 1. Registration Flow (Manual)
```
1. กรอกเลขบัตร/เบอร์โทร → ค้นหา
2. หากไม่พบ → กรอกข้อมูลใหม่ทั้งหมด
3. หากพบแล้ว → แสดงข้อมูล (แก้ไขได้เฉพาะเบอร์โทร)
4. เลือกข้อมูลเพิ่มเติม (วันที่, อุปกรณ์, เด็ก)
5. บันทึกลงฐานข้อมูล
```

### 2. ID Card Reading Flow
```
1. เชื่อมต่อ Smart Card Reader
2. เสียบบัตรประชาชน
3. อ่านข้อมูลและแสดงผล (รูปภาพ + ข้อมูล)
4. ยืนยันและบันทึก
```

### 3. White Robe Distribution Flow
```
1. สแกน QR Code จากใบเสร็จ
2. ตรวจสอบรูปแบบเลขบัตรประชาชน
3. แสดงผลการอนุมัติ
```

## ⚡ ฟีเจอร์พิเศษ

### 🔓 Secret Developer Mode
- **Activation:** กดโลโก้ 🏛️ "บ้านเพชรบำเพ็ญ" 12 ครั้งภายใน 5 วินาที
- **Toast Message:** 🧙‍♂️ "Secret Developer Mode unlocked!"
- **Access:** เปิดหน้า Admin Settings แบบลับ

### 🔧 Admin Settings (Secret Developer Mode)

**📱 เมนูหลัก - การจัดการ**
- [🔒] ลงทะเบียน (ปิดไม่ได้)
- [⚙️] เบิกชุดขาว [✅ เปิด / ❌ ปิด]
- [⚙️] จองที่พัก [✅ เปิด / ❌ ปิด]  
- [⚙️] ตารางกิจกรรม (ปิดไม่ได้)
- [⚙️] สรุปผลประจำวัน (ปิดไม่ได้)

**🗃️ จัดการข้อมูล**
- [ปุ่ม] ดูสถิติฐานข้อมูล
- [ปุ่ม] ล้างข้อมูลทดสอบ
- [ปุ่ม] สร้างข้อมูลทดสอบ
- [ปุ่ม] ล้างข้อมูลทั้งหมด (มี Confirm)

**💾 สำรองข้อมูล**
- [ปุ่ม] Export ข้อมูลเป็น JSON
- [ปุ่ม] Export รายงาน PDF
- [ปุ่ม] Import ข้อมูล
- [Toggle] Auto Backup รายวัน [✅ เปิด / ❌ ปิด]

**ℹ️ ข้อมูลระบบ**
- App Version: v1.0.0
- Database Version: 4
- จำนวนผู้ลงทะเบียน: xxx คน
- ผู้เข้าพักปัจจุบัน: xxx คน
- พื้นที่ DB: x.x MB

### Data Management
- **Search & Validation:** ค้นหาสมาชิกเดิม
- **Thai National ID Validation:** ตรวจสอบความถูกต้องของเลขบัตรประชาชน
- **Editable vs Non-editable Fields:** แยกสิทธิ์การแก้ไข
- **Address Autocomplete:** ระบบที่อยู่อัตโนมัติ
- **Date Validation:** รองรับปฏิทินไทย

## 🔮 Future Enhancements
- **Dashboard & Analytics** - สถิติผู้ลงทะเบียนรายวัน/เดือน
- **Room Booking System** - จองห้องพัก/ศาลา
- **Activity Schedule** - ตารางกิจกรรมรายวัน
- **Report Generation** - สร้างรายงาน PDF/Excel
- **Backup & Sync** - สำรองข้อมูลอัตโนมัติ

## 🎯 Business Rules
- **สมาชิกเดิม:** แก้ไขได้เฉพาะเบอร์โทรศัพท์
- **สมาชิกใหม่:** กรอกข้อมูลครบถ้วนทั้งหมด
- **Equipment Limit:** จำกัดการเลือกอุปกรณ์ 0-9 ชิ้น
- **Date Validation:** วันสิ้นสุดต้องมากกว่าวันเริ่มต้น
- **Required Fields:** ชื่อ, นามสกุล, วันเกิด, ที่อยู่ (บังคับ)

---

---

## 📋 **การติดตาม Project Progress**

สำหรับผู้ที่จะมา continue project นี้ต่อ กรุณาอ่านไฟล์เหล่านี้:

### **📁 เอกสารสำคัญ**
- **`house/dashboard.md`** - Dashboard overview และ progress tracking
- **`house/tasks/`** - Task history และ implementation details แต่ละวัน
- **`house/project.md`** (ไฟล์นี้) - Project scope และ remaining tasks
- **`house/spec/`** - Technical specifications และ requirements

### **🎯 วิธีการ Continue Project**
1. อ่าน `house/dashboard.md` เพื่อดู overall progress
2. อ่าน `house/tasks/2025-07-20.md` เพื่อดู latest implementation
3. Review **Remaining Tasks (3%)** ด้านบน
4. เลือก priority task ที่จะทำต่อ
5. สร้างไฟล์ `house/tasks/YYYY-MM-DD.md` ใหม่สำหรับ session ใหม่

### **🚀 Expected Timeline to 100%**
- **Total Remaining Work**: 3%
- **Estimated Sessions**: 2-3 development sessions
- **Critical Path**: User Data Management → Terms & Conditions → Testing
- **Ready for Production**: After TestBot validation

---

*อัพเดตล่าสุด: 20 กรกฎาคม 2025*
