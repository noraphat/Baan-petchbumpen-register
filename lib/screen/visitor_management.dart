import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/reg_data.dart';
import 'visitor_edit.dart';
import 'visitor_history.dart';

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() => _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  List<RegData> _allVisitors = [];
  List<RegData> _filteredVisitors = [];
  Map<String, int> _visitorStayCounts = {};
  List<String> _availableGenders = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'ทั้งหมด';
  String _sortBy = 'created_desc'; // created_desc, created_asc
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVisitors() async {
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DbHelper();
      
      // อัปเดตสถานะ stay ที่หมดอายุก่อนดึงข้อมูล
      await dbHelper.updateExpiredStays();
      
      final visitors = await dbHelper.fetchAll();
      final availableGenders = await dbHelper.getAvailableGenders();
      
      // ดึงจำนวนครั้งที่มาปฏิบัติธรรมของแต่ละคน
      final stayCounts = <String, int>{};
      for (final visitor in visitors) {
        final stays = await dbHelper.fetchAllStays(visitor.id);
        stayCounts[visitor.id] = stays.length;
      }
      
      setState(() {
        _allVisitors = visitors;
        _availableGenders = availableGenders;
        _visitorStayCounts = stayCounts;
        _filteredVisitors = List.from(visitors);
        
        // ตรวจสอบว่า selectedGender ยังมีอยู่ในรายการหรือไม่
        if (_selectedGender != 'ทั้งหมด' && !_availableGenders.contains(_selectedGender)) {
          _selectedGender = 'ทั้งหมด';
        }
        
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  void _applyFilters() {
    List<RegData> filtered = List.from(_allVisitors);
    
    // กรองตามคำค้นหา (เลขบัตรประชาชนหรือเบอร์โทร)
    final searchTerm = _searchController.text.trim().toLowerCase();
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((visitor) {
        return visitor.id.toLowerCase().contains(searchTerm) ||
               visitor.phone.toLowerCase().contains(searchTerm);
      }).toList();
    }
    
    // กรองตามเพศ
    if (_selectedGender != 'ทั้งหมด') {
      filtered = filtered.where((visitor) => visitor.gender == _selectedGender).toList();
    }
    
    // เรียงลำดับ
    if (_sortBy == 'created_desc') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'created_asc') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    setState(() {
      _filteredVisitors = filtered;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDeleteConfirmDialog(RegData visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบข้อมูล'),
        content: Text('ต้องการลบข้อมูลของ ${visitor.first} ${visitor.last} หรือไม่?\n\nข้อมูลจะถูกเปลี่ยนสถานะเป็น "ไม่ใช้งาน" เพื่อให้ Admin ตรวจสอบ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVisitor(visitor);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVisitor(RegData visitor) async {
    try {
      final dbHelper = DbHelper();
      await dbHelper.delete(visitor.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')),
        );
      }
      
      _loadVisitors(); // โหลดข้อมูลใหม่
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการลบข้อมูล: $e');
    }
  }

  void _navigateToEdit(RegData visitor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitorEditScreen(visitor: visitor),
      ),
    );
    
    if (result == true) {
      _loadVisitors(); // โหลดข้อมูลใหม่หากมีการแก้ไข
    }
  }

  void _navigateToHistory(RegData visitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitorHistoryScreen(visitor: visitor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลผู้ปฏิบัติธรรม'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ส่วนค้นหาและกรอง
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // ช่องค้นหา
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาจากเลขบัตรประชาชนหรือเบอร์โทรศัพท์',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                
                // Filters section with responsive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    
                    if (isSmallScreen) {
                      // สำหรับหน้าจอเล็ก - จัดเป็นคอลัมน์
                      return Column(
                        children: [
                          _buildGenderFilter(),
                          const SizedBox(height: 12),
                          _buildSortFilter(),
                        ],
                      );
                    } else {
                      // สำหรับหน้าจอใหญ่ - จัดเป็นแถว
                      return Row(
                        children: [
                          Expanded(child: _buildGenderFilter()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSortFilter()),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // ส่วนแสดงจำนวนผลลัพธ์
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'พบข้อมูล ${_filteredVisitors.length} รายการ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // รายการข้อมูล
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVisitors.isEmpty
                    ? const Center(
                        child: Text(
                          'ไม่พบข้อมูลที่ตรงกับเงื่อนไขการค้นหา',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVisitors.length,
                        itemBuilder: (context, index) {
                          final visitor = _filteredVisitors[index];
                          final stayCount = _visitorStayCounts[visitor.id] ?? 0;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _navigateToEdit(visitor),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${visitor.first} ${visitor.last}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            visitor.gender,
                                            style: TextStyle(
                                              color: Colors.purple[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _navigateToHistory(visitor),
                                            child: Text(
                                              'จำนวนครั้งที่มาปฏิบัติธรรม: $stayCount ครั้ง',
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w500,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'วันที่สมัคร: ${_formatDate(visitor.createdAt)}',
                                            style: const TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _navigateToEdit(visitor),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('แก้ไข'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _showDeleteConfirmDialog(visitor),
                                          icon: const Icon(Icons.delete, size: 16),
                                          label: const Text('ลบ'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter() {
    final genderOptions = ['ทั้งหมด', ..._availableGenders];
    
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'เพศ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: genderOptions
          .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender),
              ))
          .toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value!);
        _applyFilters();
      },
    );
  }

  Widget _buildSortFilter() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: InputDecoration(
        labelText: 'เรียงตาม',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: 'created_desc',
          child: Text('วันที่สมัคร (ใหม่ → เก่า)'),
        ),
        DropdownMenuItem(
          value: 'created_asc',
          child: Text('วันที่สมัคร (เก่า → ใหม่)'),
        ),
      ],
      onChanged: (value) {
        setState(() => _sortBy = value!);
        _applyFilters();
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}