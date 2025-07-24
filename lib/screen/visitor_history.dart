import 'package:flutter/material.dart';
import '../models/reg_data.dart';
import '../services/db_helper.dart';

class VisitorHistoryScreen extends StatefulWidget {
  final RegData visitor;

  const VisitorHistoryScreen({super.key, required this.visitor});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  List<StayRecord> _allStays = [];
  List<StayRecord> _displayedStays = [];
  List<RegAdditionalInfo> _additionalInfos = [];
  
  bool _isLoading = true;
  
  // Pagination
  final int _itemsPerPage = 10;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadStayHistory();
  }

  Future<void> _loadStayHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DbHelper();
      
      // ดึงประวัติการเข้าพักทั้งหมด และเรียงจากใหม่ไปเก่า
      final stays = await dbHelper.fetchAllStays(widget.visitor.id);
      stays.sort((a, b) => b.startDate.compareTo(a.startDate)); // เรียงจากใหม่ไปเก่า (DESC)
      
      // ดึงข้อมูลเพิ่มเติม (equipment และ location) ของแต่ละครั้ง
      List<RegAdditionalInfo> additionalInfos = [];
      for (final stay in stays) {
        final info = await dbHelper.fetchAdditionalInfo(stay.visitorId);
        if (info != null) {
          additionalInfos.add(info);
        }
      }
      
      setState(() {
        _allStays = stays;
        _additionalInfos = additionalInfos;
        _totalPages = (_allStays.length / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        _updateDisplayedStays();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  void _updateDisplayedStays() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _allStays.length);
    
    setState(() {
      _displayedStays = _allStays.sublist(startIndex, endIndex);
    });
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _updateDisplayedStays();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  RegAdditionalInfo? _findAdditionalInfo(String visitorId) {
    try {
      return _additionalInfos.firstWhere((info) => info.regId == visitorId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประวัติการมาปฏิบัติธรรม'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ข้อมูลผู้ปฏิบัติธรรม
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple[100],
                      child: Icon(
                        Icons.person,
                        color: Colors.purple[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.visitor.first} ${widget.visitor.last}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'มาปฏิบัติธรรมทั้งหมด ${_allStays.length} ครั้ง',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // รายการประวัติ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allStays.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ยังไม่มีประวัติการมาปฏิบัติธรรม',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // รายการ
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _displayedStays.length,
                              itemBuilder: (context, index) {
                                final stay = _displayedStays[index];
                                final additionalInfo = _findAdditionalInfo(stay.visitorId);
                                // คำนวณหมายเลขครั้งที่ (เรียงจากใหม่สุดเป็นครั้งที่ 1)
                                final globalIndex = (_currentPage - 1) * _itemsPerPage + index;
                                final stayNumber = globalIndex + 1;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.purple[100],
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'ครั้งที่ $stayNumber',
                                                style: TextStyle(
                                                  color: Colors.purple[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            // แสดงสถานะเฉพาะเมื่อยังไม่สิ้นสุด
                                            if (stay.actualStatus != 'completed') 
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(stay.actualStatus),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getStatusText(stay.actualStatus),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // วันที่
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_formatDate(stay.startDate)} - ${_formatDate(stay.endDate)}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        
                                        // จำนวนวัน
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              'รวม ${stay.endDate.difference(stay.startDate).inDays + 1} วัน',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        
                                        if (additionalInfo != null) ...[
                                          const SizedBox(height: 12),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          
                                          // ข้อมูลที่เบิกยืม
                                          if (_hasEquipment(additionalInfo)) ...[
                                            const Text(
                                              'รายการที่เบิกยืม:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: _buildEquipmentChips(additionalInfo),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          
                                          // สถานที่พัก
                                          if (additionalInfo.location != null && additionalInfo.location!.isNotEmpty) ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.bed, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'พักที่: ${additionalInfo.location}',
                                                  style: TextStyle(color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          
                                          // หมายเหตุ
                                          if (additionalInfo.notes != null && additionalInfo.notes!.isNotEmpty) ...[
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.note, size: 16, color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'หมายเหตุ: ${additionalInfo.notes}',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          // Pagination
                          if (_totalPages > 1) _buildPagination(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'หน้า $_currentPage จาก $_totalPages',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                _totalPages.clamp(0, 5),
                (index) {
                  final page = index + 1;
                  final isCurrentPage = page == _currentPage;
                  
                  return GestureDetector(
                    onTap: () => _goToPage(page),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCurrentPage ? Colors.purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentPage ? Colors.purple : Colors.grey,
                        ),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color: isCurrentPage ? Colors.white : Colors.grey[700],
                          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _hasEquipment(RegAdditionalInfo info) {
    return (info.shirtCount != null && info.shirtCount! > 0) ||
           (info.pantsCount != null && info.pantsCount! > 0) ||
           (info.matCount != null && info.matCount! > 0) ||
           (info.pillowCount != null && info.pillowCount! > 0) ||
           (info.blanketCount != null && info.blanketCount! > 0);
  }

  List<Widget> _buildEquipmentChips(RegAdditionalInfo info) {
    List<Widget> chips = [];
    
    if (info.shirtCount != null && info.shirtCount! > 0) {
      chips.add(_buildEquipmentChip('เสื้อขาว', info.shirtCount!));
    }
    if (info.pantsCount != null && info.pantsCount! > 0) {
      chips.add(_buildEquipmentChip('กางเกงขาว', info.pantsCount!));
    }
    if (info.matCount != null && info.matCount! > 0) {
      chips.add(_buildEquipmentChip('เสื่อ', info.matCount!));
    }
    if (info.pillowCount != null && info.pillowCount! > 0) {
      chips.add(_buildEquipmentChip('หมอน', info.pillowCount!));
    }
    if (info.blanketCount != null && info.blanketCount! > 0) {
      chips.add(_buildEquipmentChip('ผ้าห่ม', info.blanketCount!));
    }
    
    return chips;
  }

  Widget _buildEquipmentChip(String name, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$name $count',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'extended':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'กำลังพัก';
      case 'extended':
        return 'ขยายเวลา';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}