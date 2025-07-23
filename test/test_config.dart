import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Test configuration for the Baan Petchbumpen Register project
class TestConfig {
  /// Initialize test configuration
  static Future<void> initialize() async {
    // Configure golden tests
    await loadAppFonts();
    
    // Set up device configurations for golden tests
    GoldenToolkit.runWithConfiguration(
      () async {
        // Your golden test configuration here
      },
      config: GoldenToolkitConfiguration(
        enableRealShadows: true,
        defaultDevices: const [
          Device.phone,
          Device.tabletPortrait,
        ],
      ),
    );
  }

  /// Common test devices
  static const List<Device> testDevices = [
    Device.phone,
    Device.tabletPortrait,
    Device.tabletLandscape,
  ];

  /// Test data constants
  static const String validThaiId = '1234567890123';
  static const String invalidThaiId = '1234567890124';
  static const String testPhone = '0812345678';
  static const String testFirstName = 'สมชาย';
  static const String testLastName = 'ทดสอบ';

  /// Database test helpers
  static Future<void> setupTestDatabase() async {
    // Initialize test database
    // This will be implemented based on your DB setup
  }

  static Future<void> cleanupTestDatabase() async {
    // Clean up test database
    // This will be implemented based on your DB setup
  }

  /// Mock services for testing
  static void setupMocks() {
    // Setup mock services like printer, camera, etc.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('sunmi_printer_plus'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'bindingPrinter':
            return true;
          case 'initPrinter':
            return true;
          case 'printText':
            return true;
          case 'printQRCode':
            return true;
          default:
            return null;
        }
      },
    );

    // Mock camera/scanner
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('mobile_scanner'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'start':
            return true;
          case 'stop':
            return true;
          default:
            return null;
        }
      },
    );
  }

  /// Test widget wrapper with theme
  static Widget testAppWrapper({
    required Widget child,
    bool darkMode = false,
  }) {
    return MaterialApp(
      theme: darkMode 
        ? ThemeData.dark().copyWith(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple,
              brightness: Brightness.dark,
            ),
          )
        : ThemeData.light().copyWith(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple,
              brightness: Brightness.light,
            ),
          ),
      home: child,
    );
  }
}

/// Test extensions
extension WidgetTesterExtensions on WidgetTester {
  /// Wait for animations and async operations
  Future<void> pumpAndSettle({Duration timeout = const Duration(seconds: 10)}) async {
    await pump();
    await binding.pump(timeout);
  }

  /// Enter Thai text safely
  Future<void> enterThaiText(Finder finder, String text) async {
    await tap(finder);
    await pump();
    await enterText(finder, text);
    await pump();
  }

  /// Scroll to find widget
  Future<void> scrollToFind(Finder finder, {Finder? scrollable}) async {
    final scrollableFinder = scrollable ?? find.byType(Scrollable);
    await scrollUntilVisible(finder, 100.0, scrollable: scrollableFinder);
  }
}