import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:thai_idcard_reader_flutter/thai_idcard_reader_flutter.dart';

/// สถานะการเชื่อมต่อเครื่องอ่านบัตร
enum CardReaderConnectionStatus {
  disconnected,   // ไม่ได้เชื่อมต่อ
  connecting,     // กำลังเชื่อมต่อ
  connected,      // เชื่อมต่อแล้ว
  error,          // เกิดข้อผิดพลาด
}

/// สถานะการอ่านบัตร
enum CardReadingStatus {
  idle,           // ไม่ได้อ่าน
  reading,        // กำลังอ่าน
  success,        // อ่านสำเร็จ
  failed,         // อ่านไม่สำเร็จ
  noCard,         // ไม่พบบัตร
  cardDamaged,    // บัตรเสียหาย
}

/// ข้อมูลจากบัตรประชาชนไทย
class ThaiIdCardData {
  final String cid;
  final String? titleTH;
  final String? firstnameTH;
  final String? lastnameTH;
  final String? titleEN;
  final String? firstnameEN;
  final String? lastnameEN;
  final String? birthdate;
  final int? gender; // 1 = ชาย, 2 = หญิง
  final String? address;
  final String? issueDate;
  final String? expireDate;
  final List<int>? photo;
  final DateTime readTimestamp;

  ThaiIdCardData({
    required this.cid,
    this.titleTH,
    this.firstnameTH,
    this.lastnameTH,
    this.titleEN,
    this.firstnameEN,
    this.lastnameEN,
    this.birthdate,
    this.gender,
    this.address,
    this.issueDate,
    this.expireDate,
    this.photo,
    DateTime? readTimestamp,
  }) : readTimestamp = readTimestamp ?? DateTime.now();

  /// สร้าง ThaiIdCardData จาก ThaiIDCard
  factory ThaiIdCardData.fromThaiIDCard(ThaiIDCard card) {
    return ThaiIdCardData(
      cid: card.cid ?? '',
      titleTH: card.titleTH,
      firstnameTH: card.firstnameTH,
      lastnameTH: card.lastnameTH,
      titleEN: card.titleEN,
      firstnameEN: card.firstnameEN,
      lastnameEN: card.lastnameEN,
      birthdate: card.birthdate,
      gender: card.gender,
      address: card.address,
      issueDate: card.issueDate,
      expireDate: card.expireDate,
      photo: card.photo,
      readTimestamp: DateTime.now(),
    );
  }

  /// ตรวจสอบความถูกต้องของข้อมูลพื้นฐาน
  bool get isValid {
    return cid.isNotEmpty && 
           cid.length == 13 && 
           firstnameTH?.isNotEmpty == true &&
           lastnameTH?.isNotEmpty == true;
  }

  /// ชื่อเต็มภาษาไทย
  String get fullNameTH {
    final parts = [titleTH, firstnameTH, lastnameTH]
        .where((part) => part?.isNotEmpty == true);
    return parts.join(' ');
  }

  /// ชื่อเต็มภาษาอังกฤษ
  String get fullNameEN {
    final parts = [titleEN, firstnameEN, lastnameEN]
        .where((part) => part?.isNotEmpty == true);
    return parts.join(' ');
  }

  /// เพศเป็นข้อความ
  String get genderText {
    switch (gender) {
      case 1:
        return 'ชาย';
      case 2:
        return 'หญิง';
      default:
        return 'ไม่ระบุ';
    }
  }
}

/// Exception สำหรับเครื่องอ่านบัตร
class CardReaderException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  const CardReaderException(this.message, this.code, [this.originalError]);

  @override
  String toString() => 'CardReaderException($code): $message';
}

/// Service สำหรับจัดการเครื่องอ่านบัตรประชาชนไทย
class CardReaderService extends ChangeNotifier {
  static final CardReaderService _instance = CardReaderService._internal();
  factory CardReaderService() => _instance;
  CardReaderService._internal();

  // สถานะ
  CardReaderConnectionStatus _connectionStatus = CardReaderConnectionStatus.disconnected;
  CardReadingStatus _readingStatus = CardReadingStatus.idle;
  UsbDevice? _currentDevice;
  String? _lastError;
  ThaiIdCardData? _lastReadData;
  
  // การตั้งค่า
  Duration _readTimeout = const Duration(seconds: 10);
  final int _maxRetryAttempts = 3;
  Duration _retryDelay = const Duration(seconds: 1);

  // Streams และ Subscriptions
  StreamSubscription<UsbDevice>? _deviceStreamSubscription;
  StreamSubscription? _cardStreamSubscription;
  Timer? _connectionTimer;
  Timer? _readTimeoutTimer;

  // Getters
  CardReaderConnectionStatus get connectionStatus => _connectionStatus;
  CardReadingStatus get readingStatus => _readingStatus;
  UsbDevice? get currentDevice => _currentDevice;
  String? get lastError => _lastError;
  ThaiIdCardData? get lastReadData => _lastReadData;
  bool get isConnected => _connectionStatus == CardReaderConnectionStatus.connected;
  bool get isReading => _readingStatus == CardReadingStatus.reading;

  /// เริ่มต้นการเชื่อมต่อกับเครื่องอ่านบัตร
  Future<void> initialize() async {
    try {
      debugPrint('🔧 CardReaderService: เริ่มต้นการเชื่อมต่อ...');
      _setConnectionStatus(CardReaderConnectionStatus.connecting);
      
      // ตั้งค่า timeout ตาม platform
      _configureTimeouts();
      
      // เริ่มฟัง USB device events
      _startListeningToDeviceEvents();
      
      debugPrint('✅ CardReaderService: เริ่มต้นสำเร็จ');
    } catch (e) {
      debugPrint('❌ CardReaderService: เริ่มต้นล้มเหลว - $e');
      _setError('ไม่สามารถเริ่มต้นเครื่องอ่านบัตรได้', 'INIT_ERROR', e);
    }
  }

  /// ตั้งค่า timeout ตาม platform
  void _configureTimeouts() {
    if (Platform.isAndroid) {
      _readTimeout = const Duration(seconds: 15); // Android ต้องการเวลานานกว่า
      _retryDelay = const Duration(seconds: 2);
    } else {
      _readTimeout = const Duration(seconds: 10); // Desktop เร็วกว่า
      _retryDelay = const Duration(seconds: 1);
    }
    debugPrint('⏱️ CardReaderService: ตั้งค่า timeout = ${_readTimeout.inSeconds}s');
  }

  /// เริ่มฟัง USB device events
  void _startListeningToDeviceEvents() {
    _deviceStreamSubscription?.cancel();
    _deviceStreamSubscription = ThaiIdcardReaderFlutter.deviceHandlerStream.listen(
      _onDeviceEvent,
      onError: _onDeviceError,
    );
  }

  /// จัดการ device events
  void _onDeviceEvent(UsbDevice device) {
    debugPrint('📱 CardReaderService: Device event - ${device.productName}');
    
    _currentDevice = device;
    
    if (device.hasPermission && device.isAttached) {
      _setConnectionStatus(CardReaderConnectionStatus.connected);
      _startListeningToCardEvents();
    } else if (device.isAttached && !device.hasPermission) {
      _setError('ไม่ได้รับอนุญาตใช้งานเครื่องอ่านบัตร', 'NO_PERMISSION');
    } else {
      _setConnectionStatus(CardReaderConnectionStatus.disconnected);
      _stopListeningToCardEvents();
    }
  }

  /// จัดการ device errors
  void _onDeviceError(dynamic error) {
    debugPrint('❌ CardReaderService: Device error - $error');
    _setError('เกิดข้อผิดพลาดในการเชื่อมต่อเครื่องอ่านบัตร', 'DEVICE_ERROR', error);
  }

  /// เริ่มฟัง card events
  void _startListeningToCardEvents() {
    _cardStreamSubscription?.cancel();
    _cardStreamSubscription = ThaiIdcardReaderFlutter.cardHandlerStream.listen(
      _onCardEvent,
      onError: _onCardError,
    );
  }

  /// หยุดฟัง card events
  void _stopListeningToCardEvents() {
    _cardStreamSubscription?.cancel();
  }

  /// จัดการ card events
  void _onCardEvent(dynamic cardEvent) {
    debugPrint('💳 CardReaderService: Card event - ${cardEvent.isReady}');
    
    if (cardEvent.isReady && !isReading) {
      // บัตรพร้อม - อ่านข้อมูลอัตโนมัติ
      _performCardRead();
    } else if (!cardEvent.isReady) {
      // ไม่พบบัตร
      _setReadingStatus(CardReadingStatus.noCard);
    }
  }

  /// จัดการ card errors
  void _onCardError(dynamic error) {
    debugPrint('❌ CardReaderService: Card error - $error');
    _setReadingStatus(CardReadingStatus.failed);
  }

  /// อ่านข้อมูลจากบัตรประชาชน (manual trigger)
  Future<ThaiIdCardData?> readCard({
    int? retryAttempts,
    Duration? timeout,
  }) async {
    if (!isConnected) {
      throw const CardReaderException(
        'เครื่องอ่านบัตรไม่ได้เชื่อมต่อ', 
        'NOT_CONNECTED'
      );
    }

    if (isReading) {
      throw const CardReaderException(
        'กำลังอ่านข้อมูลอยู่', 
        'ALREADY_READING'
      );
    }

    final attempts = retryAttempts ?? _maxRetryAttempts;
    final readTimeout = timeout ?? _readTimeout;

    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        debugPrint('📖 CardReaderService: พยายามอ่านครั้งที่ $attempt/$attempts');
        
        final result = await _performCardRead(timeout: readTimeout);
        if (result != null) {
          return result;
        }
        
        // หากไม่สำเร็จและยังมีการพยายามอีก ให้รอสักครู่
        if (attempt < attempts) {
          await Future.delayed(_retryDelay);
        }
        
      } catch (e) {
        debugPrint('❌ CardReaderService: การพยายามครั้งที่ $attempt ล้มเหลว - $e');
        
        if (attempt == attempts) {
          rethrow; // พ้อความพยายามสุดท้ายแล้ว ให้โยน error
        }
        
        await Future.delayed(_retryDelay);
      }
    }

    throw const CardReaderException(
      'ไม่สามารถอ่านข้อมูลจากบัตรได้หลังจากพยายามหลายครั้ง',
      'READ_FAILED'
    );
  }

  /// ดำเนินการอ่านบัตร
  Future<ThaiIdCardData?> _performCardRead({Duration? timeout}) async {
    _setReadingStatus(CardReadingStatus.reading);
    _clearError();

    final readTimeout = timeout ?? _readTimeout;
    
    try {
      // ตั้งค่า timeout timer
      _readTimeoutTimer?.cancel();
      _readTimeoutTimer = Timer(readTimeout, () {
        throw const CardReaderException(
          'หมดเวลาการอ่านบัตร',
          'READ_TIMEOUT'
        );
      });

      // อ่านข้อมูล
      final result = await ThaiIdcardReaderFlutter.read();
      _readTimeoutTimer?.cancel();

      if (result.cid == null || result.cid!.isEmpty) {
        _setReadingStatus(CardReadingStatus.noCard);
        return null;
      }

      // แปลงเป็น ThaiIdCardData
      final cardData = ThaiIdCardData.fromThaiIDCard(result);
      
      if (!cardData.isValid) {
        _setReadingStatus(CardReadingStatus.cardDamaged);
        throw const CardReaderException(
          'ข้อมูลในบัตรไม่ถูกต้องหรือไม่สมบูรณ์',
          'INVALID_CARD_DATA'
        );
      }

      // บันทึกข้อมูลล่าสุด
      _lastReadData = cardData;
      _setReadingStatus(CardReadingStatus.success);
      
      debugPrint('✅ CardReaderService: อ่านบัตรสำเร็จ - ${cardData.fullNameTH}');
      return cardData;
      
    } catch (e) {
      _readTimeoutTimer?.cancel();
      _setReadingStatus(CardReadingStatus.failed);
      
      if (e is CardReaderException) {
        rethrow;
      } else {
        throw CardReaderException(
          'เกิดข้อผิดพลาดในการอ่านบัตร: $e',
          'READ_ERROR',
          e,
        );
      }
    }
  }

  /// รีเซ็ตการเชื่อมต่อ (Enhanced version with deeper reset)
  Future<void> resetConnection() async {
    try {
      debugPrint('🔄 CardReaderService: เริ่มการรีเซ็ตแบบขั้นสูง...');
      
      _setConnectionStatus(CardReaderConnectionStatus.connecting);
      
      // 1. หยุดการฟังทั้งหมด
      await _stopAllListeners();
      
      // 2. ล้างข้อมูลที่ cache ไว้ทั้งหมด
      _currentDevice = null;
      _lastReadData = null;
      _lastError = null;
      
      // 3. รอให้ USB subsystem ทำงานให้เสร็จ
      debugPrint('⏳ CardReaderService: รอ USB subsystem reset...');
      await Future.delayed(const Duration(seconds: 3));
      
      // 4. เริ่มต้นใหม่
      debugPrint('🔄 CardReaderService: เริ่มต้นระบบใหม่...');
      await initialize();
      
      // 5. รอสักครู่แล้วตรวจสอบสถานะ
      await Future.delayed(const Duration(seconds: 1));
      
      debugPrint('✅ CardReaderService: รีเซ็ตแบบขั้นสูงสำเร็จ');
      
    } catch (e) {
      debugPrint('❌ CardReaderService: รีเซ็ตล้มเหลว - $e');
      _setError('ไม่สามารถรีเซ็ตการเชื่อมต่อได้ - อาจต้องถอด USB แล้วเสียบใหม่', 'ENHANCED_RESET_ERROR', e);
    }
  }

  /// รีเซ็ตการเชื่อมต่อแบบเร็ว (สำหรับกรณีปกติ)
  Future<void> quickResetConnection() async {
    try {
      debugPrint('🔄 CardReaderService: รีเซ็ตแบบเร็ว...');
      
      _setConnectionStatus(CardReaderConnectionStatus.connecting);
      
      // หยุดการฟังทั้งหมด
      await _stopAllListeners();
      
      // รอสักครู่
      await Future.delayed(const Duration(milliseconds: 500));
      
      // เริ่มต้นใหม่
      await initialize();
      
      debugPrint('✅ CardReaderService: รีเซ็ตเร็วสำเร็จ');
      
    } catch (e) {
      debugPrint('❌ CardReaderService: รีเซ็ตเร็วล้มเหลว - $e');
      _setError('ไม่สามารถรีเซ็ตการเชื่อมต่อได้', 'QUICK_RESET_ERROR', e);
    }
  }

  /// ตรวจสอบสถานะการเชื่อมต่อ
  Future<bool> checkConnection() async {
    try {
      // ตรวจสอบ device
      if (_currentDevice == null || !_currentDevice!.isAttached) {
        _setConnectionStatus(CardReaderConnectionStatus.disconnected);
        return false;
      }
      
      if (!_currentDevice!.hasPermission) {
        _setConnectionStatus(CardReaderConnectionStatus.error);
        return false;
      }
      
      _setConnectionStatus(CardReaderConnectionStatus.connected);
      return true;
      
    } catch (e) {
      debugPrint('❌ CardReaderService: เช็คการเชื่อมต่อล้มเหลว - $e');
      _setConnectionStatus(CardReaderConnectionStatus.error);
      return false;
    }
  }

  /// หยุดการทำงานทั้งหมด
  Future<void> _stopAllListeners() async {
    _deviceStreamSubscription?.cancel();
    _cardStreamSubscription?.cancel();
    _connectionTimer?.cancel();
    _readTimeoutTimer?.cancel();
  }

  /// ตั้งค่าสถานะการเชื่อมต่อ
  void _setConnectionStatus(CardReaderConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      notifyListeners();
      debugPrint('🔗 CardReaderService: Connection status = $status');
    }
  }

  /// ตั้งค่าสถานะการอ่าน
  void _setReadingStatus(CardReadingStatus status) {
    if (_readingStatus != status) {
      _readingStatus = status;
      notifyListeners();
      debugPrint('📖 CardReaderService: Reading status = $status');
    }
  }

  /// ตั้งค่า error
  void _setError(String message, String code, [dynamic originalError]) {
    _lastError = message;
    _setConnectionStatus(CardReaderConnectionStatus.error);
    notifyListeners();
    
    debugPrint('❌ CardReaderService: Error($code) = $message');
    if (originalError != null) {
      debugPrint('   Original: $originalError');
    }
  }

  /// ล้าง error
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// ทำความสะอาดทรัพยากร
  @override
  void dispose() {
    debugPrint('🧹 CardReaderService: Disposing...');
    _stopAllListeners();
    super.dispose();
  }

  /// รายงานสถิติการใช้งาน
  Map<String, dynamic> getUsageStats() {
    return {
      'connectionStatus': _connectionStatus.name,
      'readingStatus': _readingStatus.name,
      'hasDevice': _currentDevice != null,
      'deviceName': _currentDevice?.productName,
      'lastReadTime': _lastReadData?.readTimestamp.toIso8601String(),
      'lastError': _lastError,
    };
  }

  /// ตรวจสอบว่าต้องใช้การรีเซ็ต USB จริงหรือไม่
  bool shouldUsePhysicalReset() {
    return _lastError?.contains('ENHANCED_RESET_ERROR') == true ||
           _connectionStatus == CardReaderConnectionStatus.error;
  }

  /// ข้อความแนะนำสำหรับผู้ใช้เมื่อต้องรีเซ็ต USB จริง
  String getPhysicalResetInstructions() {
    return '''
🔧 คำแนะนำการรีเซ็ต USB การ์ดรีดเดอร์:

เนื่องจากระบบไม่สามารถรีเซ็ตการเชื่อมต่อ USB ได้ที่ระดับฮาร์ดแวร์ 
กรุณาทำตามขั้นตอนดังนี้:

1. ❌ ถอดสาย USB ของเครื่องอ่านบัตรออกจากเครื่อง
2. ⏳ รอประมาณ 3-5 วินาที  
3. ✅ เสียบสาย USB เข้าไปใหม่
4. 🔍 รอให้ระบบตรวจพบเครื่องอ่านบัตร
5. 📱 ลองอ่านบัตรประชาชนอีกครั้ง

⚠️ หมายเหตุ: 
- ปัญหานี้เกิดจาก Plugin thai_idcard_reader_flutter 
  ที่ไม่รองรับการรีเซ็ต USB ระดับฮาร์ดแวร์
- การกดปุ่มรีเซ็ตจะรีเซ็ตเฉพาะระบบ Flutter เท่านั้น
- สำหรับการใช้งานต่อเนื่อง แนะนำให้ใช้ Hub USB คุณภาพดี
    ''';
  }
}