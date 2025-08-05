import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_petchbumpen_register/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    test('should validate correct Thai phone numbers', () {
      const validPhones = [
        '0812345678', // Mobile
        '0823456789', // Mobile
        '0901234567', // Mobile
        '0212345678', // Bangkok landline
        '0711234567', // Other regions
        '0612345678', // Valid prefix
      ];

      for (final phone in validPhones) {
        expect(PhoneValidator.isValidPhone(phone), isTrue, 
          reason: '$phone should be valid');
      }
    });

    test('should reject invalid Thai phone numbers', () {
      const invalidPhones = [
        '', // empty
        '123456789', // too short
        '12345678901', // too long
        '1234567890', // doesn't start with valid prefix
        '0112345678', // invalid prefix (01)
        '0412345678', // invalid prefix (04)
        '081234567', // too short
        '08123456789', // too long
        'abcd123456', // contains letters
        '081-234-5678', // contains dashes
        ' 0812345678', // leading space
        '0812345678 ', // trailing space
        '081 234 5678', // contains spaces
      ];

      for (final phone in invalidPhones) {
        expect(PhoneValidator.isValidPhone(phone), isFalse, 
          reason: '$phone should be invalid');
      }
    });

    test('should validate phone numbers with correct length', () {
      expect(PhoneValidator.isValidPhone('0812345678'), isTrue); // exactly 10 digits
      expect(PhoneValidator.isValidPhone('081234567'), isFalse); // 9 digits
      expect(PhoneValidator.isValidPhone('08123456789'), isFalse); // 11 digits
    });

    test('should check valid prefixes', () {
      const validPrefixes = ['09', '08', '06', '07', '02'];
      
      for (final prefix in validPrefixes) {
        final phone = '${prefix}12345678';
        expect(PhoneValidator.isValidPhone(phone), isTrue,
          reason: 'Phone with prefix $prefix should be valid');
      }

      const invalidPrefixes = ['01', '03', '04', '05', '10'];
      
      for (final prefix in invalidPrefixes) {
        final phone = '${prefix}12345678';
        expect(PhoneValidator.isValidPhone(phone), isFalse,
          reason: 'Phone with prefix $prefix should be invalid');
      }
    });

    test('should format phone display correctly', () {
      const testCases = [
        ['0812345678', '081-234-5678'],
        ['0223456789', '022-345-6789'],
        ['0901234567', '090-123-4567'],
        ['0712345678', '071-234-5678'],
      ];

      for (final testCase in testCases) {
        final input = testCase[0];
        final expected = testCase[1];
        expect(PhoneValidator.formatPhoneDisplay(input), equals(expected));
      }
    });

    test('should return original string for invalid format input', () {
      const invalidInputs = [
        '', 
        '123456789',
        '12345678901',
        'invalid',
        '081-234-5678', // already formatted
      ];

      for (final input in invalidInputs) {
        expect(PhoneValidator.formatPhoneDisplay(input), equals(input));
      }
    });

    test('should validate phone with validator function', () {
      // Valid phone numbers
      expect(PhoneValidator.validatePhone('0812345678'), isNull);
      expect(PhoneValidator.validatePhone('0223456789'), isNull);
      
      // Invalid phone numbers
      expect(PhoneValidator.validatePhone(''), isNotNull);
      expect(PhoneValidator.validatePhone(null), isNotNull);
      expect(PhoneValidator.validatePhone('123456789'), isNotNull);
      expect(PhoneValidator.validatePhone('0112345678'), isNotNull);
      
      // Check error messages
      final emptyError = PhoneValidator.validatePhone('');
      expect(emptyError, contains('กรุณากรอกเบอร์โทรศัพท์'));
      
      final invalidError = PhoneValidator.validatePhone('123456789');
      expect(invalidError, contains('เบอร์โทรต้องขึ้นต้นด้วย'));
    });

    test('should provide correct input formatters', () {
      final formatters = PhoneValidator.getPhoneInputFormatters();
      
      expect(formatters.length, equals(2));
      expect(formatters[0], isA<FilteringTextInputFormatter>());
      expect(formatters[1], isA<LengthLimitingTextInputFormatter>());
      
      // Test that it includes digits only formatter
      final digitsOnly = formatters[0] as FilteringTextInputFormatter;
      expect(digitsOnly.allow, isNotNull);
      
      // Test length limiting
      final lengthLimiter = formatters[1] as LengthLimitingTextInputFormatter;
      expect(lengthLimiter.maxLength, equals(10));
    });

    test('should handle edge cases', () {
      // Test null safety in validatePhone
      expect(PhoneValidator.validatePhone(null), isNotNull);
      
      // Test empty string
      expect(PhoneValidator.isValidPhone(''), isFalse);
      
      // Test very long strings
      final veryLongString = '0' * 100;
      expect(PhoneValidator.isValidPhone(veryLongString), isFalse);
      
      // Test numbers with all same digits
      expect(PhoneValidator.isValidPhone('0888888888'), isTrue);
      expect(PhoneValidator.isValidPhone('0222222222'), isTrue);
      
      // Test formatting with wrong length
      expect(PhoneValidator.formatPhoneDisplay('123'), equals('123'));
      expect(PhoneValidator.formatPhoneDisplay('1234567890123'), equals('1234567890123'));
    });

    test('should check regex pattern correctly', () {
      // Only digits should be valid
      expect(PhoneValidator.isValidPhone('0812345678'), isTrue);
      expect(PhoneValidator.isValidPhone('081234567a'), isFalse);
      expect(PhoneValidator.isValidPhone('081234567#'), isFalse);
      expect(PhoneValidator.isValidPhone('081234567.'), isFalse);
      expect(PhoneValidator.isValidPhone('081234567-'), isFalse);
    });

    test('should maintain consistency', () {
      const testPhone = '0812345678';
      
      // Valid phone should pass validation
      expect(PhoneValidator.isValidPhone(testPhone), isTrue);
      expect(PhoneValidator.validatePhone(testPhone), isNull);
      
      // Valid phone should format correctly
      final formatted = PhoneValidator.formatPhoneDisplay(testPhone);
      expect(formatted, equals('081-234-5678'));
      
      // Formatted phone should have correct structure
      expect(formatted.length, equals(12)); // 10 digits + 2 dashes
      expect(formatted.split('-').length, equals(3));
    });

    test('should handle all valid Thai prefixes according to current implementation', () {
      const validPrefixes = ['09', '08', '06', '07', '02'];
      
      for (final prefix in validPrefixes) {
        final phone = '${prefix}12345678';
        expect(PhoneValidator.isValidPhone(phone), isTrue,
          reason: 'Phone $phone with prefix $prefix should be valid');
        
        // Test validation function too
        expect(PhoneValidator.validatePhone(phone), isNull,
          reason: 'Phone $phone should pass validation');
      }
    });

    test('should handle phone formatting edge cases', () {
      // Test phones exactly 10 digits
      expect(PhoneValidator.formatPhoneDisplay('0123456789'), equals('012-345-6789'));
      
      // Test phones not exactly 10 digits
      expect(PhoneValidator.formatPhoneDisplay('012345678'), equals('012345678'));
      expect(PhoneValidator.formatPhoneDisplay('01234567890'), equals('01234567890'));
      
      // Test empty string
      expect(PhoneValidator.formatPhoneDisplay(''), equals(''));
    });
  });
}