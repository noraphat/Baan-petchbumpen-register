#!/bin/bash

echo "🚀 เริ่มต้นการทดสอบระบบ Baan Petchbumpen Register"
echo "=================================================="

# สร้างโฟลเดอร์สำหรับ golden test images ถ้ายังไม่มี
mkdir -p test/golden/images

echo ""
echo "📋 1. กำลังรัน Unit Tests..."
flutter test test/unit/ --coverage

echo ""
echo "🎨 2. กำลังรัน Widget Tests..."
flutter test test/widget/

echo ""
echo "🔗 3. กำลังรัน Integration Tests..."
flutter test test/integration/

echo ""
echo "🖼️  4. กำลังรัน Golden Tests..."
flutter test test/golden/

echo ""
echo "✅ การทดสอบเสร็จสิ้น!"
echo "📊 ดูรายงาน coverage ได้ที่: coverage/lcov.info"
echo "🖼️  ดู golden test images ได้ที่: test/golden/images/"
