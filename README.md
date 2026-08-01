# Professional CV Builder App 🚀

A highly customizable and professional CV Builder application built with Flutter.

## 🌟 Features

### Core Features
- **5 Professional Templates**: Modern, Classic, Professional, Creative, and Minimal designs
- **Complete Customization**: Change colors, fonts, and font sizes
- **Comprehensive CV Sections**: Personal info, experience, education, skills, languages, certifications, and hobbies
- **PDF Generation**: High-quality PDF export with template-specific styling
- **Print Support**: Direct printing from the app
- **Download & Share**: Save and share your CV easily
- **Skill Proficiency**: Visual skill level indicators
- **Profile Photo**: Add your professional photo to your CV

### Template Showcase

1. **Modern Template**: Clean and contemporary design with color accents
2. **Classic Template**: Traditional centered layout with elegant styling
3. **Professional Template**: Two-column layout with sidebar
4. **Creative Template**: Bold design with gradient headers
5. **Minimal Template**: Simple and refined black & white design

### Customization Options
- **8 Color Schemes**: Blue, Green, Purple, Orange, Red, Teal, Indigo, Black
- **5 Font Families**: Roboto, Open Sans, Lato, Montserrat, Poppins
- **Adjustable Font Sizes**: 10pt to 16pt

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK for Android development

### Installation

1. Extract the project and navigate to directory:
```bash
cd cv_builder_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── cv_data.dart         # CV data models
├── providers/
│   └── cv_provider.dart     # State management
├── screens/
│   ├── home_screen.dart     # Home screen
│   ├── editor_screen.dart   # CV editing interface
│   ├── template_selection_screen.dart  # Template chooser
│   └── preview_screen.dart  # PDF preview & export
└── services/
    └── pdf_generator.dart   # PDF generation logic

android/
├── build.gradle.kts         # Project-level Gradle (Kotlin DSL)
├── settings.gradle.kts      # Settings (Kotlin DSL)
└── app/
    ├── build.gradle.kts     # App-level Gradle (Kotlin DSL)
    └── src/main/kotlin/     # Kotlin MainActivity
```

## 📦 Dependencies

- **pdf**: PDF document generation
- **printing**: PDF preview and printing
- **path_provider**: File system access
- **share_plus**: File sharing functionality
- **provider**: State management
- **image_picker**: Profile photo selection
- **google_fonts**: Custom fonts support

## 🎨 How to Use

### 1. Personal Information
- Navigate to the Personal tab
- Fill in your name, job title, contact details
- Add a profile photo (optional)
- Write a professional summary

### 2. Add Experience
- Go to the Experience tab
- Add your work history with responsibilities

### 3. Add Education
- Navigate to Education tab
- Add your degrees and institutions

### 4. Add Skills
- Go to Skills tab
- Add skills with proficiency levels (0-100%)

### 5. Additional Information
- Add languages, certifications, and hobbies

### 6. Customize Design
- Choose from 8 color schemes
- Select font family
- Adjust font size

### 7. Select Template
- Browse 5 professional templates
- Select your favorite

### 8. Export Your CV
- Preview your CV in PDF format
- Print directly or Download and share

## 🛠️ Technical Details

### State Management
- Uses Provider pattern for state management
- CVProvider manages all CV data
- Reactive UI updates

### Android Configuration
- **Kotlin gradle files** (build.gradle.kts)
- Configured for Android SDK 21-34
- Kotlin-based MainActivity

## 📝 Notes

- **Free version** with no paid features
- All features available without restrictions
- No user accounts required
- All data stored locally
- Export and share functionality included

---

**Built with ❤️ using Flutter**
