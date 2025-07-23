# 🎯 คู่มือการใช้งาน Prompt สำหรับโปรเจ็กต์ บ้านเพชรบำเพ็ญ

## 📚 การเริ่มต้นใช้งาน

**🔥 Prompt เริ่มต้น (แนะนำให้ใช้ทุกครั้ง):**
```
อ่านและโหลด Context จาก folder house/ ทั้งหมด เพื่อทำความเข้าใจโปรเจ็กต์นี้ 

แล้วเตรียมพร้อมทำงานตามโปรเจ็กต์ระบบลงทะเบียนสถานปฏิบัติธรรม

รวมถึง project scope, progress status, และ role definitions

จากนั้นช่วยทำงานต่อตาม house/tasks/2025-07-20.md Priority 1 ให้หน่อย

รู้จักทีมงานไหม? เรียก Dev-san, Design-san , TestBot และ Wisdom Busy มาทำความรู้จักกัน
```

หลังจากนั้นจึงสั่งงานเฉพาะด้านต่อไป

---

## 📋 ภาพรวมระบบ Prompt

โปรเจ็กต์นี้ใช้ระบบ **Role-Based AI Assistant** ที่มี 4 ตัวละครหลัก แต่ละตัวมีความเชี่ยวชาญเฉพาะด้าน:

- 🧘‍♂️ **Wisdom Busy** - Product Owner (Business Logic & Strategy)
- 👨‍💻 **Dev-san** - Flutter Developer (Technical Implementation)  
- 🧪 **TestBot** - QA Tester (Quality Assurance)
- 🎨 **Design-san** - UI/UX Designer (User Experience)

---

## 🎯 วิธีการเรียกใช้แต่ละ Role

### 1. 🧘‍♂️ Wisdom Busy (Product Owner)

**เมื่อไหร่ใช้:** ตัดสินใจธุรกิจ, จัดลำดับความสำคัญ, กำหนดทิศทาง

**Trigger Commands:**
```
ปรึกษา Wisdom Busy
ขอความเห็น PO  
จัดลำดับ Priority
ควรตัด scope ไหม
วาง Roadmap
ทิศทางโปรเจ็กต์
ช่วยตัดสินใจ
Trade-off time vs quality
```

**ตัวอย่างการใช้:**
```
โปรดอ่านไฟล์ใน house/ แล้วปรึกษา Wisdom Busy: 
ผู้ใช้บอกว่า SmartCard Reader ใช้ยาก 
ควรเปลี่ยนเป็น Manual form อย่างเดียวหรือไม่?
```

---

### 2. 👨‍💻 Dev-san (Flutter Developer)

**เมื่อไหร่ใช้:** เขียนโค้ด, แก้บั๊ก, ปรับปรุงฟีเจอร์

**Trigger Commands:**
```
เรียก Flutter Dev
ขอ Dev-san ช่วย
สร้าง Widget/Screen/Service
ปรับปรุงโค้ด
Refactor
แก้บั๊ก
Debug
เพิ่มฟีเจอร์
Implement feature
```

**ตัวอย่างการใช้:**
```
อ่านไฟล์ใน house/ แล้วเรียก Flutter Dev: 
สร้าง Widget สำหรับแสดงสถิติผู้เข้าพักรายวัน 
แบบ Card พร้อม Chart แยกตามเพศ
```

---

### 3. 🧪 TestBot (QA Tester)

**เมื่อไหร่ใช้:** ทดสอบฟีเจอร์, หา Bug, เขียน Test Cases

**Trigger Commands:**
```
เรียก Tester Bot
ให้ TestBot ช่วย
ทดสอบฟีเจอร์
Test this feature
หา Test Cases
เขียน Test Scenarios
ตรวจสอบ Edge Cases
ทำ UAT
User Acceptance Testing
```

**ตัวอย่างการใช้:**
```
อ่าน house/ แล้วเรียก Tester Bot: 
ทดสอบฟีเจอร์ลงทะเบียน Manual Form
หา Edge Cases ที่อาจเกิดข้อผิดพลาด
```

---

### 4. 🎨 Design-san (UI/UX Designer)

**เมื่อไหร่ใช้:** ออกแบบ UI, ปรับปรุง UX, สร้าง Design System

**Trigger Commands:**
```
เรียก UI Designer  
ขอ Design-san ช่วย
ออกแบบ UI
Design layout
ปรับปรุง UX
Improve user experience
ดู Design System
ตรวจ Component
ทำ Prototype
Wireframe
```

**ตัวอย่างการใช้:**
```
อ่าน house/ แล้วเรียก UI Designer: 
ออกแบบหน้า Dashboard สำหรับผู้ใช้วัยผู้ใหญ่
ให้เห็นสถิติการเข้าพักแบบเข้าใจง่าย
```

---

## 🎯 Prompt Patterns ที่แนะนำ

### Pattern 1: การพัฒนาฟีเจอร์ใหม่ (Complete Feature)
```
1. อ่าน house/ แล้วปรึกษา Wisdom Busy: [Feature นี้ควรทำไหม? Priority อย่างไร?]
2. เรียก UI Designer: [ออกแบบ UI สำหรับ Feature นี้]  
3. เรียก Flutter Dev: [Implement Feature ตาม Design]
4. เรียก Tester Bot: [ทดสอบ Feature ให้ครบถ้วน]
```

### Pattern 2: การแก้ไขปัญหา (Problem Solving)
```
1. อ่าน house/ แล้วเรียก Tester Bot: [ระบุปัญหาและ Reproduce Steps]
2. เรียก Flutter Dev: [วิเคราะห์และแก้ไขปัญหา]
3. เรียก Tester Bot: [ทดสอบ Regression ให้แน่ใจ]
```

### Pattern 3: การปรับปรุง UX (UX Improvement)
```
1. อ่าน house/ แล้วเรียก UI Designer: [วิเคราะห์ปัญหา UX ปัจจุบัน]
2. ปรึกษา Wisdom Busy: [ประเมิน Impact vs Effort]
3. เรียก Flutter Dev: [Implement การปรับปรุง]
```

### Pattern 4: การต่อยอดโปรเจ็กต์ (Project Continuation)
```
1. อ่าน house/dashboard.md และ house/tasks/ แล้วบอกสถานะล่าสุด
2. ปรึกษา Wisdom Busy: [กำหนด Priority ต่อไป]
3. [เลือก Role ที่เหมาะสม]: [ดำเนินการงานตาม Priority]
```

---

## 📁 การอ้างอิง Documentation

เมื่อ AI ตอบ จะอ่านไฟล์เหล่านี้อัตโนมัติ:

### 📊 Core Documentation
- **`house/project.md`** - Project scope และ requirements  
- **`house/dashboard.md`** - Progress tracking และ status
- **`house/retrospectives.md`** - Project insights และ lessons learned

### 📅 Task History  
- **`house/tasks/2025-01-20.md`** - Manual Form development และ testing
- **`house/tasks/2025-07-20.md`** - Daily Summary Dashboard implementation

### 🎭 Role Definitions
- **`house/roles/flutter_dev.md`** - Dev-san character และ expertise
- **`house/roles/tester_bot.md`** - TestBot character และ testing approach  
- **`house/roles/ui_designer.md`** - Design-san character และ UX principles
- **`house/roles/wisdom_busy.md`** - Wisdom Busy character และ business focus

### 📋 Technical Specifications
- **`house/spec/db_schema.md`** - Database design และ relationships
- **`house/spec/registration_flow.md`** - User workflows และ business logic
- **`house/spec/screens_flow.md`** - Screen navigation และ UI flow

---

## 🎯 ตัวอย่าง Prompt ที่ดี

### ✅ Good Examples:

```
อ่าน house/ แล้วเรียก Flutter Dev: 
เพิ่มฟีเจอร์ Export ข้อมูลเป็น PDF ในหน้า Daily Summary 
พร้อมกราฟและตาราง ตาม existing design pattern
```

```
อ่าน house/ แล้วปรึกษา Wisdom Busy: 
User บอกว่าปุ่ม +/- Equipment เล็กไปสำหรับผู้สูงอายุ 
ควรปรับอย่างไร? มี impact กับ existing users ไหม?
```

```
อ่าน house/ แล้วเรียก Tester Bot: 
ทดสอบการลงทะเบียนคนมีบัตรประชาชน
กรณี Reader disconnected ระหว่างอ่าน
```

```
อ่าน house/dashboard.md แล้วบอกสถานะโปรเจ็กต์ปัจจุบัน
และแนะนำ task ต่อไปที่ควรทำ priority สูงสุด
```

### ❌ Poor Examples:

```
ช่วยทำอะไรสักอย่าง  // ไม่ชัดเจน
แก้บั๊ก  // ไม่บอกว่าบั๊กอะไร  
ออกแบบหน้าใหม่  // ไม่บอกรายละเอียด
ทำต่อจากเมื่อวาน  // ไม่ได้อ่าน house/ ก่อน
```

---

## 📊 Project Status ปัจจุบัน (97% Complete)

### ✅ Completed Features
- **Manual Registration Form** - Production ready with Thai ID validation
- **Database Architecture** - SQLite with v5 schema (regs, reg_additional_info, stays, app_settings)
- **Thai Address System** - จังหวัด/อำเภอ/ตำบล dropdown integration
- **Buddhist Calendar** - Thai localization with Buddhist era support
- **Admin System & Secret Developer Mode** - Complete menu management และ developer tools
- **Daily Summary Dashboard** - Comprehensive analytics with multi-period selection
- **Menu Management System** - Dynamic visibility control via SQLite settings

### 🔄 In Progress (2%)
- **SmartCard Reader Integration** - Research phase
- **Printer Service** - Basic implementation complete

### 📋 Planned (1%)  
- **User Data Management** - จัดการข้อมูลผู้ปฏิบัติธรรม
- **Terms & Conditions Integration** - Legal compliance framework
- **TestBot Comprehensive Testing** - Complete test coverage validation
- **Developer Settings Completion** - Full admin functionality

---

## 🎯 Workflow แนะนำ

### สำหรับ New Features:
1. **อ่าน house/ ก่อน** → เข้าใจ context และ existing architecture
2. **Wisdom Busy** → กำหนด Priority และ Scope
3. **Design-san** → ออกแบบ UI/UX  
4. **Dev-san** → Implement โค้ด
5. **TestBot** → ทดสอบครบถ้วน

### สำหรับ Bug Fixes:
1. **อ่าน house/ ก่อน** → เข้าใจ existing implementation
2. **TestBot** → Reproduce และระบุปัญหา
3. **Dev-san** → แก้ไขปัญหา  
4. **TestBot** → Regression testing

### สำหรับ Project Continuation:
1. **อ่าน house/dashboard.md** → ดู overall progress
2. **อ่าน house/tasks/latest** → ดู recent implementations
3. **Wisdom Busy** → กำหนด next priorities
4. **[Appropriate Role]** → Execute tasks

### สำหรับ UX Improvements:
1. **อ่าน house/ ก่อน** → เข้าใจ current UX decisions
2. **Design-san** → วิเคราะห์และเสนอแนะ
3. **Wisdom Busy** → ประเมินความคุ้มค่า
4. **Dev-san** → Implement การปรับปรุง

---

## 📚 Quick Reference Commands

### Project Status
```
อ่าน house/dashboard.md แล้วสรุปสถานะโปรเจ็กต์
อ่าน house/tasks/ แล้วบอก recent achievements
อ่าน house/ แล้วแนะนำ next steps ที่ควรทำ
```

### Technical Deep Dive  
```
อ่าน house/spec/ แล้วอธิบาย database architecture
อ่าน house/ แล้วอธิบาย registration workflow
อ่าน lib/ และ house/ แล้ววิเคราะห์ code quality
```

### Role-Specific Tasks
```
อ่าน house/ แล้วเรียก [Role]: [Specific Task]
อ่าน house/roles/ แล้วอธิบาย capabilities ของแต่ละ role
```

---

## 🎉 Tips การใช้งานอย่างมีประสิทธิภาพ

### 🔥 Essential Tips
1. **เริ่มด้วย house/ เสมอ:** ใช้ prompt เริ่มต้นทุกครั้ง
2. **ระบุบริบท:** บอกสถานการณ์และเป้าหมายชัดเจน
3. **ใช้ Role ที่เหมาะสม:** Developer สำหรับโค้ด, PO สำหรับธุรกิจ  
4. **ถามทีละ Role:** อย่าผสมคำถามหลาย Role ในครั้งเดียว
5. **อ้างอิง Existing Code:** ระบุไฟล์หรือฟีเจอร์ที่เกี่ยวข้อง

### 📈 Advanced Usage
6. **Follow Project Patterns:** ใช้ established patterns ในโปรเจ็กต์
7. **Reference Task History:** อ้างอิง house/tasks/ สำหรับ context
8. **Understand Current Status:** อ่าน dashboard.md เพื่อเข้าใจ progress
9. **Respect Architecture:** ทำงานภายใต้ existing architecture
10. **Document Changes:** เสนอให้อัพเดต house/ เมื่อมีการเปลี่ยนแปลงใหญ่

---

## 🚀 Ready to Start!

**ระบบนี้พร้อมใช้งานแล้ว** - เริ่มต้นด้วย prompt เริ่มต้นแล้วสั่งงานได้เลย!

### Template เริ่มต้น:
```
โปรดอ่านไฟล์ทั้งหมดใน folder house/ เพื่อทำความเข้าใจโปรเจ็กต์นี้ 
รวมถึง project scope, progress status, และ role definitions

จากนั้น[งานที่ต้องการ เช่น:]
- ปรึกษา Wisdom Busy: [คำถามเชิงธุรกิจ]
- เรียก Flutter Dev: [งานพัฒนาโค้ด]  
- เรียก Tester Bot: [งานทดสอบ]
- เรียก UI Designer: [งานออกแบบ]
```

---

*📝 คู่มือนี้ใช้สำหรับโปรเจ็กต์ บ้านเพชรบำเพ็ญ - ระบบลงทะเบียนสถานปฏิบัติธรรม*  
*🔄 อัพเดตล่าสุด: 20 กรกฎาคม 2025*