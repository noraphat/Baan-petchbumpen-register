import 'package:flutter/services.dart';

class PhoneValidator {
  static const List<String> validPrefixes = ['09', '08', '06', '07', '02'];
  static const int phoneLength = 10;
  
  /// ตรวจสอบรูปแบบเบอร์โทรศัพท์
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    
    // ตรวจสอบความยาว
    if (phone.length != phoneLength) return false;
    
    // ตรวจสอบว่าเป็นตัวเลขทั้งหมด
    if (!RegExp(r'^\d+$').hasMatch(phone)) return false;
    
    // ตรวจสอบเลขขึ้นต้น
    for (String prefix in validPrefixes) {
      if (phone.startsWith(prefix)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// ฟังก์ชัน validator สำหรับ TextFormField
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }
    
    if (!isValidPhone(value)) {
      return 'เบอร์โทรต้องขึ้นต้นด้วย ${validPrefixes.join(', ')} และต้องมี $phoneLength หลัก';
    }
    
    return null;
  }
  
  /// InputFormatter สำหรับจำกัดให้กรอกเฉพาะตัวเลขและความยาว
  static List<TextInputFormatter> getPhoneInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(phoneLength),
    ];
  }
  
  /// ฟอร์แมตเบอร์โทรให้แสดงผลในรูปแบบ xxx-xxx-xxxx
  static String formatPhoneDisplay(String phone) {
    if (phone.length != phoneLength) return phone;
    
    return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
  }
}