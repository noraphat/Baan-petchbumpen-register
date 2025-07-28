import 'package:flutter/material.dart';
import '../widgets/interactive_map.dart';
import '../services/map_service.dart';
import '../models/room_model.dart';

class Activity {
  final String startTime;
  final String endTime;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  Activity({
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final MapService _mapService = MapService();

  static final List<Activity> _dailyActivities = [
    Activity(
      startTime: '04:30',
      endTime: '05:00',
      title: 'ตื่นนอน / อาบน้ำ / เตรียมตัว',
      description: 'เตรียมพร้อมสำหรับวันใหม่',
      icon: Icons.bed_outlined,
      iconColor: Colors.indigo,
    ),
    Activity(
      startTime: '05:00',
      endTime: '06:00',
      title: 'ทำวัตรเช้า',
      description: 'สวดมนต์ / นั่งสมาธิ',
      icon: Icons.self_improvement,
      iconColor: Colors.orange,
    ),
    Activity(
      startTime: '06:00',
      endTime: '07:00',
      title: 'พัก / เตรียมโรงฉัน',
      description: 'เตรียมความพร้อมสำหรับมื้ออาหาร',
      icon: Icons.kitchen,
      iconColor: Colors.brown,
    ),
    Activity(
      startTime: '07:00',
      endTime: '08:00',
      title: 'ฉันอาหารเช้า',
      description: 'รับประทานอาหารเช้าในความเงียบ',
      icon: Icons.restaurant,
      iconColor: Colors.green,
    ),
    Activity(
      startTime: '08:00',
      endTime: '09:00',
      title: 'เดินจงกรม',
      description: 'เดินสมาธิ พัฒนาสติ',
      icon: Icons.directions_walk,
      iconColor: Colors.blue,
    ),
    Activity(
      startTime: '09:00',
      endTime: '10:00',
      title: 'นั่งสมาธิ',
      description: 'ปฏิบัติสมาธิในท่านั่ง',
      icon: Icons.spa,
      iconColor: Colors.purple,
    ),
    Activity(
      startTime: '10:00',
      endTime: '11:00',
      title: 'ฉันน้ำปานะ / พักผ่อน',
      description: 'ดื่มน้ำปานะ เติมพลังงาน',
      icon: Icons.local_cafe,
      iconColor: Colors.amber,
    ),
    Activity(
      startTime: '11:00',
      endTime: '13:00',
      title: 'เดินจงกรม / ปฏิบัติภาคบ่าย',
      description: 'ปฏิบัติธรรมช่วงกลางวัน',
      icon: Icons.wb_sunny,
      iconColor: Colors.deepOrange,
    ),
    Activity(
      startTime: '13:00',
      endTime: '15:00',
      title: 'พักผ่อน / ทำความสะอาด',
      description: 'งานจิตอาสา / พักผ่อน',
      icon: Icons.cleaning_services,
      iconColor: Colors.teal,
    ),
    Activity(
      startTime: '15:00',
      endTime: '16:30',
      title: 'เดินจงกรม / เจริญสติ',
      description: 'ปฏิบัติธรรมช่วงบ่าย',
      icon: Icons.self_improvement,
      iconColor: Colors.cyan,
    ),
    Activity(
      startTime: '16:30',
      endTime: '18:00',
      title: 'พัก / อาบน้ำ / เตรียมตัว',
      description: 'เตรียมพร้อมสำหรับทำวัตรเย็น',
      icon: Icons.shower,
      iconColor: Colors.blueGrey,
    ),
    Activity(
      startTime: '18:00',
      endTime: '19:00',
      title: 'ทำวัตรเย็น',
      description: 'สวดมนต์ / นั่งสมาธิ',
      icon: Icons.nights_stay,
      iconColor: Colors.deepPurple,
    ),
    Activity(
      startTime: '19:00',
      endTime: '20:30',
      title: 'สาธยายพระไตรปิฎก / ฟังธรรม',
      description: 'ศึกษาพระธรรม / ฟังเทศน์',
      icon: Icons.menu_book,
      iconColor: Colors.red,
    ),
    Activity(
      startTime: '20:30',
      endTime: '21:00',
      title: 'พักผ่อนประจำวัน',
      description: 'แยกย้ายเข้าที่พัก',
      icon: Icons.bedtime,
      iconColor: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text(
          'ตารางกิจกรรม & แผนที่',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => _showMapDialog(),
            tooltip: 'ดูแผนที่ห้องพัก',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.withValues(alpha: 0.8),
                  Colors.deepPurple.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'กิจกรรมประจำวันปฏิบัติธรรม',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ทั้งหมด ${_dailyActivities.length} กิจกรรม',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Activities List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              itemCount: _dailyActivities.length,
              itemBuilder: (context, index) {
                final activity = _dailyActivities[index];
                final isLastItem = index == _dailyActivities.length - 1;
                
                return Column(
                  children: [
                    _buildActivityCard(activity, index + 1),
                    if (!isLastItem) const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Activity activity, int sequence) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sequence number and icon
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: activity.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activity.iconColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$sequence',
                    style: TextStyle(
                      color: activity.iconColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activity.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.iconColor,
                  size: 20,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Activity content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time range
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${activity.startTime} - ${activity.endTime}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Activity title
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Activity description
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'แผนที่ห้องพัก',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Map Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<(MapData?, List<Room>)>(
                    future: _loadMapData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }
                      
                      final (mapData, rooms) = snapshot.data!;
                      
                      if (mapData == null) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'ยังไม่มีแผนที่',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'กรุณาติดต่อเจ้าหน้าที่เพื่อตั้งค่าแผนที่',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                        children: [
                          // Map Info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'แผนที่: ${mapData.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text('ห้องพักทั้งหมด: ${rooms.length} ห้อง'),
                                      const Text(
                                        '🟢 ว่าง | 🟠 จอง | 🔴 มีคนพัก',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Map Viewer
                          Expanded(
                            child: MapViewer(
                              rooms: rooms,
                              mapData: mapData,
                              onRoomTap: (room) {
                                _showRoomDetailsDialog(room);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<(MapData?, List<Room>)> _loadMapData() async {
    try {
      final mapData = await _mapService.getActiveMap();
      final rooms = await _mapService.getRoomsWithPosition();
      return (mapData, rooms);
    } catch (e) {
      throw Exception('ไม่สามารถโหลดข้อมูลแผนที่ได้: $e');
    }
  }

  void _showRoomDetailsDialog(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getRoomStatusIcon(room.status),
              color: _getRoomStatusColor(room.status),
            ),
            const SizedBox(width: 8),
            Text(room.name),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomDetailRow('ขนาด', room.size.displayName),
            _buildRoomDetailRow('ความจุ', '${room.capacity} คน'),
            _buildRoomDetailRow('สถานะ', room.status.displayName),
            if (room.description != null)
              _buildRoomDetailRow('คำอธิบาย', room.description!),
            if (room.currentOccupant != null)
              _buildRoomDetailRow('ผู้พักปัจจุบัน', room.currentOccupant!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
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
}