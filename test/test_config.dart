import 'package:flutter_test/flutter_test.dart';

void main() {
  // Test configuration for the entire test suite
  setUpAll(() {
    // Global setup for all tests
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDownAll(() {
    // Global cleanup for all tests
  });
}
