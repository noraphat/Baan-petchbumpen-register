import 'dart:async';
import 'package:flutter/foundation.dart';
import 'card_reader_service.dart';

/// Enhanced card reader service with automatic detection and caching
class EnhancedCardReaderService {
  static const Duration _pollingInterval = Duration(milliseconds: 1500);
  static const Duration _cardCacheTimeout = Duration(minutes: 5);

  Timer? _pollingTimer;
  String? _lastProcessedCardId;
  DateTime? _lastProcessedTime;
  bool _isPolling = false;
  bool _isProcessing = false;

  // ใช้ CardReaderService จริง
  final CardReaderService _cardReaderService = CardReaderService();

  final StreamController<CardReaderEvent> _eventController =
      StreamController<CardReaderEvent>.broadcast();
  final StreamController<String?> _errorController =
      StreamController<String?>.broadcast();
  final StreamController<CardReaderStatus> _statusController =
      StreamController<CardReaderStatus>.broadcast();

  // Streams for external listeners
  Stream<CardReaderEvent> get eventStream => _eventController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<CardReaderStatus> get statusStream => _statusController.stream;

  CardReaderStatus _currentStatus = CardReaderStatus.disconnected;
  CardReaderStatus get currentStatus => _currentStatus;

  /// Initialize the card reader service
  Future<bool> initialize() async {
    try {
      debugPrint('🔧 EnhancedCardReaderService: เริ่มต้นระบบ...');
      
      // เริ่มต้น CardReaderService จริง
      await _cardReaderService.initialize();
      
      // ตรวจสอบการเชื่อมต่อ
      final isConnected = await _cardReaderService.checkConnection();

      if (isConnected) {
        debugPrint('✅ EnhancedCardReaderService: เชื่อมต่อสำเร็จ');
        _updateStatus(CardReaderStatus.connected);
        await _performInitialCardCheck();
        return true;
      } else {
        debugPrint('❌ EnhancedCardReaderService: ไม่สามารถเชื่อมต่อได้');
        _updateStatus(CardReaderStatus.disconnected);
        _emitError('Card reader not connected');
        return false;
      }
    } catch (e) {
      debugPrint('❌ EnhancedCardReaderService: เริ่มต้นล้มเหลว - $e');
      _updateStatus(CardReaderStatus.error);
      _emitError('Failed to initialize card reader: $e');
      return false;
    }
  }

  /// ตรวจสอบและฟื้นฟูการเชื่อมต่อ (สำหรับกรณีที่กลับมาหน้า card reader)
  Future<bool> ensureConnection() async {
    try {
      debugPrint(
        '🔧 EnhancedCardReaderService: ตรวจสอบและฟื้นฟูการเชื่อมต่อ...',
      );

      // 1. ใช้ ensureConnection จาก CardReaderService ที่มีการตรวจสอบแบบแข็งแกร่ง
      final isConnected = await _cardReaderService.ensureConnection();

      if (isConnected) {
        debugPrint(
          '✅ EnhancedCardReaderService: การเชื่อมต่อปัจจุบันใช้งานได้',
        );
        _updateStatus(CardReaderStatus.connected);
        return true;
      }

      // 2. ถ้าไม่สำเร็จ ให้ลองรีเซ็ตการเชื่อมต่อ
      debugPrint('🔄 EnhancedCardReaderService: ลองรีเซ็ตการเชื่อมต่อ...');
      _updateStatus(CardReaderStatus.disconnected);

      // 3. รีเซ็ตการเชื่อมต่อแบบเร็ว
      await _cardReaderService.quickResetConnection();

      // 4. ตรวจสอบอีกครั้ง
      final isReconnected = await _cardReaderService.checkConnection();
      
      if (isReconnected) {
        debugPrint('✅ EnhancedCardReaderService: รีเซ็ตและเชื่อมต่อสำเร็จ');
        _updateStatus(CardReaderStatus.connected);
        return true;
      } else {
        debugPrint('❌ EnhancedCardReaderService: ไม่สามารถฟื้นฟูการเชื่อมต่อได้');
        _updateStatus(CardReaderStatus.disconnected);
        return false;
      }
    } catch (e) {
      debugPrint('❌ EnhancedCardReaderService: ฟื้นฟูการเชื่อมต่อล้มเหลว - $e');
      _updateStatus(CardReaderStatus.error);
      return false;
    }
  }

  /// Start automatic card monitoring
  Future<bool> startMonitoring() async {
    if (_isPolling) {
      debugPrint('Card monitoring is already running');
      return true;
    }

    if (_currentStatus != CardReaderStatus.connected) {
      _emitError('Card reader is not connected');
      return false;
    }

    try {
      _isPolling = true;
      _updateStatus(CardReaderStatus.monitoring);

      // Start polling timer
      _pollingTimer = Timer.periodic(_pollingInterval, (_) => _checkForCard());

      // Also perform an immediate check
      await _checkForCard();

      debugPrint(
        'Card monitoring started with ${_pollingInterval.inMilliseconds}ms interval',
      );
      return true;
    } catch (e) {
      _isPolling = false;
      _updateStatus(CardReaderStatus.error);
      _emitError('Failed to start monitoring: $e');
      return false;
    }
  }

  /// Stop automatic card monitoring
  void stopMonitoring() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }

    _isPolling = false;

    if (_currentStatus == CardReaderStatus.monitoring) {
      _updateStatus(CardReaderStatus.connected);
    }

    debugPrint('Card monitoring stopped');
  }

  /// Manually check for card (fallback option)
  Future<void> manualCardCheck() async {
    if (_isProcessing) {
      debugPrint('Card processing already in progress');
      return;
    }

    debugPrint('Manual card check requested');
    await _checkForCard(forceCheck: true);
  }

  /// Check for card presence and process if new card detected
  Future<void> _checkForCard({bool forceCheck = false}) async {
    if (_isProcessing && !forceCheck) {
      return;
    }

    try {
      _isProcessing = true;

      // Read card data (this is your existing readIdCard() function)
      final cardData = await _readIdCard();

      if (cardData != null && cardData.isNotEmpty) {
        final currentCardId = cardData['cid'] as String?;

        if (currentCardId != null && currentCardId.isNotEmpty) {
          // Check if this is a new card or if we should reprocess
          if (_shouldProcessCard(currentCardId, forceCheck)) {
            debugPrint('New card detected: $currentCardId');

            // Update cache
            _lastProcessedCardId = currentCardId;
            _lastProcessedTime = DateTime.now();

            // Emit card detected event
            _eventController.add(
              CardReaderEvent(
                type: CardReaderEventType.cardDetected,
                cardData: IdCardData.fromMap(cardData),
                timestamp: DateTime.now(),
              ),
            );

            _updateStatus(CardReaderStatus.cardPresent);
          } else {
            // Card is already processed and still present
            if (_currentStatus != CardReaderStatus.cardPresent) {
              _updateStatus(CardReaderStatus.cardPresent);
            }
          }
        } else {
          _handleNoCardOrInvalidData();
        }
      } else {
        _handleNoCardOrInvalidData();
      }
    } catch (e) {
      debugPrint('Error checking for card: $e');
      _emitError('Error reading card: $e');
      _updateStatus(CardReaderStatus.error);
    } finally {
      _isProcessing = false;
    }
  }

  /// Handle case when no card is present or data is invalid
  void _handleNoCardOrInvalidData() {
    if (_currentStatus == CardReaderStatus.cardPresent) {
      debugPrint('Card removed or no longer readable');

      _eventController.add(
        CardReaderEvent(
          type: CardReaderEventType.cardRemoved,
          cardData: null,
          timestamp: DateTime.now(),
        ),
      );

      _updateStatus(CardReaderStatus.monitoring);
    }
  }

  /// Check if we should process this card
  bool _shouldProcessCard(String cardId, bool forceCheck) {
    if (forceCheck) return true;

    // If no previous card processed
    if (_lastProcessedCardId == null) return true;

    // If different card
    if (_lastProcessedCardId != cardId) return true;

    // If same card but cache has expired
    if (_lastProcessedTime != null) {
      final timeSinceLastProcess = DateTime.now().difference(
        _lastProcessedTime!,
      );
      if (timeSinceLastProcess > _cardCacheTimeout) {
        debugPrint('Card cache expired, allowing reprocessing');
        return true;
      }
    }

    return false;
  }

  /// Perform initial card check when service starts
  Future<void> _performInitialCardCheck() async {
    debugPrint('Performing initial card check...');
    await _checkForCard(forceCheck: true);
  }

  /// Check reader connection using CardReaderService
  Future<bool> _checkReaderConnection() async {
    try {
      return await _cardReaderService.checkConnection();
    } catch (e) {
      debugPrint('Error checking reader connection: $e');
      return false;
    }
  }

  /// Read ID card data using CardReaderService
  Future<Map<String, dynamic>?> _readIdCard() async {
    try {
      // ใช้ CardReaderService จริงในการอ่านบัตร
      final cardData = await _cardReaderService.readCard();
      
      if (cardData != null && cardData.isValid) {
        return {
          'cid': cardData.cid,
          'firstnameTH': cardData.firstnameTH ?? '',
          'lastnameTH': cardData.lastnameTH ?? '',
          'titleTH': cardData.titleTH ?? '',
          'birthdate': cardData.birthdate ?? '',
          'gender': cardData.gender ?? 0,
          'address': cardData.address ?? '',
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Error reading ID card: $e');
      
      // ถ้าเป็น CardReaderException ให้ส่งต่อ error message
      if (e is CardReaderException) {
        _emitError(e.message);
      } else {
        _emitError('เกิดข้อผิดพลาดในการอ่านบัตร: $e');
      }
      
      return null;
    }
  }

  /// Update status and notify listeners
  void _updateStatus(CardReaderStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('Card reader status changed to: $status');
    }
  }

  /// Emit error to listeners
  void _emitError(String error) {
    debugPrint('Card reader error: $error');
    _errorController.add(error);
  }

  /// Clear the processed card cache
  void clearCache() {
    _lastProcessedCardId = null;
    _lastProcessedTime = null;
    debugPrint('Card cache cleared');
  }

  /// Get cache information
  Map<String, dynamic> getCacheInfo() {
    return {
      'lastProcessedCardId': _lastProcessedCardId,
      'lastProcessedTime': _lastProcessedTime?.toIso8601String(),
      'cacheAge': _lastProcessedTime != null
          ? DateTime.now().difference(_lastProcessedTime!).inMinutes
          : null,
    };
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _eventController.close();
    _errorController.close();
    _statusController.close();
    // ไม่ต้อง dispose CardReaderService เพราะเป็น singleton
    debugPrint('Enhanced card reader service disposed');
  }
}

/// Card reader status enumeration
enum CardReaderStatus {
  disconnected,
  connected,
  monitoring,
  cardPresent,
  error,
}

/// Card reader event types
enum CardReaderEventType { cardDetected, cardRemoved, error }

/// Card reader event class
class CardReaderEvent {
  final CardReaderEventType type;
  final IdCardData? cardData;
  final DateTime timestamp;

  CardReaderEvent({
    required this.type,
    required this.cardData,
    required this.timestamp,
  });
}

/// ID Card data model
class IdCardData {
  final String id;
  final String firstName;
  final String lastName;
  final String title;
  final String dateOfBirth;
  final String gender;
  final String address;

  IdCardData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.dateOfBirth,
    required this.gender,
    required this.address,
  });

  factory IdCardData.fromMap(Map<String, dynamic> map) {
    return IdCardData(
      id: map['cid'] ?? '',
      firstName: map['firstnameTH'] ?? '',
      lastName: map['lastnameTH'] ?? '',
      title: map['titleTH'] ?? '',
      dateOfBirth: map['birthdate'] ?? '',
      gender: map['gender'] == 1 ? 'ชาย' : 'หญิง',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
    };
  }

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
}
