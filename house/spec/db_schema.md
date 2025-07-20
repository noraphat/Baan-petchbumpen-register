# Database Schema

## ตาราง visitors (ข้อมูลผู้มาปฏิบัติธรรม)
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- id_card (TEXT UNIQUE) - เลขบัตরประชาชน
- full_name (TEXT NOT NULL) - ชื่อ-นามสกุล
- phone (TEXT) - เบอร์โทรศัพท์
- address (TEXT) - ที่อยู่
- date_of_birth (TEXT) - วันเกิด
- created_at (TEXT DEFAULT CURRENT_TIMESTAMP)
- updated_at (TEXT DEFAULT CURRENT_TIMESTAMP)

## ตาราง stays (การพำนักแต่ละครั้ง)
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- visitor_id (INTEGER) - FOREIGN KEY → visitors.id
- start_date (TEXT NOT NULL) - วันที่เริ่มพัก
- end_date (TEXT NOT NULL) - วันที่สิ้นสุด
- status (TEXT DEFAULT 'active') - 'active', 'extended', 'completed'
- note (TEXT) - หมายเหตุ (อาหาร, โรคประจำตัว, etc.)
- created_at (TEXT DEFAULT CURRENT_TIMESTAMP)

## ตาราง equipment_loans (การยืม-คืนอุปกรณ์)
- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- stay_id (INTEGER) - FOREIGN KEY → stays.id
- item_name (TEXT NOT NULL) - ชื่ออุปกรณ์ (เช่น 'ชุดขาว', 'หมอน', 'ผ้าห่ม')
- quantity (INTEGER DEFAULT 1) - จำนวน
- in_out (TEXT NOT NULL) - 'IN' (ยืม) หรือ 'OUT' (คืน)
- transaction_date (TEXT DEFAULT CURRENT_TIMESTAMP)
- note (TEXT) - หมายเหตุ

## Relations
- visitors → stays (1:N)
- stays → equipment_loans (1:N)

## Indexes
- CREATE INDEX idx_visitors_id_card ON visitors(id_card);
- CREATE INDEX idx_stays_visitor_id ON stays(visitor_id);
- CREATE INDEX idx_stays_date_range ON stays(start_date, end_date);
- CREATE INDEX idx_equipment_stay_id ON equipment_loans(stay_id);