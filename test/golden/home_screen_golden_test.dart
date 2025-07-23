import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_petchbumpen_register/screen/home_screen.dart';

void main() {
  group('HomeScreen Golden Tests', () {
    testGoldens('should render home screen on different devices', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletPortrait,
          Device.tabletLandscape,
        ])
        ..addScenario(
          widget: const HomeScreen(),
          name: 'home_screen_default',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_screen_devices');
    });

    testGoldens('should render home screen in light theme', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
            brightness: Brightness.light,
          ),
        ),
        surfaceSize: Device.phone.size,
      );
      await screenMatchesGolden(tester, 'home_screen_light_theme');
    });

    testGoldens('should render home screen in dark theme', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple,
              brightness: Brightness.dark,
            ),
            brightness: Brightness.dark,
          ),
        ),
        surfaceSize: Device.phone.size,
      );
      await screenMatchesGolden(tester, 'home_screen_dark_theme');
    });

    testGoldens('should render home screen with Thai localization', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          locale: const Locale('th', 'TH'),
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ),
        surfaceSize: Device.phone.size,
      );
      await screenMatchesGolden(tester, 'home_screen_thai_locale');
    });

    testGoldens('should render home screen on small device', (tester) async {
      const smallDevice = Device(
        name: 'small_phone',
        size: Size(320, 568), // iPhone SE size
        devicePixelRatio: 2.0,
        textScale: 1.0,
        brightness: Brightness.light,
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [smallDevice])
        ..addScenario(
          widget: const HomeScreen(),
          name: 'small_device',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_screen_small_device');
    });

    testGoldens('should render home screen with accessibility features', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ),
        surfaceSize: Device.phone.size,
        // Simulate accessibility text scaling
        textScaleFactors: [1.0, 1.3, 1.8],
      );
      await multiScreenGolden(tester, 'home_screen_accessibility');
    });

    testGoldens('should render home screen landscape orientation', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ),
        surfaceSize: const Size(812, 375), // iPhone landscape
      );
      await screenMatchesGolden(tester, 'home_screen_landscape');
    });

    testGoldens('should render home screen with different color schemes', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: const HomeScreen(),
          name: 'purple_theme',
          wrapper: materialAppWrapper(
            theme: ThemeData(
              primarySwatch: Colors.purple,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
            ),
          ),
        )
        ..addScenario(
          widget: const HomeScreen(),
          name: 'blue_theme',
          wrapper: materialAppWrapper(
            theme: ThemeData(
              primarySwatch: Colors.blue,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            ),
          ),
        )
        ..addScenario(
          widget: const HomeScreen(),
          name: 'green_theme',
          wrapper: materialAppWrapper(
            theme: ThemeData(
              primarySwatch: Colors.green,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            ),
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_screen_color_schemes');
    });
  });
}