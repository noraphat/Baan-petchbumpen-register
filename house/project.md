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
- **Stay Information:** วันที่เริ่ม-สิ้นสุด, ห้องพัก, จำนวนเด็ก, สถานะการพัก
- **Equipment Management:** ชุดขาว, กางเกงขาว, เสื่อ, หมอน, ผ้าห่ม
- **Counter Interface:** ปุ่ม +/- สำหรับเพิ่ม-ลดจำนวนอุปกรณ์
- **Receipt Printing:** ใบเสร็จแสดงจำนวนอุปกรณ์จริง, วันที่เข้าพัก, และ QR Code

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

### ตาราง `stays` (ข้อมูลการเข้าพัก)
```sql
CREATE TABLE stays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  visitor_id TEXT,              -- FK → regs.id
  start_date TEXT,              -- วันที่เริ่มพัก
  end_date TEXT,                -- วันที่สิ้นสุด
  status TEXT,                  -- 'active', 'extended', 'completed'
  note TEXT,                    -- หมายเหตุ
  created_at TEXT               -- วันที่สร้างข้อมูล
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
- **`RegAdditionalInfo`** - ข้อมูลอุปกรณ์และรายละเอียดเพิ่มเติม
- **`StayRecord`** - ข้อมูลการเข้าพัก (วันที่เริ่ม-สิ้นสุด, สถานะ)
- **`AddressInfo`** - จัดการที่อยู่แยกส่วน

### Services
- **`DbHelper`** - จัดการฐานข้อมูล SQLite
- **`AddressService`** - โหลดข้อมูลที่อยู่จาก JSON
- **`PrinterService`** - จัดการเครื่องพิมพ์ Sunmi (รองรับข้อมูลอุปกรณ์และวันที่เข้าพัก)

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

---

## 🎯 Recent Updates (23 มกราคม 2568)

### ✅ แก้ไขปัญหา PrinterService
- **Issue:** ข้อผิดพลาด `printTable` method ไม่มีอยู่ในไลบรารี `sunmi_printer_plus`
- **Solution:** แทนที่ด้วย `printText` method สำหรับแสดงรายการอุปกรณ์

### ✨ ปรับปรุงใบเสร็จ (Receipt Enhancement)
- **Equipment Display:** แสดงจำนวนอุปกรณ์จริงจาก Dialog แทนรายการมาตรฐาน
- **Stay Information:** เพิ่มข้อมูลวันที่เข้าพักในรูปแบบภาษาไทย (พ.ศ.)
  - กรณีพักวันเดียว: "วันที่เข้าพัก-วันที่สิ้นสุด: XX เดือน XXXX"
  - กรณีพักหลายวัน: แสดงวันเริ่มและวันสิ้นสุดแยกกัน
  - แสดงจำนวนวันที่เข้าพักทั้งหมด
- **QR Code:** เพิ่มขนาดจาก size 6 เป็น size 7

### 🔧 Technical Improvements
- **PrinterService:** รับ parameters เพิ่มเติม (`RegAdditionalInfo`, `StayRecord`)
- **Date Formatting:** ฟังก์ชัน `_formatDateThai()` สำหรับแปลงวันที่เป็นภาษาไทย
- **Database Structure:** ใช้ `stays` table สำหรับจัดการข้อมูลวันที่เข้าพัก

*อัพเดตล่าสุด: 24 กรกฎาคม 2568*

---

## 🎯 **Latest Updates (24 กรกฎาคม 2568)**

### ✅ **ฟีเจอร์ "ตรวจสอบและแก้ไขข้อมูลผู้ปฏิบัติธรรม" - การปรับปรุงครบถ้วน**

#### **🔧 การแก้ไขปัญหาหลัก:**
1. **Dynamic Gender Filter** - เปลี่ยนจาก hardcoded เป็นดึงจากฐานข้อมูลจริง
2. **Layout Overflow Fix** - แก้ไข "Right Overflowed by 49 pixels" ด้วย Responsive Design
3. **History Sorting Fix** - เรียงลำดับจากใหม่สุด→เก่าสุด และแก้ไขหมายเลข "ครั้งที่..."
4. **Developer Settings** - เพิ่มหน้าจัดการ Soft Delete (กู้คืน/ลบถาวร)

#### **🏗️ การปรับปรุงระบบ:**
- **Database Schema:** อัปเดตเป็น version 6 (เพิ่ม status column สำหรับ soft delete)
- **Soft Delete System:** สมบูรณ์แบบ พร้อม restore function
- **Status Auto-Update:** แก้ไขปัญหาการแสดงสถานะที่ไม่ตรงกับความเป็นจริง
- **Responsive UI:** รองรับหน้าจอทุกขนาดโดยไม่ overflow

#### **📁 ไฟล์ใหม่ที่สร้าง:**
- `lib/screen/developer_settings.dart` - หน้าจัดการ Soft Delete
- `lib/widgets/status_test_widget.dart` - Widget ทดสอบระบบ status update
- `VISITOR_MANAGEMENT_UPDATE.md` - เอกสารสรุปการอัปเดต
- `STATUS_UPDATE_FIX.md` - เอกสารสรุปการแก้ไขสถานะ

---

## 🎯 **งานที่เหลือ (Remaining Tasks) - เรียงตาม Priority**

### **🔥 Priority 1 - Critical (ต้องทำก่อน Production)**

#### **1. Equipment Loan/Return System Enhancement**
- **สถานะปัจจุบัน:** ใช้ `reg_additional_info` table (บันทึกแค่จำนวนที่เบิก)
- **ที่ต้องทำ:**
  - สร้าง `equipment_loans` table ตาม spec (IN/OUT tracking)
  - ระบบ check-in/check-out อุปกรณ์
  - ตรวจสอบอุปกรณ์คงเหลือ (inventory)
  - รายงานอุปกรณ์ที่ยังไม่คืน
- **ประมาณเวลา:** 2-3 sessions

#### **2. Room/Accommodation Booking System**  
- **สถานะปัจจุบัน:** มีเพียง location field ใน `reg_additional_info`
- **ที่ต้องทำ:**
  - ระบบจองห้อง/ศาลา/กุฏิ
  - ตรวจสอบว่างของห้อง
  - Calendar view สำหรับดูการจอง
  - จัดการ overbooking
- **ประมาณเวลา:** 3-4 sessions

#### **3. Advanced Reporting System**
- **สถานะปัจจุบัน:** มีแค่ daily summary พื้นฐาน
- **ที่ต้องทำ:**
  - Dashboard แสดงสถิติ real-time
  - Export รายงาน PDF/Excel
  - กราฟแสดงแนวโน้ม (จำนวนคนเข้าพัก, อุปกรณ์ที่ใช้)
  - รายงานรายเดือน/รายปี
- **ประมาณเวลา:** 2-3 sessions

### **🔶 Priority 2 - Important (Performance & UX)**

#### **4. Data Backup & Sync System**
- **สถานะปัจจุบัน:** ไม่มีระบบ backup
- **ที่ต้องทำ:**
  - Auto backup ประจำวัน
  - Export/Import database
  - Cloud sync (Google Drive/Dropbox)
  - Recovery system
- **ประมาณเวลา:** 2 sessions

#### **5. Activity Schedule Management**
- **สถานะปัจจุบัน:** เมนูมีแต่ยังไม่ได้ implement
- **ที่ต้องทำ:**
  - ระบบจัดการตารางกิจกรรมรายวัน
  - Calendar view
  - แจ้งเตือนกิจกรรม
  - Integration กับข้อมูลผู้เข้าพัก
- **ประมาณเวลา:** 2-3 sessions

#### **6. Enhanced Search & Filter System**
- **สถานะปัจจุบัน:** ค้นหาพื้นฐานใน visitor management
- **ที่ต้องทำ:**
  - Advanced search (ชื่อ, ที่อยู่, หมายเหตุ)
  - Date range filtering
  - Multi-criteria search
  - Search history
- **ประมาณเวลา:** 1-2 sessions

### **🔷 Priority 3 - Nice to Have (Enhancement)**

#### **7. User Management & Permissions**
- **สถานะปัจจุบัน:** ไม่มีระบบ user login
- **ที่ต้องทำ:**
  - Multi-user support
  - Role-based access control
  - Admin/Staff/Viewer permissions
  - Activity logging
- **ประมาณเวลา:** 3-4 sessions

#### **8. Mobile App Optimization**
- **สถานะปัจจุบัน:** ทำงานบน mobile แต่ยังไม่ optimize
- **ที่ต้องทำ:**
  - Touch-friendly interface
  - Offline mode
  - Mobile-specific layouts
  - Push notifications
- **ประมาณเวลา:** 2-3 sessions

#### **9. Internationalization (i18n)**
- **สถานะปัจจุบัน:** Thai only
- **ที่ต้องทำ:**
  - English localization
  - Language switcher
  - RTL support (อนาคต)
- **ประมาณเวลา:** 1-2 sessions

#### **10. Performance Optimization**
- **สถานะปัจจุบัน:** ทำงานได้ดีกับข้อมูลน้อย
- **ที่ต้องทำ:**
  - Database indexing optimization
  - Lazy loading
  - Image caching
  - Memory management
- **ประมาณเวลา:** 1-2 sessions

---

## 📊 **Project Completion Status**

### **✅ สิ่งที่เสร็จแล้ว (85%)**
- ✅ Basic Registration System (Manual + ID Card)
- ✅ Database Schema & Models
- ✅ Visitor Management (CRUD + Search + Filter)
- ✅ History Tracking with Status Auto-Update
- ✅ Soft Delete with Recovery System
- ✅ White Robe Distribution (QR Scanner)
- ✅ Basic Equipment Management
- ✅ Receipt Printing with Stay Information
- ✅ Thai Buddhist Calendar
- ✅ Address Management (Province/District/Sub-district)
- ✅ Admin Settings & Developer Tools
- ✅ Responsive UI Design

### **🔄 กำลังดำเนินการ (0%)**
- ไม่มี (ทุก task ที่เริ่มแล้วเสร็จหมดแล้ว)

### **📋 ยังไม่เริ่ม (15%)**
- ❌ Equipment Loan/Return System (IN/OUT tracking)
- ❌ Room Booking System
- ❌ Advanced Reporting & Dashboard
- ❌ Data Backup & Sync
- ❌ Activity Schedule Management
- ❌ Enhanced Search System
- ❌ User Management
- ❌ Mobile Optimization
- ❌ Internationalization
- ❌ Performance Optimization

---

## 🎯 **แนะนำลำดับการทำงานต่อไป**

### **Phase 1 (สำคัญสุด - 4-6 sessions)**
1. Equipment Loan/Return System → จำเป็นสำหรับการจัดการอุปกรณ์ที่แท้จริง
2. Room Booking System → ระบบหลักที่ขาดหายไป
3. Advanced Reporting → ต้องการสำหรับการบริหารจัดการ

### **Phase 2 (สำคัญรอง - 3-4 sessions)**  
4. Data Backup & Sync → ความปลอดภัยของข้อมูล
5. Activity Schedule → เพิ่มความสมบูรณ์ของระบบ
6. Enhanced Search → ปรับปรุง UX

### **Phase 3 (พัฒนาต่อยอด - 6-8 sessions)**
7. User Management → สำหรับการใช้งานจริงในองค์กร
8. Mobile Optimization → เพื่อการใช้งานที่สะดวกขึ้น
9. Internationalization → เพื่อผู้ใช้ต่างชาติ
10. Performance Optimization → เมื่อมีข้อมูลเยอะขึ้น

---

## 🎯 **Expected Production Readiness**
- **Current Status:** 85% (Ready for pilot/testing)
- **Production Ready:** 95% (หลัง Phase 1 completion)
- **Enterprise Ready:** 100% (หลัง Phase 2-3 completion)

*อัพเดตล่าสุด: 24 กรกฎาคม 2568*
