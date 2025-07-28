import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../services/map_service.dart';

/// Widget สำหรับแสดงแผนที่แบบ Interactive ที่สามารถลากวางห้องได้ (ปรับปรุงใหม่)
class InteractiveMapImproved extends StatefulWidget {
  final bool isEditable;
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;
  final Function(Room, Offset)? onRoomPositionChanged;
  final VoidCallback? onRoomsChanged;

  const InteractiveMapImproved({
    super.key,
    this.isEditable = false,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
    this.onRoomPositionChanged,
    this.onRoomsChanged,
  });

  @override
  State<InteractiveMapImproved> createState() => _InteractiveMapImprovedState();
}

class _InteractiveMapImprovedState extends State<InteractiveMapImproved> {
  final MapService _mapService = MapService();
  Room? _draggedRoom;
  Offset? _dragOffset;
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _containerKey = GlobalKey();
  Size? _mapImageSize;
  Size? _containerSize;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    debugPrint('=== InteractiveMapImproved initState ===');
    debugPrint('MapData in initState: ${widget.mapData?.name}');
    _loadMapImage();
  }

  @override
  void didUpdateWidget(InteractiveMapImproved oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('=== InteractiveMapImproved didUpdateWidget ===');
    debugPrint('Old MapData: ${oldWidget.mapData?.name}');
    debugPrint('New MapData: ${widget.mapData?.name}');
    debugPrint('Old ID: ${oldWidget.mapData?.id}');
    debugPrint('New ID: ${widget.mapData?.id}');

    // โหลดแผนที่ใหม่หากมีการเปลี่ยนแปลง
    if (oldWidget.mapData?.id != widget.mapData?.id) {
      debugPrint('MapData changed, calling _loadMapImage()');
      _loadMapImage();
    } else {
      debugPrint('MapData not changed, skipping _loadMapImage()');
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadMapImage() async {
    // Debug: ตรวจสอบข้อมูลแผนที่
    debugPrint('=== _loadMapImage Debug ===');
    debugPrint('MapData: ${widget.mapData?.name}');
    debugPrint('HasImage: ${widget.mapData?.hasImage}');
    debugPrint('ImagePath: ${widget.mapData?.imagePath}');
    debugPrint('IsActive: ${widget.mapData?.isActive}');

    // รีเซ็ตสถานะก่อนโหลดใหม่
    setState(() {
      _isImageLoaded = false;
    });

    if (widget.mapData?.hasImage == true && widget.mapData?.imagePath != null) {
      try {
        final File imageFile = File(widget.mapData!.imagePath!);
        debugPrint('Image file exists: ${await imageFile.exists()}');
        debugPrint('Image file path: ${imageFile.path}');

        if (await imageFile.exists()) {
          final bytes = await imageFile.readAsBytes();
          debugPrint('Image file size: ${bytes.length} bytes');

          final ui.Image image = await decodeImageFromList(bytes);
          debugPrint(
            'Image decoded successfully: ${image.width}x${image.height}',
          );

          if (mounted) {
            setState(() {
              _mapImageSize = Size(
                image.width.toDouble(),
                image.height.toDouble(),
              );
              _isImageLoaded = true;
            });

            // Auto-fit image when first loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _autoFitImage();
              }
            });
          }
        } else {
          debugPrint('ERROR: Image file does not exist!');
          if (mounted) {
            setState(() {
              _mapImageSize = const Size(1200, 800);
              _isImageLoaded = true;
            });
          }
        }
      } catch (e) {
        debugPrint('ERROR loading map image: $e');
        if (mounted) {
          setState(() {
            _mapImageSize = const Size(1200, 800);
            _isImageLoaded = true;
          });
        }
      }
    } else {
      debugPrint('No image path or hasImage is false');
      if (mounted) {
        setState(() {
          _mapImageSize = const Size(1200, 800); // Default size for grid
          _isImageLoaded = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _autoFitImage();
          }
        });
      }
    }
  }

  void _autoFitImage() {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _mapImageSize == null) return;

    final containerSize = renderBox.size;
    final imageSize = _mapImageSize!;

    debugPrint('AutoFit - Container: ${containerSize}, Image: ${imageSize}');

    // คำนวณ scale ที่เหมาะสมเพื่อให้รูปภาพพอดีกับ container
    final scaleX = containerSize.width / imageSize.width;
    final scaleY = containerSize.height / imageSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.85; // ลดลง 15% เพื่อให้มี margin

    debugPrint('AutoFit scales - X: $scaleX, Y: $scaleY, Final: $scale');

    // คำนวณตำแหน่งที่จะทำให้ภาพอยู่กลาง container
    final scaledImageWidth = imageSize.width * scale;
    final scaledImageHeight = imageSize.height * scale;
    
    final offsetX = (containerSize.width - scaledImageWidth) / 2;
    final offsetY = (containerSize.height - scaledImageHeight) / 2;

    // สร้าง transformation matrix แบบใหม่
    final matrix = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(scale);

    debugPrint('AutoFit - Offset: ($offsetX, $offsetY), Scale: $scale');

    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== InteractiveMapImproved build ===');
    debugPrint('IsImageLoaded: $_isImageLoaded');
    debugPrint('MapImageSize: $_mapImageSize');
    debugPrint('MapData in build: ${widget.mapData?.name}');
    debugPrint('HasImage in build: ${widget.mapData?.hasImage}');

    if (!_isImageLoaded) {
      debugPrint('Showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }

    final positionedRooms = widget.rooms
        .where((room) => room.hasPosition)
        .toList();
    final availableRooms = widget.rooms
        .where((room) => !room.hasPosition)
        .toList();

    debugPrint('Positioned rooms: ${positionedRooms.length}');
    debugPrint('Available rooms: ${availableRooms.length}');

    return LayoutBuilder(
      builder: (context, constraints) {
        // คำนวณขนาดที่เหมาะสมสำหรับ UI
        final availableHeight = constraints.maxHeight;
        final roomPanelHeight = widget.isEditable && availableRooms.isNotEmpty
            ? 140.0
            : 0.0;
        final mapHeight =
            availableHeight - roomPanelHeight - 16; // 16 for spacing

        return Column(
          children: [
            // Available rooms panel at top (แก้ไข overflow)
            if (widget.isEditable && availableRooms.isNotEmpty)
              SizedBox(
                height: roomPanelHeight,
                child: _buildAvailableRoomsScrollablePanel(availableRooms),
              ),

            if (widget.isEditable && availableRooms.isNotEmpty)
              const SizedBox(height: 8),

            // Map container with controlled height
            Expanded(
              child: Container(
                height: mapHeight > 200 ? mapHeight : 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // InteractiveViewer for map
                      InteractiveViewer(
                        key: _containerKey,
                        transformationController: _transformationController,
                        minScale: 0.1,
                        maxScale: 5.0,
                        boundaryMargin: const EdgeInsets.all(50),
                        constrained: false,
                        scaleEnabled: true,
                        panEnabled: true,
                        child: Container(
                          width: _mapImageSize?.width ?? 1200,
                          height: _mapImageSize?.height ?? 800,
                          child: DragTarget<Room>(
                            onAccept: (room) {
                              // This will be handled by individual positioned drag targets
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Stack(
                                children: [
                                  // Background Map Image or Grid
                                  _buildMapBackground(),

                                  // Drag target overlay for positioning
                                  if (widget.isEditable)
                                    _buildDragTargetOverlay(),

                                  // Room widgets that are already positioned
                                  ...positionedRooms.map(
                                    (room) => _buildPositionedRoomWidget(room),
                                  ),

                                  // Drop zone indicator (when dragging)
                                  if (_draggedRoom != null &&
                                      _dragOffset != null)
                                    _buildDropZoneIndicator(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      // Zoom controls overlay
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildZoomControls(),
                      ),
                      // Status indicator
                      if (widget.isEditable)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: _buildStatusIndicator(
                            positionedRooms.length,
                            availableRooms.length,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapBackground() {
    // Debug: ตรวจสอบข้อมูลแผนที่
    debugPrint('=== _buildMapBackground Debug ===');
    debugPrint('MapData: ${widget.mapData?.name}');
    debugPrint('HasImage: ${widget.mapData?.hasImage}');
    debugPrint('ImagePath: ${widget.mapData?.imagePath}');
    debugPrint('MapImageSize: $_mapImageSize');

    return Container(
      width: _mapImageSize?.width ?? 1200,
      height: _mapImageSize?.height ?? 800,
      child:
          widget.mapData?.hasImage == true && widget.mapData?.imagePath != null
          ? Image.file(
              File(widget.mapData!.imagePath!),
              fit: BoxFit.cover, // เปลี่ยนกลับเป็น cover เพื่อคงอัตราส่วน
              errorBuilder: (context, error, stackTrace) {
                debugPrint('ERROR loading image in UI: $error');
                debugPrint('Stack trace: $stackTrace');
                return _buildGridBackground();
              },
              // เพิ่ม cache สำหรับปรับปรุงประสิทธิภาพ
              cacheWidth: 1920, // จำกัดความกว้างสูงสุด
              cacheHeight: 1920, // จำกัดความสูงสูงสุด
            )
          : _buildGridBackground(),
    );
  }

  Widget _buildGridBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: GridPainter(),
            size: Size(
              _mapImageSize?.width ?? 1200,
              _mapImageSize?.height ?? 800,
            ),
          ),
          // แสดงข้อความเมื่อไม่มีแผนที่
          if (widget.mapData == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีแผนที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรุณาตั้งแผนที่หลักในแท็บ "แผนที่"',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (widget.mapData!.hasImage == false)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่มีภาพแผนที่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'กรุณาเพิ่มภาพแผนที่ในแท็บ "แผนที่"',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // แสดงรายการห้องที่ยังไม่ได้วางตำแหน่งแบบ scrollable (แก้ไข overflow และเพิ่ม scrollable)
  Widget _buildAvailableRoomsScrollablePanel(List<Room> availableRooms) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                Expanded(
                  child: Text(
                    'ห้องที่รอวาง (${availableRooms.length} ห้อง)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ลากห้องมาวางบนแผนที่',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Scrollable content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: availableRooms.isEmpty
                  ? Center(
                      child: Text(
                        'ทุกห้องถูกวางบนแผนที่แล้ว',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: availableRooms.length,
                      itemBuilder: (context, index) {
                        final room = availableRooms[index];
                        return _buildImprovedDraggableRoomCard(room);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedDraggableRoomCard(Room room) {
    final (width, height) = room.getSizeForUI();

    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Draggable<Room>(
        data: room,
        feedback: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          child: _buildRoomContainer(room, width, height, isDragging: true),
        ),
        childWhenDragging: Container(
          width: 110,
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 4),
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
                  Icon(Icons.open_with, color: Colors.grey.shade600, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    'กำลังลาก',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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
          // เมื่อปล่อย drag ให้วางห้องที่ตำแหน่งที่ปล่อย
          if (widget.onRoomPositionChanged != null) {
            final RenderBox? renderBox =
                _containerKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPosition = renderBox.globalToLocal(details.offset);
              _handleRoomDrop(room, localPosition);
            }
          }

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
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: _getRoomStatusColor(room.status).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getRoomStatusColor(room.status).withValues(alpha: 0.4),
                  _getRoomStatusColor(room.status).withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRoomStatusColor(
                      room.status,
                    ).withValues(alpha: 0.6),
                    border: Border.all(
                      color: _getRoomStatusColor(room.status),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getRoomStatusIcon(room.status),
                    size: 16,
                    color: _getRoomStatusColor(room.status),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  room.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getRoomStatusColor(room.status),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${room.size.displayName} • ${room.capacity} คน',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับห้องที่วางตำแหน่งแล้ว
  Widget _buildPositionedRoomWidget(Room room) {
    debugPrint(
      'Building positioned room: ${room.name} at (${room.positionX}, ${room.positionY})',
    );

    final (width, height) = room.getSizeForUI();

    // คำนวณตำแหน่งจาก percentage เป็น absolute position
    final imageSize = _mapImageSize ?? const Size(1200, 800);
    final absoluteX = (room.positionX! / 100) * imageSize.width;
    final absoluteY = (room.positionY! / 100) * imageSize.height;

    debugPrint(
      'Room ${room.name}: percentage(${room.positionX}, ${room.positionY}) -> absolute(${absoluteX}, ${absoluteY})',
    );

    return Transform.translate(
      offset: Offset(absoluteX - (width / 2), absoluteY - (height / 2)),
      child: widget.isEditable
          ? Draggable<Room>(
              data: room,
              feedback: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(8),
                child: _buildRoomContainer(
                  room,
                  width,
                  height,
                  isDragging: true,
                ),
              ),
              childWhenDragging: _buildRoomContainer(
                room,
                width,
                height,
                isPlaceholder: true,
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
              child: _buildRoomContainer(room, width, height),
            )
          : GestureDetector(
              onTap: () => widget.onRoomTap?.call(room),
              child: _buildRoomContainer(room, width, height),
            ),
    );
  }

  // สร้าง overlay สำหรับรับ drag target ทั่วแผนที่ (ปรับปรุงการทำงาน)
  Widget _buildDragTargetOverlay() {
    final imageSize = _mapImageSize ?? const Size(1200, 800);

    return Positioned.fill(
      child: DragTarget<Room>(
        onAcceptWithDetails: (details) {
          // จัดการการวางห้องเมื่อปล่อย drag
          if (widget.onRoomPositionChanged != null && details.data != null) {
            final RenderBox? renderBox =
                _containerKey.currentContext?.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPosition = renderBox.globalToLocal(details.offset);
              _handleRoomDrop(details.data!, localPosition);
            }
          }
        },
        onWillAcceptWithDetails: (details) {
          return details.data != null && widget.onRoomPositionChanged != null;
        },
        builder: (context, candidateData, rejectedData) {
          final isDragging = candidateData.isNotEmpty;

          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
            child: isDragging
                ? Stack(
                    children: [
                      // Grid pattern when dragging
                      CustomPaint(
                        painter: DropZoneGridPainter(),
                        size: Size.infinite,
                      ),
                      // Center instruction
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'ปล่อยที่นี่เพื่อวางห้อง',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                candidateData.isNotEmpty &&
                                        candidateData.first != null
                                    ? 'กำลังวาง: ${candidateData.first!.name}'
                                    : '',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }

  // ฟังก์ชันใหม่สำหรับจัดการการวางห้อง (แก้ไขการคำนวณตำแหน่ง)
  void _handleRoomDrop(Room room, Offset localPosition) {
    if (widget.onRoomPositionChanged == null) return;

    // หา RenderBox ของ InteractiveViewer
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final containerSize = renderBox.size;
    final imageSize = _mapImageSize ?? const Size(1200, 800);

    // คำนวณ scale ปัจจุบันของ InteractiveViewer
    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    // คำนวณ offset ของ InteractiveViewer (pan)
    final offsetX = matrix.getTranslation().x;
    final offsetY = matrix.getTranslation().y;

    // แปลงตำแหน่ง local เป็นตำแหน่งในภาพ (คำนึงถึง zoom และ pan)
    final imageX = (localPosition.dx - offsetX) / currentScale;
    final imageY = (localPosition.dy - offsetY) / currentScale;

    // แปลงเป็น percentage และ clamp ให้อยู่ในขอบเขต
    final percentX = (imageX / imageSize.width * 100).clamp(0.0, 100.0);
    final percentY = (imageY / imageSize.height * 100).clamp(0.0, 100.0);

    // เรียก callback พร้อมตำแหน่งที่ถูกต้อง
    widget.onRoomPositionChanged!(room, Offset(percentX, percentY));

    debugPrint(
      'Drop position: local(${localPosition.dx}, ${localPosition.dy}) -> image(${imageX}, ${imageY}) -> percent(${percentX}, ${percentY})',
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
    backgroundColor = _getRoomStatusColor(room.status).withValues(alpha: 0.8);
    borderColor = _getRoomStatusColor(room.status);
    icon = _getRoomStatusIcon(room.status);

    if (isPlaceholder) {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade400;
    } else if (isDragging) {
      backgroundColor = backgroundColor.withValues(alpha: 0.9);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isDragging
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.7),
                ],
              )
            : null,
        color: isDragging ? null : backgroundColor,
        border: Border.all(color: borderColor, width: isDragging ? 3 : 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
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
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: borderColor,
              size: height > 35
                  ? 18
                  : height > 25
                  ? 14
                  : 10,
            ),
          ),
          if (height > 30) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                room.name,
                style: TextStyle(
                  fontSize: width > 80
                      ? 12
                      : width > 60
                      ? 10
                      : 9,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (height > 45)
              Text(
                '${room.capacity} คน',
                style: TextStyle(
                  fontSize: 8,
                  color: borderColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
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
      left: _dragOffset!.dx - 35,
      top: _dragOffset!.dy - 35,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.3),
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.green, size: 20),
            const SizedBox(height: 2),
            Text(
              _draggedRoom!.name,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              'วาง',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // เพิ่ม Zoom Controls Widget
  Widget _buildZoomControls() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              final currentMatrix = _transformationController.value;
              final currentScale = currentMatrix.getMaxScaleOnAxis();
              final newScale = (currentScale * 1.3).clamp(0.1, 5.0);
              
              // สร้าง matrix ใหม่โดยรักษาตำแหน่งปัจจุบัน
              final translation = currentMatrix.getTranslation();
              final newMatrix = Matrix4.identity()
                ..translate(translation.x, translation.y)
                ..scale(newScale);
              
              _transformationController.value = newMatrix;
            },
            icon: const Icon(Icons.zoom_in, size: 20),
            tooltip: 'ขยาย',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: () {
              final currentMatrix = _transformationController.value;
              final currentScale = currentMatrix.getMaxScaleOnAxis();
              final newScale = (currentScale / 1.3).clamp(0.1, 5.0);
              
              // สร้าง matrix ใหม่โดยรักษาตำแหน่งปัจจุบัน
              final translation = currentMatrix.getTranslation();
              final newMatrix = Matrix4.identity()
                ..translate(translation.x, translation.y)
                ..scale(newScale);
              
              _transformationController.value = newMatrix;
            },
            icon: const Icon(Icons.zoom_out, size: 20),
            tooltip: 'ย่อ',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: () {
              // บังคับให้ autofit ทำงานแม้จะมีภาพแล้ว
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _autoFitImage();
                }
              });
            },
            icon: const Icon(Icons.fit_screen, size: 20),
            tooltip: 'ปรับขนาดพอดีหน้าจอ',
          ),
        ],
      ),
    );
  }

  // เพิ่ม Status Indicator Widget
  Widget _buildStatusIndicator(int positionedCount, int availableCount) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              'วางแล้ว: $positionedCount | รอวาง: $availableCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // วาดเส้นแนวนอน
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8),
        ),
      );

    _drawDashedPath(canvas, path, dashPattern, paint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    List<double> pattern,
    Paint paint,
  ) {
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

/// Custom Painter สำหรับวาด Drop Zone Grid
class DropZoneGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 50.0;

    // วาดเส้นแนวตั้ง
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // วาดเส้นแนวนอน
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
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
    return InteractiveMapImproved(
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
          child: InteractiveMapImproved(
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
                    'วิธีใช้: ลากห้องเพื่อย้ายตำแหน่ง | คลิกห้องเพื่อเลือก | ใช้ปุ่มซูมเพื่อขยาย/ย่อ',
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
