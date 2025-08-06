import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// ข้อมูลที่อ่านได้จากบัตรประชาชน
class IdCardData {
  final String id;           // เลขบัตรประชาชน
  final String firstName;    // ชื่อ
  final String lastName;     // นามสกุล
  final String dateOfBirth;  // วันเกิด (YYYY-MM-DD format)
  final String address;      // ที่อยู่
  final String gender;       // เพศ (ชาย/หญิง)
  final DateTime readAt;     // วันเวลาที่อ่าน

  IdCardData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.address,
    required this.gender,
    required this.readAt,
  });

  factory IdCardData.fromJson(Map<String, dynamic> json) {
    return IdCardData(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? 'อื่น ๆ',
      readAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'gender': gender,
        'readAt': readAt.toIso8601String(),
      };

  @override
  String toString() {
    return 'IdCardData{id: $id, name: $firstName $lastName, dob: $dateOfBirth}';
  }
}

/// สถานะของเครื่องอ่านบัตร
enum CardReaderStatus {
  disconnected,   // ไม่ได้เชื่อมต่อ
  connected,      // เชื่อมต่อแล้ว
  waiting,        // รออ่านบัตร
  reading,        // กำลังอ่านบัตร
  error,          // เกิดข้อผิดพลาด
}

/// บริการจัดการเครื่องอ่านบัตรประชาชน
/// รองรับการเชื่อมต่อผ่าน USB และการอ่านข้อมูลแบบ Real-time
class CardReaderService {
  static final CardReaderService _instance = CardReaderService._internal();
  factory CardReaderService() => _instance;
  CardReaderService._internal();

  final StreamController<CardReaderStatus> _statusController = 
      StreamController<CardReaderStatus>.broadcast();
  final StreamController<IdCardData> _cardDataController = 
      StreamController<IdCardData>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();

  CardReaderStatus _currentStatus = CardReaderStatus.disconnected;
  Timer? _connectionTimer;
  Process? _readerProcess;

  /// Stream สำหรับติดตามสถานะเครื่องอ่านบัตร
  Stream<CardReaderStatus> get statusStream => _statusController.stream;

  /// Stream สำหรับรับข้อมูลบัตรที่อ่านได้
  Stream<IdCardData> get cardDataStream => _cardDataController.stream;

  /// Stream สำหรับรับข้อความข้อผิดพลาด
  Stream<String> get errorStream => _errorController.stream;

  /// สถานะปัจจุบันของเครื่องอ่านบัตร
  CardReaderStatus get currentStatus => _currentStatus;

  /// เริ่มการเชื่อมต่อเครื่องอ่านบัตร
  Future<bool> initialize() async {
    try {
      debugPrint('🔍 กำลังเริ่มต้นเครื่องอ่านบัตรประชาชน...');
      
      // ตรวจสอบระบบปฏิบัติการ
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        _setError('ระบบปฏิบัติการไม่รองรับเครื่องอ่านบัตร');
        return false;
      }

      _updateStatus(CardReaderStatus.connected);

      // เริ่มตรวจสอบการเชื่อมต่อแบบ interval
      _startConnectionMonitoring();

      debugPrint('✅ เริ่มต้นเครื่องอ่านบัตรสำเร็จ');
      return true;
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการเริ่มต้นเครื่องอ่านบัตร: $e');
      _setError('ไม่สามารถเริ่มต้นเครื่องอ่านบัตรได้');
      return false;
    }
  }

  /// เริ่มการอ่านบัตรประชาชน
  Future<bool> startReading() async {
    try {
      if (_currentStatus != CardReaderStatus.connected && 
          _currentStatus != CardReaderStatus.waiting) {
        debugPrint('❌ เครื่องอ่านบัตรไม่พร้อมใช้งาน');
        return false;
      }

      debugPrint('🔍 กำลังรอการใส่บัตรประชาชน...');
      _updateStatus(CardReaderStatus.waiting);

      // จำลองการอ่านบัตร (ในการใช้งานจริงจะเชื่อมต่อกับ hardware)
      if (kDebugMode) {
        _simulateCardReading();
      } else {
        _startActualCardReading();
      }

      return true;
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการเริ่มอ่านบัตร: $e');
      _setError('ไม่สามารถเริ่มการอ่านบัตรได้');
      return false;
    }
  }

  /// หยุดการอ่านบัตร
  Future<void> stopReading() async {
    try {
      if (_readerProcess != null) {
        _readerProcess!.kill();
        _readerProcess = null;
      }

      _updateStatus(CardReaderStatus.connected);
      debugPrint('⏹️ หยุดการอ่านบัตรแล้ว');
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการหยุดอ่านบัตร: $e');
    }
  }

  /// ตัดการเชื่อมต่อเครื่องอ่านบัตร
  Future<void> disconnect() async {
    try {
      _connectionTimer?.cancel();
      _connectionTimer = null;

      if (_readerProcess != null) {
        _readerProcess!.kill();
        _readerProcess = null;
      }

      _updateStatus(CardReaderStatus.disconnected);
      debugPrint('🔌 ตัดการเชื่อมต่อเครื่องอ่านบัตรแล้ว');
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการตัดการเชื่อมต่อ: $e');
    }
  }

  /// จำลองการอ่านบัตร (สำหรับการพัฒนา)
  void _simulateCardReading() {
    Timer(const Duration(seconds: 2), () {
      _updateStatus(CardReaderStatus.reading);
      
      Timer(const Duration(seconds: 3), () {
        // จำลองข้อมูลบัตรประชาชน
        final simulatedData = IdCardData(
          id: '1234567890123',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
          dateOfBirth: '1990-05-15',
          address: 'กรุงเทพมหานคร, เขตดุสิต, แขวงดุสิต',
          gender: 'ชาย',
          readAt: DateTime.now(),
        );

        _cardDataController.add(simulatedData);
        _updateStatus(CardReaderStatus.connected);
        debugPrint('✅ อ่านบัตรจำลองสำเร็จ: ${simulatedData.id}');
      });
    });
  }

  /// เริ่มการอ่านบัตรจริง (เชื่อมต่อกับ hardware)
  void _startActualCardReading() async {
    try {
      _updateStatus(CardReaderStatus.reading);

      // ในการใช้งานจริง จะใช้ library หรือ executable สำหรับอ่านบัตร
      // เช่น Thai ID Card Reader SDK หรือ command line tools
      
      // ตัวอย่างการใช้ command line (ปรับตามเครื่องอ่านบัตรที่ใช้)
      if (Platform.isWindows) {
        _readerProcess = await Process.start(
          'thailand_id_reader.exe', // executable สำหรับ Windows
          ['--read', '--format=json'],
        );
      } else if (Platform.isLinux) {
        _readerProcess = await Process.start(
          'thailand_id_reader', // executable สำหรับ Linux
          ['--read', '--format=json'],
        );
      }

      if (_readerProcess != null) {
        _readerProcess!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              _parseCardData,
              onError: (error) => _setError('ข้อผิดพลาดในการอ่านบัตร: $error'),
            );

        _readerProcess!.stderr
            .transform(utf8.decoder)
            .listen((error) => _setError('ข้อผิดพลาดระบบ: $error'));
      }
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการเริ่มอ่านบัตรจริง: $e');
      _setError('ไม่สามารถเชื่อมต่อเครื่องอ่านบัตรได้');
    }
  }

  /// แยกวิเคราะห์ข้อมูลจากเครื่องอ่านบัตร
  void _parseCardData(String rawData) {
    try {
      final jsonData = jsonDecode(rawData);
      
      if (jsonData['status'] == 'success' && jsonData['data'] != null) {
        final cardData = IdCardData.fromJson(jsonData['data']);
        _cardDataController.add(cardData);
        _updateStatus(CardReaderStatus.connected);
        debugPrint('✅ อ่านบัตรสำเร็จ: ${cardData.id}');
      } else if (jsonData['status'] == 'error') {
        _setError(jsonData['message'] ?? 'ข้อผิดพลาดไม่ทราบสาเหตุ');
      }
    } catch (e) {
      debugPrint('❌ ข้อผิดพลาดในการแยกวิเคราะห์ข้อมูล: $e');
      _setError('ข้อมูลจากเครื่องอ่านบัตรไม่ถูกต้อง');
    }
  }

  /// เริ่มตรวจสอบการเชื่อมต่ออย่างต่อเนื่อง
  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _checkConnection(),
    );
  }

  /// ตรวจสอบการเชื่อมต่อเครื่องอ่านบัตร
  void _checkConnection() async {
    try {
      // ในการใช้งานจริงจะตรวจสอบผ่าน USB หรือ driver
      // สำหรับตอนนี้จำลองว่าเชื่อมต่ออยู่เสมอ
      if (_currentStatus == CardReaderStatus.disconnected) {
        _updateStatus(CardReaderStatus.connected);
      }
    } catch (e) {
      debugPrint('❌ การตรวจสอบการเชื่อมต่อล้มเหลว: $e');
      _updateStatus(CardReaderStatus.error);
    }
  }

  /// อัปเดตสถานะเครื่องอ่านบัตร
  void _updateStatus(CardReaderStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('📡 สถานะเครื่องอ่านบัตร: ${_statusToString(status)}');
    }
  }

  /// ส่งข้อความข้อผิดพลาด
  void _setError(String message) {
    _updateStatus(CardReaderStatus.error);
    _errorController.add(message);
    debugPrint('❌ ข้อผิดพลาดเครื่องอ่านบัตร: $message');
  }

  /// แปลงสถานะเป็นข้อความ
  String _statusToString(CardReaderStatus status) {
    switch (status) {
      case CardReaderStatus.disconnected:
        return 'ไม่ได้เชื่อมต่อ';
      case CardReaderStatus.connected:
        return 'เชื่อมต่อแล้ว';
      case CardReaderStatus.waiting:
        return 'รออ่านบัตร';
      case CardReaderStatus.reading:
        return 'กำลังอ่านบัตร';
      case CardReaderStatus.error:
        return 'เกิดข้อผิดพลาด';
    }
  }

  /// ทำความสะอาดทรัพยากร
  void dispose() {
    _connectionTimer?.cancel();
    _readerProcess?.kill();
    _statusController.close();
    _cardDataController.close();
    _errorController.close();
  }
}