import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_petchbumpen_register/widgets/buddhist_calendar_picker.dart';

void main() {
  group('BuddhistCalendarPicker Widget Tests', () {
    testWidgets('should display calendar with correct initial date', (WidgetTester tester) async {
      // Arrange
      final initialDate = DateTime(2025, 1, 23);
      DateTime? selectedDate;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: initialDate,
              onDateSelected: (date) => selectedDate = date,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BuddhistCalendarPicker), findsOneWidget);
      expect(find.text('2568'), findsOneWidget); // Buddhist year
    });

    testWidgets('should handle date selection correctly', (WidgetTester tester) async {
      // Arrange
      final initialDate = DateTime(2025, 1, 15);
      DateTime? selectedDate;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: initialDate,
              onDateSelected: (date) => selectedDate = date,
            ),
          ),
        ),
      );

      // Find and tap a date (assuming day 20 exists)
      final dayToTap = find.text('20').first;
      await tester.tap(dayToTap);
      await tester.pump();

      // Assert
      expect(selectedDate, isNotNull);
      expect(selectedDate?.day, equals(20));
    });

    testWidgets('should display Thai month names', (WidgetTester tester) async {
      // Arrange
      final januaryDate = DateTime(2025, 1, 1);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: januaryDate,
              onDateSelected: (date) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('มกราคม'), findsOneWidget);
    });

    testWidgets('should handle null initial date gracefully', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: null,
              onDateSelected: (date) {},
            ),
          ),
        ),
      );

      // Assert - Should not crash and display current date
      expect(find.byType(BuddhistCalendarPicker), findsOneWidget);
    });

    testWidgets('should convert to Buddhist year correctly', (WidgetTester tester) async {
      // Arrange
      final testDate = DateTime(2025, 6, 15); // 2568 in Buddhist calendar

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: testDate,
              onDateSelected: (date) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2568'), findsOneWidget);
      expect(find.text('มิถุนายน'), findsOneWidget);
    });

    testWidgets('should be responsive to theme changes', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BuddhistCalendarPicker(
              initialDate: DateTime.now(),
              onDateSelected: (date) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BuddhistCalendarPicker), findsOneWidget);
    });
  });
}