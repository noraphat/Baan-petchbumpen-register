import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../models/reg_data.dart';

/// Widget สำหรับแสดงข้อมูลการจองห้องพักแยกจากการลงทะเบียน
class BookingInfoWidget extends StatefulWidget {
  final String visitorId;
  final RegAdditionalInfo? practiceInfo;
  final VoidCallback? onBookingUpdated;

  const BookingInfoWidget({
    Key? key,
    required this.visitorId,
    this.practiceInfo,
    this.onBookingUpdated,
  }) : super(key: key);

  @override
  _BookingInfoWidgetState createState() => _BookingInfoWidgetState();
}

class _BookingInfoWidgetState extends State<BookingInfoWidget> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _roomBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoomBookings();
  }

  Future<void> _loadRoomBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ดึงข้อมูลการจองห้องพักทั้งหมดของผู้ปฏิบัติธรรม
      final db = await _bookingService.dbHelper.db;
      final result = await db.rawQuery(
        '''
        SELECT rb.*, r.name as room_name
        FROM room_bookings rb
        JOIN rooms r ON rb.room_id = r.id
        WHERE rb.visitor_id = ? AND rb.status != 'cancelled'
        ORDER BY rb.check_in_date DESC
      ''',
        [widget.visitorId],
      );

      setState(() {
        _roomBookings = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการโหลดข้อมูลการจอง: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // หัวข้อ
            Row(
              children: [
                Icon(Icons.hotel, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'ข้อมูลการจองห้องพัก',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _loadRoomBookings,
                  tooltip: 'รีเฟรชข้อมูล',
                ),
              ],
            ),

            SizedBox(height: 12),

            // ข้อมูลช่วงเวลาปฏิบัติธรรม
            if (widget.practiceInfo != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ช่วงเวลาปฏิบัติธรรม',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(widget.practiceInfo!.startDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.practiceInfo!.endDate!)}',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ไม่เปลี่ยนแปลง',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // รายการการจองห้องพัก
            Text(
              'การจองห้องพัก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_roomBookings.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'ยังไม่มีการจองห้องพัก',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              ..._roomBookings
                  .map((booking) => _buildBookingCard(booking))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final checkInDate = DateTime.parse(booking['check_in_date']);
    final checkOutDate = DateTime.parse(booking['check_out_date']);
    final roomName = booking['room_name'] ?? 'ไม่ระบุ';
    final bookingId = booking['id'];

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.room, color: Colors.blue[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ห้อง $roomName',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBookingAction(value, booking),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('แก้ไขวันที่'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'ยกเลิกการจอง',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(Icons.more_vert),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(checkInDate)} - ${DateFormat('dd/MM/yyyy').format(checkOutDate)}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.hotel, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'จำนวน ${checkOutDate.difference(checkInDate).inDays + 1} คืน',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookingAction(String action, Map<String, dynamic> booking) async {
    if (action == 'edit') {
      await _showEditBookingDialog(booking);
    } else if (action == 'cancel') {
      await _showCancelBookingDialog(booking);
    }
  }

  Future<void> _showEditBookingDialog(Map<String, dynamic> booking) async {
    final checkInDate = DateTime.parse(booking['check_in_date']);
    final checkOutDate = DateTime.parse(booking['check_out_date']);
    final roomName = booking['room_name'] ?? 'ไม่ระบุ';
    final bookingId = booking['id'];

    DateTime? newCheckOutDate = checkOutDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขวันที่ออก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ห้อง: $roomName'),
            Text('วันที่เข้า: ${DateFormat('dd/MM/yyyy').format(checkInDate)}'),
            SizedBox(height: 16),
            Text('เลือกวันที่ออกใหม่:'),
            SizedBox(height: 8),
            CalendarDatePicker(
              initialDate: checkOutDate,
              firstDate: checkInDate,
              lastDate:
                  widget.practiceInfo?.endDate ??
                  DateTime.now().add(Duration(days: 365)),
              onDateChanged: (date) {
                newCheckOutDate = date;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newCheckOutDate != null) {
                Navigator.of(context).pop();
                await _updateBookingCheckOut(bookingId, newCheckOutDate!);
              }
            },
            child: Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelBookingDialog(Map<String, dynamic> booking) async {
    final roomName = booking['room_name'] ?? 'ไม่ระบุ';
    final checkInDate = DateTime.parse(booking['check_in_date']);
    final checkOutDate = DateTime.parse(booking['check_out_date']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการยกเลิก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการยกเลิกการจองห้อง $roomName หรือไม่?'),
            SizedBox(height: 8),
            Text(
              'วันที่: ${DateFormat('dd/MM/yyyy').format(checkInDate)} - ${DateFormat('dd/MM/yyyy').format(checkOutDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'หมายเหตุ: การยกเลิกการจองห้องจะไม่กระทบช่วงเวลาปฏิบัติธรรม',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelBooking(booking['id']);
    }
  }

  Future<void> _updateBookingCheckOut(
    int bookingId,
    DateTime newCheckOutDate,
  ) async {
    try {
      final success = await _bookingService.updateRoomBookingCheckOut(
        bookingId: bookingId,
        newCheckOutDate: newCheckOutDate,
        visitorId: widget.visitorId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัพเดตการจองห้องพักสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadRoomBookings();
        widget.onBookingUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัพเดตการจอง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      final db = await _bookingService.dbHelper.db;
      await db.update(
        'room_bookings',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [bookingId],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ยกเลิกการจองห้องพักสำเร็จ'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadRoomBookings();
      widget.onBookingUpdated?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการยกเลิกการจอง: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
