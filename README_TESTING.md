# 🧪 Testing Guide - Baan Petchbumpen Register

This guide covers the comprehensive testing strategy for the Baan Petchbumpen Register Flutter application.

## 📋 Table of Contents

- [Testing Overview](#testing-overview)
- [Test Types](#test-types)
- [Quick Start](#quick-start)
- [Running Tests](#running-tests)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## 🎯 Testing Overview

Our testing strategy includes:

- **Unit Tests** - Models, services, and utility functions
- **Widget Tests** - UI components and user interactions
- **Integration Tests** - End-to-end user flows
- **Golden Tests** - Visual regression testing

### Test Coverage Goals
- **Unit Tests**: 90%+ coverage
- **Widget Tests**: All custom widgets
- **Integration Tests**: Critical user flows
- **Golden Tests**: Key UI components

## 🔬 Test Types

### 1. Unit Tests (`test/`)
Test individual functions, classes, and services.

```bash
# Run unit tests
./test_runner.sh unit
# or
make test-unit
```

**Examples:**
- Model validation (`test/models/`)
- Database operations (`test/services/db_helper_test.dart`)
- Address service (`test/services/address_service_test.dart`)

### 2. Widget Tests (`test/widgets/`)
Test individual UI components in isolation.

```bash
# Run widget tests
./test_runner.sh widget
# or
make test-widget
```

**Examples:**
- `MenuCard` interactions
- `BuddhistCalendarPicker` functionality
- Form validation behavior

### 3. Integration Tests (`integration_test/`)
Test complete user workflows from start to finish.

```bash
# Run integration tests (requires device/emulator)
./test_runner.sh integration
# or
make test-integration
```

**Examples:**
- Complete registration flow
- White robe distribution process
- Navigation between screens

### 4. Golden Tests (`test/golden/`)
Visual regression testing to ensure UI consistency.

```bash
# Run golden tests
./test_runner.sh golden

# Update golden files
./test_runner.sh golden --update
# or
make test-golden-update
```

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.16.0+
- Device/emulator for integration tests
- lcov (optional, for coverage reports)

### Install lcov (for coverage reports)
```bash
# macOS
brew install lcov

# Ubuntu/Debian
sudo apt-get install lcov
```

### Run All Tests
```bash
# Quick test (unit + widget)
make quick-test

# All tests except integration
./test_runner.sh all
make test

# All tests including integration
./test_runner.sh all --integration
make test-all

# Full test suite with reports
make full-test
```

## 🏃‍♂️ Running Tests

### Using the Test Runner Script

The `test_runner.sh` script provides a unified interface:

```bash
# Make it executable (first time only)
chmod +x test_runner.sh

# Run specific test types
./test_runner.sh unit
./test_runner.sh widget
./test_runner.sh golden
./test_runner.sh integration

# Run all tests
./test_runner.sh all

# Update golden files
./test_runner.sh golden --update

# Get help
./test_runner.sh help
```

### Using Makefile Commands

```bash
# View all available commands
make help

# Common commands
make test          # All tests except integration
make test-unit     # Unit tests only  
make test-widget   # Widget tests only
make test-golden   # Golden tests only
make coverage      # Generate coverage report
make pre-commit    # Pre-commit checks
```

### Using Flutter Commands Directly

```bash
# Unit tests with coverage
flutter test --coverage

# Specific test file
flutter test test/widgets/menu_card_test.dart

# Golden tests
flutter test test/golden/

# Integration tests
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/registration_flow_test.dart
```

## 📁 Test Structure

```
test/
├── golden/                     # Golden/visual tests
│   ├── home_screen_golden_test.dart
│   ├── menu_card_golden_test.dart
│   └── buddhist_calendar_golden_test.dart
├── models/                     # Model tests
│   └── reg_data_test.dart
├── screens/                    # Screen tests
│   ├── home_screen_test.dart
│   ├── manual_form_test.dart
│   └── registration_menu_test.dart
├── services/                   # Service tests
│   ├── db_helper_test.dart
│   └── address_service_test.dart
├── widgets/                    # Widget tests
│   ├── menu_card_widget_test.dart
│   └── buddhist_calendar_picker_widget_test.dart
├── test_helpers/               # Test utilities
│   ├── test_data.dart
│   └── widget_test_helpers.dart
├── test_config.dart            # Test configuration
└── widget_test.dart            # Default widget test

integration_test/               # Integration tests
├── registration_flow_test.dart
└── white_robe_flow_test.dart

test_driver/                    # Integration test driver
└── integration_test.dart
```

## ✍️ Writing Tests

### Unit Test Example

```dart
// test/services/validation_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationService', () {
    test('should validate Thai National ID correctly', () {
      // Arrange
      const validId = '1234567890123';
      const invalidId = '1234567890124';
      
      // Act & Assert
      expect(ValidationService.validateThaiId(validId), isTrue);
      expect(ValidationService.validateThaiId(invalidId), isFalse);
    });
  });
}
```

### Widget Test Example

```dart
// test/widgets/menu_card_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MenuCard should display title and respond to tap', (tester) async {
    // Arrange
    bool tapped = false;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: MenuCard(
          title: 'Test',
          icon: Icons.test,
          color: Colors.blue,
          onTap: () => tapped = true,
        ),
      ),
    );
    
    // Assert
    expect(find.text('Test'), findsOneWidget);
    
    await tester.tap(find.byType(MenuCard));
    expect(tapped, isTrue);
  });
}
```

### Golden Test Example

```dart
// test/golden/menu_card_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('MenuCard should match golden file', (tester) async {
    await tester.pumpWidgetBuilder(
      const MenuCard(
        title: 'ลงทะเบียน',
        icon: Icons.person_add,
        color: Colors.blue,
        onTap: null,
      ),
    );
    
    await screenMatchesGolden(tester, 'menu_card_default');
  });
}
```

### Integration Test Example

```dart
// integration_test/registration_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('should complete registration flow', (tester) async {
    // Launch app
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to registration
    await tester.tap(find.text('ลงทะเบียน'));
    await tester.pumpAndSettle();
    
    // Fill form and submit
    // ... test implementation
  });
}
```

## 🤖 CI/CD Integration

### GitHub Actions

The project includes a comprehensive GitHub Actions workflow (`.github/workflows/test.yml`) that:

- Runs on push/PR to main/develop branches
- Executes all test types
- Generates coverage reports
- Uploads artifacts
- Runs security scans

### Running in CI

```yaml
# Trigger integration tests with commit message
git commit -m "Add new feature [integration]"

# Or manually trigger workflow
# Go to GitHub Actions tab and run "Test Suite" workflow
```

## 📊 Coverage Reports

### Generate Coverage

```bash
# Generate coverage report
make coverage

# Open in browser
make open-coverage
```

### Coverage Locations
- **Text report**: `coverage/lcov.info`
- **HTML report**: `coverage/html/index.html`
- **CI upload**: Automatically uploaded to Codecov

## 🔧 Configuration

### Test Configuration (`test/test_config.dart`)
- Mock services setup
- Common test data
- Helper functions
- Device configurations

### Flutter Test Config (`flutter_test_config.dart`)
- Golden test setup
- Font loading
- Global test configuration

## 🐛 Troubleshooting

### Common Issues

#### Golden Tests Failing
```bash
# Update golden files
./test_runner.sh golden --update
make test-golden-update
```

#### Integration Tests Not Running
```bash
# Check if device is connected
flutter devices

# Start emulator
open -a Simulator  # iOS
emulator -avd test_avd  # Android
```

#### Coverage Report Not Generated
```bash
# Install lcov
brew install lcov  # macOS
sudo apt-get install lcov  # Ubuntu

# Then run coverage
make coverage
```

#### Tests Running Slowly
```bash
# Run in parallel (if supported)
flutter test --concurrency=4

# Run specific test files only
flutter test test/widgets/menu_card_test.dart
```

### Debug Mode

```bash
# Run with verbose output
flutter test --verbose

# Run with debug prints
flutter test test/widgets/ --debug
```

### Test Data Issues

```bash
# Reset test database
make db-reset

# Clear test artifacts
make clean
```

## 🎯 Best Practices

1. **Write tests first** (TDD approach)
2. **Keep tests isolated** and independent
3. **Use descriptive test names** in Thai/English
4. **Mock external dependencies** (printer, camera, etc.)
5. **Update golden files** when UI changes intentionally
6. **Run tests before committing** code
7. **Maintain high coverage** (90%+ for unit tests)
8. **Test error conditions** and edge cases

## 📚 Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Mockito for Dart](https://pub.dev/packages/mockito)

---

**Happy Testing! 🧪✨**

For questions or issues, please check the troubleshooting section or create an issue in the repository.