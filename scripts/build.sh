#!/bin/bash

# Clix Flutter SDK Build Script
# Alternative to Makefile for environments without make

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Help function
show_help() {
    echo "Clix Flutter SDK Build Script"
    echo ""
    echo "Usage: ./scripts/build.sh [command]"
    echo ""
    echo "Available commands:"
    echo "  build                - Build the Flutter package"
    echo "  clean                - Clean build artifacts and caches"
    echo "  format               - Format Dart code"
    echo "  lint                 - Run code analysis (lint)"
    echo "  lint-fix             - Fix linting issues automatically"
    echo "  test                 - Run tests with coverage"
    echo "  analyze              - Run comprehensive code analysis"
    echo "  get                  - Get package dependencies"
    echo "  upgrade              - Upgrade package dependencies"
    echo "  doctor               - Check Flutter/Dart installation"
    echo "  check-dependencies   - Check for dependency issues"
    echo "  all                  - Run format, lint-fix, test, and build"
    echo "  help                 - Show this help message"
    echo ""
    echo "Example usage:"
    echo "  ./scripts/build.sh build    # Build the package"
    echo "  ./scripts/build.sh test     # Run tests"
    echo "  ./scripts/build.sh all      # Complete development workflow"
}

# Build function
build() {
    print_status "🔨 Building Clix Flutter SDK..."
    flutter packages get
    dart compile kernel lib/clix.dart -o build/clix.dill
    print_success "Build completed successfully"
}

# Clean function
clean() {
    print_status "🧹 Cleaning build artifacts..."
    flutter clean
    rm -rf .dart_tool/ build/ .packages pubspec.lock
    print_success "Clean completed successfully"
}

# Format function
format() {
    print_status "🎨 Formatting Dart code..."
    dart format --set-exit-if-changed lib/ test/ samples/
    print_success "Code formatting completed"
}

# Lint function
lint() {
    print_status "🔍 Running code analysis..."
    dart analyze --fatal-infos --fatal-warnings
    print_success "Code analysis completed"
}

# Lint fix function
lint_fix() {
    print_status "🔧 Fixing linting issues..."
    dart fix --apply
    dart format lib/ test/ samples/
    print_success "Lint fixes applied"
}

# Test function
test() {
    print_status "🧪 Running tests..."
    flutter test --coverage
    print_success "Tests completed"
}

# Analyze function
analyze() {
    print_status "📊 Running comprehensive analysis..."
    dart analyze --verbose
    dart pub deps
    print_success "Analysis completed"
}

# Get dependencies function
get() {
    print_status "📦 Getting package dependencies..."
    flutter packages get
    print_success "Dependencies updated"
}

# Upgrade dependencies function
upgrade() {
    print_status "⬆️ Upgrading package dependencies..."
    flutter packages upgrade
    print_success "Dependencies upgraded"
}

# Doctor function
doctor() {
    print_status "🩺 Checking Flutter/Dart installation..."
    flutter doctor -v
    dart --version
    print_success "Doctor check completed"
}

# Check dependencies function
check_dependencies() {
    print_status "🔍 Checking dependencies..."
    dart pub deps
    dart pub outdated
    print_success "Dependency check completed"
}

# All function
all() {
    print_status "🚀 Running complete development workflow..."
    format
    lint_fix
    test
    build
    echo ""
    print_success "🎉 All tasks completed successfully!"
    echo ""
    echo "Summary:"
    echo "  ✅ Code formatted"
    echo "  ✅ Lint issues fixed"
    echo "  ✅ Tests passed"
    echo "  ✅ Build successful"
    echo ""
    echo "Your Clix Flutter SDK is ready! 🚀"
}

# Main script logic
case "${1:-help}" in
    build)
        build
        ;;
    clean)
        clean
        ;;
    format)
        format
        ;;
    lint)
        lint
        ;;
    lint-fix)
        lint_fix
        ;;
    test)
        test
        ;;
    analyze)
        analyze
        ;;
    get)
        get
        ;;
    upgrade)
        upgrade
        ;;
    doctor)
        doctor
        ;;
    check-dependencies)
        check_dependencies
        ;;
    all)
        all
        ;;
    help|*)
        show_help
        ;;
esac