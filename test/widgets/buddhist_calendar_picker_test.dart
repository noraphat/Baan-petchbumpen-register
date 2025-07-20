import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_petchbumpen_register/widgets/buddhist_calendar_picker.dart';

void main() {
  setUpAll(() async {
    // Initialize Thai locale for date formatting
    await initializeDateFormatting('th_TH', null);
  });

  group('BuddhistCalendarPicker Tests', () {
    late DateTime selectedDate;
    
    void onDateSelected(DateTime date) {
      selectedDate = date;
    }

    Widget createTestWidget({DateTime? initialDate}) {
      return MaterialApp(
        home: Scaffold(
          body: BuddhistCalendarPicker(
            initialDate: initialDate,
            onDateSelected: onDateSelected,
          ),
        ),
      );
    }

    group('Initialization', () {
      testWidgets('should display current month when no initial date provided',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final now = DateTime.now();
        final currentYear = now.year + 543; // Convert to Buddhist Era
        
        // Should show current year in Buddhist Era
        expect(find.textContaining('$currentYear'), findsOneWidget);
        
        // Should show Thai month names
        expect(find.textContaining('มกราคม'), findsAny);
      });

      testWidgets('should display initial date when provided',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15); // 15 พฤษภาคม 2530
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Should show 2530 (1987 + 543)
        expect(find.textContaining('2530'), findsOneWidget);
        expect(find.textContaining('พฤษภาคม'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate to next month when next button pressed',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Find and tap the next month button (right arrow)
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Should show June (มิถุนายน)
        expect(find.textContaining('มิถุนายน'), findsOneWidget);
        expect(find.textContaining('2530'), findsOneWidget);
      });

      testWidgets('should navigate to previous month when previous button pressed',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Find and tap the previous month button (left arrow)
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        // Should show April (เมษายน)
        expect(find.textContaining('เมษายน'), findsOneWidget);
        expect(find.textContaining('2530'), findsOneWidget);
      });

      testWidgets('should handle year transition correctly',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 1, 15); // January 2530
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Go to previous month (should be December of previous year)
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();

        expect(find.textContaining('ธันวาคม'), findsOneWidget);
        expect(find.textContaining('2529'), findsOneWidget);
      });
    });

    group('Year Selection', () {
      testWidgets('should open year selector when month/year button pressed',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Tap on the month/year button
        await tester.tap(find.textContaining('พฤษภาคม 2530'));
        await tester.pumpAndSettle();

        // Should show year selection dialog
        expect(find.text('เลือกปี พ.ศ.'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should display years in Buddhist Era in year selector',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('พฤษภาคม 2530'));
        await tester.pumpAndSettle();

        // Should show years in Buddhist Era (CE + 543)
        expect(find.text('2530'), findsAtLeastNWidgets(1));
        expect(find.text('2531'), findsAtLeastNWidgets(1));
        expect(find.text('2529'), findsAtLeastNWidgets(1));
      });

      testWidgets('should select year and close dialog',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('พฤษภาคม 2530'));
        await tester.pumpAndSettle();

        // Select a different year
        await tester.tap(find.text('2535').first);
        await tester.pumpAndSettle();

        // Should show the selected year
        expect(find.textContaining('พฤษภาคม 2535'), findsOneWidget);
        expect(find.text('เลือกปี พ.ศ.'), findsNothing);
      });
    });

    group('Day Labels', () {
      testWidgets('should display Thai day labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for Thai day abbreviations
        expect(find.text('อา'), findsOneWidget); // Sunday
        expect(find.text('จ'), findsOneWidget);  // Monday
        expect(find.text('อ'), findsOneWidget);  // Tuesday
        expect(find.text('พ'), findsOneWidget);  // Wednesday
        expect(find.text('พฤ'), findsOneWidget); // Thursday
        expect(find.text('ศ'), findsOneWidget);  // Friday
        expect(find.text('ส'), findsOneWidget);  // Saturday
      });
    });

    group('Day Selection', () {
      testWidgets('should highlight initially selected date',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Find the container for day 15
        final dayContainers = find.byType(Container);
        bool foundSelectedDay = false;

        for (int i = 0; i < tester.widgetList(dayContainers).length; i++) {
          final container = tester.widget<Container>(dayContainers.at(i));
          if (container.decoration is BoxDecoration) {
            final boxDecoration = container.decoration as BoxDecoration;
            if (boxDecoration.color == Colors.orange) {
              foundSelectedDay = true;
              break;
            }
          }
        }

        expect(foundSelectedDay, isTrue);
      });

      testWidgets('should call onDateSelected when day is tapped',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        selectedDate = initialDate;
        
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Tap on day 20
        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();

        // Should call onDateSelected with the new date
        expect(selectedDate.day, equals(20));
        expect(selectedDate.month, equals(5));
        expect(selectedDate.year, equals(1987));
      });

      testWidgets('should update visual selection when day is tapped',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Tap on day 20
        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();

        // Should update the visual selection
        final dayContainers = find.byType(Container);
        bool foundSelectedDay = false;

        for (int i = 0; i < tester.widgetList(dayContainers).length; i++) {
          final container = tester.widget<Container>(dayContainers.at(i));
          if (container.child is Text) {
            final text = container.child as Text;
            if (text.data == '20' && 
                container.decoration is BoxDecoration) {
              final boxDecoration = container.decoration as BoxDecoration;
              if (boxDecoration.color == Colors.orange) {
                foundSelectedDay = true;
                break;
              }
            }
          }
        }

        expect(foundSelectedDay, isTrue);
      });

      testWidgets('should handle edge cases for month boundaries',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 31);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Tap day 1
        await tester.tap(find.text('1'));
        await tester.pumpAndSettle();

        expect(selectedDate.day, equals(1));
        expect(selectedDate.month, equals(5));
        expect(selectedDate.year, equals(1987));
      });
    });

    group('Calendar Grid Layout', () {
      testWidgets('should display proper number of days for the month',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 2, 15); // February 1987 (28 days)
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Should find days 1-28 for February 1987
        for (int day = 1; day <= 28; day++) {
          expect(find.text('$day'), findsOneWidget);
        }
        expect(find.text('29'), findsNothing);
        expect(find.text('30'), findsNothing);
        expect(find.text('31'), findsNothing);
      });

      testWidgets('should handle leap year correctly',
          (WidgetTester tester) async {
        final initialDate = DateTime(1988, 2, 15); // February 1988 (leap year, 29 days)
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Should find days 1-29 for February 1988
        for (int day = 1; day <= 29; day++) {
          expect(find.text('$day'), findsOneWidget);
        }
        expect(find.text('30'), findsNothing);
        expect(find.text('31'), findsNothing);
      });

      testWidgets('should display 31 days for months with 31 days',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 1, 15); // January 1987 (31 days)
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Should find all days 1-31
        for (int day = 1; day <= 31; day++) {
          expect(find.text('$day'), findsOneWidget);
        }
      });
    });

    group('Buddhist Era Conversion', () {
      testWidgets('should correctly convert CE to Buddhist Era',
          (WidgetTester tester) async {
        final testCases = [
          (DateTime(1987, 5, 15), '2530'), // 1987 + 543 = 2530
          (DateTime(2000, 1, 1), '2543'),  // 2000 + 543 = 2543
          (DateTime(2024, 12, 31), '2567'), // 2024 + 543 = 2567
        ];

        for (final (date, expectedYear) in testCases) {
          await tester.pumpWidget(createTestWidget(initialDate: date));
          await tester.pumpAndSettle();

          expect(find.textContaining(expectedYear), findsOneWidget);

          // Clean up for next iteration
          await tester.pumpWidget(const SizedBox());
        }
      });
    });

    group('Accessibility', () {
      testWidgets('should be accessible for screen readers',
          (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check that navigation buttons have proper semantics
        final prevButton = find.byIcon(Icons.chevron_left);
        final nextButton = find.byIcon(Icons.chevron_right);

        expect(prevButton, findsOneWidget);
        expect(nextButton, findsOneWidget);

        // Buttons should be tappable
        expect(tester.widget<IconButton>(prevButton).onPressed, isNotNull);
        expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);
      });

      testWidgets('should support tap interactions on all interactive elements',
          (WidgetTester tester) async {
        final initialDate = DateTime(1987, 5, 15);
        await tester.pumpWidget(createTestWidget(initialDate: initialDate));
        await tester.pumpAndSettle();

        // Test month/year button
        final monthYearButton = find.textContaining('พฤษภาคม 2530');
        expect(tester.widget<TextButton>(monthYearButton).onPressed, isNotNull);

        // Test day selection
        final dayButtons = find.byType(GestureDetector);
        expect(dayButtons, findsAtLeastNWidgets(20)); // At least 20 days should be tappable
      });
    });

    group('Error Handling', () {
      testWidgets('should handle extreme dates gracefully',
          (WidgetTester tester) async {
        final extremeDate = DateTime(1900, 1, 1);
        await tester.pumpWidget(createTestWidget(initialDate: extremeDate));
        await tester.pumpAndSettle();

        // Should display without crashing
        expect(find.textContaining('2443'), findsOneWidget); // 1900 + 543
        expect(find.textContaining('มกราคม'), findsOneWidget);
      });

      testWidgets('should handle future dates gracefully',
          (WidgetTester tester) async {
        final futureDate = DateTime(2100, 12, 31);
        await tester.pumpWidget(createTestWidget(initialDate: futureDate));
        await tester.pumpAndSettle();

        // Should display without crashing
        expect(find.textContaining('2643'), findsOneWidget); // 2100 + 543
        expect(find.textContaining('ธันวาคม'), findsOneWidget);
      });
    });
  });
}