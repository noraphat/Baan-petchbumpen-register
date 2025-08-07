import 'dart:async';
import 'package:flutter/foundation.dart';

/// Enhanced card reader service with automatic detection and caching
class EnhancedCardReaderService {
  static const Duration _pollingInterval = Duration(milliseconds: 1500);
  static const Duration _cardCacheTimeout = Duration(minutes: 5);

  Timer? _pollingTimer;
  String? _lastProcessedCardId;
  DateTime? _lastProcessedTime;
  bool _isPolling = false;
  bool _isProcessing = false;

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
      // Check if card reader is connected
      final isConnected = await _checkReaderConnection();

      if (isConnected) {
        _updateStatus(CardReaderStatus.connected);
        await _performInitialCardCheck();
        return true;
      } else {
        _updateStatus(CardReaderStatus.disconnected);
        _emitError('Card reader not connected');
        return false;
      }
    } catch (e) {
      _updateStatus(CardReaderStatus.error);
      _emitError('Failed to initialize card reader: $e');
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

  /// Mock function to check reader connection
  /// Replace this with actual hardware detection logic
  Future<bool> _checkReaderConnection() async {
    // TODO: Implement actual hardware detection
    // For now, simulate connection check
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Assume connected for development
  }

  /// Read ID card data
  /// This should call your existing readIdCard() function
  Future<Map<String, dynamic>?> _readIdCard() async {
    try {
      // TODO: Replace this with your actual readIdCard() implementation
      // For development, return mock data or null

      // Example implementation:
      // final result = await YourCardReaderPlugin.readIdCard();
      // return result;

      // Mock implementation for development
      await Future.delayed(const Duration(milliseconds: 300));

      // Return null to simulate no card (replace with actual implementation)
      return null;

      // Uncomment below for testing with mock data:
      /*
      return {
        'cid': '1234567890123',
        'firstnameTH': 'สมชาย',
        'lastnameTH': 'ใจดี',
        'titleTH': 'นาย',
        'birthdate': '1990-01-01',
        'gender': 1, // 1 = male, 2 = female
        'address': '123 หมู่ 1 ตำบล... อำเภอ... จังหวัด...',
      };
      */
    } catch (e) {
      debugPrint('Error reading ID card: $e');
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
