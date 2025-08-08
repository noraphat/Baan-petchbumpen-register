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

    // ตรวจสอบว่าผู้ปฏิบัติธรรมเข้าพักมาแล้วหรือไม่
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final hasCheckedIn =
        todayOnly.isAfter(checkInDate) ||
        todayOnly.isAtSameMomentAs(checkInDate);

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
                // แสดงสถานะการเข้าพัก
                if (hasCheckedIn)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'เข้าพักแล้ว',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'รอเข้าพัก',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBookingAction(value, booking),
                  itemBuilder: (context) => _buildMenuItems(hasCheckedIn),
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

  List<PopupMenuEntry<String>> _buildMenuItems(bool hasCheckedIn) {
    if (hasCheckedIn) {
      // ถ้าเข้าพักแล้ว ให้เมนูปรับปรุงวันที่เท่านั้น
      return [
        PopupMenuItem(
          value: 'edit_dates',
          child: Row(
            children: [
              Icon(Icons.edit_calendar, size: 18, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'ปรับปรุงวันที่เข้าพัก',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('แก้ไขวันที่ออก'),
            ],
          ),
        ),
      ];
    } else {
      // ถ้ายังไม่เข้าพัก ให้เมนูแก้ไขและยกเลิกได้
      return [
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
              Text('ยกเลิกการจอง', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ];
    }
  }

  void _handleBookingAction(String action, Map<String, dynamic> booking) async {
    if (action == 'edit') {
      await _showEditBookingDialog(booking);
    } else if (action == 'edit_dates') {
      await _showEditDatesDialog(booking);
    } else if (action == 'cancel') {
      await _showCancelBookingDialog(booking);
    }
  }

  Future<void> _showEditDatesDialog(Map<String, dynamic> booking) async {
    final checkInDate = DateTime.parse(booking['check_in_date']);
    final checkOutDate = DateTime.parse(booking['check_out_date']);
    final roomName = booking['room_name'] ?? 'ไม่ระบุ';
    final bookingId = booking['id'];

    DateTime? newCheckInDate = checkInDate;
    DateTime? newCheckOutDate = checkOutDate;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('ปรับปรุงวันที่เข้าพัก'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ห้อง: $roomName'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ข้อกำหนด:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• วันที่เข้าพักต้องไม่น้อยกว่าวันปัจจุบัน\n• ต้องอยู่ในช่วงเวลาปฏิบัติธรรม\n• ไม่ขัดแย้งกับการจองอื่น',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text('เลือกวันที่เข้าใหม่:'),
                SizedBox(height: 8),
                CalendarDatePicker(
                  initialDate: newCheckInDate ?? todayOnly,
                  firstDate: todayOnly,
                  lastDate:
                      widget.practiceInfo?.endDate ??
                      DateTime.now().add(Duration(days: 365)),
                  onDateChanged: (date) {
                    setState(() {
                      newCheckInDate = date;
                      // ถ้าวันที่ออกน้อยกว่าวันที่เข้าใหม่ ให้ปรับวันที่ออก
                      if (newCheckOutDate != null &&
                          newCheckOutDate!.isBefore(date)) {
                        newCheckOutDate = date.add(Duration(days: 1));
                      }
                    });
                  },
                ),
                SizedBox(height: 16),
                Text('เลือกวันที่ออกใหม่:'),
                SizedBox(height: 8),
                CalendarDatePicker(
                  initialDate:
                      newCheckOutDate ??
                      (newCheckInDate?.add(Duration(days: 1)) ??
                          todayOnly.add(Duration(days: 1))),
                  firstDate: (newCheckInDate ?? todayOnly).add(
                    Duration(days: 1),
                  ),
                  lastDate:
                      widget.practiceInfo?.endDate ??
                      DateTime.now().add(Duration(days: 365)),
                  onDateChanged: (date) {
                    setState(() {
                      newCheckOutDate = date;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newCheckInDate != null && newCheckOutDate != null) {
                  Navigator.of(context).pop();
                  await _updateBookingDates(
                    bookingId,
                    newCheckInDate!,
                    newCheckOutDate!,
                  );
                }
              },
              child: Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
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
    final bookingId = booking['id'];

    // ตรวจสอบว่าสามารถยกเลิกได้หรือไม่
    final validation = await _bookingService.canCancelBooking(
      bookingId: bookingId,
      visitorId: widget.visitorId,
    );

    if (!mounted) return;

    if (!validation) {
      // แสดงข้อความ error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ไม่สามารถยกเลิกการจองได้ อนุญาตให้ยกเลิกได้เฉพาะวันที่เช็คอินเท่านั้น',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

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
      await _cancelBooking(bookingId);
    }
  }

  Future<void> _updateBookingDates(
    int bookingId,
    DateTime newCheckInDate,
    DateTime newCheckOutDate,
  ) async {
    try {
      final validation = await _bookingService
          .updateRoomBookingDatesWithValidation(
            bookingId: bookingId,
            newCheckInDate: newCheckInDate,
            newCheckOutDate: newCheckOutDate,
            visitorId: widget.visitorId,
          );

      if (!mounted) return;

      if (validation) {
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
            content: Text('ไม่สามารถอัพเดตได้ เนื่องจากมีช่วงเวลาซ้อนทับ'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

      if (!mounted) return;

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
      if (!mounted) return;
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
      final success = await _bookingService.cancelBooking(
        bookingId: bookingId,
        visitorId: widget.visitorId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยกเลิกการจองห้องพักสำเร็จ'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadRoomBookings();
        widget.onBookingUpdated?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถยกเลิกการจองได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการยกเลิกการจอง: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
