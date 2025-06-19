# Clix Flutter SDK Makefile
# This Makefile provides common development tasks for the Clix Flutter SDK

.PHONY: help build clean format lint lint-fix test analyze get upgrade doctor check-dependencies all run-ios build-ios run-android build-android

# Default target - show help
help:
	@echo "Clix Flutter SDK - Available commands:"
	@echo ""
	@echo "  build                - Build the Flutter package"
	@echo "  clean                - Clean build artifacts and caches"
	@echo "  format               - Format Dart code"
	@echo "  lint                 - Run code analysis (lint)"
	@echo "  lint-fix             - Fix linting issues automatically"
	@echo "  test                 - Run tests with coverage"
	@echo "  analyze              - Run comprehensive code analysis"
	@echo "  get                  - Get package dependencies"
	@echo "  upgrade              - Upgrade package dependencies"
	@echo "  doctor               - Check Flutter/Dart installation"
	@echo "  check-dependencies   - Check for dependency issues"
	@echo "  all                  - Run format, lint-fix, test, and build"
	@echo "  build-ios            - Build the iOS version of the basic_app"
	@echo "  run-ios              - Run the iOS version of the basic_app in simulator"
	@echo "  build-android        - Build the Android version of the basic_app"
	@echo "  run-android          - Run the Android version of the basic_app in emulator"
	@echo ""
	@echo "Example usage:"
	@echo "  make build           # Build the package"
	@echo "  make test            # Run tests"
	@echo "  make all             # Complete development workflow"
	@echo "  make run-ios         # Run the iOS version of the basic_app"
	@echo "  make run-android     # Run the Android version of the basic_app"

# Build the Flutter package
build:
	@echo "🔨 Building Clix Flutter SDK..."
	@flutter packages get
	@flutter analyze --no-pub --no-fatal-warnings lib/
	@echo "✅ SDK build completed successfully"

# Clean build artifacts and caches
clean:
	@echo "🧹 Cleaning build artifacts..."
	@flutter clean
	@rm -rf .dart_tool/
	@rm -rf build/
	@rm -rf .packages
	@rm -rf pubspec.lock
	@echo "✅ Clean completed successfully"

# Format Dart code
format:
	@echo "🎨 Formatting Dart code..."
	@dart format --set-exit-if-changed lib/ samples/ $(shell [ -d test ] && echo test/)
	@echo "✅ Code formatting completed"

# Run code analysis (lint)
lint:
	@echo "🔍 Running code analysis..."
	@dart analyze --fatal-infos --fatal-warnings
	@echo "✅ Code analysis completed"

# Fix linting issues automatically
lint-fix:
	@echo "🔧 Fixing linting issues..."
	@dart fix --apply
	@dart format lib/ test/ samples/
	@echo "✅ Lint fixes applied"

# Run tests with coverage
test:
	@echo "🧪 Running tests..."
	@if [ -d test ]; then flutter test --coverage; else echo "No test directory found, skipping tests"; fi
	@echo "✅ Tests completed"

# Run comprehensive code analysis
analyze:
	@echo "📊 Running comprehensive analysis..."
	@dart analyze --verbose
	@dart pub deps
	@echo "✅ Analysis completed"

# Get package dependencies
get:
	@echo "📦 Getting package dependencies..."
	@flutter packages get
	@echo "✅ Dependencies updated"

# Upgrade package dependencies
upgrade:
	@echo "⬆️ Upgrading package dependencies..."
	@flutter packages upgrade
	@echo "✅ Dependencies upgraded"

# Check Flutter/Dart installation
doctor:
	@echo "🩺 Checking Flutter/Dart installation..."
	@flutter doctor -v
	@dart --version
	@echo "✅ Doctor check completed"

# Check for dependency issues
check-dependencies:
	@echo "🔍 Checking dependencies..."
	@dart pub deps
	@dart pub outdated
	@echo "✅ Dependency check completed"

# Complete development workflow
all: format lint-fix test build
	@echo "🎉 All tasks completed successfully!"
	@echo ""
	@echo "Summary:"
	@echo "  ✅ Code formatted"
	@echo "  ✅ Lint issues fixed"
	@echo "  ✅ Tests passed"
	@echo "  ✅ Build successful"
	@echo ""
	@echo "Your Clix Flutter SDK is ready! 🚀"

# Build the iOS version of the basic_app
build-ios:
	@echo "🔨 Building iOS version of basic_app..."
	@cd samples/basic_app && flutter build ios --no-codesign
	@echo "✅ iOS build completed successfully"

# Run the iOS version of the basic_app in simulator
run-ios:
	@echo "🚀 Running iOS version of basic_app in simulator..."
	@cd samples/basic_app && flutter run -d ios
	@echo "✅ iOS app launched successfully"

# Build the Android version of the basic_app
build-android:
	@echo "🔨 Building Android version of basic_app..."
	@cd samples/basic_app && flutter pub get
	@cd samples/basic_app && flutter build apk
	@echo "✅ Android build completed successfully"

# Run the Android version of the basic_app in emulator
run-android:
	@echo "🚀 Running Android version of basic_app in emulator..."
	@cd samples/basic_app && flutter pub get
	@cd samples/basic_app && flutter run -d android
	@echo "✅ Android app launched successfully"
