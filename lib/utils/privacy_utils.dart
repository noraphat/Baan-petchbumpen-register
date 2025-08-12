/// Utility functions for privacy and data masking
class PrivacyUtils {
  
  /// Mask Thai ID card number by replacing middle 5 digits with asterisks
  /// Example: 1234567890123 -> 1234*****0123
  static String maskThaiIdCard(String idCard) {
    if (idCard.length != 13) {
      return idCard; // Return as-is if not valid Thai ID format
    }
    
    // Take first 4 digits + ***** + last 4 digits
    return '${idCard.substring(0, 4)}*****${idCard.substring(9)}';
  }

  /// Unmask Thai ID card number (return original)
  /// This is for display purposes where we need the full number
  static String unmaskThaiIdCard(String idCard) {
    // In this implementation, we assume the original data is always stored
    // This method exists for consistency but typically the original data
    // would be retrieved from secure storage
    return idCard;
  }

  /// Check if ID card is already masked
  static bool isThaiIdCardMasked(String idCard) {
    return idCard.contains('*');
  }

  /// Format Thai ID card with dashes for better readability
  /// Example: 1234567890123 -> 1-2345-67890-12-3
  static String formatThaiIdCard(String idCard, {bool masked = false}) {
    String cardNumber = masked ? maskThaiIdCard(idCard) : idCard;
    
    if (cardNumber.length != 13) {
      return cardNumber;
    }
    
    return '${cardNumber.substring(0, 1)}-${cardNumber.substring(1, 5)}-${cardNumber.substring(5, 10)}-${cardNumber.substring(10, 12)}-${cardNumber.substring(12)}';
  }

  /// Get display text for sensitive information
  /// This method determines whether to show masked or unmasked data
  /// based on user privileges or app settings
  static String getDisplayText(String originalText, {
    bool shouldMask = true,
    String fieldType = 'general',
  }) {
    if (!shouldMask) {
      return originalText;
    }

    switch (fieldType) {
      case 'thai_id':
        return maskThaiIdCard(originalText);
      case 'phone':
        return _maskPhoneNumber(originalText);
      case 'email':
        return _maskEmail(originalText);
      default:
        return originalText;
    }
  }

  /// Mask phone number with exactly 4 middle digits
  /// Example: 0812345678 -> 081****678
  static String _maskPhoneNumber(String phone) {
    if (phone.length < 7) return phone; // Need at least 7 digits for 3+4+X pattern
    
    int visibleStart = 3;
    int maskLength = 4; // Always mask exactly 4 middle digits
    
    if (phone.length < visibleStart + maskLength) return phone;
    
    // Calculate remaining digits for the end
    int visibleEnd = phone.length - visibleStart - maskLength;
    
    return '${phone.substring(0, visibleStart)}${'*' * maskLength}${phone.substring(visibleStart + maskLength)}';
  }

  /// Mask email address
  /// Example: user@example.com -> u***@example.com
  static String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    
    List<String> parts = email.split('@');
    String username = parts[0];
    String domain = parts[1];
    
    if (username.length <= 2) return email;
    
    String maskedUsername = '${username.substring(0, 1)}${'*' * (username.length - 1)}';
    return '$maskedUsername@$domain';
  }

  /// Security check for displaying sensitive data
  /// This can be expanded to include role-based access control
  static bool canViewSensitiveData({
    String? userRole,
    String? permission,
    bool isDebugMode = false,
  }) {
    // For now, return false to always mask data
    // This can be expanded based on actual security requirements
    if (isDebugMode) return true;
    
    // Add role-based logic here if needed
    // For example: return userRole == 'admin' || permission == 'view_sensitive';
    
    return false; // Default to masked for privacy
  }
}