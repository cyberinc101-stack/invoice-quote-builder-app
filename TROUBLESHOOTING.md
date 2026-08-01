# Troubleshooting Guide

## Common Issues and Solutions

### 1. "Unsupported Gradle Project" Error

If you see this error when running the app, follow these steps:

#### Solution 1: Let Flutter Auto-Configure
```bash
# Navigate to your project directory
cd cv_builder_app

# Clean the project
flutter clean

# Run pub get
flutter pub get

# Try running again
flutter run
```

Flutter should automatically create the `android/local.properties` file with the correct paths.

#### Solution 2: Manual Configuration
If the auto-configuration doesn't work:

1. Open `android/local.properties` (create it if it doesn't exist)
2. Add these lines:
```properties
sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\src\\flutter
```

**Note:** Replace the paths with your actual Android SDK and Flutter SDK paths.

To find your paths:
- Android SDK: Usually in `C:\Users\YourUsername\AppData\Local\Android\sdk` on Windows
- Flutter SDK: Where you installed Flutter (check with `flutter doctor -v`)

### 2. Gradle Build Fails

If gradle build fails:

```bash
# Clean the project
flutter clean

# Delete gradle cache
cd android
./gradlew clean

# Go back and try again
cd ..
flutter pub get
flutter run
```

### 3. Kotlin Version Mismatch

If you see Kotlin version errors:

The project uses Kotlin 1.7.10. Make sure your Android Studio/Gradle supports this version.

### 4. "SDK location not found"

This means `local.properties` is missing or incorrect:

```bash
# Let Flutter create it automatically
flutter pub get

# Or manually create android/local.properties with:
sdk.dir=/path/to/your/android/sdk
flutter.sdk=/path/to/your/flutter
```

### 5. Dependencies Download Issues

If dependencies fail to download:

```bash
# Clear pub cache
flutter pub cache clean

# Clear gradle cache
cd android
./gradlew clean

# Try again
cd ..
flutter pub get
flutter run
```

### 6. Build Takes Too Long

If the first build is very slow (normal):

- First build can take 5-15 minutes
- Subsequent builds are much faster
- Be patient on first run

### 7. "Unable to locate Android SDK"

Set the ANDROID_HOME environment variable:

**Windows:**
```
setx ANDROID_HOME "C:\Users\YourUsername\AppData\Local\Android\sdk"
```

**Mac/Linux:**
```bash
export ANDROID_HOME=/path/to/android/sdk
```

### 8. Device Not Detected

```bash
# Check connected devices
flutter devices

# Make sure USB debugging is enabled on your phone
# Enable Developer Options on phone
# Enable USB Debugging in Developer Options
```

### 9. Package Name Conflicts

If you get package name conflicts:

The app uses package name `com.cvbuilder.app`. If you need to change it:

1. Update `android/app/build.gradle` - change `applicationId`
2. Update `android/app/src/main/AndroidManifest.xml` - change package name
3. Rename folder structure in `android/app/src/main/kotlin/`
4. Update `MainActivity.kt` package declaration

### 10. Gradle Wrapper Issues

If gradle wrapper is missing or corrupt:

```bash
cd android
# Download gradle wrapper manually
gradle wrapper --gradle-version 7.5
```

## Quick Fix Checklist

Before asking for help, try these in order:

1. ✅ Run `flutter doctor` - fix any issues shown
2. ✅ Run `flutter clean`
3. ✅ Delete `android/local.properties` and let Flutter recreate it
4. ✅ Run `flutter pub get`
5. ✅ Try `flutter run` again
6. ✅ Make sure USB debugging is enabled (for real device)
7. ✅ Try running on an emulator if real device fails
8. ✅ Check Android Studio has latest updates

## Still Having Issues?

### Check Flutter Setup
```bash
flutter doctor -v
```

Fix any issues shown in the output.

### Check Project Structure

Make sure you have these key files:
```
android/
├── build.gradle
├── settings.gradle
├── gradle.properties
├── gradlew
├── gradlew.bat
├── gradle/wrapper/gradle-wrapper.properties
└── app/
    ├── build.gradle
    └── src/main/
        ├── AndroidManifest.xml
        └── kotlin/com/cvbuilder/app/
            └── MainActivity.kt
```

### Verify Permissions

Check that `AndroidManifest.xml` has required permissions:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

## Platform-Specific Issues

### Windows
- Use `gradlew.bat` instead of `./gradlew`
- Check that paths use backslashes: `C:\Users\...`
- Run Command Prompt as Administrator if permission issues

### Mac/Linux
- Make sure `gradlew` has execute permissions: `chmod +x android/gradlew`
- Check that paths use forward slashes: `/Users/...`

## Getting More Help

If you're still stuck:

1. Run `flutter doctor -v` and check output
2. Check Flutter version with `flutter --version`
3. Make sure you have Flutter 3.0.0 or higher
4. Try creating a new test Flutter project to verify your setup:
   ```bash
   flutter create test_app
   cd test_app
   flutter run
   ```
5. If test app works but CV Builder doesn't, compare the `android` folder structures

## Success Indicators

You'll know it's working when you see:
```
Launching lib\main.dart on SM A165F in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app.apk...
```

The first build may take several minutes - this is normal!
