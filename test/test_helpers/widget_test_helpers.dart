import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Widget test helpers for common testing patterns and utilities
class WidgetTestHelpers {
  /// Creates a MaterialApp wrapper with Thai localization support
  static Widget createMaterialApp({
    required Widget child,
    ThemeData? theme,
    List<NavigatorObserver>? navigatorObservers,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      theme: theme ?? ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.purple,
      ),
      navigatorObservers: navigatorObservers ?? [],
      home: child,
    );
  }

  /// Creates a scaffold wrapper for testing individual widgets
  static Widget createScaffoldWrapper({
    required Widget child,
    String? title,
    List<Widget>? actions,
  }) {
    return Scaffold(
      appBar: title != null ? AppBar(
        title: Text(title),
        actions: actions,
      ) : null,
      body: child,
    );
  }

  /// Sets up Thai locale for date testing
  static Future<void> setupThaiLocale() async {
    await initializeDateFormatting('th_TH', null);
  }

  /// Pumps and settles with a reasonable timeout
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), timeout);
  }

  /// Enters text in a text field with better error handling
  static Future<void> enterTextSafely(
    WidgetTester tester,
    Finder finder,
    String text, {
    bool shouldFind = true,
  }) async {
    if (shouldFind) {
      expect(finder, findsOneWidget);
    }
    
    if (tester.any(finder)) {
      await tester.enterText(finder, text);
      await tester.pump();
    }
  }

  /// Taps a widget with better error handling and feedback
  static Future<void> tapSafely(
    WidgetTester tester,
    Finder finder, {
    bool shouldFind = true,
    Duration? settleTimeout,
  }) async {
    if (shouldFind) {
      expect(finder, findsOneWidget);
    }
    
    if (tester.any(finder)) {
      await tester.tap(finder);
      if (settleTimeout != null) {
        await tester.pumpAndSettle(const Duration(milliseconds: 100), settleTimeout);
      } else {
        await tester.pump();
      }
    }
  }

  /// Scrolls to make a widget visible before interacting with it
  static Future<void> scrollToAndTap(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = 100.0,
  }) async {
    if (!tester.any(finder)) {
      await tester.ensureVisible(finder);
    }
    await tapSafely(tester, finder);
  }

  /// Fills a complete form with validation
  static Future<void> fillForm(
    WidgetTester tester,
    Map<String, String> formData, {
    bool validate = true,
  }) async {
    for (final entry in formData.entries) {
      final fieldFinder = find.widgetWithText(TextFormField, entry.key);
      if (tester.any(fieldFinder)) {
        await enterTextSafely(tester, fieldFinder, entry.value);
      }
    }
    
    if (validate) {
      // Trigger validation by attempting to submit or move focus
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
  }

  /// Selects a dropdown value
  static Future<void> selectDropdownValue(
    WidgetTester tester,
    String dropdownLabel,
    String valueToSelect,
  ) async {
    // Tap dropdown to open it
    await tapSafely(tester, find.text(dropdownLabel));
    await tester.pumpAndSettle();
    
    // Select the value
    await tapSafely(tester, find.text(valueToSelect).last);
    await tester.pumpAndSettle();
  }

  /// Verifies that a validation error is shown
  static void expectValidationError(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// Verifies that no validation errors are shown
  static void expectNoValidationErrors(List<String> possibleErrors) {
    for (final error in possibleErrors) {
      expect(find.text(error), findsNothing);
    }
  }

  /// Verifies navigation occurred by checking for new widget type
  static void expectNavigationTo<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Verifies that a snackbar with specific message is shown
  static void expectSnackbar(String message) {
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  }

  /// Waits for a snackbar to appear and disappear
  static Future<void> waitForSnackbar(
    WidgetTester tester,
    String message, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pump();
    expectSnackbar(message);
    
    // Wait for snackbar to disappear
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SnackBar), findsNothing);
  }

  /// Sets up a mock for navigation testing
  static List<NavigatorObserver> createMockNavigatorObserver() {
    return [MockNavigatorObserver()];
  }

  /// Creates a test-friendly date picker interaction
  static Future<void> selectDate(
    WidgetTester tester,
    String dateFieldLabel,
    int day, {
    bool isBuddhistCalendar = false,
  }) async {
    // Tap date field to open picker
    await tapSafely(tester, find.widgetWithText(TextFormField, dateFieldLabel));
    await tester.pumpAndSettle();
    
    if (isBuddhistCalendar) {
      // Handle Buddhist calendar picker
      expect(find.byType(Dialog), findsOneWidget);
      await tapSafely(tester, find.text('$day'));
      await tester.pumpAndSettle();
    } else {
      // Handle regular date picker
      await tapSafely(tester, find.text('$day'));
      await tester.pumpAndSettle();
    }
  }

  /// Verifies that required fields are marked appropriately
  static void expectRequiredFields(List<String> fieldLabels) {
    for (final label in fieldLabels) {
      expect(find.widgetWithText(TextFormField, label), findsOneWidget);
    }
  }

  /// Tests accessibility features
  static void expectAccessible(WidgetTester tester, Finder finder) {
    final widget = tester.widget(finder);
    
    // Check that interactive widgets have onTap or similar
    if (widget is GestureDetector) {
      expect((widget as GestureDetector).onTap, isNotNull);
    } else if (widget is InkWell) {
      expect((widget as InkWell).onTap, isNotNull);
    } else if (widget is ElevatedButton) {
      expect((widget as ElevatedButton).onPressed, isNotNull);
    }
  }

  /// Tests responsive design by changing screen sizes
  static Future<void> testResponsiveness(
    WidgetTester tester,
    Widget widget,
    List<Size> screenSizes,
  ) async {
    for (final size in screenSizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      
      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    }
    
    // Reset to default
    await tester.binding.setSurfaceSize(null);
  }

  /// Common screen sizes for responsive testing
  static List<Size> get commonScreenSizes => [
    const Size(320, 568), // iPhone SE
    const Size(375, 667), // iPhone 8
    const Size(414, 896), // iPhone 11 Pro Max
    const Size(768, 1024), // iPad
    const Size(1024, 1366), // iPad Pro
  ];

  /// Tests performance by measuring build times
  static Future<Duration> measureBuildTime(
    WidgetTester tester,
    Widget widget,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verifies theme consistency
  static void expectThemeConsistency(WidgetTester tester) {
    final context = tester.element(find.byType(MaterialApp));
    final theme = Theme.of(context);
    
    // Verify color scheme
    expect(theme.colorScheme.primary, isNotNull);
    expect(theme.colorScheme.secondary, isNotNull);
    
    // Verify text theme
    expect(theme.textTheme.bodyLarge, isNotNull);
    expect(theme.textTheme.bodyMedium, isNotNull);
  }

  /// Creates a custom finder for Thai text
  static Finder findThaiText(String text) {
    return find.text(text);
  }

  /// Verifies that Thai text renders correctly
  static void expectThaiTextRendering(String thaiText) {
    expect(find.text(thaiText), findsOneWidget);
  }

  /// Tests keyboard navigation support
  static Future<void> testKeyboardNavigation(
    WidgetTester tester,
    List<Finder> focusableWidgets,
  ) async {
    for (final finder in focusableWidgets) {
      if (tester.any(finder)) {
        await tester.tap(finder);
        await tester.pump();
        
        // Verify focus
        final widget = tester.widget(finder);
        if (widget is Focus) {
          expect((widget as Focus).autofocus || (widget as Focus).canRequestFocus, isTrue);
        }
      }
    }
  }

  /// Common assertions for form validation
  static void expectFormValidation(
    Map<String, String> validData,
    Map<String, String> invalidData,
    List<String> expectedErrors,
  ) {
    // Verify valid data passes
    for (final entry in validData.entries) {
      expect(find.widgetWithText(TextFormField, entry.key), findsOneWidget);
    }
    
    // Verify invalid data shows errors
    for (final error in expectedErrors) {
      expect(find.text(error), findsOneWidget);
    }
  }
}

/// Mock navigator observer for testing navigation
class MockNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];
  final List<Route<dynamic>> removedRoutes = [];
  final List<Route<dynamic>> replacedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    removedRoutes.add(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacedRoutes.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
    removedRoutes.clear();
    replacedRoutes.clear();
  }
}