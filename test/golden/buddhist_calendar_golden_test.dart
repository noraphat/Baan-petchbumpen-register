import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_petchbumpen_register/widgets/buddhist_calendar_picker.dart';

void main() {
  group('BuddhistCalendarPicker Golden Tests', () {
    testGoldens('should render Buddhist calendar in different themes', (tester) async {
      final testDate = DateTime(2025, 1, 23);
      
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: Dialog(
            child: SizedBox(
              width: 300,
              height: 400,
              child: BuddhistCalendarPicker(
                initialDate: testDate,
                onDateSelected: (date) {},
              ),
            ),
          ),
          name: 'light_theme',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'buddhist_calendar_light');
    });

    testGoldens('should render Buddhist calendar in dark theme', (tester) async {
      final testDate = DateTime(2025, 6, 15);
      
      await tester.pumpWidgetBuilder(
        Dialog(
          child: SizedBox(
            width: 350,
            height: 450,
            child: BuddhistCalendarPicker(
              initialDate: testDate,
              onDateSelected: (date) {},
            ),
          ),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData.dark(),
        ),
      );
      await screenMatchesGolden(tester, 'buddhist_calendar_dark');
    });

    testGoldens('should render Buddhist calendar for different months', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: Dialog(
            child: SizedBox(
              width: 300,
              height: 400,
              child: BuddhistCalendarPicker(
                initialDate: DateTime(2025, 1, 15), // January
                onDateSelected: (date) {},
              ),
            ),
          ),
          name: 'january_2568',
        )
        ..addScenario(
          widget: Dialog(
            child: SizedBox(
              width: 300,
              height: 400,
              child: BuddhistCalendarPicker(
                initialDate: DateTime(2025, 12, 25), // December
                onDateSelected: (date) {},
              ),
            ),
          ),
          name: 'december_2568',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'buddhist_calendar_months');
    });

    testGoldens('should render Buddhist calendar on tablet', (tester) async {
      final testDate = DateTime(2025, 4, 13); // Songkran
      
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.tabletPortrait])
        ..addScenario(
          widget: Dialog(
            child: SizedBox(
              width: 400,
              height: 500,
              child: BuddhistCalendarPicker(
                initialDate: testDate,
                onDateSelected: (date) {},
              ),
            ),
          ),
          name: 'tablet_calendar',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'buddhist_calendar_tablet');
    });

    testGoldens('should render Buddhist calendar with Thai numerals', (tester) async {
      await tester.pumpWidgetBuilder(
        Dialog(
          child: SizedBox(
            width: 320,
            height: 420,
            child: BuddhistCalendarPicker(
              initialDate: DateTime(2025, 8, 12), // Mother's Day
              onDateSelected: (date) {},
            ),
          ),
        ),
        wrapper: materialAppWrapper(
          locale: const Locale('th', 'TH'),
        ),
      );
      await screenMatchesGolden(tester, 'buddhist_calendar_thai_numerals');
    });

    testGoldens('should render calendar dialog in registration context', (tester) async {
      await tester.pumpWidgetBuilder(
        Scaffold(
          appBar: AppBar(
            title: const Text('ลงทะเบียน'),
            backgroundColor: Colors.purple,
          ),
          body: const Center(
            child: Text('เลือกวันเกิด'),
          ),
          // Simulate dialog overlay
          floatingActionButton: Dialog(
            child: SizedBox(
              width: 300,
              height: 400,
              child: BuddhistCalendarPicker(
                initialDate: DateTime(1990, 5, 20),
                onDateSelected: (date) {},
              ),
            ),
          ),
        ),
        wrapper: materialAppWrapper(
          theme: ThemeData(
            primarySwatch: Colors.purple,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ),
      );
      await screenMatchesGolden(tester, 'buddhist_calendar_registration_context');
    });
  });
}