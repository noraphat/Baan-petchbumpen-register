import 'package:flutter/material.dart';
import 'lib/services/db_helper.dart';

/// ไฟล์ทดสอบเพื่อตรวจสอบข้อมูลในตาราง stays
class TestStaysData extends StatefulWidget {
  const TestStaysData({super.key});

  @override
  State<TestStaysData> createState() => _TestStaysDataState();
}

class _TestStaysDataState extends State<TestStaysData> {
  List<Map<String, dynamic>> staysData = [];
  List<Map<String, dynamic>> regsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final db = await DbHelper().db;

      // โหลดข้อมูลจากตาราง stays
      final stays = await db.query('stays', orderBy: 'created_at DESC');

      // โหลดข้อมูลจากตาราง regs
      final regs = await db.query(
        'regs',
        where: 'status = ?',
        whereArgs: ['A'],
      );

      setState(() {
        staysData = stays;
        regsData = regs;
        isLoading = false;
      });

      debugPrint('📊 Data loaded:');
      debugPrint('   Stays records: ${staysData.length}');
      debugPrint('   Active registrations: ${regsData.length}');

      // แสดงข้อมูล stays
      for (var stay in staysData) {
        debugPrint(
          '   Stay: ${stay['visitor_id']} - ${stay['start_date']} to ${stay['end_date']} (${stay['status']})',
        );
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบข้อมูล Stays'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // สรุปข้อมูล
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📊 สรุปข้อมูล',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('จำนวน Stay Records: ${staysData.length}'),
                          Text(
                            'จำนวน Active Registrations: ${regsData.length}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ข้อมูล Stays
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏠 ข้อมูล Stays',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (staysData.isEmpty)
                            const Text(
                              'ไม่พบข้อมูลในตาราง stays',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...staysData.map(
                              (stay) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
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
                                    Text('Start Date: ${stay['start_date']}'),
                                    Text('End Date: ${stay['end_date']}'),
                                    Text('Status: ${stay['status']}'),
                                    Text('Note: ${stay['note'] ?? 'ไม่มี'}'),
                                    Text('Created: ${stay['created_at']}'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ข้อมูล Registrations
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '👥 ข้อมูล Registrations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (regsData.isEmpty)
                            const Text(
                              'ไม่พบข้อมูลในตาราง regs',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...regsData
                                .take(10)
                                .map(
                                  (reg) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ID: ${reg['id']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Name: ${reg['first']} ${reg['last']}',
                                        ),
                                        Text('Phone: ${reg['phone']}'),
                                        Text('Status: ${reg['status']}'),
                                      ],
                                    ),
                                  ),
                                ),
                          if (regsData.length > 10)
                            Text(
                              '... และอีก ${regsData.length - 10} รายการ',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
