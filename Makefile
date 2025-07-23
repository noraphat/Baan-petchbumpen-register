# 🧪 Baan Petchbumpen Register - Test Makefile
# ==============================================

.PHONY: help test test-unit test-widget test-golden test-integration clean deps setup coverage report

# Default target
help: ## Show this help message
	@echo "🧪 Baan Petchbumpen Register Test Commands"
	@echo "==========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup and dependencies
setup: ## Initial project setup
	@echo "🔧 Setting up project..."
	flutter clean
	flutter pub get
	@echo "✅ Setup complete"

deps: ## Get dependencies
	@echo "📦 Getting dependencies..."
	flutter pub get

clean: ## Clean build artifacts
	@echo "🧹 Cleaning project..."
	flutter clean
	rm -rf coverage/
	rm -rf test_reports/
	@echo "✅ Clean complete"

# Test commands
test: ## Run all tests (except integration)
	@./test_runner.sh all

test-unit: ## Run unit tests only
	@./test_runner.sh unit

test-widget: ## Run widget tests only
	@./test_runner.sh widget

test-golden: ## Run golden tests only
	@./test_runner.sh golden

test-golden-update: ## Update golden test files
	@./test_runner.sh golden --update

test-integration: ## Run integration tests only
	@./test_runner.sh integration

test-all: ## Run all tests including integration
	@./test_runner.sh all --integration

# Coverage and reporting
coverage: ## Generate test coverage report
	@echo "📊 Generating coverage report..."
	flutter test --coverage
	@if command -v genhtml >/dev/null 2>&1; then \
		genhtml coverage/lcov.info -o coverage/html; \
		echo "✅ Coverage report generated in coverage/html/"; \
	else \
		echo "⚠️  Install lcov to generate HTML coverage report"; \
	fi

report: ## Generate comprehensive test report
	@./test_runner.sh all
	@echo "📈 Test report generated in test_reports/"

# Development helpers
watch: ## Watch for changes and run tests
	@echo "👀 Watching for changes..."
	@find lib test -name "*.dart" | entr -c make test-unit

watch-golden: ## Watch for changes and run golden tests
	@echo "👀 Watching for golden test changes..."
	@find lib test/golden -name "*.dart" | entr -c make test-golden

# Lint and format
lint: ## Run dart analyzer
	@echo "🔍 Running dart analyzer..."
	dart analyze

format: ## Format dart code
	@echo "✨ Formatting code..."
	dart format .

format-check: ## Check if code is properly formatted
	@echo "🔍 Checking code format..."
	dart format --set-exit-if-changed .

# CI/CD helpers
ci-test: ## Run tests suitable for CI environment
	@echo "🚀 Running CI tests..."
	flutter clean
	flutter pub get
	flutter test --coverage
	flutter test test/golden/

# Build and verify
build: ## Build the app
	@echo "🏗️  Building app..."
	flutter build apk --debug

build-release: ## Build release version
	@echo "🏗️  Building release..."
	flutter build apk --release

verify: ## Full verification (format, lint, test, build)
	@echo "✅ Running full verification..."
	make format-check
	make lint
	make test
	make build
	@echo "🎉 All verifications passed!"

# Database and setup
db-reset: ## Reset test database
	@echo "🗄️  Resetting test database..."
	@# Add database reset commands here if needed

# Documentation
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	dart doc .

# Utility commands
open-coverage: ## Open coverage report in browser
	@if [ -f "coverage/html/index.html" ]; then \
		open coverage/html/index.html || xdg-open coverage/html/index.html; \
	else \
		echo "❌ Coverage report not found. Run 'make coverage' first."; \
	fi

open-report: ## Open test report in browser
	@if [ -f "test_reports/test_report.html" ]; then \
		open test_reports/test_report.html || xdg-open test_reports/test_report.html; \
	else \
		echo "❌ Test report not found. Run 'make report' first."; \
	fi

# Quick commands for common workflows
quick-test: deps test-unit test-widget ## Quick test run (unit + widget)
	@echo "⚡ Quick tests completed"

full-test: clean setup test-all coverage report ## Full test suite with reporting
	@echo "🎯 Full test suite completed"

pre-commit: format lint test-unit test-widget ## Pre-commit checks
	@echo "✅ Pre-commit checks passed"

# Default target when no argument is provided
.DEFAULT_GOAL := help