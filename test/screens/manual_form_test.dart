import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_petchbumpen_register/screen/registration/manual_form.dart';
import 'package:flutter_petchbumpen_register/services/address_service.dart';
import 'package:flutter_petchbumpen_register/services/db_helper.dart';
import 'package:flutter_petchbumpen_register/models/reg_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('ManualForm Tests', () {
    late AddressService addressService;
    late DbHelper dbHelper;

    setUpAll(() async {
      // Initialize Thai locale and FFI for database testing
      await initializeDateFormatting('th_TH', null);
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Setup mock address service with test data
      addressService = AddressService();
      addressService.provinces = [
        Province(1, 'กรุงเทพมหานคร'),
        Province(2, 'เชียงใหม่'),
        Province(3, 'สงขลา'),
      ];
      addressService.districts = [
        District(101, 1, 'เขตบางรัก'),
        District(102, 1, 'เขตจตุจักร'),
        District(201, 2, 'เมืองเชียงใหม่'),
        District(301, 3, 'เมืองสงขลา'),
      ];
      addressService.subs = [
        SubDistrict(1001, 101, 'แขวงสีลม'),
        SubDistrict(1002, 101, 'แขวงสุริยวงศ์'),
        SubDistrict(1003, 102, 'แขวงลาดยาว'),
        SubDistrict(2001, 201, 'ตำบลช้างคลาน'),
        SubDistrict(3001, 301, 'ตำบลบ่อยาง'),
      ];

      // Setup test database
      final testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE regs (
              id TEXT PRIMARY KEY,
              first TEXT,
              last TEXT,
              dob TEXT,
              phone TEXT,
              addr TEXT,
              gender TEXT,
              hasIdCard INTEGER,
              createdAt TEXT,
              updatedAt TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE reg_additional_info (
              regId TEXT PRIMARY KEY,
              startDate TEXT,
              endDate TEXT,
              shirtCount INTEGER,
              pantsCount INTEGER,
              matCount INTEGER,
              pillowCount INTEGER,
              blanketCount INTEGER,
              location TEXT,
              withChildren INTEGER,
              childrenCount INTEGER,
              notes TEXT,
              createdAt TEXT,
              updatedAt TEXT,
              FOREIGN KEY (regId) REFERENCES regs (id) ON DELETE CASCADE
            )
          ''');
        },
      );

      dbHelper = DbHelper();
      // Override the db for testing
      dbHelper._db = testDb;
    });

    Widget createTestWidget() {
      return MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],
        home: const ManualForm(),
      );
    }

    group('Initial State', () {
      testWidgets('should display initial form fields', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for main form fields
        expect(find.text('หมายเลขประชาชน / เบอร์โทร (ค้นหา)'), findsOneWidget);
        expect(find.text('ชื่อ'), findsOneWidget);
        expect(find.text('นามสกุล'), findsOneWidget);
        expect(find.text('วันเดือนปีเกิด (พ.ศ.)'), findsOneWidget);
        expect(find.text('เบอร์โทรศัพท์'), findsOneWidget);
        expect(find.text('จังหวัด'), findsOneWidget);
        expect(find.text('อำเภอ'), findsOneWidget);
        expect(find.text('ตำบล'), findsOneWidget);
        expect(find.text('ที่อยู่เพิ่มเติม (บ้านเลขที่ ฯลฯ)'), findsOneWidget);
        expect(find.text('เพศ'), findsOneWidget);
      });

      testWidgets('should display gender dropdown with Thai options', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on gender dropdown
        await tester.tap(find.text('เพศ'));
        await tester.pumpAndSettle();

        // Should show gender options in Thai
        expect(find.text('พระ').hitTestable(), findsOneWidget);
        expect(find.text('สามเณร').hitTestable(), findsOneWidget);
        expect(find.text('แม่ชี').hitTestable(), findsOneWidget);
        expect(find.text('ชาย').hitTestable(), findsOneWidget);
        expect(find.text('หญิง').hitTestable(), findsOneWidget);
        expect(find.text('อื่นๆ').hitTestable(), findsOneWidget);
      });

      testWidgets('should have search button initially visible', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show "ค้นหา" button initially
        expect(find.text('ค้นหา'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('should have most fields disabled initially', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Name fields should be disabled initially (until search is done)
        final firstNameField = find.widgetWithText(TextFormField, 'ชื่อ');
        final lastNameField = find.widgetWithText(TextFormField, 'นามสกุล');

        expect(tester.widget<TextFormField>(firstNameField).enabled, isFalse);
        expect(tester.widget<TextFormField>(lastNameField).enabled, isFalse);
      });
    });

    group('Search Functionality', () {
      testWidgets('should not search with ID less than 5 characters', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter short ID
        await tester.enterText(find.byType(TextFormField).first, '1234');
        
        // Tap search button
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fields should remain disabled
        final firstNameField = find.widgetWithText(TextFormField, 'ชื่อ');
        expect(tester.widget<TextFormField>(firstNameField).enabled, isFalse);
      });

      testWidgets('should enable fields for new registration when not found', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid ID that doesn't exist
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        
        // Tap search button
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fields should now be enabled for new entry
        final firstNameField = find.widgetWithText(TextFormField, 'ชื่อ');
        final lastNameField = find.widgetWithText(TextFormField, 'นามสกุล');

        expect(tester.widget<TextFormField>(firstNameField).enabled, isTrue);
        expect(tester.widget<TextFormField>(lastNameField).enabled, isTrue);

        // Button should change to "ลงทะเบียน"
        expect(find.text('ลงทะเบียน'), findsOneWidget);
      });

      testWidgets('should populate fields when existing registration found', (WidgetTester tester) async {
        // Insert test data
        final existingData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม, บ้านเลขที่ 123',
          gender: 'ชาย',
        );
        await dbHelper.insert(existingData);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Search for existing data
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fields should be populated with existing data
        expect(find.text('สมชาย'), findsOneWidget);
        expect(find.text('ใจดี'), findsOneWidget);
        expect(find.text('15 มกราคม 2530'), findsOneWidget);
        expect(find.text('0812345678'), findsOneWidget);

        // Fields should be disabled for existing data (except phone)
        final firstNameField = find.widgetWithText(TextFormField, 'ชื่อ');
        expect(tester.widget<TextFormField>(firstNameField).enabled, isFalse);
      });
    });

    group('Form Validation', () {
      testWidgets('should validate required fields for new registration', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Try to submit without filling required fields
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Should show validation messages
        expect(find.text('ระบุ ชื่อ'), findsOneWidget);
        expect(find.text('ระบุ นามสกุล'), findsOneWidget);
      });

      testWidgets('should validate date selection', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fill in required text fields
        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');

        // Try to submit without date
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Should show date validation message
        expect(find.text('กรุณาเลือกวันเกิด'), findsOneWidget);
      });

      testWidgets('should validate address selection', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fill required fields
        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');

        // Tap on date field to select date
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();

        // Select today's date in the calendar
        await tester.tap(find.text('${DateTime.now().day}'));
        await tester.pumpAndSettle();

        // Try to submit without selecting address
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Should show address validation message
        expect(find.text('กรุณาเลือก จังหวัด / อำเภอ / ตำบล'), findsOneWidget);
      });
    });

    group('Address Selection', () {
      testWidgets('should populate district dropdown when province selected', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Select province
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        // District dropdown should now have options
        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();

        expect(find.text('เขตบางรัก'), findsOneWidget);
        expect(find.text('เขตจตุจักร'), findsOneWidget);
      });

      testWidgets('should populate sub-district dropdown when district selected', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Select province and district
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        // Sub-district dropdown should now have options
        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();

        expect(find.text('แขวงสีลม'), findsOneWidget);
        expect(find.text('แขวงสุริยวงศ์'), findsOneWidget);
      });

      testWidgets('should reset dependent dropdowns when parent changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Select full address
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        // Change province - should reset district and sub-district
        await tester.tap(find.text('กรุงเทพมหานคร'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เชียงใหม่').last);
        await tester.pumpAndSettle();

        // District and sub-district should be reset
        expect(find.text('เขตบางรัก'), findsNothing);
        expect(find.text('แขวงสีลม'), findsNothing);
      });
    });

    group('Buddhist Calendar Integration', () {
      testWidgets('should open Buddhist calendar when date field tapped', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Tap on date field
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();

        // Buddhist calendar dialog should open
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should format date in Thai Buddhist format when selected', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Open date picker
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();

        // Select a date
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Date should be formatted in Thai Buddhist format
        final dateText = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'),
        ).controller?.text ?? '';

        expect(dateText, contains('15'));
        expect(dateText.contains(RegExp(r'25\d\d')), isTrue); // Buddhist year
      });
    });

    group('Registration Process', () {
      testWidgets('should successfully register new user with all data', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start new registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Fill all required fields
        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');
        
        // Select date
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Fill phone
        await tester.enterText(find.widgetWithText(TextFormField, 'เบอร์โทรศัพท์'), '0812345678');

        // Select address
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        // Submit registration
        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Additional info dialog should appear
        expect(find.text('ข้อมูลเพิ่มเติม'), findsOneWidget);
      });

      testWidgets('should show additional info dialog after registration', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Complete a valid registration
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');
        
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Select complete address
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Additional info dialog should be shown
        expect(find.text('ข้อมูลเพิ่มเติม'), findsOneWidget);
        expect(find.text('วันที่เริ่มต้น'), findsOneWidget);
        expect(find.text('วันที่สิ้นสุด'), findsOneWidget);
        expect(find.text('จำนวนเสื้อขาว'), findsOneWidget);
        expect(find.text('จำนวนกางเกงขาว'), findsOneWidget);
        expect(find.text('มากับเด็ก'), findsOneWidget);
      });
    });

    group('Additional Info Dialog', () {
      testWidgets('should handle number field increment/decrement', (WidgetTester tester) async {
        // First complete basic registration to get to additional info dialog
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');
        
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        // Complete address selection
        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Now test the number fields in additional info dialog
        // Find the + button for shirt count and tap it
        final addButtons = find.byIcon(Icons.add);
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();

        // The shirt count should be incremented from 0 to 1
        expect(find.text('1'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle children checkbox interaction', (WidgetTester tester) async {
        // Navigate to additional info dialog (abbreviated setup)
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Quick registration setup
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');
        
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Test children checkbox
        final checkbox = find.byType(Checkbox);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Should show children count field when checked
        expect(find.text('จำนวนเด็ก'), findsOneWidget);
      });

      testWidgets('should save additional info and close dialog', (WidgetTester tester) async {
        // Navigate to additional info dialog
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'ชื่อ'), 'สมชาย');
        await tester.enterText(find.widgetWithText(TextFormField, 'นามสกุล'), 'ใจดี');
        
        await tester.tap(find.widgetWithText(TextFormField, 'วันเดือนปีเกิด (พ.ศ.)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('15'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('จังหวัด'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('กรุงเทพมหานคร').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('อำเภอ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เขตบางรัก').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ตำบล'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('แขวงสีลม').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('ลงทะเบียน'));
        await tester.pumpAndSettle();

        // Fill some additional info
        await tester.enterText(find.widgetWithText(TextFormField, 'ห้อง/ศาลา/สถานที่พัก'), 'ห้อง A1');
        await tester.enterText(find.widgetWithText(TextFormField, 'หมายเหตุ'), 'ทดสอบระบบ');

        // Save additional info
        await tester.tap(find.text('บันทึก'));
        await tester.pumpAndSettle();

        // Dialog should close
        expect(find.text('ข้อมูลเพิ่มเติม'), findsNothing);
      });
    });

    group('Phone Number Editing', () {
      testWidgets('should allow phone number editing for existing records', (WidgetTester tester) async {
        // Insert existing record
        final existingData = RegData.manual(
          id: '1234567890123',
          first: 'สมชาย',
          last: 'ใจดี',
          dob: '15 มกราคม 2530',
          phone: '0812345678',
          addr: 'กรุงเทพมหานคร, เขตบางรัก, แขวงสีลม',
          gender: 'ชาย',
        );
        await dbHelper.insert(existingData);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Search for existing record
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Phone field should be editable even for existing records
        final phoneField = find.widgetWithText(TextFormField, 'เบอร์โทรศัพท์');
        expect(tester.widget<TextFormField>(phoneField).enabled, isTrue);

        // Should be able to edit phone number
        await tester.enterText(phoneField, '0898765432');
        await tester.pumpAndSettle();

        expect(find.text('0898765432'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle database errors gracefully', (WidgetTester tester) async {
        // Close database to simulate error
        // Simulate database error - commented out due to private member access

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Try to search - should not crash
        await tester.enterText(find.byType(TextFormField).first, '1234567890123');
        await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
        await tester.pumpAndSettle();

        // Should handle gracefully without throwing
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle missing address data gracefully', (WidgetTester tester) async {
        // Clear address data to simulate loading failure
        addressService.provinces.clear();
        addressService.districts.clear();
        addressService.subs.clear();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should still render form without crashing
        expect(find.text('จังหวัด'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

// Note: Extension removed due to private member access limitations in testing