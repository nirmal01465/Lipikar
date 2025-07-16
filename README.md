# Lipikar

**Lipikar** is a Flutter-based mobile application designed for advanced document scanning and text detection, capable of extracting and translating handwritten or printed text. This repository contains the full source code, release configurations, and setup instructions to help developers get started quickly.

---

## 📖 Table of Contents

* [Features](#features)
* [Demo](#demo)
* [Prerequisites](#prerequisites)
* [Setup and Installation](#setup-and-installation)
* [Project Structure](#project-structure)
* [Pubspec Configuration](#pubspec-configuration)
* [Running the App](#running-the-app)
* [Building a Release APK](#building-a-release-apk)
* [Resources & Downloads](#resources--downloads)
* [Contributing](#contributing)
* [License](#license)

---

## ✨ Features

* 📄 Document scanning and cropping
* 🔍 OCR-based handwritten and printed text extraction
* 🌐 In-app translation powered by Google Translate
* 📊 Animated UI with charts and shimmer effects
* 🔒 Secure storage for sensitive data
* 🎨 Customizable themes and fonts

---

## 🎬 Demo

Watch the working demo video here: [Lipikar App Demo](https://drive.google.com/file/d/1qVpQSUaQIELDtwrUw38abBdnpklXCr9l/view?usp=drive_link)

---

## 🛠 Prerequisites

Make sure you have the following installed:

* [Flutter SDK (>=3.4.4 <4.0.0)](https://flutter.dev/docs/get-started/install)
* Android SDK + platform tools
* Xcode (for iOS builds, macOS only)
* Java JDK (for signing keystore)

---

## 🚀 Setup and Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/nirmal01465/Lipikar.git
   cd Lipikar
   ```

2. **Download and place configuration files** under `android/app/`:

   * `key.properties`: [https://drive.google.com/file/d/19JJV2zoMbcSYaT-UOUNiewJXre5mNv89/view?usp=drive\_link](https://drive.google.com/file/d/19JJV2zoMbcSYaT-UOUNiewJXre5mNv89/view?usp=drive_link)
   * `my_release_key.jks`: [https://drive.google.com/file/d/1rcZ3mFVWWJLCvgZUo1KSYSqtbjwaIQfd/view?usp=drive\_link](https://drive.google.com/file/d/1rcZ3mFVWWJLCvgZUo1KSYSqtbjwaIQfd/view?usp=drive_link)

3. **Configure `android/key.properties`:**

   ```properties
   storePassword=<YOUR_STORE_PASSWORD>
   keyPassword=<YOUR_KEY_PASSWORD>
   keyAlias=<YOUR_KEY_ALIAS>
   storeFile=app/my_release_key.jks
   ```

4. **Install dependencies:**

   ```bash
   flutter pub get
   ```

5. **Set up Android SDK path:**

   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

---

## 📂 Project Structure

```
Lipikar/
├── android/            # Android project files
├── ios/                # iOS project files
├── lib/                # Dart source code
│   ├── main.dart       # App entry point
│   ├── models/         # Data models
│   ├── providers/      # State management
│   ├── screens/        # UI screens
│   ├── widgets/        # Reusable widgets
│   └── utils/          # Utility functions
├── test/               # Unit & widget tests
├── pubspec.yaml        # Dependencies & project metadata
└── android/app/
    ├── key.properties  # Keystore config (ignored in VCS)
    └── my_release_key.jks
```

---

## 📝 Pubspec Configuration (`pubspec.yaml`)

```yaml
name: lipikar
description: "A new Flutter project."
publish_to: 'none'
version: 1.0.2

environment:
  sdk: '>=3.4.4 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_staggered_animations: ^1.1.1
  dropdown_button2: ^2.3.9
  image_picker: ^1.1.2
  hyper_effects: ^0.3.0
  fl_chart: ^0.70.2
  flutter_doc_scanner: ^0.0.16
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  photo_view: ^0.15.0
  translator: ^1.0.3+1
  path_provider: ^2.0.13
  provider: ^6.1.4
  share_plus: ^10.1.4
  pdf: ^3.9.0
  saver_gallery: ^4.0.1
  flutter_secure_storage: ^9.2.4
  flutter_document_scanner: ^1.1.2
  url_launcher: ^6.3.1
  shared_preferences: ^2.2.1
  flutter_animate: ^4.5.0
  blobs: ^2.0.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

---

## ▶️ Running the App

To launch in debug mode on your connected device or emulator:

```bash
flutter run
```

---

## 📦 Building a Release APK

Generate a signed APK for Play Store distribution:

```bash
flutter build apk --release
```

The signed APK will be located at:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔗 Resources & Downloads

* **GitHub Repository:** [https://github.com/nirmal01465/Lipikar](https://github.com/nirmal01465/Lipikar)
* **Google Drive – All Flutter files (lib.zip):** [https://drive.google.com/file/d/1uQDaT-ptbvp-xG9QoZydjEN\_\_HR4tEOi/view?usp=drive\_link](https://drive.google.com/file/d/1uQDaT-ptbvp-xG9QoZydjEN__HR4tEOi/view?usp=drive_link)
* **key.properties:** [https://drive.google.com/file/d/19JJV2zoMbcSYaT-UOUNiewJXre5mNv89/view?usp=drive\_link](https://drive.google.com/file/d/19JJV2zoMbcSYaT-UOUNiewJXre5mNv89/view?usp=drive_link)
* **my\_release\_key.jks:** [https://drive.google.com/file/d/1rcZ3mFVWWJLCvgZUo1KSYSqtbjwaIQfd/view?usp=drive\_link](https://drive.google.com/file/d/1rcZ3mFVWWJLCvgZUo1KSYSqtbjwaIQfd/view?usp=drive_link)
* **pubspec.yaml:** [https://drive.google.com/file/d/1xfCIrdPlzzdZfw70ePBpLf04mxXo-G3h/view?usp=drive\_link](https://drive.google.com/file/d/1xfCIrdPlzzdZfw70ePBpLf04mxXo-G3h/view?usp=drive_link)
* **Demo Video:** [https://drive.google.com/file/d/1qVpQSUaQIELDtwrUw38abBdnpklXCr9l/view?usp=drive\_link](https://drive.google.com/file/d/1qVpQSUaQIELDtwrUw38abBdnpklXCr9l/view?usp=drive_link)

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and open a pull request with your improvements.

---

## 📜 License

This project is released under the MIT License. See the [LICENSE](LICENSE) file for details.
