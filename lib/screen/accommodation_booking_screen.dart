import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/interactive_map_improved.dart';
import '../services/map_service.dart';
import '../services/db_helper.dart';
import '../models/room_model.dart';
import '../models/reg_data.dart';
import 'test_map_display.dart';

class AccommodationBookingScreen extends StatefulWidget {
  const AccommodationBookingScreen({super.key});

  @override
  State<AccommodationBookingScreen> createState() =>
      _AccommodationBookingScreenState();
}

class _AccommodationBookingScreenState
    extends State<AccommodationBookingScreen> {
  final MapService _mapService = MapService();
  final DbHelper _dbHelper = DbHelper();

  MapData? _selectedMap;
  List<Room> _rooms = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapAndRooms();
  }

  Future<void> _loadMapAndRooms() async {
    setState(() => _isLoading = true);

    try {
      // โหลดแผนที่หลัก (active)
      final maps = await _mapService.getAllMaps();
      debugPrint('📍 โหลดแผนที่ได้ ${maps.length} แผน');

      _selectedMap = maps.where((map) => map.isActive).isNotEmpty
          ? maps.firstWhere((map) => map.isActive)
          : (maps.isNotEmpty ? maps.first : null);

      if (_selectedMap != null) {
        debugPrint('✅ เลือกแผนที่: ${_selectedMap!.name}');
        debugPrint('🖼️ แผนที่มีรูปภาพ: ${_selectedMap!.hasImage}');
        if (_selectedMap!.hasImage) {
          debugPrint('📁 path รูปภาพ: ${_selectedMap!.imagePath}');
        }

        // โหลดห้องพักทั้งหมด
        _rooms = await _mapService.getAllRooms();
        debugPrint('🏠 โหลดห้องพักได้ ${_rooms.length} ห้อง');

        for (var room in _rooms) {
          debugPrint(
            '   - ห้อง ${room.name}: (${room.positionX}, ${room.positionY})',
          );
        }

        // อัพเดทสถานะห้องตามวันที่เลือก
        await _updateRoomStatusForDate(_selectedDate);
      } else {
        debugPrint('❌ ไม่พบแผนที่ในระบบ');
      }
    } catch (e) {
      debugPrint('❌ Error loading map and rooms: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRoomStatusForDate(DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      for (int i = 0; i < _rooms.length; i++) {
        final room = _rooms[i];

        // ตรวจสอบการจองในวันที่เลือก
        final bookings = await _getBookingsForRoomAndDate(room.id!, dateStr);

        if (bookings.isNotEmpty) {
          // มีการจองแล้ว - สีแดง
          _rooms[i] = room.copyWith(status: RoomStatus.occupied);
        } else {
          // ห้องว่าง - สีเขียว
          _rooms[i] = room.copyWith(status: RoomStatus.available);
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error updating room status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getBookingsForRoomAndDate(
    int roomId,
    String date,
  ) async {
    final db = await _dbHelper.db;

    // ตรวจสอบการจองที่ครอบคลุมวันที่เลือก
    return await db.query(
      'room_bookings',
      where:
          'room_id = ? AND check_in_date <= ? AND check_out_date >= ? AND status != ?',
      whereArgs: [roomId, date, date, 'cancelled'],
    );
  }

  Future<void> _onRoomTapped(Room room) async {
    if (room.status != RoomStatus.available) {
      await _showRoomManagementDialog(room);
      return;
    }

    await _showBookingDialog(room);
  }

  Future<void> _showRoomManagementDialog(Room room) async {
    if (room.status == RoomStatus.occupied) {
      // ห้องมีผู้เข้าพัก - แสดงตัวเลือกการจัดการ
      await _showOccupiedRoomDialog(room);
    } else {
      // ห้องไม่พร้อมใช้งาน - แสดงข้อความธรรมดา
      _showSimpleUnavailableDialog(room);
    }
  }

  void _showSimpleUnavailableDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ห้อง ${room.name}'),
        content: const Text('ห้องนี้ไม่พร้อมให้บริการ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOccupiedRoomDialog(Room room) async {
    // หาข้อมูลผู้เข้าพักในห้องนี้
    final occupantInfo = await _getRoomOccupantInfo(room.id!, _selectedDate);

    if (occupantInfo == null) {
      _showSimpleUnavailableDialog(room);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ห้อง ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ผู้เข้าพัก: ${occupantInfo['first_name']} ${occupantInfo['last_name']}',
            ),
            Text('เบอร์โทร: ${occupantInfo['phone']}'),
            Text(
              'วันที่เข้าพัก: ${_formatDate(occupantInfo['check_in_date'])}',
            ),
            Text('วันที่ออก: ${_formatDate(occupantInfo['check_out_date'])}'),
            const SizedBox(height: 16),
            const Text(
              'คุณต้องการทำอะไร?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showExtendStayDialog(occupantInfo);
            },
            child: const Text('ขยายวันพัก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showChangeRoomDialog(occupantInfo, room);
            },
            child: const Text('เปลี่ยนห้อง'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showCancelBookingDialog(occupantInfo, room);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยกเลิกการจอง'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy', 'th').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<Map<String, dynamic>?> _getRoomOccupantInfo(
    int roomId,
    DateTime date,
  ) async {
    try {
      final db = await _dbHelper.db;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final result = await db.rawQuery(
        '''
        SELECT rb.*, r.first AS first_name, r.last AS last_name, r.phone
        FROM room_bookings rb
        INNER JOIN regs r ON rb.visitor_id = r.id
        WHERE rb.room_id = ? 
          AND rb.check_in_date <= ? 
          AND rb.check_out_date >= ?
          AND rb.status != 'cancelled'
        LIMIT 1
      ''',
        [roomId, dateStr, dateStr],
      );

      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('Error getting room occupant info: $e');
      return null;
    }
  }

  Future<void> _showExtendStayDialog(Map<String, dynamic> occupantInfo) async {
    final currentCheckOut = DateTime.parse(occupantInfo['check_out_date']);
    DateTime? newCheckOutDate = currentCheckOut;

    // ดึงข้อมูลการลงทะเบียนเพื่อจำกัดวันที่ขยาย
    final stayInfo = await _getStayInfo(occupantInfo['visitor_id']);
    DateTime? maxAllowedDate;

    if (stayInfo != null && stayInfo['endDate'] != null) {
      maxAllowedDate = DateTime.parse(stayInfo['endDate']);
      debugPrint('📅 Max allowed date from registration: $maxAllowedDate');
    }

    if (!mounted) return;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'ขยายวันพักสำหรับ ${occupantInfo['first_name']} ${occupantInfo['last_name']}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'วันที่ออกปัจจุบัน: ${_formatDate(occupantInfo['check_out_date'])}',
              ),
              if (maxAllowedDate != null) ...[
                const SizedBox(height: 8),
                // ตรวจสอบว่าสามารถขยายวันพักได้หรือไม่
                Builder(
                  builder: (context) {
                    final currentCheckOut = DateTime.parse(
                      occupantInfo['check_out_date'],
                    );
                    final firstAvailableDate = currentCheckOut.add(
                      const Duration(days: 1),
                    );
                    final canExtend = !firstAvailableDate.isAfter(
                      maxAllowedDate!,
                    );

                    if (canExtend) {
                      return Text(
                        'วันที่สูงสุดที่สามารถขยายได้: ${_formatDate(maxAllowedDate!.toIso8601String())}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    } else {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ไม่สามารถขยายวันพักได้ เนื่องจากวันที่ออกปัจจุบันเกินกว่าวันที่สิ้นสุดที่ลงทะเบียน',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'เลือกวันที่สิ้นสุดเข้าพักใหม่:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  debugPrint('📅 เปิดปฏิทินเลือกวันที่...');

                  // ใช้ WidgetsBinding เพื่อให้แน่ใจว่า context พร้อมใช้งาน
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    try {
                      // คำนวณวันที่เริ่มต้นและวันที่แรกที่เลือกได้
                      final firstAvailableDate = currentCheckOut.add(
                        const Duration(days: 1),
                      );

                      // กำหนดวันที่สูงสุดที่สามารถเลือกได้
                      final lastAvailableDate =
                          maxAllowedDate ??
                          DateTime.now().add(const Duration(days: 365));

                      // ตรวจสอบว่า firstDate ไม่เกิน lastDate
                      final adjustedFirstDate =
                          firstAvailableDate.isAfter(lastAvailableDate)
                          ? lastAvailableDate
                          : firstAvailableDate;

                      // ตรวจสอบว่า newCheckOutDate ต้องไม่น้อยกว่า adjustedFirstDate
                      DateTime initialDate;
                      if (newCheckOutDate != null &&
                          newCheckOutDate!.isAfter(
                            adjustedFirstDate.subtract(const Duration(days: 1)),
                          )) {
                        initialDate = newCheckOutDate!;
                      } else {
                        initialDate = adjustedFirstDate;
                      }

                      debugPrint('📅 currentCheckOut: $currentCheckOut');
                      debugPrint('📅 firstAvailableDate: $firstAvailableDate');
                      debugPrint('📅 lastAvailableDate: $lastAvailableDate');
                      debugPrint('📅 adjustedFirstDate: $adjustedFirstDate');
                      debugPrint('📅 initialDate: $initialDate');

                      // ตรวจสอบว่าสามารถแสดง DatePicker ได้หรือไม่
                      if (adjustedFirstDate.isAfter(lastAvailableDate)) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ไม่สามารถขยายวันพักได้ เนื่องจากวันที่ออกปัจจุบัน (${_formatDate(currentCheckOut.toIso8601String())}) เกินกว่าวันที่สิ้นสุดที่ลงทะเบียน (${_formatDate(lastAvailableDate.toIso8601String())})',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: adjustedFirstDate,
                        lastDate: lastAvailableDate,
                        locale: const Locale('th'),
                      );
                      debugPrint('📅 เลือกวันที่: $picked');
                      if (picked != null) {
                        setState(() {
                          newCheckOutDate = picked;
                        });
                      }
                    } catch (e) {
                      debugPrint('❌ Error showing date picker: $e');
                      // แสดงข้อความ error ให้ผู้ใช้ทราบ
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการเปิดปฏิทิน: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        newCheckOutDate == null
                            ? 'เลือกวันที่'
                            : _formatDate(newCheckOutDate!.toIso8601String()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: newCheckOutDate == null
                  ? null
                  : () {
                      // ตรวจสอบว่าวันที่เลือกไม่เกินวันที่ที่ลงทะเบียน
                      if (maxAllowedDate != null &&
                          newCheckOutDate!.isAfter(maxAllowedDate)) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('วันที่ไม่ถูกต้อง'),
                            content: Text(
                              'ไม่สามารถขยายวันพักเกินวันที่ที่ลงทะเบียนไว้\n'
                              'วันที่สูงสุดที่สามารถเลือกได้: ${_formatDate(maxAllowedDate!.toIso8601String())}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ตกลง'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, newCheckOutDate);
                    },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _updateCheckOutDate(occupantInfo, result);
    }
  }

  Future<void> _updateCheckOutDate(
    Map<String, dynamic> occupantInfo,
    DateTime newCheckOutDate,
  ) async {
    try {
      // ตรวจสอบว่าวันที่ใหม่ไม่เกินวันที่ที่ลงทะเบียน
      final stayInfo = await _getStayInfo(occupantInfo['visitor_id']);
      if (stayInfo != null && stayInfo['endDate'] != null) {
        final maxAllowedDate = DateTime.parse(stayInfo['endDate']);
        final newCheckOutDateOnly = DateTime(
          newCheckOutDate.year,
          newCheckOutDate.month,
          newCheckOutDate.day,
        );
        final maxAllowedDateOnly = DateTime(
          maxAllowedDate.year,
          maxAllowedDate.month,
          maxAllowedDate.day,
        );

        if (newCheckOutDateOnly.isAfter(maxAllowedDateOnly)) {
          debugPrint('❌ Cannot extend beyond registration date');
          if (mounted) {
            _showErrorDialog(
              'ไม่สามารถขยายวันพักเกินวันที่ที่ลงทะเบียนไว้\n'
              'วันที่สูงสุด: ${_formatDate(maxAllowedDate.toIso8601String())}',
            );
          }
          return;
        }
      }

      final db = await _dbHelper.db;
      final newCheckOutStr = DateFormat('yyyy-MM-dd').format(newCheckOutDate);

      // อัพเดต room_bookings table
      await db.update(
        'room_bookings',
        {'check_out_date': newCheckOutStr},
        where: 'id = ?',
        whereArgs: [occupantInfo['id']],
      );

      // อัพเดตข้อมูลในตาราง stays ด้วย
      await db.update(
        'stays',
        {'end_date': newCheckOutStr},
        where: 'visitor_id = ? AND status = ?',
        whereArgs: [occupantInfo['visitor_id'], 'active'],
      );

      // รีโหลดข้อมูลห้อง
      await _updateRoomStatusForDate(_selectedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ขยายวันพักสำเร็จ วันที่ออกใหม่: ${_formatDate(newCheckOutStr)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating check out date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการขยายวันพัก'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showChangeRoomDialog(
    Map<String, dynamic> occupantInfo,
    Room currentRoom,
  ) async {
    // หาห้องว่างสำหรับย้าย
    final availableRooms = await _getAvailableRoomsForTransfer(occupantInfo);

    if (availableRooms.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่มีห้องว่างสำหรับย้าย')),
        );
      }
      return;
    }

    if (!mounted) return;

    Room? selectedRoom;

    final result = await showDialog<Room>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'เปลี่ยนห้องสำหรับ ${occupantInfo['first_name']} ${occupantInfo['last_name']}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ห้องปัจจุบัน: ${currentRoom.name}'),
                const SizedBox(height: 16),
                const Text(
                  'เลือกห้องใหม่:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableRooms.length,
                    itemBuilder: (context, index) {
                      final room = availableRooms[index];
                      final isSelected = selectedRoom?.id == room.id;

                      return ListTile(
                        title: Text(room.name),
                        subtitle: Text(
                          'ขนาด: ${room.size.name}, จุได้: ${room.capacity} คน',
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.hotel, color: Colors.white),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          setState(() {
                            selectedRoom = room;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: selectedRoom == null
                  ? null
                  : () => Navigator.pop(context, selectedRoom),
              child: const Text('ย้ายห้อง'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _transferToNewRoom(occupantInfo, currentRoom, result);
    }
  }

  Future<List<Room>> _getAvailableRoomsForTransfer(
    Map<String, dynamic> occupantInfo,
  ) async {
    try {
      final checkInDate = occupantInfo['check_in_date'];
      final checkOutDate = occupantInfo['check_out_date'];

      final availableRooms = <Room>[];

      for (final room in _rooms) {
        if (room.id == occupantInfo['room_id']) continue; // ข้ามห้องปัจจุบัน

        // ตรวจสอบว่าห้องว่างในช่วงเวลาที่ต้องการย้าย
        final conflicts = await _getBookingsForRoomAndDateRange(
          room.id!,
          checkInDate,
          checkOutDate,
        );

        if (conflicts.isEmpty) {
          availableRooms.add(room);
        }
      }

      return availableRooms;
    } catch (e) {
      debugPrint('Error getting available rooms for transfer: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getBookingsForRoomAndDateRange(
    int roomId,
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.db;

    return await db.query(
      'room_bookings',
      where: '''
        room_id = ? AND status != 'cancelled' AND (
          (check_in_date <= ? AND check_out_date >= ?) OR
          (check_in_date <= ? AND check_out_date >= ?) OR
          (check_in_date >= ? AND check_out_date <= ?)
        )
      ''',
      whereArgs: [
        roomId,
        startDate,
        startDate,
        endDate,
        endDate,
        startDate,
        endDate,
      ],
    );
  }

  Future<void> _transferToNewRoom(
    Map<String, dynamic> occupantInfo,
    Room oldRoom,
    Room newRoom,
  ) async {
    try {
      final db = await _dbHelper.db;

      // อัพเดตการจองไปห้องใหม่
      await db.update(
        'room_bookings',
        {'room_id': newRoom.id},
        where: 'id = ?',
        whereArgs: [occupantInfo['id']],
      );

      // รีโหลดข้อมูลห้อง
      await _updateRoomStatusForDate(_selectedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ย้ายห้องสำเร็จ จาก ${oldRoom.name} ไป ${newRoom.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error transferring to new room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการย้ายห้อง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCancelBookingDialog(
    Map<String, dynamic> occupantInfo,
    Room room,
  ) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการยกเลิกการจอง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ผู้เข้าพัก: ${occupantInfo['first_name']} ${occupantInfo['last_name']}',
            ),
            Text('ห้อง: ${room.name}'),
            Text(
              'วันที่เข้าพัก: ${_formatDate(occupantInfo['check_in_date'])}',
            ),
            Text('วันที่ออก: ${_formatDate(occupantInfo['check_out_date'])}'),
            const SizedBox(height: 16),
            const Text(
              'คุณต้องการยกเลิกการจองนี้หรือไม่?',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยกเลิกการจอง'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelBooking(occupantInfo);
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> occupantInfo) async {
    try {
      final db = await _dbHelper.db;

      // ลบข้อมูลการจองจากตาราง room_bookings
      await db.delete(
        'room_bookings',
        where: 'id = ?',
        whereArgs: [occupantInfo['id']],
      );

      // อัพเดตข้อมูลใน reg_additional_info เพื่อลบข้อมูลที่พัก (location)
      await db.update(
        'reg_additional_info',
        {'location': null},
        where: 'regId = ?',
        whereArgs: [occupantInfo['visitor_id']],
      );

      // รีโหลดข้อมูลห้อง
      await _updateRoomStatusForDate(_selectedDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ยกเลิกการจองสำเร็จ สำหรับ ${occupantInfo['first_name']} ${occupantInfo['last_name']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error canceling booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาดในการยกเลิกการจอง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showBookingDialog(Room room) async {
    // โหลดรายชื่อผู้ปฏิบัติธรรมที่สามารถจองได้
    final availablePractitioners = await _getAvailablePractitioners(
      _selectedDate,
    );

    if (availablePractitioners.isEmpty) {
      _showErrorDialog(
        'ไม่พบผู้ปฏิบัติธรรมที่สามารถเข้าพักในวันนี้ กรุณาตรวจสอบข้อมูลการลงทะเบียน',
      );
      return;
    }

    RegData? selectedPractitioner;

    if (!mounted) return;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('จองห้อง ${room.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'วันที่: ${DateFormat('dd/MM/yyyy', 'th').format(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'เลือกผู้ปฏิบัติธรรม:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: availablePractitioners.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'ยังไม่มีผู้ปฏิบัติธรรมที่สามารถ\nจองห้องพักในวันนี้',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: availablePractitioners.length,
                          itemBuilder: (context, index) {
                            final practitioner = availablePractitioners[index];
                            final isSelected =
                                selectedPractitioner?.id == practitioner.id;

                            return ListTile(
                              title: Text(
                                '${practitioner.first} ${practitioner.last}',
                              ),
                              subtitle: Text(
                                'เบอร์โทร: ${practitioner.phone}\n'
                                'เพศ: ${practitioner.gender}',
                              ),
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                child: Text(
                                  practitioner.first.isNotEmpty
                                      ? practitioner.first[0]
                                      : '?',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50,
                              onTap: () {
                                setState(() {
                                  selectedPractitioner = practitioner;
                                });
                              },
                            );
                          },
                        ),
                ),
                if (selectedPractitioner != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'เลือก: ${selectedPractitioner!.first} ${selectedPractitioner!.last}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: selectedPractitioner == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _processBooking(room, selectedPractitioner!.id);
                    },
              child: const Text('จองห้อง'),
            ),
          ],
        ),
      ),
    );
  }

  /// โหลดรายชื่อผู้ปฏิบัติธรรมที่สามารถจองห้องได้
  Future<List<RegData>> _getAvailablePractitioners(
    DateTime selectedDate,
  ) async {
    try {
      final db = await _dbHelper.db;
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

      // ค้นหาผู้ปฏิบัติธรรมที่:
      // 1. กำลังเข้าพักในวันที่เลือก (start_date <= selectedDate <= end_date)
      // 2. ยังไม่ได้จองห้องพัก หรือห้องเป็น "ศาลาใหญ่"
      final result = await db.rawQuery(
        '''
        SELECT DISTINCT r.*, s.start_date, s.end_date
        FROM regs r
        LEFT JOIN stays s ON r.id = s.visitor_id AND s.status = 'active'
        WHERE r.status = 'A'
          AND (
            (s.start_date IS NOT NULL AND s.end_date IS NOT NULL AND DATE(s.start_date) <= ? AND DATE(s.end_date) >= ?) OR
            (s.start_date IS NULL AND s.end_date IS NULL)
          )
          AND r.id NOT IN (
            SELECT DISTINCT rb.visitor_id
            FROM room_bookings rb
            INNER JOIN rooms room ON rb.room_id = room.id
            WHERE rb.check_in_date <= ? 
              AND rb.check_out_date >= ?
              AND rb.status != 'cancelled'
              AND room.name != 'ศาลาใหญ่'
          )
        ORDER BY r.first, r.last
      ''',
        [dateStr, dateStr, dateStr, dateStr],
      );

      debugPrint('📊 Query for available practitioners on $dateStr:');
      debugPrint('   Found ${result.length} practitioners');

      // Debug: แสดงข้อมูลผู้ปฏิบัติธรรมที่พบ
      for (var practitioner in result) {
        debugPrint(
          '   - ${practitioner['first']} ${practitioner['last']} (ID: ${practitioner['id']})',
        );
        if (practitioner['start_date'] != null) {
          debugPrint(
            '     Stay period: ${practitioner['start_date']} - ${practitioner['end_date']}',
          );
        }
      }

      // Debug: แสดงข้อมูลผู้ปฏิบัติธรรมที่พบ
      for (var practitioner in result) {
        debugPrint(
          '   - ${practitioner['first']} ${practitioner['last']} (ID: ${practitioner['id']})',
        );
      }

      if (result.isEmpty) {
        // ตรวจสอบว่ามีคนลงทะเบียนหรือไม่
        final allRegs = await db.query(
          'regs',
          where: 'status = ?',
          whereArgs: ['A'],
        );
        debugPrint('   Total active registrations: ${allRegs.length}');

        // ตรวจสอบว่ามีข้อมูลการเข้าพักหรือไม่
        final allStays = await db.rawQuery(
          '''
          SELECT s.*, r.first, r.last
          FROM stays s
          INNER JOIN regs r ON s.visitor_id = r.id
          WHERE r.status = 'A' AND s.status = 'active' AND DATE(s.start_date) <= ? AND DATE(s.end_date) >= ?
        ''',
          [dateStr, dateStr],
        );
        debugPrint('   People staying on $dateStr: ${allStays.length}');

        // ตรวจสอบข้อมูลทั้งหมดใน stays
        final allStaysData = await db.rawQuery('''
          SELECT s.*, r.first, r.last
          FROM stays s
          INNER JOIN regs r ON s.visitor_id = r.id
          WHERE r.status = 'A' AND s.status = 'active'
        ''');
        debugPrint('   All active stays records: ${allStaysData.length}');

        for (var stay in allStaysData) {
          debugPrint(
            '     - ${stay['first']} ${stay['last']}: ${stay['start_date']} - ${stay['end_date']} (visitor_id: ${stay['visitor_id']})',
          );
        }

        // ตรวจสอบว่ามีใครลงทะเบียนแต่ไม่มีข้อมูลการเข้าพักหรือไม่
        final regsWithoutStays = await db.rawQuery('''
          SELECT r.*
          FROM regs r
          LEFT JOIN stays s ON r.id = s.visitor_id AND s.status = 'active'
          WHERE r.status = 'A' AND s.visitor_id IS NULL
        ''');
        debugPrint('   People without stays info: ${regsWithoutStays.length}');

        for (var reg in regsWithoutStays) {
          debugPrint(
            '     - ${reg['first']} ${reg['last']} (ID: ${reg['id']}) - No stays info',
          );
        }

        for (var stay in allStays) {
          debugPrint(
            '     - ${stay['first']} ${stay['last']}: ${stay['start_date']} - ${stay['end_date']}',
          );
        }

        // ตรวจสอบการจองห้อง
        final bookings = await db.rawQuery(
          '''
          SELECT rb.*, r.first, r.last, room.name as room_name
          FROM room_bookings rb
          INNER JOIN regs r ON rb.visitor_id = r.id
          INNER JOIN rooms room ON rb.room_id = room.id
          WHERE rb.check_in_date <= ? AND rb.check_out_date >= ? AND rb.status != 'cancelled'
        ''',
          [dateStr, dateStr],
        );
        debugPrint('   Existing bookings on $dateStr: ${bookings.length}');

        for (var booking in bookings) {
          debugPrint(
            '     - ${booking['first']} ${booking['last']} in ${booking['room_name']}',
          );
        }
      }

      return result.map((map) => RegData.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting available practitioners: $e');
      return [];
    }
  }

  Future<void> _processBooking(Room room, String idNumber) async {
    try {
      debugPrint(
        '🚀 Starting booking process for ID: $idNumber, Room: ${room.name}',
      );

      // ตรวจสอบว่ามีผู้ปฏิบัติธรรมคนนี้หรือไม่
      final practitioner = await _getPractitionerById(idNumber);
      if (practitioner == null) {
        debugPrint('❌ Practitioner not found: $idNumber');
        _showErrorDialog('ไม่พบข้อมูลผู้ปฏิบัติธรรมที่มีหมายเลขบัตรประชาชนนี้');
        return;
      }
      debugPrint(
        '✅ Practitioner found: ${practitioner.first} ${practitioner.last}',
      );

      // ตรวจสอบว่ากำลังเข้าพักในช่วงเวลานี้หรือไม่
      final isCurrentlyStaying = await _isCurrentlyStaying(
        idNumber,
        _selectedDate,
      );
      if (!isCurrentlyStaying) {
        debugPrint('❌ Practitioner not currently staying on ${_selectedDate}');
        _showErrorDialog(
          'ผู้ปฏิบัติธรรมไม่ได้เข้าพักในช่วงวันที่นี้\nกรุณาตรวจสอบข้อมูลการลงทะเบียน',
        );
        return;
      }
      debugPrint('✅ Practitioner is currently staying');

      // ตรวจสอบว่าไม่ได้จองห้องอื่นในวันเดียวกันแล้ว
      final existingBooking = await _getExistingBookingForDate(
        idNumber,
        _selectedDate,
      );
      if (existingBooking != null) {
        debugPrint('❌ Existing booking found: ${existingBooking['room_name']}');
        _showErrorDialog(
          'ผู้ปฏิบัติธรรมรายนี้ได้จองห้องพักไว้แล้ว หากต้องการเปลี่ยนห้อง กรุณายกเลิกการจองเดิมก่อน\n\nห้องที่จองไว้: ${existingBooking['room_name']}',
        );
        return;
      }
      debugPrint('✅ No existing booking found');

      // ดึงข้อมูลช่วงเวลาเข้าพักของผู้ปฏิบัติธรรม
      final stayInfo = await _getStayInfo(idNumber);
      if (stayInfo == null) {
        debugPrint('❌ Stay info not found for: $idNumber');
        _showErrorDialog('ไม่พบข้อมูลการเข้าพักของผู้ปฏิบัติธรรม');
        return;
      }
      debugPrint(
        '✅ Stay info found: ${stayInfo['startDate']} - ${stayInfo['endDate']}',
      );

      // กำหนด Logic การจองตามเงื่อนไขใหม่
      await _processBookingWithDateRange(
        room,
        idNumber,
        practitioner,
        stayInfo,
      );
    } catch (e) {
      debugPrint('❌ Error processing booking: $e');
      _showErrorDialog('เกิดข้อผิดพลาดในการจองห้อง\nกรุณาลองใหม่อีกครั้ง');
    }
  }

  Future<RegData?> _getPractitionerById(String idNumber) async {
    final db = await _dbHelper.db;
    final result = await db.query(
      'regs',
      where: 'id = ? AND status = ?',
      whereArgs: [idNumber, 'A'],
    );

    return result.isNotEmpty ? RegData.fromMap(result.first) : null;
  }

  Future<bool> _isCurrentlyStaying(String idNumber, DateTime checkDate) async {
    final db = await _dbHelper.db;
    final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);

    // เปลี่ยนไปตรวจสอบจากตาราง stays แทน reg_additional_info
    // ใช้ rawQuery เพื่อใช้ DATE() function ในการเปรียบเทียบวันที่
    final result = await db.rawQuery(
      '''
      SELECT * FROM stays 
      WHERE visitor_id = ? 
        AND status = ? 
        AND DATE(start_date) <= ? 
        AND DATE(end_date) >= ?
      ''',
      [idNumber, 'active', dateStr, dateStr],
    );

    debugPrint(
      '🔍 Checking stay status for $idNumber on $dateStr: ${result.isNotEmpty ? "ALLOWED" : "NOT ALLOWED"}',
    );
    if (result.isNotEmpty) {
      final record = result.first;
      debugPrint(
        '   - start_date: ${record['start_date']}, end_date: ${record['end_date']}',
      );
      debugPrint(
        '   - Comparing: DATE(${record['start_date']}) <= $dateStr AND DATE(${record['end_date']}) >= $dateStr',
      );
    } else {
      debugPrint('   - No matching stay records found');
    }

    return result.isNotEmpty;
  }

  /// ดึงข้อมูลช่วงเวลาเข้าพักของผู้ปฏิบัติธรรม
  Future<Map<String, dynamic>?> _getStayInfo(String idNumber) async {
    final db = await _dbHelper.db;

    // เปลี่ยนไปอ่านจากตาราง stays แทน reg_additional_info
    final result = await db.query(
      'stays',
      where: 'visitor_id = ? AND status = ?',
      whereArgs: [idNumber, 'active'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final stay = result.first;
      // แปลงข้อมูลให้ตรงกับรูปแบบที่โค้ดเดิมคาดหวัง
      return {
        'startDate': stay['start_date'],
        'endDate': stay['end_date'],
        'regId': idNumber,
      };
    }

    return null;
  }

  /// Logic การจองใหม่ที่รองรับ Date Range Picker
  Future<void> _processBookingWithDateRange(
    Room room,
    String idNumber,
    RegData practitioner,
    Map<String, dynamic> stayInfo,
  ) async {
    final currentDate = DateTime.now();

    debugPrint('🔄 Processing booking with date range:');
    debugPrint(
      '   Stay info: ${stayInfo['startDate']} - ${stayInfo['endDate']}',
    );
    debugPrint('   Current date: $currentDate');
    debugPrint('   Selected date: $_selectedDate');

    // ตรวจสอบว่ามีข้อมูลวันที่หรือไม่
    if (stayInfo['startDate'] == null || stayInfo['endDate'] == null) {
      // ไม่มีข้อมูลวันที่ - ใช้ DateRangePicker
      debugPrint('🟡 No date info - showing Date Range Picker');
      await _showDateRangePickerDialog(room, idNumber, practitioner, stayInfo);
      return;
    }

    final startDate = DateTime.parse(stayInfo['startDate']);
    final endDate = DateTime.parse(stayInfo['endDate']);

    // กรณีพัก 1 วัน - จองอัตโนมัติ
    if (_isSameDay(startDate, endDate)) {
      debugPrint('🟢 Single day stay - booking automatically for: $startDate');
      await _saveBooking(room, idNumber, practitioner, startDate, endDate);
      await _updateRoomStatusForDate(_selectedDate);
      _showSuccessDialog(room, practitioner, startDate, endDate);
      return;
    }

    // กรณีหลายวัน - ใช้ DateRangePicker
    debugPrint('🟡 Multi-day stay - showing Date Range Picker');
    await _showDateRangePickerDialog(room, idNumber, practitioner, stayInfo);
  }

  /// ตรวจสอบว่าเป็นวันเดียวกันหรือไม่
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// แสดง Date Range Picker Dialog ที่จำกัดช่วงวันที่ตามข้อมูลการลงทะเบียน
  Future<void> _showDateRangePickerDialog(
    Room room,
    String idNumber,
    RegData practitioner,
    Map<String, dynamic> stayInfo,
  ) async {
    debugPrint('🎯 _showDateRangePickerDialog called!');

    // ตรวจสอบว่ามีข้อมูลวันที่ลงทะเบียนหรือไม่
    if (stayInfo['startDate'] == null || stayInfo['endDate'] == null) {
      debugPrint('❌ No registration date info found');
      _showErrorDialog(
        'ไม่พบข้อมูลช่วงเวลาเข้าพักที่ลงทะเบียนไว้\nกรุณาตรวจสอบข้อมูลการลงทะเบียน',
      );
      return;
    }

    // แปลงข้อมูลวันที่จาก String เป็น DateTime
    final DateTime startDate = DateTime.parse(stayInfo['startDate']);
    final DateTime endDate = DateTime.parse(stayInfo['endDate']);

    debugPrint('📅 Registration Date Range:');
    debugPrint('   startDate: $startDate');
    debugPrint('   endDate: $endDate');

    // กำหนดช่วงวันที่ที่อนุญาตให้เลือกได้
    // ✅ ตามเงื่อนไขที่ต้องการ: firstDate = startDate, lastDate = endDate
    final DateTime firstDate = startDate;
    final DateTime lastDate = endDate;

    // กำหนดช่วงเริ่มต้น (initial range) เป็นช่วงเต็มที่ลงทะเบียนไว้
    final DateTimeRange initialRange = DateTimeRange(
      start: startDate,
      end: endDate,
    );

    debugPrint('📅 DateRangePicker Configuration:');
    debugPrint('   firstDate: $firstDate');
    debugPrint('   lastDate: $lastDate');
    debugPrint('   initialRange: ${initialRange.start} - ${initialRange.end}');

    // คำนวณจำนวนวันทั้งหมด
    final int totalDays = endDate.difference(startDate).inDays + 1;

    // สร้างข้อความแสดงผล
    final String dialogMessage =
        'ผู้ปฏิบัติธรรมลงทะเบียนเข้าพักทั้งหมด $totalDays วัน\n'
        '(${_formatDate(startDate.toIso8601String())} - ${_formatDate(endDate.toIso8601String())})\n\n'
        'กรุณาเลือกช่วงวันที่ที่ต้องการจองห้องพัก';

    if (!mounted) return;

    debugPrint('🎯 About to show DateRangePicker dialog');

    DateTimeRange? selectedRange;

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('จองห้อง ${room.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialogMessage, style: const TextStyle(fontSize: 14)),

                const SizedBox(height: 16),
                const Text(
                  'เลือกช่วงวันที่:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () async {
                      try {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDateRange: selectedRange ?? initialRange,
                          locale: const Locale('th'),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(
                                  context,
                                ).colorScheme.copyWith(primary: Colors.blue),
                              ),
                              child: child!,
                            );
                          },
                          helpText: 'เลือกช่วงวันที่เข้าพัก',
                          cancelText: 'ยกเลิก',
                          confirmText: 'ยืนยัน',
                          saveText: 'บันทึก',
                          errorFormatText: 'รูปแบบวันที่ไม่ถูกต้อง',
                          errorInvalidText: 'วันที่ไม่ถูกต้อง',
                          errorInvalidRangeText: 'ช่วงวันที่ไม่ถูกต้อง',
                          fieldStartHintText: 'วันเริ่มต้น',
                          fieldEndHintText: 'วันสิ้นสุด',
                        );

                        if (picked != null && mounted) {
                          setState(() {
                            selectedRange = picked;
                          });
                        }
                      } catch (e) {
                        debugPrint('Error showing date range picker: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'เกิดข้อผิดพลาดในการเปิดปฏิทิน: $e',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedRange == null
                                ? 'กดเพื่อเลือกช่วงวันที่'
                                : '${_formatDate(selectedRange!.start.toIso8601String())} - ${_formatDate(selectedRange!.end.toIso8601String())}',
                            style: TextStyle(
                              color: selectedRange == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedRange != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จำนวนวันที่เลือก: ${selectedRange!.duration.inDays + 1} วัน',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'จำนวนวันที่ลงทะเบียน: $totalDays วัน',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: selectedRange == null
                  ? null
                  : () {
                      // ตรวจสอบว่าช่วงวันที่ที่เลือกถูกต้องหรือไม่
                      final isValid = _validateBookingDateRange(
                        selectedRange!,
                        startDate,
                        endDate,
                      );

                      if (isValid) {
                        Navigator.pop(context, selectedRange);
                      } else {
                        // แสดง error message ที่ชัดเจน
                        final errorMessage = _getDateRangeErrorMessage(
                          selectedRange!,
                          startDate,
                          endDate,
                        );

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ช่วงวันที่ไม่ถูกต้อง'),
                            content: Text(errorMessage),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('ตกลง'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
              child: const Text('ยืนยันการจอง'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        // ตรวจสอบอีกครั้งก่อนบันทึก (Double validation)
        final finalValidation = _validateBookingDateRange(
          result,
          startDate,
          endDate,
        );

        if (!finalValidation) {
          final errorMessage = _getDateRangeErrorMessage(
            result,
            startDate,
            endDate,
          );
          debugPrint('❌ Final validation failed: $errorMessage');
          if (mounted) {
            _showErrorDialog('การตรวจสอบครั้งสุดท้ายไม่ผ่าน:\n$errorMessage');
          }
          return;
        }

        debugPrint('✅ Final validation passed - saving booking');

        // บันทึกการจอง
        await _saveBooking(
          room,
          idNumber,
          practitioner,
          result.start,
          result.end,
        );
        await _updateRoomStatusForDate(_selectedDate);

        if (mounted) {
          _showSuccessDialog(room, practitioner, result.start, result.end);
        }
      } catch (e) {
        debugPrint('Error saving booking: $e');
        if (mounted) {
          _showErrorDialog('เกิดข้อผิดพลาดในการบันทึกการจอง: $e');
        }
      }
    }
  }

  /// ตรวจสอบความถูกต้องของช่วงวันที่การจองอย่างเคร่งครัด
  bool _validateBookingDateRange(
    DateTimeRange selectedRange,
    DateTime startDate,
    DateTime endDate,
  ) {
    debugPrint('🔍 Validating booking date range:');
    debugPrint('   Selected: ${selectedRange.start} - ${selectedRange.end}');
    debugPrint('   Registered: $startDate - $endDate');

    // แปลงเป็นวันที่เท่านั้น (ตัดเวลา) เพื่อเปรียบเทียบ
    final selectedStartDate = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final selectedEndDate = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
    );
    final registeredStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final registeredEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    // ตรวจสอบว่าวันเริ่มต้นต้องไม่ก่อนวันที่ลงทะเบียน
    final startValid =
        selectedStartDate.isAtSameMomentAs(registeredStartDate) ||
        selectedStartDate.isAfter(registeredStartDate);

    // ตรวจสอบว่าวันสิ้นสุดต้องไม่หลังวันที่ลงทะเบียน
    final endValid =
        selectedEndDate.isAtSameMomentAs(registeredEndDate) ||
        selectedEndDate.isBefore(registeredEndDate);

    // ตรวจสอบว่าวันเริ่มต้นไม่หลังวันสิ้นสุด
    final rangeValid =
        selectedStartDate.isBefore(selectedEndDate) ||
        _isSameDay(selectedStartDate, selectedEndDate);

    debugPrint(
      '   Start valid: $startValid, End valid: $endValid, Range valid: $rangeValid',
    );
    debugPrint('   Start check: $selectedStartDate >= $registeredStartDate');
    debugPrint('   End check: $selectedEndDate <= $registeredEndDate');

    return startValid && endValid && rangeValid;
  }

  /// สร้างข้อความ error ที่ชัดเจนสำหรับช่วงวันที่ที่ไม่ถูกต้อง
  String _getDateRangeErrorMessage(
    DateTimeRange selectedRange,
    DateTime startDate,
    DateTime endDate,
  ) {
    final selectedStart = _formatDate(selectedRange.start.toIso8601String());
    final selectedEnd = _formatDate(selectedRange.end.toIso8601String());
    final regStart = _formatDate(startDate.toIso8601String());
    final regEnd = _formatDate(endDate.toIso8601String());

    // แปลงเป็นวันที่เท่านั้น (ตัดเวลา) เพื่อเปรียบเทียบ
    final selectedStartDate = DateTime(
      selectedRange.start.year,
      selectedRange.start.month,
      selectedRange.start.day,
    );
    final selectedEndDate = DateTime(
      selectedRange.end.year,
      selectedRange.end.month,
      selectedRange.end.day,
    );
    final registeredStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final registeredEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    String errorMessage =
        '❌ **ไม่สามารถเลือกวันเกินช่วงที่ลงทะเบียนไว้ได้**\n\n';

    // ตรวจสอบว่าวันเริ่มต้นหรือวันสิ้นสุดที่เกิน
    if (selectedStartDate.isBefore(registeredStartDate)) {
      errorMessage +=
          '• วันเริ่มต้น ($selectedStart) ต้องไม่ก่อนวันที่ลงทะเบียน ($regStart)\n';
    }

    if (selectedEndDate.isAfter(registeredEndDate)) {
      errorMessage +=
          '• วันสิ้นสุด ($selectedEnd) ต้องไม่หลังวันที่ลงทะเบียน ($regEnd)\n';
    }

    errorMessage += '\n**ช่วงที่เลือก:** $selectedStart - $selectedEnd\n';
    errorMessage += '**ช่วงที่ลงทะเบียน:** $regStart - $regEnd\n\n';
    errorMessage += '⚠️ กรุณาเลือกวันที่ระหว่าง $regStart ถึง $regEnd เท่านั้น';

    return errorMessage;
  }

  Future<Map<String, dynamic>?> _getExistingBookingForDate(
    String idNumber,
    DateTime checkDate,
  ) async {
    final db = await _dbHelper.db;
    final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);

    final result = await db.rawQuery(
      '''
      SELECT rb.*, r.name as room_name 
      FROM room_bookings rb
      INNER JOIN rooms r ON rb.room_id = r.id
      WHERE rb.visitor_id = ? 
        AND rb.check_in_date <= ? 
        AND rb.check_out_date >= ?
        AND rb.status != ?
    ''',
      [idNumber, dateStr, dateStr, 'cancelled'],
    );

    return result.isNotEmpty ? result.first : null;
  }

  Future<void> _saveBooking(
    Room room,
    String idNumber,
    RegData practitioner,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) async {
    final db = await _dbHelper.db;
    final now = DateTime.now();
    final checkInStr = DateFormat('yyyy-MM-dd').format(checkInDate);
    final checkOutStr = DateFormat('yyyy-MM-dd').format(checkOutDate);

    await db.insert('room_bookings', {
      'room_id': room.id,
      'visitor_id': idNumber,
      'check_in_date': checkInStr,
      'check_out_date': checkOutStr,
      'status': 'confirmed',
      'note': 'จองผ่านระบบ',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ไม่สามารถจองได้'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(
    Room room,
    RegData practitioner,
    DateTime checkIn,
    DateTime checkOut,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('จองห้องสำเร็จ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ห้อง: ${room.name}'),
            Text('ผู้จอง: ${practitioner.first} ${practitioner.last}'),
            Text('วันที่เข้าพัก: ${_formatDate(checkIn.toIso8601String())}'),
            Text('วันที่ออก: ${_formatDate(checkOut.toIso8601String())}'),
            if (_isSameDay(checkIn, checkOut))
              const Text('(พัก 1 วัน)', style: TextStyle(color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🔄 Building accommodation screen - isLoading: $_isLoading, selectedMap: ${_selectedMap?.name}, rooms: ${_rooms.length}',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('จองที่พัก'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TestMapDisplayScreen()),
            ),
            tooltip: 'หน้าทดสอบแผนที่',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'คำแนะนำการใช้งาน',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showTestDataDialog(),
            tooltip: 'ทดสอบข้อมูล',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedMap == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีแผนที่และห้องพัก',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'กรุณาเลือกวิธีใดวิธีหนึ่งด้านล่าง\nเพื่อเริ่มใช้งานระบบจองที่พัก',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createTestMapAndRooms,
                    icon: const Icon(Icons.add_business),
                    label: const Text('สร้างข้อมูลทดสอบ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ใช้เมนู "จัดการแผนที่และห้องพัก"'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Date Picker
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'วันที่: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy', 'th').format(_selectedDate),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            locale: const Locale('th'),
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() => _selectedDate = picked);
                            await _updateRoomStatusForDate(picked);
                          }
                        },
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('เปลี่ยน'),
                      ),
                    ],
                  ),
                ),

                // Instructions and Legend
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'คำแนะนำ: คลิกเลือกห้องสีเขียวเพื่อจอง',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem(Colors.green, 'ห้องว่าง (คลิกได้)'),
                          _buildLegendItem(Colors.red, 'มีผู้เข้าพัก'),
                          _buildLegendItem(Colors.orange, 'จองแล้ว'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ห้องทั้งหมด: ${_rooms.length} ห้อง | '
                        'ห้องว่าง: ${_rooms.where((r) => r.status == RoomStatus.available).length} ห้อง',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Map
                Expanded(
                  child: Column(
                    children: [
                      // แผนที่จริง
                      Expanded(
                        child: MapViewer(
                          mapData: _selectedMap!,
                          rooms: _rooms,
                          onRoomTap: _onRoomTapped,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _createTestMapAndRooms() async {
    try {
      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังสร้างข้อมูลทดสอบ...'),
                ],
              ),
            ),
          ),
        ),
      );

      // สร้างข้อมูลทดสอบแผนที่และห้องพัก
      await _mapService.createTestData();

      // สร้างข้อมูลทดสอบผู้ปฏิบัติธรรม (เพื่อให้สามารถทดสอบการจองได้)
      await _dbHelper.createTestData();

      // ปิด loading dialog
      if (mounted) Navigator.pop(context);

      // รีโหลดข้อมูล
      await _loadMapAndRooms();

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สร้างข้อมูลทดสอบเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ปิด loading dialog หากยังเปิดอยู่
      if (mounted) Navigator.pop(context);

      // แสดงข้อความ error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      debugPrint('Error creating test data: $e');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('คำแนะนำการใช้งาน'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'วิธีการจองห้องพัก:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('1. เลือกวันที่ที่ต้องการจอง'),
              Text('2. คลิกที่ห้องสีเขียว (ห้องว่าง)'),
              Text('3. กรอกหมายเลขบัตรประชาชน 13 หลัก'),
              Text('4. ระบบจะตรวจสอบข้อมูลและบันทึกการจอง'),
              SizedBox(height: 16),
              Text(
                'เงื่อนไขการจอง:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• ต้องเป็นผู้ปฏิบัติธรรมที่ลงทะเบียนแล้ว'),
              Text('• ต้องอยู่ในช่วงเวลาเข้าพักที่กำหนด'),
              Text('• หนึ่งคนจองได้หนึ่งห้องต่อวัน'),
              Text('• ห้องสีแดงคือห้องที่มีผู้เข้าพักแล้ว'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('เข้าใจแล้ว'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// แสดง Dialog ทดสอบข้อมูล
  void _showTestDataDialog() async {
    try {
      final db = await _dbHelper.db;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // โหลดข้อมูลจากตาราง stays
      final stays = await db.query('stays', orderBy: 'created_at DESC');

      // โหลดข้อมูลจากตาราง regs
      final regs = await db.query(
        'regs',
        where: 'status = ?',
        whereArgs: ['A'],
      );

      // ทดสอบการเปรียบเทียบวันที่
      final testQuery = await db.rawQuery(
        '''
        SELECT s.*, r.first, r.last
        FROM stays s
        INNER JOIN regs r ON s.visitor_id = r.id
        WHERE r.status = 'A' AND s.status = 'active' AND DATE(s.start_date) <= ? AND DATE(s.end_date) >= ?
        ''',
        [dateStr, dateStr],
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ข้อมูลทดสอบ'),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📅 วันที่เลือก: $dateStr'),
                  Text('📊 จำนวน Stay Records: ${stays.length}'),
                  Text('👥 จำนวน Active Registrations: ${regs.length}'),
                  Text('✅ คนที่เข้าพักในวันที่เลือก: ${testQuery.length}'),
                  const SizedBox(height: 16),
                  const Text(
                    '🏠 ข้อมูล Stays:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (stays.isEmpty)
                    const Text(
                      'ไม่พบข้อมูลในตาราง stays',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...stays
                        .take(5)
                        .map(
                          (stay) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visitor ID: ${stay['visitor_id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Start: ${stay['start_date']}'),
                                Text('End: ${stay['end_date']}'),
                                Text('Status: ${stay['status']}'),
                              ],
                            ),
                          ),
                        ),
                  if (stays.length > 5)
                    Text(
                      '... และอีก ${stays.length - 5} รายการ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    '✅ คนที่เข้าพักในวันที่เลือก:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (testQuery.isEmpty)
                    const Text(
                      'ไม่พบคนที่เข้าพักในวันที่เลือก',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...testQuery.map(
                      (stay) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stay['first']} ${stay['last']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text('Start: ${stay['start_date']}'),
                            Text('End: ${stay['end_date']}'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing test data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
