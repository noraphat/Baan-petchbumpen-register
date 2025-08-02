import 'dart:io';
import 'package:flutter/material.dart';
import '../services/map_service.dart';
import '../models/room_model.dart';

class TestMapDisplayScreen extends StatefulWidget {
  const TestMapDisplayScreen({super.key});

  @override
  State<TestMapDisplayScreen> createState() => _TestMapDisplayScreenState();
}

class _TestMapDisplayScreenState extends State<TestMapDisplayScreen> {
  final MapService _mapService = MapService();
  MapData? _mapData;
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    try {
      final maps = await _mapService.getAllMaps();
      if (maps.isNotEmpty) {
        _mapData = maps.first;
        _rooms = await _mapService.getAllRooms();
      }
    } catch (e) {
      debugPrint('Error loading test data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบแสดงแผนที่'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mapData == null
              ? const Center(child: Text('ไม่มีข้อมูลแผนที่'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ข้อมูลแผนที่
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ข้อมูลแผนที่',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text('ชื่อ: ${_mapData!.name}'),
                                Text('มีรูปภาพ: ${_mapData!.hasImage ? "ใช่" : "ไม่"}'),
                                if (_mapData!.hasImage) ...[
                                  Text('Path: ${_mapData!.imagePath}'),
                                  Text('ขนาด: ${_mapData!.imageWidth}x${_mapData!.imageHeight}'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // ข้อมูลห้องพัก
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ห้องพัก (${_rooms.length} ห้อง)',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                for (var room in _rooms)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${room.name}: (${room.positionX?.toStringAsFixed(1)}, ${room.positionY?.toStringAsFixed(1)}) - ${room.status.name}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // แสดงรูปภาพ
                        if (_mapData!.hasImage) ...[
                          Text(
                            'แสดงรูปภาพแผนที่',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_mapData!.imagePath!),
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.red[100],
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error, color: Colors.red),
                                          const SizedBox(height: 8),
                                          Text('ไม่สามารถแสดงรูปได้: $error'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (frame == null) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return child;
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // ทดสอบ Stack overlay
                          Text(
                            'ทดสอบ Stack กับ Positioned (ห้องพัก)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // รูปพื้นหลัง
                                  Image.file(
                                    File(_mapData!.imagePath!),
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                  ),
                                  // ห้องพัก overlay
                                  for (var room in _rooms.where((r) => r.hasPosition))
                                    Positioned(
                                      left: (room.positionX! / 100) * 300 - 15,
                                      top: (room.positionY! / 100) * 300 - 15,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: _getRoomColor(room.status),
                                          border: Border.all(color: Colors.white, width: 2),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Center(
                                          child: Text(
                                            room.name.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          const Text('ไม่มีรูปภาพแผนที่'),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Color _getRoomColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.red;
      case RoomStatus.reserved:
        return Colors.orange;
    }
  }
}