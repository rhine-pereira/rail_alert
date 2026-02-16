# 🚉 Rail Alert

**Never miss your railway station stop again!**

Rail Alert is a Flutter-based mobile application that monitors your real-time GPS location and triggers an audio-visual alarm when you enter a predefined radius around your destination railway station. Perfect for commuters who want to rest or work during their journey without worrying about missing their stop.

![Flutter](https://img.shields.io/badge/Flutter-3.4.3-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4.3-0175C2?logo=dart)
![Android](https://img.shields.io/badge/Android-23%2B-3DDC84?logo=android)
![iOS](https://img.shields.io/badge/iOS-13.0%2B-000000?logo=apple)

---

## 📱 Features

### Core Functionality
- **🗺️ Station Selection**: Search and select from a comprehensive list of railway stations
- **📍 Geofence Monitoring**: Continuous background GPS tracking with configurable alert radius (0.5-10 km)
- **🔔 Smart Alerts**: High-priority notifications and loud alarm sound when approaching your station
- **📊 Live Distance Tracking**: Real-time distance display to your destination
- **⚙️ Customizable Settings**: Adjust default radius, alarm volume, and vibration preferences
- **💾 State Persistence**: Remembers your last selected station and settings

### User Experience
- **Material 3 Design**: Modern, clean UI with light/dark theme support
- **Permission Wizard**: Step-by-step onboarding for required permissions
- **Battery Optimization**: Requests exemption from Android Doze mode for reliable background tracking
- **Test Alarm**: Preview your alarm sound before starting a journey

---

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.4.3 / Dart 3.4.3
- **State Management**: Provider (ChangeNotifier pattern)
- **Location Services**: geolocator (v12.0.0)
- **Permissions**: permission_handler (v11.3.1)
- **Audio Playback**: audioplayers (v6.1.0)
- **Notifications**: flutter_local_notifications (v17.2.4)
- **Persistence**: shared_preferences (v2.3.3)

### Project Structure
```
lib/
├── main.dart                         # App entry point, routing, splash screen
├── models/
│   ├── station.dart                  # Station data model
│   ├── geofence_config.dart          # Geofence tracking state
│   └── app_settings.dart             # User preferences
├── providers/
│   └── app_state.dart                # Central state management
├── services/
│   ├── station_data_service.dart     # Loads stations from JSON
│   ├── location_service.dart         # GPS position stream
│   ├── audio_service.dart            # Alarm playback
│   ├── notification_service.dart     # Local notifications
│   ├── permission_service.dart       # Permission management
│   └── storage_service.dart          # SharedPreferences wrapper
└── screens/
    ├── permissions_screen.dart       # Onboarding flow
    └── home_screen.dart              # Main UI (3 tabs)

assets/
├── stations.json                     # Station coordinates database
└── alarm.mp3                         # Alarm sound file
```

---

## 🚀 Setup Instructions

### Prerequisites
- **Flutter SDK**: 3.4.3 or higher
- **Android Studio** (for Android development) with:
  - Android SDK 34
  - JDK 17 (Amazon Corretto recommended)
- **Xcode** (for iOS development, macOS only)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd rail_alert
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure station data** (if needed):
   - Edit `assets/stations.json` with your railway station coordinates
   - Format:
     ```json
     {
       "stations": [
         {
           "id": "STN001",
           "name": "Station Name",
           "lat": 19.1234,
           "lng": 72.5678,
           "line": "Line Name"
         }
       ]
     }
     ```

4. **Customize alarm sound** (optional):
   - Replace `assets/alarm.mp3` with your preferred alarm sound

### Platform-Specific Setup

#### Android
- Minimum SDK: **23** (Android 6.0)
- Target SDK: **34** (Android 14)
- Compile SDK: **34**

**Gradle Configuration** (already set):
- `android/app/build.gradle`: `compileSdkVersion 34`
- `android/settings.gradle`: Kotlin version `1.9.22`

**Permissions** (auto-configured in AndroidManifest.xml):
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `POST_NOTIFICATIONS`
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `FOREGROUND_SERVICE`

#### iOS
- Minimum Version: **13.0**

**Info.plist Keys** (already configured):
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `UIBackgroundModes`: `location`, `fetch`, `audio`

**First-time iOS setup**:
```bash
cd ios
pod install
cd ..
```

---

## 🎮 Usage Guide

### 1. First Launch - Permissions
On first launch, the app will guide you through granting essential permissions:
- **Location (Always)**: Required for background tracking
- **Notifications**: Required for alarm alerts
- **Battery Optimization**: Prevents Android from killing the app

### 2. Select Your Station
- **Search**: Use the search bar to find your destination
- **Select**: Tap on a station to select it
- **Set Radius**: Adjust the alert radius slider (0.5-10 km)
  - Recommended: 2 km for suburban trains, 5 km for express trains

### 3. Start Tracking
- Navigate to the **Tracking** tab
- Tap **"Start Tracking"**
- The app will show:
  - Current tracking status
  - Live distance to your station
  - Estimated proximity

### 4. When Alarm Triggers
- You'll receive:
  - Full-screen notification
  - Loud looped alarm sound
  - Vibration (if enabled)
- **Dismiss**: Tap the notification or open the app and tap "DISMISS ALARM"

### 5. Adjust Settings
- Navigate to the **Settings** tab
- Configure:
  - Default alert radius
  - Alarm volume
  - Vibration on/off
  - Test your alarm sound

---

## 📋 Permissions Explained

### Why Each Permission is Required

| Permission | Purpose | Critical? |
|------------|---------|-----------|
| **Location (When in Use)** | Get your position while app is open | ✅ Yes |
| **Location (Always)** | Track position when app is minimized | ✅ Yes |
| **Notifications** | Show alarm alerts on your screen | ✅ Yes |
| **Battery Optimization Override** | Prevent Android from stopping geofence monitoring | ⚠️ Recommended |
| **Vibrate** | Vibration feedback for alarm | ❌ Optional |

---

## 🔧 Configuration

### Stations Database
Edit `assets/stations.json` to add/modify stations:

```json
{
  "stations": [
    {
      "id": "UNIQUE_ID",
      "name": "Display Name",
      "lat": 19.123456,
      "lng": 72.123456,
      "line": "Line/Route Name (optional)"
    }
  ]
}
```

**Getting Coordinates**:
- Use Google Maps: Right-click → "What's here?"
- Or use GPS coordinate apps

### Alarm Sound
Replace `assets/alarm.mp3` with any MP3 file:
- Recommended: 3-10 seconds, looped playback
- Format: MP3, AAC, or WAV
- Size: < 1 MB for optimal performance

---

## 🏃 Running the App

### Android Emulator
```bash
# Start emulator from Android Studio, then:
flutter run
```

### Physical Android Device
1. Enable **Developer Options** on your phone
2. Enable **USB Debugging**
3. Connect via USB
4. Run:
   ```bash
   flutter run
   ```

### iOS Simulator (macOS only)
```bash
open -a Simulator
flutter run
```

### Build Release APK (Android)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Troubleshooting

### Alarm Doesn't Trigger in Background
**Cause**: Battery optimization killing the app  
**Solution**:
1. Go to Settings → Battery → Battery Optimization
2. Find "Rail Alert" → Select "Don't optimize"
3. For Xiaomi/Huawei: Also disable "Battery Saver" for the app

### GPS Not Updating
**Cause**: Poor GPS signal inside train  
**Solution**: The app uses cell tower triangulation as fallback. Increase alert radius for safety margin.

### Permission Denied
**Cause**: User denied permissions  
**Solution**: Go to phone Settings → Apps → Rail Alert → Permissions → Enable required permissions

### Gradle Build Error (Android)
**Cause**: SDK version mismatch  
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

### iOS Build Error
**Cause**: Missing CocoaPods dependencies  
**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

---

## 🔐 Privacy & Security

- **No Internet Required**: All data stored locally, zero network calls
- **No Data Collection**: Your location data never leaves your device
- **Open Source**: Full transparency - audit the code yourself
- **Permissions**: Only requests permissions essential for core functionality

---

## 📊 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests (with GPS spoofing)
1. Install fake GPS app (Android only)
2. Enable mock location in Developer Options
3. Set fake location near test station
4. Verify alarm triggers

---

## 🚀 Future Enhancements

Potential features for future versions:
- [ ] Multiple destination support with waypoints
- [ ] Travel history and statistics
- [ ] Offline map visualization
- [ ] Widget for quick station selection
- [ ] Android Auto / CarPlay integration
- [ ] ML-based ETA prediction
- [ ] Cloud sync for station lists
- [ ] Multi-language support (i18n)

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Plugin Developers**:
  - geolocator by Baseflow
  - permission_handler by Baseflow
  - audioplayers by Blue Fire
  - flutter_local_notifications by Michael Bui
- **Mumbai Railway Network** for inspiration (station data)

---

## 📞 Support

If you encounter issues or have questions:
- Open an issue on GitHub
- Check the [Troubleshooting](#-troubleshooting) section
- Review Flutter documentation: [docs.flutter.dev](https://docs.flutter.dev/)

---

**Built with ❤️ using Flutter**
