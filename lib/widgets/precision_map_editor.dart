import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/room_model.dart';
// import '../services/map_service.dart'; // Not used in this widget

/// Widget สำหรับ Drag & Drop แผนที่ที่แม่นยำสูง
class PrecisionMapEditor extends StatefulWidget {
  final List<Room> rooms;
  final MapData? mapData;
  final Function(Room)? onRoomTap;
  final Function(Room, Offset)? onRoomPositionChanged;

  const PrecisionMapEditor({
    super.key,
    this.rooms = const [],
    this.mapData,
    this.onRoomTap,
    this.onRoomPositionChanged,
  });

  @override
  State<PrecisionMapEditor> createState() => _PrecisionMapEditorState();
}

class _PrecisionMapEditorState extends State<PrecisionMapEditor> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _mapContainerKey = GlobalKey();
  Size? _mapImageSize;
  bool _isImageLoaded = false;
  Room? _draggedRoom;

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
    if (widget.mapData?.hasImage == true) {
      try {
        final File imageFile = File(widget.mapData!.imagePath!);
        final bytes = await imageFile.readAsBytes();
        final ui.Image image = await decodeImageFromList(bytes);
        
        setState(() {
          _mapImageSize = Size(image.width.toDouble(), image.height.toDouble());
          _isImageLoaded = true;
        });

        // Auto-fit image when first loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoFitImage();
        });
      } catch (e) {
        debugPrint('Error loading map image: $e');
      }
    } else {
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
    final RenderBox? renderBox = _mapContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || _mapImageSize == null) return;

    final containerSize = renderBox.size;
    final imageSize = _mapImageSize!;

    // Calculate appropriate scale to fit image in container
    final scaleX = containerSize.width / imageSize.width;
    final scaleY = containerSize.height / imageSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9; // 90% to provide margin

    // Calculate center position
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;

    // Create transformation matrix
    final matrix = Matrix4.identity()
      ..translate(-centerX, -centerY) // Move to center
      ..scale(scale) // Scale
      ..translate(containerSize.width / 2, containerSize.height / 2); // Move back to container center

    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isImageLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final positionedRooms = widget.rooms.where((room) => room.hasPosition).toList();
    final availableRooms = widget.rooms.where((room) => !room.hasPosition).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header with instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ลากห้องจากด้านล่างมาวางบนแผนที่ • ใช้สองนิ้วเพื่อซูม/แพน',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map container with InteractiveViewer
          Expanded(
            flex: 7, // Take most of the space
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
                child: Stack(
                  children: [
                    // Interactive Map with precise drag handling
                    InteractiveViewer(
                      key: _mapContainerKey,
                      transformationController: _transformationController,
                      minScale: 0.1,
                      maxScale: 5.0,
                      boundaryMargin: const EdgeInsets.all(50),
                      constrained: false,
                      child: _buildMapWithDragTarget(positionedRooms),
                    ),

                    // Zoom controls
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildZoomControls(),
                    ),

                    // Status indicator
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _buildStatusIndicator(positionedRooms.length, availableRooms.length),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Available rooms panel (scrollable horizontally)
          if (availableRooms.isNotEmpty)
            Flexible(
              flex: 2, // Limited space to prevent overflow
              child: Container(
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
                child: _buildAvailableRoomsList(availableRooms),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapWithDragTarget(List<Room> positionedRooms) {
    final imageSize = _mapImageSize ?? const Size(1200, 800);

    return SizedBox(
      width: imageSize.width,
      height: imageSize.height,
      child: DragTarget<Room>(
        onAcceptWithDetails: (details) => _handleRoomDrop(details),
        onWillAcceptWithDetails: (details) => true,
        builder: (context, candidateData, rejectedData) {
          final isDragging = candidateData.isNotEmpty;
          
          return Stack(
            children: [
              // Background map image or grid
              _buildMapBackground(imageSize),

              // Drop zone overlay when dragging
              if (isDragging)
                _buildDropZoneOverlay(),

              // Positioned room widgets
              ...positionedRooms.map((room) => _buildPositionedRoomWidget(room, imageSize)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapBackground(Size imageSize) {
    return SizedBox(
      width: imageSize.width,
      height: imageSize.height,
      child: widget.mapData?.hasImage == true
          ? Image.file(
              File(widget.mapData!.imagePath!),
              fit: BoxFit.cover,
              width: imageSize.width,
              height: imageSize.height,
              errorBuilder: (context, error, stackTrace) => _buildGridBackground(imageSize),
            )
          : _buildGridBackground(imageSize),
    );
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
    
    // Convert percentage position to absolute position
    final absoluteX = (room.positionX! / 100) * imageSize.width;
    final absoluteY = (room.positionY! / 100) * imageSize.height;
    
    return Positioned(
      left: absoluteX - (width / 2),
      top: absoluteY - (height / 2),
      child: Draggable<Room>(
        data: room,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: _buildRoomWidget(room, width, height, isDragging: true),
        ),
        childWhenDragging: _buildRoomWidget(room, width, height, isPlaceholder: true),
        onDragStarted: () => setState(() => _draggedRoom = room),
        onDragEnd: (details) => setState(() => _draggedRoom = null),
        child: GestureDetector(
          onTap: () => widget.onRoomTap?.call(room),
          child: _buildRoomWidget(room, width, height),
        ),
      ),
    );
  }

  Widget _buildAvailableRoomsList(List<Room> availableRooms) {
    return Column(
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
              Icon(Icons.swipe, color: Colors.grey.shade600, size: 16),
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
        onDragStarted: () => setState(() => _draggedRoom = room),
        onDragEnd: (details) => setState(() => _draggedRoom = null),
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.2),
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _getRoomStatusIcon(room.status),
                size: 12,
                color: borderColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              room.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
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
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomWidget(Room room, double width, double height, {bool isDragging = false, bool isPlaceholder = false}) {
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
        borderRadius: BorderRadius.circular(6),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getRoomStatusIcon(room.status),
            color: borderColor,
            size: height > 30 ? 14 : 10,
          ),
          if (height > 25) ...[
            const SizedBox(height: 2),
            Text(
              room.name,
              style: TextStyle(
                fontSize: width > 60 ? 9 : 7,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

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
              final newMatrix = currentMatrix.clone()..scale(1.2);
              _transformationController.value = newMatrix;
            },
            icon: const Icon(Icons.zoom_in, size: 18),
            tooltip: 'ขยาย',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: () {
              final currentMatrix = _transformationController.value;
              final newMatrix = currentMatrix.clone()..scale(0.8);
              _transformationController.value = newMatrix;
            },
            icon: const Icon(Icons.zoom_out, size: 18),
            tooltip: 'ย่อ',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: _autoFitImage,
            icon: const Icon(Icons.fit_screen, size: 18),
            tooltip: 'ปรับขนาด',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(int positionedCount, int availableCount) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Text(
              'วางแล้ว: $positionedCount | รอวาง: $availableCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRoomDrop(DragTargetDetails<Room> details) {
    final room = details.data;
    if (widget.onRoomPositionChanged == null) return;

    // Get the render box of the map container to calculate local position
    final RenderBox? renderBox = _mapContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Convert global position to local position within the map
    final localPosition = renderBox.globalToLocal(details.offset);
    
    // Account for the transformation (zoom/pan) of InteractiveViewer
    final matrix = _transformationController.value;
    final inverse = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(inverse, localPosition);
    
    // Convert to percentage relative to image size
    final imageSize = _mapImageSize ?? const Size(1200, 800);
    final percentX = (transformedPoint.dx / imageSize.width * 100).clamp(0.0, 100.0);
    final percentY = (transformedPoint.dy / imageSize.height * 100).clamp(0.0, 100.0);

    // Call the callback with the calculated position
    widget.onRoomPositionChanged!(room, Offset(percentX, percentY));

    setState(() => _draggedRoom = null);
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

/// Custom Painter for grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double gridSize = 20.0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for drop zone grid
class DropZoneGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double gridSize = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}