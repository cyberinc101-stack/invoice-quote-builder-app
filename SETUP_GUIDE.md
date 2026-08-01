# CV Builder App - Complete Setup Guide

## 🚀 Quick Start Guide

### Step 1: Prerequisites

Before you begin, ensure you have the following installed:

1. **Flutter SDK** (3.0.0 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK
   - Install Android Emulator

3. **Xcode** (for iOS development - macOS only)
   - Download from Mac App Store
   - Install Command Line Tools

4. **VS Code** or **Android Studio** with Flutter extensions

### Step 2: Verify Installation

Open a terminal and run:

```bash
flutter doctor
```

This will check your Flutter installation and show any missing dependencies.

### Step 3: Extract and Setup Project

1. Extract the ZIP file:
```bash
unzip cv_builder_app.zip
cd cv_builder_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Verify project setup:
```bash
flutter analyze
```

### Step 4: Run the App

#### On an Emulator/Simulator

1. **Start Android Emulator:**
   - Open Android Studio > AVD Manager > Start Emulator
   
2. **Or Start iOS Simulator (macOS only):**
   ```bash
   open -a Simulator
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

#### On a Physical Device

**Android:**
1. Enable Developer Options on your device
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter devices` to verify
5. Run: `flutter run`

**iOS:**
1. Connect iPhone/iPad via USB
2. Trust the computer on your device
3. In Xcode, add your Apple ID in Preferences > Accounts
4. Run: `flutter run`

## 📱 Building for Release

### Android APK

Build a release APK:
```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

Build an app bundle:
```bash
flutter build appbundle --release
```

The AAB will be located at:
```
build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS only)

Build for iOS:
```bash
flutter build ios --release
```

Then open the project in Xcode to archive and submit to App Store:
```bash
open ios/Runner.xcworkspace
```

## 🔧 Configuration

### Changing App Name

1. **Android:**
   - Edit `android/app/src/main/AndroidManifest.xml`
   - Change `android:label="CV Builder"` to your app name

2. **iOS:**
   - Edit `ios/Runner/Info.plist`
   - Change `<key>CFBundleDisplayName</key>` value

### Changing Package Name/Bundle ID

**Android:**
1. Rename folder structure in `android/app/src/main/kotlin/`
2. Update `namespace` in `android/app/build.gradle.kts`
3. Update package in `MainActivity.kt`
4. Update `applicationId` in `android/app/build.gradle.kts`

**iOS:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner in Project Navigator
3. Change Bundle Identifier in General tab

### App Icon

1. Generate icons using: https://www.appicon.co/
2. Replace icons in:
   - Android: `android/app/src/main/res/mipmap-*/`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Or use `flutter_launcher_icons` package:

1. Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
```

2. Run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 🎨 Customization Guide

### Adding New Templates

1. Open `lib/models/cv_data.dart`
2. Add new template to `CVTemplate` enum:
```dart
enum CVTemplate {
  modern,
  classic,
  professional,
  creative,
  minimal,
  yourTemplate, // Add here
}
```

3. Open `lib/services/pdf_service.dart`
4. Add template method:
```dart
static void _addYourTemplate(pw.Document pdf, CVData cvData) {
  // Your template design
}
```

5. Add case in `generatePDF` switch statement

### Adding New Color Schemes

1. Open `lib/models/cv_data.dart`
2. Add color to enum:
```dart
enum CVColor {
  blue,
  green,
  purple,
  orange,
  red,
  teal,
  indigo,
  yourColor, // Add here
}
```

3. Open `lib/services/pdf_service.dart`
4. Add color mapping:
```dart
case CVColor.yourColor:
  return PdfColors.yourColorValue;
```

5. Open `lib/widgets/customization_panel.dart`
6. Add color to UI in `_getColor` method

### Modifying Fonts

Available fonts are in `lib/widgets/customization_panel.dart`.

To add more:
1. Add font name to the `fonts` list
2. Font will automatically be available via Google Fonts

To use custom fonts:
1. Add font files to `fonts/` folder
2. Update `pubspec.yaml`:
```yaml
flutter:
  fonts:
    - family: YourFont
      fonts:
        - asset: fonts/YourFont-Regular.ttf
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### 2. "No valid Android SDK found"
- Open Android Studio
- Go to SDK Manager
- Ensure Android SDK is installed
- Set ANDROID_HOME environment variable

#### 3. "CocoaPods not installed" (iOS)
```bash
sudo gem install cocoapods
cd ios
pod install
cd ..
```

#### 4. "Building for iOS Simulator, but linking in dylib built for iOS"
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install --repo-update
cd ..
```

#### 5. PDF generation shows blank page
- Ensure all required fields (especially name) are filled
- Check console for errors
- Verify PDF package version

#### 6. Image picker not working
- Check permissions in AndroidManifest.xml and Info.plist
- Ensure image_picker package is properly installed
- Run `flutter pub get` again

## 📦 Dependencies Explained

### Production Dependencies

- **provider**: State management solution
- **pdf**: Creates PDF documents programmatically
- **printing**: Handles PDF preview, printing, and sharing
- **path_provider**: Access device file system
- **share_plus**: Share files with other apps
- **image_picker**: Select images from gallery/camera
- **google_fonts**: Beautiful typography
- **flutter_colorpicker**: Color selection UI
- **intl**: Internationalization and date formatting

### Development Dependencies

- **flutter_test**: Testing framework
- **flutter_lints**: Code quality rules

## 🔐 Code Signing (for Publishing)

### Android

1. Create keystore:
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=key
storeFile=<path-to-key>/key.jks
```

3. Update `android/app/build.gradle.kts` (already configured for signing)

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner > Signing & Capabilities
3. Select your Team
4. Ensure "Automatically manage signing" is checked

## 📱 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Code Coverage
```bash
flutter test --coverage
```

## 🚀 Deployment

### Google Play Store

1. Build app bundle:
```bash
flutter build appbundle --release
```

2. Create Google Play Developer account
3. Upload AAB file
4. Fill in store listing details
5. Submit for review

### Apple App Store

1. Build for release:
```bash
flutter build ios --release
```

2. Open in Xcode:
```bash
open ios/Runner.xcworkspace
```

3. Archive the app (Product > Archive)
4. Upload to App Store Connect
5. Submit for review

## 🎯 Performance Optimization

### Reduce APK Size

1. Enable Proguard (already configured)
2. Split APKs by ABI:
```bash
flutter build apk --split-per-abi
```

### Improve Build Times

1. Enable Gradle daemon (already enabled)
2. Increase Gradle memory in `gradle.properties`
3. Use release build only when necessary

## 📚 Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Language**: https://dart.dev/guides
- **Provider Package**: https://pub.dev/packages/provider
- **PDF Package**: https://pub.dev/packages/pdf
- **Material Design**: https://material.io/design

## 💡 Tips for Success

1. **Test on Real Devices**: Always test on physical devices before release
2. **Handle Edge Cases**: Test with empty data, special characters, etc.
3. **Performance**: Monitor app performance with Flutter DevTools
4. **User Feedback**: Implement analytics and crash reporting
5. **Regular Updates**: Keep dependencies up to date

## 🆘 Getting Help

If you encounter issues:

1. Check Flutter documentation
2. Search on StackOverflow
3. Check GitHub issues for package problems
4. Run `flutter doctor` for system issues
5. Use `flutter clean` for build cache issues

## 📝 Next Steps

1. Customize the app to your needs
2. Add your branding (icons, colors, name)
3. Test thoroughly on multiple devices
4. Implement monetization features
5. Submit to app stores
6. Market your app

---

Good luck with your CV Builder app! 🎉
