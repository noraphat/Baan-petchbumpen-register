import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/map_service.dart';

/// Widget สำหรับแสดงแผนที่แบบ Interactive ที่สามารถลากวางห้องได้
class InteractiveMap extends StatefulWidget {
  final bool isEditable;
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;
  final Function(Room, Offset)? onRoomPositionChanged;
  final VoidCallback? onRoomsChanged;

  const InteractiveMap({
    super.key,
    this.isEditable = false,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
    this.onRoomPositionChanged,
    this.onRoomsChanged,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final MapService _mapService = MapService();
  Room? _draggedRoom;
  Offset? _dragOffset;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _containerKey = GlobalKey();
  Size? _mapImageSize;
  Size? _containerSize;
  bool _isImageLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _loadMapImage();
  }
  
  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMapImage() async {
    debugPrint('🔄 กำลังโหลดรูปภาพแผนที่...');
    if (widget.mapData?.hasImage == true) {
      debugPrint('📸 มีรูปภาพแผนที่: ${widget.mapData!.imagePath}');
      try {
        final File imageFile = File(widget.mapData!.imagePath!);
        debugPrint('📁 ตรวจสอบไฟล์: ${imageFile.existsSync() ? "มีไฟล์" : "ไม่มีไฟล์"}');
        
        final bytes = await imageFile.readAsBytes();
        debugPrint('💾 อ่านไฟล์ได้: ${bytes.length} bytes');
        
        final ui.Image image = await decodeImageFromList(bytes);
        debugPrint('🖼️ decode รูปสำเร็จ: ${image.width}x${image.height}');
        
        setState(() {
          _mapImageSize = Size(image.width.toDouble(), image.height.toDouble());
          _isImageLoaded = true;
        });
        
        debugPrint('✅ โหลดรูปภาพแผนที่สำเร็จ');
        
        // Auto-fit image when first loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoFitImage();
        });
      } catch (e) {
        debugPrint('❌ Error loading map image: $e');
      }
    } else {
      debugPrint('📋 ใช้แผนที่ grid เริ่มต้น (ไม่มีรูปภาพ)');
      setState(() {
        _mapImageSize = const Size(1200, 800); // Default size for grid
        _isImageLoaded = true;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFitImage();
      });
    }
  }
  
  void _autoFitImage() {
    final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _mapImageSize == null) return;
    
    final containerSize = renderBox.size;
    final imageSize = _mapImageSize!;
    
    // คำนวณ scale ที่เหมาะสมเพื่อให้รูปภาพพอดีกับ container
    final scaleX = containerSize.width / imageSize.width;
    final scaleY = containerSize.height / imageSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9; // ลดลง 10% เพื่อให้มี margin
    
    // คำนวณตำแหน่งกลางภาพ
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;
    
    // สร้าง transformation matrix
    final matrix = Matrix4.identity()
      ..translate(-centerX, -centerY) // ย้ายไปที่จุดกลาง
      ..scale(scale) // ปรับขนาด
      ..translate(containerSize.width / 2, containerSize.height / 2); // ย้ายกลับมากลาง container
    
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 Building InteractiveMap - isImageLoaded: $_isImageLoaded, rooms: ${widget.rooms.length}');
    
    if (!_isImageLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final positionedRooms = widget.rooms.where((room) => room.hasPosition).toList();
    final availableRooms = widget.rooms.where((room) => !room.hasPosition).toList();
    
    debugPrint('📍 ห้องที่วางตำแหน่งแล้ว: ${positionedRooms.length}, ห้องที่ยังไม่ได้วาง: ${availableRooms.length}');
    
    return Column(
      children: [
        // Available rooms panel at top
        if (widget.isEditable && availableRooms.isNotEmpty)
          _buildAvailableRoomsHorizontalPanel(availableRooms),
        
        // Map container
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  debugPrint('📐 Available space: ${constraints.maxWidth}x${constraints.maxHeight}');
                  
                  // คำนวณขนาดที่เหมาะสม
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final imageSize = _mapImageSize ?? const Size(1200, 800);
                  
                  // Scale ให้พอดีกับพื้นที่ที่มี
                  final scaleX = availableWidth / imageSize.width;
                  final scaleY = availableHeight / imageSize.height;
                  final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 1.0);
                  
                  final displayWidth = imageSize.width * scale;
                  final displayHeight = imageSize.height * scale;
                  
                  debugPrint('🖼️ Image: ${imageSize.width}x${imageSize.height}, Display: ${displayWidth.toInt()}x${displayHeight.toInt()}, Scale: ${scale.toStringAsFixed(2)}');
                  
                  return InteractiveViewer(
                    key: _containerKey,
                    transformationController: _transformationController,
                    minScale: 0.1,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.all(20),
                    constrained: true, // เปลี่ยนเป็น true
                    scaleEnabled: true,
                    panEnabled: true,
                    child: SizedBox(
                      width: displayWidth,
                      height: displayHeight,
                      child: DragTarget<Room>(
                    onAccept: (room) {
                      // This will be handled by individual positioned drag targets
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          // Background Map Image or Grid
                          _buildMapBackground(displayWidth, displayHeight),
                          
                          // Drag target overlay for positioning
                          if (widget.isEditable)
                            _buildDragTargetOverlay(),
                          
                          // Room widgets that are already positioned
                          ...positionedRooms.map(
                            (room) => _buildPositionedRoomWidget(room, displayWidth, displayHeight),
                          ),
                          
                          // Drop zone indicator (when dragging)
                          if (_draggedRoom != null && _dragOffset != null)
                            _buildDropZoneIndicator(),
                        ],
                      );
                    },
                  ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapBackground(double width, double height) {
    debugPrint('🎨 กำลังสร้าง map background - hasImage: ${widget.mapData?.hasImage}, size: ${width.toInt()}x${height.toInt()}');
    return Container(
      width: width,
      height: height,
      color: Colors.blue[50], // เพิ่มสีพื้นหลังเพื่อดูขอบเขต
      child: widget.mapData?.hasImage == true
          ? Stack(
              children: [
                Image.file(
                  File(widget.mapData!.imagePath!),
                  width: width,
                  height: height,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Error แสดงรูปภาพ: $error');
                    return _buildGridBackground(width, height);
                  },
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null) {
                      debugPrint('⏳ กำลังโหลดเฟรมรูปภาพ...');
                      return Container(
                        width: width,
                        height: height,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    debugPrint('✅ แสดงรูปภาพสำเร็จ');
                    return child;
                  },
                ),
                // เพิ่มข้อความ debug
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.black54,
                    child: Text(
                      'รูปภาพ: ${_mapImageSize?.width}x${_mapImageSize?.height}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            )
          : _buildGridBackground(width, height),
    );
  }

  Widget _buildGridBackground([double? width, double? height]) {
    final w = width ?? _mapImageSize?.width ?? 1200;
    final h = height ?? _mapImageSize?.height ?? 800;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: CustomPaint(
        painter: GridPainter(),
        size: Size(w, h),
      ),
    );
  }

  // แสดงรายการห้องที่ยังไม่ได้วางตำแหน่งแบบ horizontal
  Widget _buildAvailableRoomsHorizontalPanel(List<Room> availableRooms) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.meeting_room, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ห้องที่รอวาง (${availableRooms.length} ห้อง)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Text(
                  'ลากห้องมาวางบนแผนที่',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: availableRooms.length,
              itemBuilder: (context, index) {
                final room = availableRooms[index];
                return _buildDraggableRoomCard(room);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableRoomCard(Room room) {
    final (width, height) = room.getSizeForUI();
    
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Draggable<Room>(
        data: room,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: _buildRoomContainer(room, width, height, isDragging: true),
        ),
        childWhenDragging: Container(
          width: 100,
          height: 60,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: Colors.grey.shade400,
              strokeWidth: 2,
              dashPattern: [5, 3],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.open_with,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'กำลังลาก',
                    style: TextStyle(
                      color: Colors.grey.shade600, 
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        onDragStarted: () {
          setState(() {
            _draggedRoom = room;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _draggedRoom = null;
            _dragOffset = null;
          });
        },
        onDragUpdate: (details) {
          setState(() {
            _dragOffset = details.globalPosition;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getRoomStatusColor(room.status).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: _getRoomStatusColor(room.status).withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getRoomStatusColor(room.status).withValues(alpha: 0.1),
                  border: Border.all(color: _getRoomStatusColor(room.status)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _getRoomStatusIcon(room.status),
                  size: 12,
                  color: _getRoomStatusColor(room.status),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                room.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                '${room.capacity} คน',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับห้องที่วางตำแหน่งแล้ว
  Widget _buildPositionedRoomWidget(Room room, [double? mapWidth, double? mapHeight]) {
    final (width, height) = room.getSizeForUI();
    
    // คำนวณตำแหน่งจาก percentage เป็น absolute position
    final mapW = mapWidth ?? _mapImageSize?.width ?? 1200;
    final mapH = mapHeight ?? _mapImageSize?.height ?? 800;
    final absoluteX = (room.positionX! / 100) * mapW;
    final absoluteY = (room.positionY! / 100) * mapH;
    
    debugPrint('🏠 แสดงห้อง ${room.name}: ${room.positionX}%,${room.positionY}% → (${absoluteX.toInt()},${absoluteY.toInt()}) size: ${width}x$height');
    
    return Positioned(
      left: absoluteX - (width / 2),
      top: absoluteY - (height / 2),
      child: widget.isEditable
          ? Draggable<Room>(
              data: room,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: _buildRoomContainer(room, width, height, isDragging: true),
              ),
              childWhenDragging: _buildRoomContainer(room, width, height, isPlaceholder: true),
              onDragStarted: () {
                setState(() {
                  _draggedRoom = room;
                });
              },
              onDragEnd: (details) {
                setState(() {
                  _draggedRoom = null;
                  _dragOffset = null;
                });
              },
              onDragUpdate: (details) {
                setState(() {
                  _dragOffset = details.globalPosition;
                });
              },
              child: _buildRoomContainer(room, width, height),
            )
          : GestureDetector(
              onTap: () => widget.onRoomTap?.call(room),
              child: _buildRoomContainer(room, width, height),
            ),
    );
  }
  
  // สร้าง overlay สำหรับรับ drag target ทั้วแผนที่
  Widget _buildDragTargetOverlay() {
    final imageSize = _mapImageSize ?? const Size(1200, 800);
    
    return Positioned.fill(
      child: DragTarget<Room>(
        onAcceptWithDetails: (details) {
          // จัดการโดย callback ใน onWillAccept
        },
        onWillAcceptWithDetails: (details) {
          return details.data != null && widget.onRoomPositionChanged != null;
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTapDown: (details) {
              // ถ้ามีห้องที่กำลัง drag อยู่ ให้วางที่ตำแหน่งที่คลิก
              if (_draggedRoom != null && widget.onRoomPositionChanged != null) {
                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final localPosition = details.localPosition;
                  
                  // แปลงเป็น percentage
                  final percentX = (localPosition.dx / imageSize.width * 100).clamp(0.0, 100.0);
                  final percentY = (localPosition.dy / imageSize.height * 100).clamp(0.0, 100.0);
                  
                  widget.onRoomPositionChanged!(_draggedRoom!, Offset(percentX, percentY));
                  
                  setState(() {
                    _draggedRoom = null;
                    _dragOffset = null;
                  });
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: candidateData.isNotEmpty 
                ? Colors.blue.withValues(alpha: 0.1) 
                : Colors.transparent,
              child: candidateData.isNotEmpty 
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Text(
                        'ปล่อยที่นี่เพื่อวางห้อง',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            ),
          );
        },
      ),
    );
  }

  // ฟังก์ชันช่วยเหลือสำหรับสีและไอคอนตามสถานะห้อง
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

  Widget _buildRoomContainer(
    Room room,
    double width,
    double height, {
    bool isDragging = false,
    bool isPlaceholder = false,
  }) {
    Color backgroundColor;
    Color borderColor;
    IconData icon;
    
    // กำหนดสีตามสถานะ
    backgroundColor = _getRoomStatusColor(room.status).withValues(alpha: 0.1);
    borderColor = _getRoomStatusColor(room.status);
    icon = _getRoomStatusIcon(room.status);
    
    if (isPlaceholder) {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade400;
    } else if (isDragging) {
      backgroundColor = backgroundColor.withValues(alpha: 0.8);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: borderColor,
            size: height > 30 ? 16 : 12,
          ),
          if (height > 30) ...[
            const SizedBox(height: 2),
            Text(
              room.name,
              style: TextStyle(
                fontSize: width > 60 ? 10 : 8,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (height > 40)
              Text(
                '${room.capacity} คน',
                style: TextStyle(
                  fontSize: 8,
                  color: borderColor.withValues(alpha: 0.7),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropZoneIndicator() {
    if (_dragOffset == null) return const SizedBox.shrink();
    
    // แสดง indicator ตามตำแหน่งเมาส์
    return Positioned(
      left: _dragOffset!.dx - 20,
      top: _dragOffset!.dy - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          border: Border.all(color: Colors.green, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.green,
              size: 16,
            ),
            Text(
              _draggedRoom!.name,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ลบฟังก์ชัน tap-to-add ออกเพราะใช้ drag-only
  // Widget _buildTapToAddIndicator() - ไม่ใช้แล้ว
}

/// Custom Painter สำหรับวาดเส้นกริด
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 20.0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // วาดเส้นแนวตั้ง
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // วาดเส้นแนวนอน
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter สำหรับวาดขอบเส้นประ
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    _drawDashedPath(canvas, path, dashPattern, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, List<double> pattern, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final length = pattern[draw ? 0 : 1];
        if (draw) {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget สำหรับแสดงแผนที่ในโหมดดูอย่างเดียว (สำหรับหน้าจองที่พัก)
class MapViewer extends StatelessWidget {
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;

  const MapViewer({
    super.key,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveMap(
      isEditable: false,
      rooms: rooms,
      mapData: mapData,
      onRoomTap: onRoomTap,
    );
  }
}

/// Widget สำหรับแก้ไขแผนที่ (สำหรับ Developer Settings)
class MapEditor extends StatefulWidget {
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;
  final Function(Room, Offset)? onRoomPositionChanged;

  const MapEditor({
    super.key,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
    this.onRoomPositionChanged,
  });

  @override
  State<MapEditor> createState() => _MapEditorState();
}

class _MapEditorState extends State<MapEditor> {
  Room? _selectedRoom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Control Panel
        if (_selectedRoom != null)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.room,
                    color: _getRoomStatusColor(_selectedRoom!.status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'เลือกห้อง: ${_selectedRoom!.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ขนาด: ${_selectedRoom!.size.displayName} | ความจุ: ${_selectedRoom!.capacity} คน',
                        ),
                        Text('สถานะ: ${_selectedRoom!.status.displayName}'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedRoom = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
        
        // Map
        Expanded(
          child: InteractiveMap(
            isEditable: true,
            rooms: widget.rooms,
            mapData: widget.mapData,
            onRoomTap: (room) {
              setState(() => _selectedRoom = room);
              widget.onRoomTap?.call(room);
            },
            onRoomPositionChanged: widget.onRoomPositionChanged,
          ),
        ),
        
        // Instructions
        const Card(
          margin: EdgeInsets.only(top: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'วิธีใช้: ลากห้องเพื่อย้ายตำแหน่ง | คลิกห้องเพื่อเลือก | คลิกพื้นที่ว่างเพื่อเพิ่มห้องใหม่',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
}