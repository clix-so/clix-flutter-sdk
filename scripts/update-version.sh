#!/bin/bash

# Script that updates the Clix Flutter SDK version in pubspec.yaml and README.md.
#
# This script updates:
# 1. pubspec.yaml - The Flutter package specification file
# 2. README.md - The installation instructions
#
# Usage: ./scripts/update-version.sh "1.0.0"

set -e

NEW_VERSION="$1"

if [ -z "$NEW_VERSION" ]; then
    echo "Error: Version number is required"
    echo "Usage: ./scripts/update-version.sh \"1.0.0\""
    exit 1
fi

RELATIVE_PATH_TO_SCRIPTS_DIR=$(dirname "$0")
ABSOLUTE_PATH_TO_ROOT_DIR=$(realpath "$RELATIVE_PATH_TO_SCRIPTS_DIR/..")

# File paths
PUBSPEC_FILE="$ABSOLUTE_PATH_TO_ROOT_DIR/pubspec.yaml"
README_FILE="$ABSOLUTE_PATH_TO_ROOT_DIR/README.md"

echo "🔄 Updating Clix Flutter SDK to version: $NEW_VERSION"
echo ""

# 1. Update pubspec.yaml
echo "📝 Updating pubspec.yaml: $PUBSPEC_FILE"
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "Error: pubspec.yaml not found at $PUBSPEC_FILE"
    exit 1
fi

# Use sed to replace the version string in pubspec.yaml
# Pattern matches: `version: 0.0.3`
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version of sed
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
else
    # Linux version of sed
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
fi

echo "✅ Updated pubspec.yaml"
echo ""

# 2. Update README.md
echo "📝 Updating README.md: $README_FILE"
if [ ! -f "$README_FILE" ]; then
    echo "Error: README file not found at $README_FILE"
    exit 1
fi

# Use sed to replace the version string in README.md
# Pattern matches: `clix_flutter: ^0.0.3`
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS version of sed
    sed -i '' "s/clix_flutter: \^[0-9]*\.[0-9]*\.[0-9]*/clix_flutter: ^$NEW_VERSION/" "$README_FILE"
else
    # Linux version of sed
    sed -i "s/clix_flutter: \^[0-9]*\.[0-9]*\.[0-9]*/clix_flutter: ^$NEW_VERSION/" "$README_FILE"
fi

echo "✅ Updated README.md"
echo ""

# Show changes
echo "🔍 Showing changes to confirm they worked:"
echo ""

echo "--- Changes to pubspec.yaml ---"
git --no-pager diff "$PUBSPEC_FILE" || echo "No git repository or no changes detected"
echo ""

echo "--- Changes to README.md ---"
git --no-pager diff "$README_FILE" || echo "No git repository or no changes detected"
echo ""

echo "🎉 Version update completed successfully!"
echo "📦 New version: $NEW_VERSION"
echo ""
echo "Next steps:"
echo "1. Review the changes above"
echo "2. Update CHANGELOG.md with release notes"
echo "3. Run tests: make test"
echo "4. Commit changes: git add . && git commit -m \"chore: bump version to $NEW_VERSION\""
echo "5. Create tag: git tag $NEW_VERSION"
echo "6. Push: git push origin main --tags"
