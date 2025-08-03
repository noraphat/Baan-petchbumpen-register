# 🗄️ ฐานข้อมูลระบบลงทะเบียนสถานปฏิบัติธรรม บ้านเพชรบำเพ็ญ

*Database Schema Overview - Version 8*

---

## 📋 **สรุปภาพรวม**
- **Database:** SQLite (`dhamma_reg.db`)
- **Version:** 8 (ปัจจุบัน)
- **Platform:** Flutter + sqflite package
- **Total Tables:** 7 ตาราง
- **Pattern:** Singleton DbHelper

---

## 🏗️ **โครงสร้างฐานข้อมูล**

### **1. 👤 ตาราง `regs` - ข้อมูลผู้ลงทะเบียนหลัก**
```sql
CREATE TABLE regs (
  id TEXT PRIMARY KEY,          -- เลขบัตรประชาชน/เบอร์โทร
  first TEXT,                   -- ชื่อจริง
  last TEXT,                    -- นามสกุล
  dob TEXT,                     -- วันเกิด (Buddhist calendar format)
  phone TEXT,                   -- เบอร์โทรศัพท์
  addr TEXT,                    -- ที่อยู่เต็ม
  gender TEXT,                  -- เพศ (พระ/สามเณร/แม่ชี/ชาย/หญิง/อื่นๆ)
  hasIdCard INTEGER,            -- มีบัตรประชาชน (1=มี, 0=ไม่มี)
  status TEXT DEFAULT 'A',      -- สถานะ (A=Active, I=Inactive - soft delete)
  createdAt TEXT,               -- วันที่สร้างข้อมูล
  updatedAt TEXT                -- วันที่แก้ไขล่าสุด
)
```
**การใช้งาน:**
- เก็บข้อมูลพื้นฐานของผู้เข้าพัก
- รองรับทั้งการลงทะเบียนด้วยบัตรประชาชนและแบบ manual
- ใช้ soft delete (status='I') แทนการลบจริง
- สามารถค้นหาด้วย id, phone, ชื่อ-นามสกุล

### **2. 📦 ตาราง `reg_additional_info` - ข้อมูลการพักและอุปกรณ์**
```sql
CREATE TABLE reg_additional_info (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  regId TEXT NOT NULL,          -- FK → regs.id
  visitId TEXT NOT NULL,        -- รหัสการมาครั้งนี้ (UUID)
  startDate TEXT,               -- วันที่เริ่มพัก
  endDate TEXT,                 -- วันที่สิ้นสุดการพัก
  shirtCount INTEGER DEFAULT 0, -- จำนวนเสื้อขาว
  pantsCount INTEGER DEFAULT 0, -- จำนวนกางเกงขาว
  matCount INTEGER DEFAULT 0,   -- จำนวนเสื่อ
  pillowCount INTEGER DEFAULT 0,-- จำนวนหมอน
  blanketCount INTEGER DEFAULT 0,-- จำนวนผ้าห่ม
  location TEXT,                -- ตำแหน่งที่พัก (ห้อง/ศาลา)
  withChildren INTEGER DEFAULT 0,-- มาพร้อมเด็ก (1=มี, 0=ไม่มี)
  childrenCount INTEGER DEFAULT 0,-- จำนวนเด็ก
  notes TEXT,                   -- หมายเหตุพิเศษ
  createdAt TEXT,
  updatedAt TEXT,
  FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE,
  UNIQUE(regId, visitId)        -- ป้องกันการซ้ำซ้อน
)
```
**การใช้งาน:**
- เก็บข้อมูลการพักแต่ละครั้ง (คนเดียวมาได้หลายครั้ง)
- จัดการอุปกรณ์ที่เบิก (เสื้อ, กางเกง, เสื่อ, หมอน, ผ้าห่ม)
- รองรับการมาพร้อมเด็ก
- visitId ทำให้ติดตามแต่ละครั้งได้แยกกัน

### **3. 🏠 ตาราง `stays` - การพำนัก**
```sql
CREATE TABLE stays (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  visitor_id TEXT NOT NULL,     -- FK → regs.id
  start_date TEXT NOT NULL,     -- วันที่เริ่มพัก
  end_date TEXT NOT NULL,       -- วันที่สิ้นสุด
  status TEXT DEFAULT 'active', -- สถานะ (active/extended/completed)
  note TEXT,                    -- หมายเหตุ
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
)
```
**การใช้งาน:**
- ติดตามช่วงเวลาการพักของแต่ละคน
- รองรับการต่อวันพัก (status='extended')
- ใช้สำหรับสร้างรายงานและสถิติ

### **4. ⚙️ ตาราง `app_settings` - การตั้งค่าระบบ**
```sql
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,         -- ชื่อการตั้งค่า
  value TEXT NOT NULL,          -- ค่าที่ตั้ง
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```
**การใช้งาน:**
- เก็บการตั้งค่าแอป (เปิด/ปิดเมนู, ธีม, ภาษา)
- รองรับ Developer Mode settings
- Auto backup settings

### **5. 🗺️ ตาราง `maps` - ข้อมูลแผนที่**
```sql
CREATE TABLE maps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,           -- ชื่อแผนที่
  image_path TEXT,              -- path ของไฟล์รูปแผนที่
  image_width REAL,             -- ความกว้างรูป
  image_height REAL,            -- ความสูงรูป
  is_active INTEGER DEFAULT 0,  -- แผนที่ที่ใช้งานปัจจุบัน
  description TEXT,             -- คำอธิบาย
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```
**การใช้งาน:**
- จัดการรูปแผนที่ของสถานที่
- รองรับแผนที่หลายชั้น/หลายพื้นที่
- ใช้ร่วมกับ Interactive Map Widget

### **6. 🏨 ตาราง `rooms` - ข้อมูลห้องพัก**
```sql
CREATE TABLE rooms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,           -- ชื่อห้อง/ศาลา
  size TEXT NOT NULL,           -- ขนาดห้อง (small/medium/large)
  capacity INTEGER NOT NULL,    -- จำนวนคนที่รองรับได้
  position_x REAL,              -- ตำแหน่ง X บนแผนที่
  position_y REAL,              -- ตำแหน่ง Y บนแผนที่
  status TEXT DEFAULT 'available', -- สถานะ (available/reserved/occupied)
  description TEXT,             -- รายละเอียดห้อง
  current_occupant TEXT,        -- ผู้พักปัจจุบัน (FK → regs.id)
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (current_occupant) REFERENCES regs (id) ON DELETE SET NULL
)
```
**การใช้งาน:**
- จัดการข้อมูลห้องพัก/ศาลา/กุฏิ
- แสดงตำแหน่งบนแผนที่ (Interactive Map)
- ติดตามสถานะว่าง/จอง/มีคนพัก

### **7. 📅 ตาราง `room_bookings` - การจองห้องพัก**
```sql
CREATE TABLE room_bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id INTEGER NOT NULL,     -- FK → rooms.id
  visitor_id TEXT NOT NULL,     -- FK → regs.id
  check_in_date TEXT NOT NULL,  -- วันที่เข้าพัก
  check_out_date TEXT NOT NULL, -- วันที่ออกจากห้อง
  status TEXT DEFAULT 'pending',-- สถานะ (pending/confirmed/cancelled/completed)
  note TEXT,                    -- หมายเหตุการจอง
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (room_id) REFERENCES rooms (id) ON DELETE CASCADE,
  FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
)
```
**การใช้งาน:**
- ระบบจองห้องพักล่วงหน้า
- ตรวจสอบ availability real-time
- จัดการการยกเลิก/เปลี่ยนแปลงการจอง

---

## 🔍 **Database Indexes สำหรับ Performance**

```sql
-- Stays table indexes
CREATE INDEX idx_stays_visitor_id ON stays(visitor_id);
CREATE INDEX idx_stays_date_range ON stays(start_date, end_date);

-- Rooms table indexes  
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_position ON rooms(position_x, position_y);

-- Room bookings indexes
CREATE INDEX idx_room_bookings_room_id ON room_bookings(room_id);
CREATE INDEX idx_room_bookings_visitor_id ON room_bookings(visitor_id);
CREATE INDEX idx_room_bookings_dates ON room_bookings(check_in_date, check_out_date);
```

---

## 🔄 **Model Classes และความสัมพันธ์**

### **Primary Models:**
1. **`RegData`** - Main visitor model
2. **`RegAdditionalInfo`** - Visit details + equipment
3. **`StayRecord`** - Stay duration tracking
4. **`Room`** - Room management
5. **`MapData`** - Interactive map
6. **`RoomBooking`** - Booking system

### **Relationships:**
```
regs (1) ──→ (M) reg_additional_info
regs (1) ──→ (M) stays  
regs (1) ──→ (M) room_bookings
rooms (1) ──→ (M) room_bookings
maps (1) ──→ (M) rooms (position reference)
```

---

## 📊 **การใช้งานจริง**

### **Registration Flow:**
1. `regs` ← บันทึกข้อมูลพื้นฐาน
2. `reg_additional_info` ← บันทึกอุปกรณ์ + visitId
3. `stays` ← บันทึกช่วงเวลาพัก
4. `room_bookings` ← จองห้อง (ถ้ามี)

### **Equipment Management:**
- ปัจจุบัน: บันทึกจำนวนใน `reg_additional_info`
- **จะต้องเพิ่ม:** `equipment_loans` table สำหรับ IN/OUT tracking

### **Room Management:**
- `rooms` + `room_bookings` สำหรับระบบจอง
- Integration กับ Interactive Map Widget
- Real-time availability checking

---

## 🎯 **ฐานข้อมูลที่ยังต้องเพิ่ม (Priority Tasks)**

### **1. `equipment_loans` - ระบบเบิก-คืนอุปกรณ์**
```sql
CREATE TABLE equipment_loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  visitor_id TEXT NOT NULL,
  equipment_type TEXT NOT NULL,    -- shirt/pants/mat/pillow/blanket
  quantity INTEGER NOT NULL,
  loan_date TEXT NOT NULL,
  return_date TEXT,               -- NULL = ยังไม่คืน
  status TEXT DEFAULT 'borrowed', -- borrowed/returned/lost
  notes TEXT,
  FOREIGN KEY (visitor_id) REFERENCES regs (id) ON DELETE CASCADE
)
```

### **2. `activities` - ตารางกิจกรรม**
```sql
CREATE TABLE activities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  location TEXT,
  max_participants INTEGER,
  status TEXT DEFAULT 'active'
)
```

### **3. `equipment_inventory` - สต็อกอุปกรณ์**
```sql
CREATE TABLE equipment_inventory (
  equipment_type TEXT PRIMARY KEY,
  total_quantity INTEGER NOT NULL,
  available_quantity INTEGER NOT NULL,
  minimum_threshold INTEGER DEFAULT 5,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```

---

## 🔧 **Technical Details**

### **Database Connection:**
- **File:** `lib/services/db_helper.dart`
- **Pattern:** Singleton
- **Version Control:** Automatic migration
- **Testing:** `test/services/db_helper_test.dart`

### **Key Features:**
- ✅ ACID Transactions
- ✅ Foreign Key Constraints
- ✅ Soft Delete Support
- ✅ Automatic Timestamps
- ✅ Data Validation
- ✅ Migration System
- ✅ Index Optimization

### **Current Version:** 8
**Migration Path:** v1 → v2 → v3 → v4 → v5 → v6 → v7 → v8

---

*สร้างเมื่อ: 31 กรกฎาคม 2568*  
*อัพเดตล่าสุด: Database Version 8*