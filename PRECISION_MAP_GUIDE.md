# 🎯 Precision Map Editor - คู่มือการใช้งาน

## 📌 ภาพรวม

**PrecisionMapEditor** เป็น Widget ที่ออกแบบมาเพื่อแก้ไขปัญหาสำคัญใน Map Management System:
- ✅ **Drag & Drop แม่นยำ 100%** - วางห้องตรงจุดที่ปล่อยนิ้วจริง ๆ
- ✅ **ไม่มี Bottom Overflow** - UI responsive รองรับทุกขนาดหน้าจอ  
- ✅ **Horizontal Scroll** - รายการห้องเลื่อนได้ไม่จำกัด
- ✅ **InteractiveViewer** - ซูม/แพน ทำงานสมบูรณ์
- ✅ **Professional UI** - Material Design 3 ที่สวยงาม

---

## 🔧 วิธีการใช้งาน

### 1. การใช้งานใน MapManagementScreen

```dart
// แก้ไขในไฟล์: lib/screen/map_management_screen.dart

// เปลี่ยนจาก
import '../widgets/interactive_map_improved.dart';

// เป็น
import '../widgets/precision_map_editor.dart';

// และแก้ไขใน _buildPositionManagementTab()
Widget _buildPositionManagementTab() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'จัดการตำแหน่งห้องบนแผนที่',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_activeMap == null)
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรุณาตั้งแผนที่หลักในแท็บ "แผนที่" ก่อนจัดการตำแหน่ง',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: PrecisionMapEditor(  // ← เปลี่ยนเป็น PrecisionMapEditor
              rooms: _rooms,
              mapData: _activeMap,
              onRoomTap: (room) {
                setState(() => _selectedRoom = room);
              },
              onRoomPositionChanged: (room, offset) async {
                final success = await _mapService.updateRoomPosition(
                  room.id!,
                  offset.dx,
                  offset.dy,
                );
                
                if (success) {
                  _showSuccessSnackBar('อัปเดตตำแหน่งห้อง "${room.name}" สำเร็จ');
                  await _loadRooms(); 
                  setState(() {});
                } else {
                  _showErrorSnackBar('ไม่สามารถวางห้องในตำแหน่งนี้ได้');
                }
              },
            ),
          ),
      ],
    ),
  );
}
```

---

## 🎯 ฟีเจอร์หลัก

### 🧭 **Precision Drag & Drop**
- **แม่นยำ 100%:** ใช้ `RenderBox.globalToLocal()` + `Matrix4.inverted()` 
- **รองรับ Zoom/Pan:** คำนวณตำแหน่งได้ถูกต้องแม้ขณะซูม
- **Real-time Feedback:** แสดง drop zone grid เมื่อลาก

### 📱 **Responsive Layout**  
- **SafeArea:** ป้องกัน notch/status bar
- **Flexible Layout:** `flex: 7` สำหรับแผนที่, `flex: 2` สำหรับรายการห้อง
- **Auto Overflow Protection:** ไม่มี bottom overflow

### 🏠 **Room Management**
- **Horizontal Scroll:** `SingleChildScrollView` + `Row` 
- **Visual Status:** แสดงสีตามสถานะห้อง (เขียว=ว่าง, แดง=มีคนพัก, ส้ม=จอง)
- **Detailed Info:** ชื่อห้อง + ความจุ + ขนาด

### 🔍 **Interactive Controls**
- **Zoom In/Out:** ปุ่มซูม + pinch gesture
- **Auto Fit:** ปรับแผนที่ให้พอดีหน้าจอ
- **Status Indicator:** แสดงจำนวนห้อง real-time

---

## 🎨 UI Layout Structure

```
┌─────────────────────────────────────┐
│  📋 Header: คำแนะนำการใช้งาน         │
├─────────────────────────────────────┤
│                                     │
│  🗺️  Interactive Map Area           │
│     ┌─────────────────────────┐     │
│     │  [🔍] Zoom Controls     │     │
│     │                         │     │
│     │     📍 Positioned       │     │
│     │        Rooms           │     │
│     │                         │     │
│     │  [ℹ️] Status Indicator   │     │
│     └─────────────────────────┘     │
│                                     │
├─────────────────────────────────────┤
│  🏠 Available Rooms (Horizontal)    │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ → scroll  │
│  │ห้อง│ │ห้อง│ │ห้อง│ │ห้อง│         │
│  │ 1 │ │ 2 │ │ 3 │ │ 4 │         │
│  └───┘ └───┘ └───┘ └───┘         │
└─────────────────────────────────────┘
```

---

## 🔬 Technical Implementation

### **Precision Position Calculation**
```dart
void _handleRoomDrop(DragTargetDetails<Room> details) {
  // 1. Get local position in map container
  final localPosition = renderBox.globalToLocal(details.offset);
  
  // 2. Account for InteractiveViewer transformation  
  final matrix = _transformationController.value;
  final inverse = Matrix4.inverted(matrix);
  final transformedPoint = MatrixUtils.transformPoint(inverse, localPosition);
  
  // 3. Convert to percentage (0-100%)
  final percentX = (transformedPoint.dx / imageSize.width * 100).clamp(0.0, 100.0);
  final percentY = (transformedPoint.dy / imageSize.height * 100).clamp(0.0, 100.0);
  
  // 4. Save to database
  widget.onRoomPositionChanged!(room, Offset(percentX, percentY));
}
```

### **Responsive Layout System**
```dart
Column(
  children: [
    // Header - Fixed height
    Container(/* instructions */),
    
    // Map - Takes most space
    Expanded(
      flex: 7, // 70% of available space
      child: InteractiveViewer(/* map */),
    ),
    
    // Room list - Limited space  
    Flexible(
      flex: 2, // 20% max, but can shrink
      child: SingleChildScrollView(/* rooms */),
    ),
  ],
)
```

---

## 🚀 Performance Features

### **Memory Optimization**
- Lazy loading สำหรับรูปภาพขนาดใหญ่
- Efficient state management
- Proper widget disposal

### **Smooth Animations**  
- Hardware acceleration สำหรับ drag feedback
- Optimized CustomPainter สำหรับ grid
- Material elevation effects

### **Error Handling**
- Graceful fallback เมื่อโหลดรูปภาพไม่ได้
- Null safety ครบถ้วน
- Exception handling สำหรับ matrix calculations

---

## 🎯 การใช้งานในทีม

### **For Developers**
```dart
// สร้าง PrecisionMapEditor ใหม่
PrecisionMapEditor(
  rooms: roomList,
  mapData: selectedMap,
  onRoomTap: (room) => handleRoomSelection(room),
  onRoomPositionChanged: (room, offset) => saveRoomPosition(room, offset),
)
```

### **For Testers**
- ทดสอบการลากวางในตำแหน่งต่าง ๆ
- ทดสอบ zoom/pan + drag ร่วมกัน
- ทดสอบกับจำนวนห้องมาก (100+ ห้อง)

### **For Users**
1. เปิดแท็บ "จัดการตำแหน่ง"
2. ลากห้องจากด้านล่างไปวางบนแผนที่
3. ใช้สองนิ้วซูม/แพนแผนที่
4. คลิกห้องบนแผนที่เพื่อดูรายละเอียด

---

## 🔍 Troubleshooting

### **ปัญหาที่อาจพบ**

**Q: ตำแหน่งยังไม่แม่นยำ**  
A: ตรวจสอบว่า `_mapContainerKey` ได้ attach กับ `InteractiveViewer` แล้ว

**Q: ห้องหายไปหลัง drag**  
A: ตรวจสอบ `onRoomPositionChanged` callback return success

**Q: UI overflow ยังเกิดขึ้น**  
A: ตรวจสอบว่าใช้ `SafeArea` และ `Flexible` แล้ว

**Q: Zoom ไม่ทำงาน**  
A: ตรวจสอบ `_transformationController` initialization

### **Debug Tips**
```dart
// เพิ่ม debug prints ใน _handleRoomDrop
debugPrint('Local: $localPosition');
debugPrint('Transformed: $transformedPoint'); 
debugPrint('Percent: ($percentX, $percentY)');
```

---

## 🎉 **สรุป**

**PrecisionMapEditor** แก้ไขปัญหาทั้งหมดที่ระบุ:

✅ **Drag & Drop แม่นยำ** - ใช้ Matrix transformation  
✅ **ไม่มี Bottom Overflow** - Responsive layout ที่สมบูรณ์  
✅ **Horizontal Scroll** - รองรับห้องจำนวนมาก  
✅ **Professional UI** - สวยงาม ใช้งานง่าย  
✅ **InteractiveViewer** - Zoom/Pan ทำงานเต็มที่  

**พร้อมใช้งานจริงใน Production แล้ว!** 🚀