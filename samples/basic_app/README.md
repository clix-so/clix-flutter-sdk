# Clix Flutter SDK Basic App

This is a basic sample app demonstrating the Clix Flutter SDK integration.

## Running the Android App

### Issue with Multiple Emulators

If you encounter the following error when trying to run the Android emulator:

```
ERROR | Running multiple emulators with the same AVD
ERROR | is an experimental feature.
ERROR | Please use -read-only flag to enable this feature.
```

This happens when you try to run multiple instances of the same Android Virtual Device (AVD). To resolve this issue, we've provided a script that runs the emulator with the `-read-only` flag.

### Using the Emulator Script

1. Make sure the script is executable:
   ```bash
   chmod +x run_android_emulator.sh
   ```

2. Run the script:
   ```bash
   ./run_android_emulator.sh
   ```

   By default, the script uses the "Pixel_3a_API_33_arm64-v8a" AVD. If you want to use a different AVD, specify it as an argument:
   ```bash
   ./run_android_emulator.sh "Your_AVD_Name"
   ```

3. Once the emulator is running, you can run the Flutter app:
   ```bash
   flutter run
   ```

### Manual Emulator Launch

If you prefer to launch the emulator manually, you can use the following command:

```bash
$ANDROID_SDK_ROOT/emulator/emulator -avd Pixel_3a_API_33_arm64-v8a -read-only
```

Replace `Pixel_3a_API_33_arm64-v8a` with your AVD name if different.

## Project Structure

- `android/`: Android-specific configuration files
- `ios/`: iOS-specific configuration files
- `main.dart`: Main entry point for the Flutter application

## Troubleshooting

If you encounter any issues:

1. Make sure your Android SDK path is correctly set in `android/local.properties` or in your environment variables (`ANDROID_SDK_ROOT` or `ANDROID_HOME`).
2. Ensure you have created the AVD mentioned in the script or provide your own AVD name as an argument.
3. Check that Flutter is properly installed and configured.