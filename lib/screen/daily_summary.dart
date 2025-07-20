import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/summary_service.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  final SummaryService _summaryService = SummaryService();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'today'; // today, week, month, 3months, 6months, year, custom
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  DailySummary? _dailySummary;
  PeriodSummary? _periodSummary;
  RepeatVisitorStats? _repeatStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      if (_selectedPeriod == 'today') {
        _dailySummary = await _summaryService.getDailySummary(date: _selectedDate);
      } else {
        final DateRange range = _getDateRange();
        _periodSummary = await _summaryService.getPeriodSummary(
          startDate: range.start,
          endDate: range.end,
        );
        _repeatStats = await _summaryService.getRepeatVisitorStats(
          startDate: range.start,
          endDate: range.end,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(start, start.add(const Duration(days: 6)));
      case 'month':
        return DateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
      case '3months':
        return DateRange(DateTime(now.year, now.month - 2, 1), now);
      case '6months':
        return DateRange(DateTime(now.year, now.month - 5, 1), now);
      case 'year':
        return DateRange(DateTime(now.year - 1, now.month, now.day), now);
      case 'custom':
        return DateRange(_customStartDate ?? now, _customEndDate ?? now);
      default:
        return DateRange(now, now);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('สรุปผลประจำวัน'),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            onSelected: _exportReport,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pdf', child: Text('ส่งออก PDF')),
              const PopupMenuItem(value: 'excel', child: Text('ส่งออก Excel')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedPeriod == 'today'
                    ? _buildDailyView()
                    : _buildPeriodView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                    _loadData();
                  },
                  items: const [
                    DropdownMenuItem(value: 'today', child: Text('วันนี้')),
                    DropdownMenuItem(value: 'week', child: Text('สัปดาห์นี้')),
                    DropdownMenuItem(value: 'month', child: Text('เดือนนี้')),
                    DropdownMenuItem(value: '3months', child: Text('3 เดือนย้อนหลัง')),
                    DropdownMenuItem(value: '6months', child: Text('6 เดือนย้อนหลัง')),
                    DropdownMenuItem(value: 'year', child: Text('1 ปีย้อนหลัง')),
                    DropdownMenuItem(value: 'custom', child: Text('กำหนดช่วงเอง')),
                  ],
                ),
              ),
              if (_selectedPeriod == 'today') ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDate,
                ),
              ],
            ],
          ),
          if (_selectedPeriod == 'custom') _buildCustomDatePicker(),
        ],
      ),
    );
  }

  Widget _buildCustomDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _selectCustomDate(true),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _customStartDate != null
                      ? DateFormat('dd/MM/yyyy').format(_customStartDate!)
                      : 'เลือกวันเริ่มต้น',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => _selectCustomDate(false),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _customEndDate != null
                      ? DateFormat('dd/MM/yyyy').format(_customEndDate!)
                      : 'เลือกวันสิ้นสุด',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _customStartDate != null && _customEndDate != null
                ? _loadData
                : null,
            child: const Text('แสดงผล'),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyView() {
    if (_dailySummary == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          const SizedBox(height: 16),
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildGenderBreakdown(),
          const SizedBox(height: 24),
          _buildEquipmentSummary(),
          const SizedBox(height: 24),
          _buildChildrenInfo(),
          const SizedBox(height: 16),
          _buildTotalSummaryRow(),
        ],
      ),
    );
  }

  Widget _buildPeriodView() {
    if (_periodSummary == null) return const Center(child: Text('ไม่มีข้อมูล'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 16),
          _buildPeriodOverview(),
          const SizedBox(height: 24),
          _buildPeriodGenderBreakdown(),
          const SizedBox(height: 24),
          _buildPeriodEquipmentSummary(),
          const SizedBox(height: 24),
          _buildLongStaysInfo(),
          const SizedBox(height: 24),
          _buildRepeatVisitorInfo(),
          const SizedBox(height: 24),
          _buildTopProvinces(),
          const SizedBox(height: 24),
          _buildDailyTrend(),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.today, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สรุปผลประจำวัน',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('วันEEEE ที่ dd MMMM yyyy', 'th').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    final range = _getDateRange();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'สรุปผลช่วงเวลา',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${DateFormat('dd/MM/yyyy').format(range.start)} - ${DateFormat('dd/MM/yyyy').format(range.end)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'ผู้เข้าพักทั้งหมด',
            _dailySummary!.totalActiveStays.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'ลงทะเบียนใหม่',
            _dailySummary!.totalNewRegistrations.toString(),
            Icons.person_add,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'เช็คเอาท์วันนี้',
            _dailySummary!.totalCheckouts.toString(),
            Icons.exit_to_app,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodOverview() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'ผู้เข้าพักทั้งหมด',
                _periodSummary!.totalStaysByGender.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'ลงทะเบียนใหม่',
                _periodSummary!.totalNewRegistrations.toString(),
                Icons.person_add,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'ระยะเวลาเฉลี่ย',
                '${_periodSummary!.averageStayDuration.toStringAsFixed(1)} วัน',
                Icons.access_time,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBreakdown() {
    return _buildSection(
      'แยกตามเพศ',
      Icons.people_alt,
      Column(
        children: [
          _buildGenderRow('ผู้เข้าพักทั้งหมด', _dailySummary!.activeStaysByGender),
          const Divider(),
          _buildGenderRow('ลงทะเบียนใหม่', _dailySummary!.newRegistrationsByGender),
          const Divider(),
          _buildGenderRow('เช็คเอาท์วันนี้', _dailySummary!.checkoutsByGender),
        ],
      ),
    );
  }

  Widget _buildGenderRow(String title, Map<String, int> genderCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genderCounts.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGenderColor(entry.key).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getGenderColor(entry.key)),
              ),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  color: _getGenderColor(entry.key),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender) {
      case 'พระ':
        return Colors.orange;
      case 'สามเณร':
        return Colors.amber;
      case 'แม่ชี':
        return Colors.pink;
      case 'ชาย':
        return Colors.blue;
      case 'หญิง':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEquipmentSummary() {
    final equipment = _dailySummary!.equipmentSummary;
    return _buildSection(
      'สรุปอุปกรณ์ที่แจกจ่าย (วันนี้)',
      Icons.inventory,
      Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildEquipmentChip('เสื้อขาว', equipment.totalShirts, Icons.checkroom),
              _buildEquipmentChip('กางเกงขาว', equipment.totalPants, Icons.checkroom_outlined),
              _buildEquipmentChip('เสื่อ', equipment.totalMats, Icons.bed),
              _buildEquipmentChip('หมอน', equipment.totalPillows, Icons.airline_seat_individual_suite),
              _buildEquipmentChip('ผ้าห่ม', equipment.totalBlankets, Icons.hotel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'รวมอุปกรณ์ที่แจกจ่ายวันนี้: ${equipment.totalShirts + equipment.totalPants + equipment.totalMats + equipment.totalPillows + equipment.totalBlankets} ชิ้น',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentChip(String name, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$name: $count',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenInfo() {
    final children = _dailySummary!.childrenInfo;
    return _buildSection(
      'ข้อมูลเด็ก',
      Icons.family_restroom,
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'ครอบครวที่มาพร้อมเด็ก',
              children.familiesWithChildren.toString(),
              Icons.family_restroom,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'จำนวนเด็กทั้งหมด',
              children.totalChildren.toString(),
              Icons.child_care,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // สำหรับ Period View
  Widget _buildPeriodGenderBreakdown() {
    return _buildSection(
      'แยกตามเพศ (ช่วงเวลาที่เลือก)',
      Icons.people_alt,
      Column(
        children: [
          _buildGenderRow('ผู้เข้าพักในช่วงเวลา', _periodSummary!.staysByGender),
          const Divider(),
          _buildGenderRow('ผู้ลงทะเบียนใหม่ในช่วงเวลา', _periodSummary!.newRegistrationsByGender),
          const SizedBox(height: 16),
          _buildTotalSummaryRow(),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'รวมผู้เข้าพัก',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedPeriod == 'today'
                    ? _dailySummary!.totalActiveStays.toString()
                    : _periodSummary!.totalStaysByGender.toString(),
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                'คน',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.purple.withValues(alpha: 0.3),
          ),
          Column(
            children: [
              Text(
                'รวมลงทะเบียนใหม่',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedPeriod == 'today'
                    ? _dailySummary!.totalNewRegistrations.toString()
                    : _periodSummary!.totalNewRegistrations.toString(),
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                'คน',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodEquipmentSummary() {
    final equipment = _periodSummary!.equipmentSummary;
    return _buildSection(
      'สรุปอุปกรณ์ที่ยืมในช่วงเวลา',
      Icons.inventory,
      Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildEquipmentChip('เสื้อขาว', equipment.totalShirts, Icons.checkroom),
              _buildEquipmentChip('กางเกงขาว', equipment.totalPants, Icons.checkroom_outlined),
              _buildEquipmentChip('เสื่อ', equipment.totalMats, Icons.bed),
              _buildEquipmentChip('หมอน', equipment.totalPillows, Icons.airline_seat_individual_suite),
              _buildEquipmentChip('ผ้าห้ม', equipment.totalBlankets, Icons.hotel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'รวมอุปกรณ์ที่ยืมทั้งหมด: ${equipment.totalShirts + equipment.totalPants + equipment.totalMats + equipment.totalPillows + equipment.totalBlankets} ชิ้น',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLongStaysInfo() {
    final longStays = _periodSummary!.longStaysSummary;
    return _buildSection(
      'ผู้เข้าพักระยะยาว',
      Icons.hotel,
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'มากกว่า 7 วัน',
              longStays.moreThan7Days.toString(),
              Icons.calendar_view_week,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'มากกว่า 14 วัน',
              longStays.moreThan14Days.toString(),
              Icons.calendar_view_month,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'มากกว่า 30 วัน',
              longStays.moreThan30Days.toString(),
              Icons.calendar_today,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatVisitorInfo() {
    if (_repeatStats == null) return const SizedBox();
    
    return _buildSection(
      'อัตราการกลับมาเข้าพักซ้ำ',
      Icons.refresh,
      Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'ผู้เข้าปฏิบัติธรรมทั้งหมด',
              _repeatStats!.totalVisitors.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'ผู้กลับมาซ้ำ',
              _repeatStats!.repeatVisitors.toString(),
              Icons.repeat,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'อัตราการกลับมา',
              '${_repeatStats!.repeatRate.toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProvinces() {
    return _buildSection(
      'จังหวัดที่มีผู้เข้าพักมากที่สุด',
      Icons.location_on,
      Column(
        children: _periodSummary!.topProvinces.take(5).map((province) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              child: Text(
                province.count.toString(),
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(province.province),
            trailing: Text(
              '${province.count} คน',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyTrend() {
    return _buildSection(
      'แนวโน้มรายวัน',
      Icons.trending_up,
      SizedBox(
        height: 200,
        child: _periodSummary!.dailyTrend.isEmpty
            ? const Center(child: Text('ไม่มีข้อมูลแนวโน้ม'))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _periodSummary!.dailyTrend.length,
                itemBuilder: (context, index) {
                  final point = _periodSummary!.dailyTrend[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: (point.checkins / (_periodSummary!.dailyTrend
                                  .map((p) => p.checkins)
                                  .reduce((a, b) => a > b ? a : b))) * 150,
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM').format(point.date),
                          style: const TextStyle(fontSize: 10),
                        ),
                        Text(
                          point.checkins.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadData();
    }
  }

  Future<void> _selectCustomDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _customStartDate ?? DateTime.now() : _customEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );
    
    if (date != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = date;
        } else {
          _customEndDate = date;
        }
      });
    }
  }

  void _exportReport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ส่งออกรายงาน $format - ฟีเจอร์นี้จะพร้อมในเวอร์ชันถัดไป'),
      ),
    );
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}