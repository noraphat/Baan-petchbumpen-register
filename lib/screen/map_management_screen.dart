import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/room_model.dart';
import '../services/map_service.dart';
import '../widgets/interactive_map_improved.dart';

/// หน้าจัดการแผนที่และห้องพัก (สำหรับ Developer Settings)
class MapManagementScreen extends StatefulWidget {
  const MapManagementScreen({super.key});

  @override
  State<MapManagementScreen> createState() => _MapManagementScreenState();
}

class _MapManagementScreenState extends State<MapManagementScreen>
    with TickerProviderStateMixin {
  final MapService _mapService = MapService();
  late TabController _tabController;

  // Map management
  List<MapData> _maps = [];
  MapData? _activeMap;
  bool _isLoadingMaps = true;

  // Room management
  List<Room> _rooms = [];
  bool _isLoadingRooms = true;
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadMaps(), _loadRooms()]);
  }

  Future<void> _loadMaps() async {
    setState(() => _isLoadingMaps = true);
    try {
      final maps = await _mapService.getAllMaps();
      final activeMap = await _mapService.getActiveMap();

      // Debug: ตรวจสอบข้อมูลแผนที่
      debugPrint('=== Maps Debug ===');
      debugPrint('Total maps: ${maps.length}');
      for (int i = 0; i < maps.length; i++) {
        final map = maps[i];
        debugPrint(
          'Map $i: ${map.name} (ID: ${map.id}, Active: ${map.isActive})',
        );
        debugPrint('  - HasImage: ${map.hasImage}');
        debugPrint('  - ImagePath: ${map.imagePath}');
      }
      debugPrint('Active map: ${activeMap?.name}');
      debugPrint('Active map hasImage: ${activeMap?.hasImage}');
      debugPrint('Active map imagePath: ${activeMap?.imagePath}');

      setState(() {
        _maps = maps;
        _activeMap = activeMap;
      });
    } catch (e) {
      debugPrint('ERROR loading maps: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูลแผนที่');
    } finally {
      setState(() => _isLoadingMaps = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final rooms = await _mapService.getAllRooms();
      setState(() => _rooms = rooms);
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูลห้องพัก');
    } finally {
      setState(() => _isLoadingRooms = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ จัดการแผนที่และห้องพัก'),
        backgroundColor: Colors.purple.shade100,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'แผนที่'),
            Tab(icon: Icon(Icons.meeting_room), text: 'ห้องพัก'),
            Tab(icon: Icon(Icons.edit_location), text: 'จัดการตำแหน่ง'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMapTab(),
          _buildRoomTab(),
          _buildPositionManagementTab(),
        ],
      ),
    );
  }

  // =================== MAP TAB ===================

  Widget _buildMapTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'จัดการแผนที่',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddMapDialog,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มแผนที่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeMap != null)
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('แผนที่ที่ใช้งาน: ${_activeMap!.name}'),
                subtitle: _activeMap!.hasImage
                    ? const Text('มีภาพแผนที่')
                    : const Text('ไม่มีภาพแผนที่'),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingMaps
                ? const Center(child: CircularProgressIndicator())
                : _maps.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีแผนที่\nกดปุ่ม "เพิ่มแผนที่" เพื่อเริ่มต้น',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _maps.length,
                    itemBuilder: (context, index) =>
                        _buildMapCard(_maps[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(MapData map) {
    final isActive = map.id == _activeMap?.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.grey,
          child: Icon(isActive ? Icons.check : Icons.map, color: Colors.white),
        ),
        title: Text(
          map.name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (map.description != null) Text(map.description!),
            Text(
              map.hasImage ? '📷 มีภาพแผนที่' : '📷 ไม่มีภาพแผนที่',
              style: TextStyle(
                color: map.hasImage ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMapAction(value, map),
          itemBuilder: (context) => [
            if (!isActive)
              const PopupMenuItem(
                value: 'activate',
                child: ListTile(
                  leading: Icon(Icons.check_circle),
                  title: Text('ใช้แผนที่นี้'),
                ),
              ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('แก้ไข')),
            ),
            if (!isActive)
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('ลบ', style: TextStyle(color: Colors.red)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleMapAction(String action, MapData map) {
    switch (action) {
      case 'activate':
        _setActiveMap(map);
        break;
      case 'edit':
        _showEditMapDialog(map);
        break;
      case 'delete':
        _showDeleteMapConfirmation(map);
        break;
    }
  }

  Future<void> _setActiveMap(MapData map) async {
    final success = await _mapService.setActiveMap(map.id!);
    if (success) {
      _showSuccessSnackBar('ตั้งแผนที่ "${map.name}" เป็นแผนที่หลักแล้ว');
      _loadMaps();
    } else {
      _showErrorSnackBar('ไม่สามารถตั้งแผนที่หลักได้');
    }
  }

  void _showAddMapDialog() {
    _showMapDialog();
  }

  void _showEditMapDialog(MapData map) {
    _showMapDialog(map: map);
  }

  void _showMapDialog({MapData? map}) {
    final isEditing = map != null;
    final nameController = TextEditingController(text: map?.name ?? '');
    final descriptionController = TextEditingController(
      text: map?.description ?? '',
    );
    String? imagePath = map?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'แก้ไขแผนที่' : 'เพิ่มแผนที่ใหม่'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อแผนที่',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย (ไม่บังคับ)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (imagePath != null) ...[
                          Image.file(
                            File(imagePath!),
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ภาพแผนที่ปัจจุบัน',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final newImagePath = await _mapService
                                        .uploadMapImage(
                                          source: ImageSource.gallery,
                                        );
                                    if (newImagePath != null) {
                                      setDialogState(
                                        () => imagePath = newImagePath,
                                      );
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('ไม่ได้เลือกภาพ'),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      final errorMessage = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 5),
                                          action:
                                              errorMessage.contains('อนุญาต')
                                              ? SnackBarAction(
                                                  label: 'ตั้งค่า',
                                                  textColor: Colors.white,
                                                  onPressed: () {
                                                    // เปิดการตั้งค่าแอป (ต้องเพิ่ม package: permission_handler)
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'กรุณาไปที่ Settings > Apps > แอปนี้ > Permissions เพื่ออนุญาตการเข้าถึง',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : null,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('เลือกภาพจากแกลเลอรี่'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final newImagePath = await _mapService
                                        .uploadMapImage(
                                          source: ImageSource.camera,
                                        );
                                    if (newImagePath != null) {
                                      setDialogState(
                                        () => imagePath = newImagePath,
                                      );
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('ไม่ได้ถ่ายภาพ'),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      final errorMessage = e
                                          .toString()
                                          .replaceFirst('Exception: ', '');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 5),
                                          action:
                                              errorMessage.contains('อนุญาต')
                                              ? SnackBarAction(
                                                  label: 'ตั้งค่า',
                                                  textColor: Colors.white,
                                                  onPressed: () {
                                                    // เปิดการตั้งค่าแอป (ต้องเพิ่ม package: permission_handler)
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'กรุณาไปที่ Settings > Apps > แอปนี้ > Permissions เพื่ออนุญาตการเข้าถึง',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : null,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('ถ่ายภาพด้วยกล้อง'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาใส่ชื่อแผนที่')),
                  );
                  return;
                }

                Navigator.pop(context);

                if (isEditing) {
                  // แก้ไขแผนที่
                  final updatedMap = map.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    imagePath: imagePath,
                  );

                  final success = await _mapService.updateMap(updatedMap);
                  if (success) {
                    _showSuccessSnackBar('แก้ไขแผนที่สำเร็จ');
                    _loadMaps();
                  } else {
                    _showErrorSnackBar('ไม่สามารถแก้ไขแผนที่ได้');
                  }
                } else {
                  // เพิ่มแผนที่ใหม่
                  final mapId = await _mapService.saveMap(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    imagePath: imagePath,
                  );

                  if (mapId != null) {
                    _showSuccessSnackBar('เพิ่มแผนที่สำเร็จ');
                    _loadMaps();
                  } else {
                    _showErrorSnackBar('ไม่สามารถเพิ่มแผนที่ได้');
                  }
                }
              },
              child: Text(isEditing ? 'บันทึก' : 'เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMapConfirmation(MapData map) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'คุณต้องการลบแผนที่ "${map.name}" หรือไม่?\n\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _mapService.deleteMap(map.id!);
              if (success) {
                _showSuccessSnackBar('ลบแผนที่สำเร็จ');
                _loadMaps();
              } else {
                _showErrorSnackBar('ไม่สามารถลบแผนที่ได้');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  // =================== ROOM TAB ===================

  Widget _buildRoomTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'จัดการห้องพัก',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddRoomDialog,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มห้องพัก'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingRooms
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                ? const Center(
                    child: Text(
                      'ยังไม่มีห้องพัก\nกดปุ่ม "เพิ่มห้องพัก" เพื่อเริ่มต้น',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) =>
                        _buildRoomCard(_rooms[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    Color statusColor;
    IconData statusIcon;

    switch (room.status) {
      case RoomStatus.available:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case RoomStatus.occupied:
        statusColor = Colors.red;
        statusIcon = Icons.person;
        break;
      case RoomStatus.reserved:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(statusIcon, color: Colors.white),
        ),
        title: Text(
          room.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ขนาด: ${room.size.displayName} | ความจุ: ${room.capacity} คน',
            ),
            Text('สถานะ: ${room.status.displayName}'),
            if (room.hasPosition)
              Text(
                'ตำแหน่ง: (${room.positionX!.toInt()}, ${room.positionY!.toInt()})',
              )
            else
              const Text(
                'ยังไม่ได้วางตำแหน่งบนแผนที่',
                style: TextStyle(color: Colors.orange),
              ),
            if (room.description != null) Text(room.description!),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleRoomAction(value, room),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('แก้ไข')),
            ),
            const PopupMenuItem(
              value: 'position',
              child: ListTile(
                leading: Icon(Icons.location_on),
                title: Text('จัดการตำแหน่ง'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('ลบ', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRoomAction(String action, Room room) {
    switch (action) {
      case 'edit':
        _showEditRoomDialog(room);
        break;
      case 'position':
        _tabController.animateTo(2); // ไปที่ tab จัดการตำแหน่ง
        setState(() => _selectedRoom = room);
        break;
      case 'delete':
        _showDeleteRoomConfirmation(room);
        break;
    }
  }

  void _showAddRoomDialog() {
    _showRoomDialog();
  }

  void _showEditRoomDialog(Room room) {
    _showRoomDialog(room: room);
  }

  void _showRoomDialog({Room? room}) {
    final isEditing = room != null;
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController = TextEditingController(
      text: room?.capacity.toString() ?? '2',
    );
    final descriptionController = TextEditingController(
      text: room?.description ?? '',
    );
    RoomSize selectedSize = room?.size ?? RoomSize.medium;
    RoomShape selectedShape = room?.shape ?? RoomShape.square;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'แก้ไขห้องพัก' : 'เพิ่มห้องพักใหม่'),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: double.maxFinite,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อห้องพัก',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoomSize>(
                  value: selectedSize,
                  decoration: const InputDecoration(
                    labelText: 'ขนาดห้อง',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: RoomSize.values
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text(
                            '${size.code} - ${size.displayName}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (size) =>
                      setDialogState(() => selectedSize = size!),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownButtonFormField<RoomShape>(
                      value: selectedShape,
                      decoration: const InputDecoration(
                        labelText: 'รูปร่างห้อง',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: RoomShape.values
                          .map(
                            (shape) => DropdownMenuItem(
                              value: shape,
                              child: SizedBox(
                                width: constraints.maxWidth - 40, // เผื่อ padding
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.6),
                                        border: Border.all(color: Colors.blue, width: 1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        shape.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (shape) =>
                          setDialogState(() => selectedShape = shape!),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'ความจุ (คน)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย (ไม่บังคับ)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาใส่ชื่อห้องพัก')),
                  );
                  return;
                }

                final capacity = int.tryParse(capacityController.text);
                if (capacity == null || capacity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาใส่ความจุที่ถูกต้อง')),
                  );
                  return;
                }

                Navigator.pop(context);

                if (isEditing) {
                  // แก้ไขห้องพัก
                  final updatedRoom = room.copyWith(
                    name: nameController.text.trim(),
                    size: selectedSize,
                    shape: selectedShape,
                    capacity: capacity,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

                  final success = await _mapService.updateRoom(updatedRoom);
                  if (success) {
                    _showSuccessSnackBar('แก้ไขห้องพักสำเร็จ');
                    await _loadRooms(); // รีเฟรชข้อมูลห้อง
                    setState(() {}); // บังคับให้ UI อัปเดต
                  } else {
                    _showErrorSnackBar('ไม่สามารถแก้ไขห้องพักได้');
                  }
                } else {
                  // เพิ่มห้องพักใหม่
                  final roomId = await _mapService.addRoom(
                    name: nameController.text.trim(),
                    size: selectedSize,
                    shape: selectedShape,
                    capacity: capacity,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                  );

                  if (roomId != null) {
                    _showSuccessSnackBar('เพิ่มห้องพักสำเร็จ');
                    await _loadRooms(); // รีเฟรชข้อมูลห้อง
                    setState(() {}); // บังคับให้ UI อัปเดต
                  } else {
                    _showErrorSnackBar('ไม่สามารถเพิ่มห้องพักได้');
                  }
                }
              },
              child: Text(isEditing ? 'บันทึก' : 'เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoomConfirmation(Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'คุณต้องการลบห้องพัก "${room.name}" หรือไม่?\n\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _mapService.deleteRoom(room.id!);
              if (success) {
                _showSuccessSnackBar('ลบห้องพักสำเร็จ');
                await _loadRooms(); // รีเฟรชข้อมูลห้อง
                setState(() {}); // บังคับให้ UI อัปเดต
              } else {
                _showErrorSnackBar('ไม่สามารถลบห้องพักได้');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  // =================== POSITION MANAGEMENT TAB ===================

  Widget _buildPositionManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'จัดการตำแหน่งห้องบนแผนที่',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_activeMap == null)
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'กรุณาตั้งแผนที่หลักในแท็บ "แผนที่" ก่อนจัดการตำแหน่ง',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: MapEditor(
              rooms: _rooms,
              mapData: _activeMap,
              onRoomTap: (room) {
                setState(() => _selectedRoom = room);
              },
              onRoomPositionChanged: (room, offset) async {
                if (_activeMap == null) {
                  _showErrorSnackBar('กรุณาตั้งแผนที่หลักก่อน');
                  return;
                }

                final success = await _mapService.updateRoomPosition(
                  room.id!,
                  offset.dx,
                  offset.dy,
                );

                if (success) {
                  _showSuccessSnackBar(
                    'อัปเดตตำแหน่งห้อง "${room.name}" สำเร็จ',
                  );
                  await _loadRooms(); // โหลดข้อมูลใหม่
                  setState(() {}); // บังคับให้ UI อัปเดต
                } else {
                  _showErrorSnackBar(
                    'ไม่สามารถวางห้องในตำแหน่งนี้ได้ (ชนกับห้องอื่น)',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
