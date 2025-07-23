import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Initialize golden toolkit
  return GoldenToolkit.runWithConfiguration(
    () async {
      // Load app fonts for golden tests
      await loadAppFonts();
      
      // Run the actual tests
      await testMain();
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