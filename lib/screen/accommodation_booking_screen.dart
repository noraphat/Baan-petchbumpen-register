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
      _showRoomUnavailableDialog(room);
      return;
    }

    await _showBookingDialog(room);
  }

  void _showRoomUnavailableDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ห้อง ${room.name}'),
        content: Text(
          room.status == RoomStatus.occupied
              ? 'ห้องนี้มีผู้เข้าพักแล้วในวันที่เลือก'
              : 'ห้องนี้ไม่พร้อมให้บริการ',
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

  Future<void> _showBookingDialog(Room room) async {
    final idController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('จองห้อง ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'วันที่: ${DateFormat('dd/MM/yyyy', 'th').format(_selectedDate)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: 'หมายเลขบัตรประชาชน',
                hintText: 'กรอกหมายเลขบัตรประชาชน 13 หลัก',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 13,
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
              final idNumber = idController.text.trim();
              if (idNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกหมายเลขบัตรประชาชน')),
                );
                return;
              }

              if (idNumber.length != 13) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('หมายเลขบัตรประชาชนต้องมี 13 หลัก'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _processBooking(room, idNumber);
            },
            child: const Text('จองห้อง'),
          ),
        ],
      ),
    );
  }

  Future<void> _processBooking(Room room, String idNumber) async {
    try {
      // ตรวจสอบว่ามีผู้ปฏิบัติธรรมคนนี้หรือไม่
      final practitioner = await _getPractitionerById(idNumber);
      if (practitioner == null) {
        _showErrorDialog('ไม่พบข้อมูลผู้ปฏิบัติธรรมที่มีหมายเลขบัตรประชาชนนี้');
        return;
      }

      // ตรวจสอบว่ากำลังเข้าพักในช่วงเวลานี้หรือไม่
      final isCurrentlyStaying = await _isCurrentlyStaying(
        idNumber,
        _selectedDate,
      );
      if (!isCurrentlyStaying) {
        _showErrorDialog(
          'ผู้ปฏิบัติธรรมไม่ได้เข้าพักในช่วงวันที่นี้\nกรุณาตรวจสอบข้อมูลการลงทะเบียน',
        );
        return;
      }

      // ตรวจสอบว่าไม่ได้จองห้องอื่นในวันเดียวกันแล้ว
      final existingBooking = await _getExistingBookingForDate(
        idNumber,
        _selectedDate,
      );
      if (existingBooking != null) {
        _showErrorDialog(
          'ผู้ปฏิบัติธรรมมีการจองห้องอื่นในวันนี้แล้ว\nห้อง: ${existingBooking['room_name']}',
        );
        return;
      }

      // บันทึกการจอง
      await _saveBooking(room, idNumber, practitioner);

      // รีโหลดข้อมูลห้อง
      await _updateRoomStatusForDate(_selectedDate);

      _showSuccessDialog(room, practitioner);
    } catch (e) {
      debugPrint('Error processing booking: $e');
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

    // ตรวจสอบจาก reg_additional_info ว่ามีช่วงเวลาที่ครอบคลุมวันที่ตรวจสอบหรือไม่
    final result = await db.query(
      'reg_additional_info',
      where: 'regId = ? AND startDate <= ? AND endDate >= ?',
      whereArgs: [idNumber, dateStr, dateStr],
    );

    return result.isNotEmpty;
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
  ) async {
    final db = await _dbHelper.db;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    await db.insert('room_bookings', {
      'room_id': room.id,
      'visitor_id': idNumber,
      'check_in_date': dateStr,
      'check_out_date': dateStr, // จองเป็นรายวัน
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

  void _showSuccessDialog(Room room, RegData practitioner) {
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
            Text(
              'วันที่: ${DateFormat('dd/MM/yyyy', 'th').format(_selectedDate)}',
            ),
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
                      // Debug info (เฉพาะ debug mode)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.yellow[100],
                        child: Text(
                          'Debug: แผนที่="${_selectedMap?.name}", รูปภาพ=${_selectedMap?.hasImage}, ห้อง=${_rooms.length}ห้อง',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
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
}
