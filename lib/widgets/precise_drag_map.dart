import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room_model.dart';

/// Widget สำหรับ Drag & Drop แผนที่ที่แม่นยำสูง โดยไม่มีปุ่ม zoom
class PreciseDragMap extends StatefulWidget {
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;
  final Function(Room, Offset)? onRoomPositionChanged;

  const PreciseDragMap({
    super.key,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
    this.onRoomPositionChanged,
  });

  @override
  State<PreciseDragMap> createState() => _PreciseDragMapState();
}

class _PreciseDragMapState extends State<PreciseDragMap>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _mapStackKey = GlobalKey();
  Size? _mapImageSize;
  bool _isImageLoaded = false;
  
  // Animation controllers
  late AnimationController _dropAnimationController;
  late Animation<double> _dropScaleAnimation;
  late Animation<double> _dropOpacityAnimation;
  Room? _animatingRoom;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMapImage();
  }

  void _setupAnimations() {
    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dropScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dropAnimationController,
      curve: Curves.elasticOut,
    ));

    _dropOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dropAnimationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _dropAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadMapImage() async {
    if (widget.mapData?.hasImage == true) {
      try {
        final File imageFile = File(widget.mapData!.imagePath!);
        final bytes = await imageFile.readAsBytes();
        final ui.Image image = await decodeImageFromList(bytes);

        setState(() {
          _mapImageSize = Size(image.width.toDouble(), image.height.toDouble());
          _isImageLoaded = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoFitImage();
        });
      } catch (e) {
        debugPrint('Error loading map image: $e');
      }
    } else {
      setState(() {
        _mapImageSize = const Size(1200, 800);
        _isImageLoaded = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFitImage();
      });
    }
  }

  void _autoFitImage() {
    final RenderBox? renderBox =
        _mapStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _mapImageSize == null) return;

    final containerSize = renderBox.size;
    final imageSize = _mapImageSize!;

    final scaleX = containerSize.width / imageSize.width;
    final scaleY = containerSize.height / imageSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;

    final matrix = Matrix4.identity()
      ..translate(-centerX, -centerY)
      ..scale(scale)
      ..translate(containerSize.width / 2, containerSize.height / 2);

    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImageLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final positionedRooms = widget.rooms.where((room) => room.hasPosition).toList();
    final availableRooms = widget.rooms.where((room) => !room.hasPosition).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header พร้อม hint
          _buildHeader(positionedRooms.length, availableRooms.length),

          // Map area
          Expanded(
            flex: 7,
            child: Container(
              margin: const EdgeInsets.all(8),
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
                borderRadius: BorderRadius.circular(10),
                child: _buildInteractiveMap(positionedRooms),
              ),
            ),
          ),

          // Available rooms list
          if (availableRooms.isNotEmpty)
            Flexible(
              flex: 2,
              child: _buildAvailableRoomsList(availableRooms),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(int positionedCount, int availableCount) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          // Instructions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ลากห้องมาวางบนแผนที่',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.gesture, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'ใช้สองนิ้วเพื่อซูม/แพน แผนที่',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 6),
                Text(
                  'วาง: $positionedCount | รอ: $availableCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(List<Room> positionedRooms) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(50),
      constrained: false,
      child: _buildMapStack(positionedRooms),
    );
  }

  Widget _buildMapStack(List<Room> positionedRooms) {
    final imageSize = _mapImageSize ?? const Size(1200, 800);

    return SizedBox(
      key: _mapStackKey,
      width: imageSize.width,
      height: imageSize.height,
      child: DragTarget<Room>(
        onAcceptWithDetails: (details) => _handlePreciseDrop(details),
        onWillAcceptWithDetails: (details) => true,
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              // Background
              _buildMapBackground(imageSize),

              // Drop zone indicator when dragging
              if (candidateData.isNotEmpty)
                _buildDropZoneOverlay(),

              // Positioned rooms
              ...positionedRooms.map((room) => 
                _buildPositionedRoomWidget(room, imageSize)
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapBackground(Size imageSize) {
    return widget.mapData?.hasImage == true
        ? Image.file(
            File(widget.mapData!.imagePath!),
            width: imageSize.width,
            height: imageSize.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildGridBackground(imageSize),
          )
        : _buildGridBackground(imageSize);
  }

  Widget _buildGridBackground(Size imageSize) {
    return Container(
      width: imageSize.width,
      height: imageSize.height,
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: CustomPaint(
        painter: GridPainter(),
        size: imageSize,
      ),
    );
  }

  Widget _buildDropZoneOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: CustomPaint(
          painter: DropZoneGridPainter(),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget _buildPositionedRoomWidget(Room room, Size imageSize) {
    final (width, height) = room.getSizeForUI();
    
    final absoluteX = (room.positionX! / 100) * imageSize.width;
    final absoluteY = (room.positionY! / 100) * imageSize.height;

    Widget roomWidget = _buildRoomWidget(room, width, height);
    
    // เพิ่ม animation ถ้าเป็นห้องที่เพิ่งวาง
    if (_animatingRoom?.id == room.id) {
      roomWidget = AnimatedBuilder(
        animation: _dropAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _dropScaleAnimation.value,
            child: Opacity(
              opacity: _dropOpacityAnimation.value,
              child: child,
            ),
          );
        },
        child: roomWidget,
      );
    }
    
    return Positioned(
      left: absoluteX - (width / 2),
      top: absoluteY - (height / 2),
      child: Draggable<Room>(
        data: room,
        feedback: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          child: _buildRoomWidget(room, width, height, isDragging: true),
        ),
        childWhenDragging: _buildRoomWidget(room, width, height, isPlaceholder: true),
        onDragStarted: () {},
        onDragEnd: (details) {},
        child: GestureDetector(
          onTap: () => widget.onRoomTap?.call(room),
          child: roomWidget,
        ),
      ),
    );
  }

  Widget _buildRoomWidget(Room room, double width, double height, {
    bool isDragging = false,
    bool isPlaceholder = false,
  }) {
    Color backgroundColor = _getRoomStatusColor(room.status).withValues(alpha: 0.2);
    Color borderColor = _getRoomStatusColor(room.status);
    
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
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            _getRoomStatusIcon(room.status),
            color: borderColor,
            size: height > 30 ? 16 : 12,
          ),
          if (height > 25) ...[
            const SizedBox(height: 2),
            Text(
              room.name,
              style: TextStyle(
                fontSize: width > 80 ? 11 : width > 60 ? 9 : 7,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailableRoomsList(List<Room> availableRooms) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
                Icon(Icons.meeting_room, color: Colors.purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  'ห้องที่รอวาง (${availableRooms.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.touch_app, color: Colors.grey.shade600, size: 16),
              ],
            ),
          ),

          // Horizontal scrollable room list
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: availableRooms
                    .map((room) => _buildDraggableRoomCard(room))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableRoomCard(Room room) {
    return Container(
      width: 100,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Draggable<Room>(
        data: room,
        feedback: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          child: _buildRoomCard(room, isDragging: true),
        ),
        childWhenDragging: _buildRoomCard(room, isPlaceholder: true),
        onDragStarted: () {},
        onDragEnd: (details) {},
        child: _buildRoomCard(room),
      ),
    );
  }

  Widget _buildRoomCard(Room room, {bool isDragging = false, bool isPlaceholder = false}) {
    Color backgroundColor = _getRoomStatusColor(room.status).withValues(alpha: 0.1);
    Color borderColor = _getRoomStatusColor(room.status);
    
    if (isPlaceholder) {
      backgroundColor = Colors.grey.shade200;
      borderColor = Colors.grey.shade400;
    } else if (isDragging) {
      backgroundColor = backgroundColor.withValues(alpha: 0.9);
    }

    return Card(
      elevation: isDragging ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: backgroundColor,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getRoomStatusIcon(room.status),
                size: 14,
                color: borderColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              room.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: borderColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '${room.capacity} คน',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePreciseDrop(DragTargetDetails<Room> details) {
    final room = details.data;
    if (widget.onRoomPositionChanged == null) return;

    // ขั้นตอนการคำนวณตำแหน่งอย่างแม่นยำ
    final RenderBox? stackRenderBox = 
        _mapStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackRenderBox == null) return;

    // 1. แปลง global position เป็น local position ใน Stack
    final localPosition = stackRenderBox.globalToLocal(details.offset);
    
    // 2. Account for InteractiveViewer transformation (zoom/pan)
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(inverse, localPosition);
    
    // 3. แปลงเป็น percentage relative กับขนาดภาพ
    final imageSize = _mapImageSize ?? const Size(1200, 800);
    final percentX = (transformedPoint.dx / imageSize.width * 100).clamp(0.0, 100.0);
    final percentY = (transformedPoint.dy / imageSize.height * 100).clamp(0.0, 100.0);

    // 4. เรียก callback พร้อมตำแหน่งที่แม่นยำ
    widget.onRoomPositionChanged!(room, Offset(percentX, percentY));

    // 5. เล่น animation หลังวางห้อง
    setState(() {
      _animatingRoom = room;
    });
    
    _dropAnimationController.forward().then((_) {
      setState(() => _animatingRoom = null);
      _dropAnimationController.reset();
    });
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

/// Custom Painter สำหรับ grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 20.0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter สำหรับ drop zone grid
class DropZoneGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 50.0;
    
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}