// 📄 ตัวอย่างการใช้งาน PrecisionMapEditor ใน MapManagementScreen
// ไฟล์: lib/screen/map_management_screen.dart

// ================ การ Import ================
// เปลี่ยนจาก
// import '../widgets/interactive_map_improved.dart';

// เป็น
import '../widgets/precision_map_editor.dart';

// ================ การแก้ไขฟังก์ชัน _buildPositionManagementTab() ================

Widget _buildPositionManagementTab() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Section
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_location,
                color: Colors.purple.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'จัดการตำแหน่งห้องบนแผนที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ลากห้องจากด้านล่างมาวางบนแผนที่ในตำแหน่งที่ต้องการ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Room Statistics
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.meeting_room,
                    size: 16,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_rooms.length} ห้อง',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 16),

      // Main Content Area
      if (_activeMap == null)
        // No Active Map Warning
        Expanded(
          child: Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.orange.shade600,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ยังไม่มีแผนที่หลัก',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณาไปที่แท็บ "แผนที่" เพื่อเพิ่มและเลือกแผนที่หลักก่อนจัดการตำแหน่งห้อง',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _tabController.animateTo(0), // ไปแท็บแผนที่
                      icon: const Icon(Icons.map),
                      label: const Text('ไปจัดการแผนที่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      else
        // Precision Map Editor
        Expanded(
          child: PrecisionMapEditor(
            rooms: _rooms,
            mapData: _activeMap,
            onRoomTap: (room) {
              // Handle room tap
              setState(() => _selectedRoom = room);
              
              // Show room details in a bottom sheet
              _showRoomDetailsBottomSheet(room);
            },
            onRoomPositionChanged: (room, offset) async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text('กำลังบันทึกตำแหน่งห้อง "${room.name}"...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );

              // Update room position in database
              final success = await _mapService.updateRoomPosition(
                room.id!,
                offset.dx,
                offset.dy,
              );
              
              if (success) {
                // Success feedback
                _showSuccessSnackBar(
                  '🎯 วางห้อง "${room.name}" สำเร็จ!\nตำแหน่ง: (${offset.dx.toInt()}, ${offset.dy.toInt()})',
                );
                
                // Reload rooms data
                await _loadRooms();
                setState(() {});
                
                // Optional: Auto-select the moved room
                setState(() => _selectedRoom = room);
                
              } else {
                // Error feedback
                _showErrorSnackBar(
                  '❌ ไม่สามารถวางห้อง "${room.name}" ได้\n(อาจมีห้องอื่นอยู่ในตำแหน่งนี้แล้ว)',
                );
              }
            },
          ),
        ),
    ],
  );
}

// ================ ฟังก์ชันเสริม ================

void _showRoomDetailsBottomSheet(Room room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRoomStatusColor(room.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoomStatusIcon(room.status),
                    color: _getRoomStatusColor(room.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        room.status.displayName,
                        style: TextStyle(
                          color: _getRoomStatusColor(room.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Room Details
            _buildDetailRow(Icons.straighten, 'ขนาด', room.size.displayName),
            _buildDetailRow(Icons.people, 'ความจุ', '${room.capacity} คน'),
            
            if (room.hasPosition) ...[
              _buildDetailRow(
                Icons.location_on,
                'ตำแหน่ง',
                '(${room.positionX!.toInt()}, ${room.positionY!.toInt()})',
              ),
            ] else ...[
              _buildDetailRow(
                Icons.location_off,
                'ตำแหน่ง',
                'ยังไม่ได้วางบนแผนที่',
                valueColor: Colors.orange,
              ),
            ],
            
            if (room.description != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(Icons.description, 'คำอธิบาย', room.description!),
            ],
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditRoomDialog(room);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('แก้ไข'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: room.hasPosition
                        ? () {
                            Navigator.pop(context);
                            // Scroll to room on map (implementation depends on your needs)
                          }
                        : null,
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('หาบนแผนที่'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: valueColor ?? Colors.grey.shade800,
            ),
          ),
        ),
      ],
    ),
  );
}

Color _getRoomStatusColor(RoomStatus status) {
  switch (status) {
    case RoomStatus.available:
      return Colors.green;
    case RoomStatus.occupied:
      return Colors.red;
    case RoomStatus.reserved:
      return Colors.orange;
  }
}

IconData _getRoomStatusIcon(RoomStatus status) {
  switch (status) {
    case RoomStatus.available:
      return Icons.check_circle;
    case RoomStatus.occupied:
      return Icons.person;
    case RoomStatus.reserved:
      return Icons.schedule;
  }
}

// ================ Enhanced Success/Error Messages ================

void _showSuccessSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green.shade600,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.red.shade600,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'ปิด',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}