#!/bin/bash

# Script to run the Android emulator with the -read-only flag
# This addresses the issue with running multiple emulators with the same AVD

# Get the path to the Android SDK
ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-$ANDROID_HOME}
if [ -z "$ANDROID_SDK_ROOT" ]; then
  # Try to find the SDK path from local.properties
  if [ -f "android/local.properties" ]; then
    SDK_DIR=$(grep "sdk.dir" android/local.properties | cut -d'=' -f2)
    ANDROID_SDK_ROOT=$SDK_DIR
  else
    echo "Error: ANDROID_SDK_ROOT or ANDROID_HOME environment variable not set"
    echo "Please set one of these variables to point to your Android SDK location"
    exit 1
  fi
fi

# Default AVD name
AVD_NAME=${1:-"Pixel_3a_API_33_arm64-v8a"}

# Path to emulator binary
EMULATOR="$ANDROID_SDK_ROOT/emulator/emulator"

if [ ! -f "$EMULATOR" ]; then
  echo "Error: Emulator not found at $EMULATOR"
  echo "Please make sure the Android SDK is properly installed"
  exit 1
fi

echo "Starting emulator with AVD: $AVD_NAME"
echo "Using read-only flag to allow multiple instances"

# Run the emulator with the read-only flag
"$EMULATOR" -avd "$AVD_NAME" -read-only &

# Wait for emulator to start
echo "Waiting for emulator to start..."
"$ANDROID_SDK_ROOT/platform-tools/adb" wait-for-device

echo "Emulator started successfully"
echo "You can now run your Flutter app with: flutter run"