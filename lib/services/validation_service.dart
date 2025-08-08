import '../services/booking_service.dart';

/// Centralized validation service for registration flows
/// This service unifies validation logic between ID card and manual registration
class ValidationService {
  /// Validate date range with basic rules
  /// Reuses the existing _validateDates() logic from manual form
  static String? validateDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
    bool allowPastDates = false,
  }) {
    if (startDate == null || endDate == null) {
      return 'กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateOnly = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

    // 1. Start date must not be greater than current date (unless allowed)
    if (!allowPastDates && startDateOnly.isAfter(today)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่ปัจจุบัน';
    }

    // 2. Start date must not be greater than end date
    if (startDateOnly.isAfter(endDateOnly)) {
      return 'วันที่เริ่มต้นต้องไม่มากกว่าวันที่สิ้นสุด';
    }

    // 3. End date must not be less than current date (for active registrations)
    if (!allowPastDates && endDateOnly.isBefore(today)) {
      return 'วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่ปัจจุบัน';
    }

    return null; // Validation passed
  }

  /// Validate practice range with room bookings
  /// This is the core requirement from the specification
  static Future<String?> validatePracticeRangeWithBookings({
    required String visitorId,
    required DateTime newStart,
    required DateTime newEnd,
  }) async {
    try {
      // First validate basic date rules
      final basicValidation = validateDateRange(
        startDate: newStart,
        endDate: newEnd,
      );
      if (basicValidation != null) {
        return basicValidation;
      }

      // Then validate with room bookings
      final bookingValidation = await BookingService.validatePracticeRangeWithBookings(
        visitorId: visitorId,
        practiceStart: newStart,
        practiceEnd: newEnd,
      );

      return bookingValidation; // Will be null if validation passes
    } catch (e) {
      throw Exception('Failed to validate practice range with bookings: $e');
    }
  }

  /// Comprehensive validation for registration updates
  /// Used by both ID card and manual registration flows
  static Future<String?> validateRegistrationUpdate({
    required String visitorId,
    required DateTime newStart,
    required DateTime newEnd,
    bool isEditMode = false,
  }) async {
    try {
      // Basic date validation
      final dateValidation = validateDateRange(
        startDate: newStart,
        endDate: newEnd,
        allowPastDates: isEditMode, // Allow past dates when editing existing records
      );
      if (dateValidation != null) {
        return dateValidation;
      }

      // Booking validation (only if in edit mode)
      if (isEditMode) {
        final bookingValidation = await validatePracticeRangeWithBookings(
          visitorId: visitorId,
          newStart: newStart,
          newEnd: newEnd,
        );
        if (bookingValidation != null) {
          return bookingValidation;
        }
      }

      return null; // All validations passed
    } catch (e) {
      throw Exception('Failed to validate registration update: $e');
    }
  }

  /// Validate if user can edit personal information
  /// Returns error if user has hasIdCard = true
  static String? validatePersonalInfoEdit(bool hasIdCard) {
    if (hasIdCard) {
      return 'ไม่สามารถแก้ไขข้อมูลส่วนตัวได้ เนื่องจากใช้ข้อมูลจากบัตรประชาชน';
    }
    return null; // Can edit
  }

  /// Validate Thai National ID format
  /// Reuses the existing validation logic from manual form
  static bool validateThaiNationalId(String id) {
    if (id.length != 13) return false;

    // Check if all characters are digits
    if (!RegExp(r'^\d{13}$').hasMatch(id)) return false;

    // Calculate checksum
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(id[i]) * (13 - i);
    }

    int remainder = sum % 11;
    int checkDigit = (11 - remainder) % 10;

    return checkDigit == int.parse(id[12]);
  }

  /// Validate phone number format
  /// Returns null if valid, error message if invalid
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Phone is optional
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Must be 9 or 10 digits
    if (cleanPhone.length < 9 || cleanPhone.length > 10) {
      return 'เบอร์โทรต้องมี 9-10 หลัก';
    }

    // Must start with valid prefixes
    if (cleanPhone.length == 10 && !cleanPhone.startsWith('0')) {
      return 'เบอร์โทร 10 หลักต้องขึ้นต้นด้วย 0';
    }

    return null; // Valid
  }

  /// Get validation summary for UI display
  /// Returns user-friendly validation status
  static Map<String, dynamic> getValidationSummary({
    required String visitorId,
    required bool hasIdCard,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isEditMode,
  }) {
    final canEditPersonalInfo = !hasIdCard;
    
    String? dateError;
    if (startDate != null && endDate != null) {
      dateError = validateDateRange(
        startDate: startDate,
        endDate: endDate,
        allowPastDates: isEditMode,
      );
    }

    return {
      'canEditPersonalInfo': canEditPersonalInfo,
      'personalInfoReason': hasIdCard 
          ? 'ข้อมูลถูกล็อคจากบัตรประชาชน' 
          : 'สามารถแก้ไขได้',
      'isEditMode': isEditMode,
      'dateValidation': dateError == null ? 'valid' : 'invalid',
      'dateError': dateError,
      'needsBookingValidation': isEditMode,
    };
  }
}