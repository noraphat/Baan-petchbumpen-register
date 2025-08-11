import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../services/menu_settings_service.dart';
import '../models/room_model.dart';

/// หน้าจอสรุปผลประจำวันสำหรับห้องพัก
class RoomUsageSummaryScreen extends StatefulWidget {
  const RoomUsageSummaryScreen({Key? key}) : super(key: key);

  @override
  _RoomUsageSummaryScreenState createState() => _RoomUsageSummaryScreenState();
}

class _RoomUsageSummaryScreenState extends State<RoomUsageSummaryScreen> {
  final BookingService _bookingService = BookingService();
  final MenuSettingsService _menuSettings = MenuSettingsService();
  List<RoomUsageSummary> _summaryData = [];
  bool _isLoading = false;
  bool _isBookingMenuEnabled = false;
  String _selectedPeriod = 'วันนี้';
  DateTime _customStartDate = DateTime.now();
  DateTime _customEndDate = DateTime.now();
  bool _isCustomPeriod = false;

  // ตัวเลือกช่วงเวลา
  final List<String> _periodOptions = [
    'วันนี้',
    'วันที่ผ่านมา',
    'สัปดาห์นี้',
    'เดือนนี้',
    '3 เดือนย้อนหลัง',
    '6 เดือนย้อนหลัง',
    '1 ปีย้อนหลัง',
    'กำหนดช่วงเอง',
  ];

  @override
  void initState() {
    super.initState();
    _loadMenuSettings();
    _loadData();
  }

  /// โหลดการตั้งค่าเมนู
  Future<void> _loadMenuSettings() async {
    try {
      final isBookingEnabled = await _menuSettings.isBookingEnabled;
      setState(() {
        _isBookingMenuEnabled = isBookingEnabled;
      });
    } catch (e) {
      debugPrint('❌ Failed to load menu settings: $e');
    }
  }

  /// โหลดข้อมูลสรุปการใช้งานห้อง
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dateRange = _getDateRange();
      final summaryData = await _bookingService.getRoomUsageSummary(
        startDate: dateRange.start,
        endDate: dateRange.end,
      );

      setState(() {
        _summaryData = summaryData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  /// คำนวณช่วงวันที่ตามตัวเลือกที่เลือก
  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedPeriod) {
      case 'วันนี้':
        return DateTimeRange(start: today, end: today);
      case 'วันที่ผ่านมา':
        final yesterday = today.subtract(Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      case 'สัปดาห์นี้':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return DateTimeRange(start: weekStart, end: today);
      case 'เดือนนี้':
        final monthStart = DateTime(today.year, today.month, 1);
        return DateTimeRange(start: monthStart, end: today);
      case '3 เดือนย้อนหลัง':
        final threeMonthsAgo = DateTime(today.year, today.month - 3, today.day);
        return DateTimeRange(start: threeMonthsAgo, end: today);
      case '6 เดือนย้อนหลัง':
        final sixMonthsAgo = DateTime(today.year, today.month - 6, today.day);
        return DateTimeRange(start: sixMonthsAgo, end: today);
      case '1 ปีย้อนหลัง':
        final oneYearAgo = DateTime(today.year - 1, today.month, today.day);
        return DateTimeRange(start: oneYearAgo, end: today);
      case 'กำหนดช่วงเอง':
        return DateTimeRange(start: _customStartDate, end: _customEndDate);
      default:
        return DateTimeRange(start: today, end: today);
    }
  }

  /// แสดง DatePicker สำหรับเลือกช่วงเวลาแบบกำหนดเอง
  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _customStartDate,
        end: _customEndDate,
      ),
      locale: const Locale('th'),
      helpText: 'เลือกช่วงเวลา',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _isCustomPeriod = true;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สรุปผลประจำวัน - ห้องพัก'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: Column(
        children: [
          // แสดงข้อความเตือนหากเมนู "จองห้องพัก" ถูกปิด
          if (!_isBookingMenuEnabled) _buildBookingMenuDisabledWarning(),

          // ส่วนเลือกช่วงเวลา
          _buildPeriodSelector(),

          // ส่วนแสดงข้อมูลสรุป
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : !_isBookingMenuEnabled
                ? _buildBookingDisabledState()
                : _summaryData.isEmpty
                ? _buildEmptyState()
                : _buildSummaryTable(),
          ),
        ],
      ),
    );
  }

  /// สร้าง Widget สำหรับเลือกช่วงเวลา
  Widget _buildPeriodSelector() {
    final dateRange = _getDateRange();
    final isCustom = _selectedPeriod == 'กำหนดช่วงเอง';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกช่วงเวลา',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),

          // Dropdown สำหรับเลือกช่วงเวลา
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPeriod,
                onChanged: (String? newValue) async {
                  setState(() {
                    _selectedPeriod = newValue!;
                  });

                  if (newValue == 'กำหนดช่วงเอง') {
                    await _showCustomDatePicker();
                  } else {
                    await _loadData();
                  }
                },
                items: _periodOptions.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(value),
                    ),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
          ),

          SizedBox(height: 12),

          // แสดงช่วงเวลาที่เลือก
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Colors.blue[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCustom && _isCustomPeriod
                        ? 'ช่วงเวลา: ${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}'
                        : 'ช่วงเวลา: ${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
                    style: TextStyle(color: Colors.blue[800], fontSize: 14),
                  ),
                ),
                if (isCustom)
                  TextButton(
                    onPressed: _showCustomDatePicker,
                    child: Text('เปลี่ยน'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// สร้างตารางแสดงข้อมูลสรุป
  Widget _buildSummaryTable() {
    final isSingleDay =
        _summaryData.isNotEmpty && _summaryData.first.isSingleDay;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.green[700]),
              SizedBox(width: 8),
              Text(
                isSingleDay ? 'สถานะห้องพักรายวัน' : 'จำนวนวันที่ใช้งาน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Spacer(),
              Text(
                'ทั้งหมด ${_summaryData.length} ห้อง',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),

          SizedBox(height: 16),

          // ตาราง
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                  columns: _buildTableColumns(isSingleDay),
                  rows: _summaryData
                      .map((summary) => _buildTableRow(summary, isSingleDay))
                      .toList(),
                ),
              ),
            ),
          ),

          if (!isSingleDay) ...[SizedBox(height: 16), _buildUsageStatistics()],
        ],
      ),
    );
  }

  /// สร้างคอลัมน์ของตาราง
  List<DataColumn> _buildTableColumns(bool isSingleDay) {
    if (isSingleDay) {
      return [
        DataColumn(
          label: Text('ห้องพัก', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('ขนาด', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'ผู้เข้าพัก',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ];
    } else {
      return [
        DataColumn(
          label: Text('ห้องพัก', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text('ขนาด', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataColumn(
          label: Text(
            'วันที่ใช้งาน',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          numeric: true,
        ),
        DataColumn(
          label: Text(
            'อัตราการใช้งาน',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ];
    }
  }

  /// สร้างแถวของตาราง
  DataRow _buildTableRow(RoomUsageSummary summary, bool isSingleDay) {
    if (isSingleDay) {
      Color statusColor = _getStatusColor(summary.dailyStatus);

      return DataRow(
        cells: [
          DataCell(
            Text(
              summary.roomName,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(Text(summary.roomSize)),
          DataCell(
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                summary.dailyStatus,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          DataCell(
            Text(
              summary.guestName.isEmpty ? '-' : summary.guestName,
              style: TextStyle(
                color: summary.guestName.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      );
    } else {
      final dateRange = _getDateRange();
      final totalDays = dateRange.end.difference(dateRange.start).inDays + 1;
      final usagePercentage = totalDays > 0
          ? (summary.usageDays / totalDays * 100).round()
          : 0;

      return DataRow(
        cells: [
          DataCell(
            Text(
              summary.roomName,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          DataCell(Text(summary.roomSize)),
          DataCell(
            Text(
              '${summary.usageDays} วัน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: summary.usageDays > 0
                    ? Colors.green[700]
                    : Colors.grey[600],
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: usagePercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getUsageColor(usagePercentage),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '$usagePercentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  /// สร้างสถิติการใช้งาน
  Widget _buildUsageStatistics() {
    final dateRange = _getDateRange();
    final totalDays = dateRange.end.difference(dateRange.start).inDays + 1;
    final totalRooms = _summaryData.length;
    final occupiedRooms = _summaryData.where((s) => s.usageDays > 0).length;
    final totalUsageDays = _summaryData.fold<int>(
      0,
      (sum, s) => sum + s.usageDays,
    );
    final averageUsage = totalRooms > 0
        ? (totalUsageDays / (totalRooms * totalDays) * 100).round()
        : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.orange[700]),
              SizedBox(width: 8),
              Text(
                'สถิติการใช้งาน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'ห้องที่มีการใช้งาน',
                  '$occupiedRooms/$totalRooms ห้อง',
                  Colors.green,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'อัตราการใช้งานเฉลี่ย',
                  '$averageUsage%',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// สร้างการ์ดสถิติ
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// สร้าง Widget เตือนเมื่อเมนู "จองห้องพัก" ถูกปิด
  Widget _buildBookingMenuDisabledWarning() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เมนู "จองห้องพัก" ถูกปิด',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ข้อมูลห้องพักอาจไม่สมบูรณ์ เนื่องจากฟีเจอร์การจองห้องไม่ได้เปิดใช้งาน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// สร้างหน้าจอเมื่อเมนู "จองห้องพัก" ถูกปิด
  Widget _buildBookingDisabledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 64, color: Colors.orange[600]),
          SizedBox(height: 16),
          Text(
            'Tab ห้องพักไม่พร้อมใช้งาน',
            style: TextStyle(
              fontSize: 18,
              color: Colors.orange[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'เมนู "จองห้องพัก" ถูกปิดใช้งาน\nกรุณาเปิดใช้งานเมนู "จองห้องพัก" ก่อนเข้าใช้หน้านี้',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('กลับไปหน้าเมนู'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// สร้างหน้าจอเมื่อไม่มีข้อมูล
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'ไม่พบข้อมูลห้องพัก',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'กรุณาตรวจสอบการตั้งค่าหรือเพิ่มข้อมูลห้องพัก',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ได้สีตามสถานะ
  Color _getStatusColor(String status) {
    switch (status) {
      case 'จองแล้ว':
        return Colors.orange[700]!;
      case 'มีผู้เข้าพัก':
        return Colors.red[700]!;
      case 'ว่าง':
        return Colors.green[700]!;
      case 'ปิดปรับปรุง':
        return Colors.grey[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// ได้สีตามอัตราการใช้งาน
  Color _getUsageColor(int percentage) {
    if (percentage >= 80) return Colors.red[600]!;
    if (percentage >= 60) return Colors.orange[600]!;
    if (percentage >= 40) return Colors.yellow[700]!;
    if (percentage >= 20) return Colors.lightGreen[600]!;
    return Colors.green[600]!;
  }
}
