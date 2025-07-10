# 🏠 บ้านเพชรบำเพ็ญ - ระบบลงทะเบียน

แอปพลิเคชัน Flutter สำหรับระบบจัดการข้อมูลและลงทะเบียนผู้เข้าร่วมกิจกรรมที่บ้านเพชรบำเพ็ญ

## 📱 ฟีเจอร์หลัก

- [x] **ลงทะเบียนผู้เข้าร่วม**
  - กรอกข้อมูลด้วยตนเอง (รวมข้อมูลเพิ่มเติม: วันที่, อุปกรณ์, ที่พัก, หมายเหตุ)
  - อ่านข้อมูลจากบัตรประชาชน (ข้อมูลจากบัตรแก้ไขไม่ได้)
- [x] **เบิกชุดขาว** - สแกน QR Code
- [ ] **จองที่พัก** - (อยู่ระหว่างพัฒนา)
- [ ] **ตารางกิจกรรม** - (อยู่ระหว่างพัฒนา)
- [ ] **สรุปผลประจำวัน** - (อยู่ระหว่างพัฒนา)

### 🔄 การแก้ไขข้อมูล
- **คนมีบัตรประชาชน**: แก้ไขได้เฉพาะเบอร์โทรและข้อมูลเพิ่มเติม
- **คนไม่มีบัตรประชาชน**: แก้ไขข้อมูลได้ทุกอย่าง

## 🛠️ การติดตั้ง

### ความต้องการของระบบ
- Flutter SDK ^3.8.1
- Dart SDK ^3.8.1
- Android Studio / VS Code

### ขั้นตอนการติดตั้ง

1. **Clone โปรเจค**
```bash
git clone https://github.com/noraphat/Baan-petchbumpen-register.git
cd Baan-petchbumpen-register
```

2. **ติดตั้ง Dependencies**
```bash
flutter pub get
```

3. **รันแอป**
```bash
flutter run
```

## 📦 Dependencies หลัก

- `sqflite` - ฐานข้อมูล SQLite
- `image_picker` - เลือกรูปภาพ
- `mobile_scanner` - สแกน QR Code
- `thai_idcard_reader_flutter` - อ่านบัตรประชาชน
- `sunmi_printer_plus` - พิมพ์ข้อมูล
- `intl` - จัดการภาษาและวันที่

## 🏗️ โครงสร้างโปรเจค

```
lib/
├── main.dart                 # จุดเริ่มต้นแอป
├── models/
│   └── reg_data.dart        # โครงสร้างข้อมูลการลงทะเบียนและข้อมูลเพิ่มเติม
├── screen/
│   ├── home_screen.dart     # หน้าหลัก
│   ├── white_robe_scaner.dart # สแกนชุดขาว
│   └── registration/
│       ├── registration_menu.dart # เมนูลงทะเบียน
│       ├── manual_form.dart      # ฟอร์มกรอกเอง (รวมข้อมูลเพิ่มเติม)
│       └── capture_form.dart     # ฟอร์มถ่ายรูปบัตร
├── services/
│   ├── db_helper.dart       # จัดการฐานข้อมูล SQLite (2 ตาราง)
│   ├── address_service.dart # จัดการที่อยู่
│   └── printer_service.dart # พิมพ์ข้อมูล
└── widgets/
    ├── menu_card.dart       # การ์ดเมนู
    └── buddhist_calendar_picker.dart # ปฏิทินพุทธศักราช
```

## 📊 ฐานข้อมูล

### ตาราง `regs` (ข้อมูลหลัก)
- `id` - เลขบัตรประชาชน/เบอร์โทร (Primary Key)
- `first` - ชื่อ
- `last` - นามสกุล
- `dob` - วันเกิด (รูปแบบ: dd MMMM yyyy พ.ศ.)
- `phone` - เบอร์โทร
- `addr` - ที่อยู่ (จังหวัด, อำเภอ, ตำบล, ที่อยู่เพิ่มเติม)
- `gender` - เพศ (พระ, สามเณร, แม่ชี, ชาย, หญิง, อื่นๆ)
- `hasIdCard` - มีบัตรประชาชนหรือไม่ (0/1)
- `createdAt` - วันที่สร้างข้อมูล
- `updatedAt` - วันที่แก้ไขล่าสุด

### ตาราง `reg_additional_info` (ข้อมูลเพิ่มเติม)
- `regId` - เลขบัตรประชาชน/เบอร์โทร (Foreign Key เชื่อมกับ regs)
- `startDate` - วันที่เริ่มต้นกิจกรรม
- `endDate` - วันที่สิ้นสุดกิจกรรม
- `shirtCount` - จำนวนเสื้อขาว
- `pantsCount` - จำนวนกางเกงขาว
- `matCount` - จำนวนเสื่อ
- `pillowCount` - จำนวนหมอน
- `blanketCount` - จำนวนผ้าห่ม
- `location` - ห้อง/ศาลา/สถานที่พัก
- `withChildren` - มากับเด็ก (0/1)
- `childrenCount` - จำนวนเด็ก
- `notes` - หมายเหตุ (โรคประจำตัว, ไม่ทานเนื้อสัตว์ ฯลฯ)
- `createdAt` - วันที่สร้างข้อมูล
- `updatedAt` - วันที่แก้ไขล่าสุด

## 🎨 ธีมและ UI

- ใช้ Material 3 Design
- สีหลัก: Teal (เขียวน้ำเงิน)
- รองรับภาษาไทยและอังกฤษ
- ปฏิทินแบบพุทธศักราช

## 📁 ข้อมูลที่อยู่

ไฟล์ JSON สำหรับข้อมูลที่อยู่ของไทย:
- `assets/addresses/thai_provinces.json`
- `assets/addresses/thai_amphures.json`
- `assets/addresses/thai_tambons.json`
- `assets/addresses/thai_geographies.json`

## 🚀 การ Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📝 TODO

- [ ] เพิ่มฟีเจอร์จองที่พัก
- [ ] เพิ่มฟีเจอร์ตารางกิจกรรม
- [ ] เพิ่มฟีเจอร์สรุปผลประจำวัน
- [ ] เพิ่มระบบ Authentication
- [ ] เพิ่มการ Backup ข้อมูล
- [ ] ปรับปรุง UI/UX

## 🤝 การมีส่วนร่วม

1. Fork โปรเจค
2. สร้าง Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit การเปลี่ยนแปลง (`git commit -m 'Add some AmazingFeature'`)
4. Push ไปยัง Branch (`git push origin feature/AmazingFeature`)
5. เปิด Pull Request

## 📄 License

โปรเจคนี้เป็นส่วนหนึ่งของบ้านเพชรบำเพ็ญ

## 📞 ติดต่อ

สำหรับคำถามหรือข้อเสนอแนะ กรุณาติดต่อทีมพัฒนา

---

**หมายเหตุ**: โปรเจคนี้อยู่ระหว่างการพัฒนา ฟีเจอร์บางส่วนอาจยังไม่สมบูรณ์
