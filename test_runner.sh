#!/bin/bash

# 🧪 Baan Petchbumpen Register Test Runner
# ==========================================
# Script สำหรับรัน tests ทุกประเภทในโปรเจ็กต์

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

print_header() {
    echo "=========================================="
    print_color $BLUE "$1"
    echo "=========================================="
}

print_success() {
    print_color $GREEN "✅ $1"
}

print_warning() {
    print_color $YELLOW "⚠️  $1"
}

print_error() {
    print_color $RED "❌ $1"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    print_success "Flutter found: $(flutter --version | head -n 1)"
}

# Clean and get dependencies
setup_dependencies() {
    print_header "Setting up dependencies"
    flutter clean
    flutter pub get
    print_success "Dependencies installed"
}

# Run unit tests
run_unit_tests() {
    print_header "Running Unit Tests"
    
    if flutter test --coverage; then
        print_success "Unit tests passed"
        
        # Generate coverage report if lcov is available
        if command -v genhtml &> /dev/null; then
            print_color $BLUE "Generating coverage report..."
            genhtml coverage/lcov.info -o coverage/html
            print_success "Coverage report generated in coverage/html/"
        else
            print_warning "genhtml not found. Install lcov to generate HTML coverage report"
        fi
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Run widget tests
run_widget_tests() {
    print_header "Running Widget Tests"
    
    if flutter test test/widgets/ --coverage; then
        print_success "Widget tests passed"
    else
        print_error "Widget tests failed"
        return 1
    fi
}

# Run golden tests
run_golden_tests() {
    print_header "Running Golden Tests"
    
    # Update goldens if --update flag is passed
    if [[ "$1" == "--update" ]]; then
        print_color $YELLOW "Updating golden files..."
        if flutter test test/golden/ --update-goldens; then
            print_success "Golden files updated"
        else
            print_error "Failed to update golden files"
            return 1
        fi
    else
        if flutter test test/golden/; then
            print_success "Golden tests passed"
        else
            print_error "Golden tests failed"
            print_warning "Run with --update to update golden files"
            return 1
        fi
    fi
}

# Run integration tests
run_integration_tests() {
    print_header "Running Integration Tests"
    
    # Check if device/emulator is connected
    if ! flutter devices | grep -q "device"; then
        print_warning "No device connected. Starting emulator..."
        # Try to start an emulator (iOS Simulator or Android Emulator)
        if command -v xcrun &> /dev/null; then
            xcrun simctl boot "iPhone 15" 2>/dev/null || true
        elif command -v emulator &> /dev/null; then
            emulator -avd test_avd -no-window &
            sleep 10
        fi
    fi
    
    if flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/registration_flow_test.dart; then
        print_success "Registration flow integration tests passed"
    else
        print_error "Registration flow integration tests failed"
        return 1
    fi
    
    if flutter drive \
        --driver=test_driver/integration_test.dart \
        --target=integration_test/white_robe_flow_test.dart; then
        print_success "White robe flow integration tests passed"
    else
        print_error "White robe flow integration tests failed"
        return 1
    fi
}

# Run all tests
run_all_tests() {
    local update_goldens=""
    if [[ "$1" == "--update" ]]; then
        update_goldens="--update"
    fi
    
    setup_dependencies
    run_unit_tests
    run_widget_tests
    run_golden_tests $update_goldens
    
    # Only run integration tests if --integration flag is passed
    if [[ "$*" == *"--integration"* ]]; then
        run_integration_tests
    else
        print_warning "Skipping integration tests (use --integration to include them)"
    fi
}

# Generate test report
generate_report() {
    print_header "Generating Test Report"
    
    local report_dir="test_reports"
    mkdir -p $report_dir
    
    # Create a simple HTML report
    cat > $report_dir/test_report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Baan Petchbumpen Register - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #6a1b9a; border-bottom: 2px solid #6a1b9a; padding-bottom: 10px; }
        .section { margin: 20px 0; }
        .pass { color: #4caf50; }
        .fail { color: #f44336; }
        .info { color: #2196f3; }
    </style>
</head>
<body>
    <h1 class="header">🧪 Test Report - $(date)</h1>
    
    <div class="section">
        <h2>Test Summary</h2>
        <ul>
            <li>Unit Tests: <span class="pass">✅ Passed</span></li>
            <li>Widget Tests: <span class="pass">✅ Passed</span></li>
            <li>Golden Tests: <span class="pass">✅ Passed</span></li>
            <li>Integration Tests: <span class="info">ℹ️ Manual Run Required</span></li>
        </ul>
    </div>
    
    <div class="section">
        <h2>Coverage</h2>
        <p>Coverage report available in: <code>coverage/html/index.html</code></p>
    </div>
    
    <div class="section">
        <h2>Test Types</h2>
        <ul>
            <li><strong>Unit Tests:</strong> Models, Services, Utilities</li>
            <li><strong>Widget Tests:</strong> UI Components, User Interactions</li>
            <li><strong>Golden Tests:</strong> Visual Regression Testing</li>
            <li><strong>Integration Tests:</strong> End-to-End User Flows</li>
        </ul>
    </div>
</body>
</html>
EOF
    
    print_success "Test report generated: $report_dir/test_report.html"
}

# Main script logic
main() {
    print_header "🧪 Baan Petchbumpen Register Test Runner"
    
    check_flutter
    
    case "${1:-all}" in
        "unit")
            setup_dependencies
            run_unit_tests
            ;;
        "widget")
            setup_dependencies
            run_widget_tests
            ;;
        "golden")
            setup_dependencies
            run_golden_tests "${2}"
            ;;
        "integration")
            setup_dependencies
            run_integration_tests
            ;;
        "all")
            run_all_tests "$@"
            generate_report
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [COMMAND] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  unit         Run unit tests only"
            echo "  widget       Run widget tests only"
            echo "  golden       Run golden tests only"
            echo "  integration  Run integration tests only"
            echo "  all          Run all tests (default)"
            echo "  help         Show this help message"
            echo ""
            echo "Options:"
            echo "  --update     Update golden files (for golden tests)"
            echo "  --integration Include integration tests in 'all' command"
            echo ""
            echo "Examples:"
            echo "  $0                     # Run all tests except integration"
            echo "  $0 all --integration   # Run all tests including integration"
            echo "  $0 golden --update     # Update golden test files"
            echo "  $0 unit                # Run unit tests only"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"