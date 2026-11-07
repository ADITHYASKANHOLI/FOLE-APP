# ENGIVAULT Mobile — Native Flutter Client

Official native mobile application for **ENGIVAULT: KTU Learning. Simplified.** Developed by FOLE (Future of Learning & Engineering).

---

## 1. Overview & Architecture

ENGIVAULT Mobile delivers native, high-performance academic learning for KTU engineering undergraduates across iOS and Android, paired with physical co-learning features for FOLE SPACE and community initiatives under FOLE WORKS.

### Architecture Highlights
- **Framework:** Flutter (Material 3) with Riverpod 2.6 state management.
- **Navigation:** `go_router` 14.8 with a 5-tab `StatefulShellRoute` (Home, Learn, Lectures, Materials, Account) and deep linking.
- **Networking:** Dio 5.8 with custom interceptors for Bearer token authorization and strict `Failure` domain mapping.
- **Storage:** `flutter_secure_storage` using platform-backed encryption (Android `EncryptedSharedPreferences`, iOS `Keychain`).
- **Media Delivery:** YouTube-first vetted playback enforcing 16:9 responsive aspect ratio via canonical nocookie embeds.
- **Backend Authority:** Root Next.js 16 / Supabase PostgreSQL backend (`app/api/mobile/v1/*`), with zero client secrets.

---

## 2. Platform & SDK Prerequisites

- **Flutter SDK:** `>= 3.22.0` (Dart `>= 3.4.0 < 4.0.0`)
- **Android:**
  - Android Studio with Android SDK Platform 34+
  - Android Build Tools 34.0.0+
  - JDK 17
  - Minimum SDK: 21 (Android 5.0 Lollipop)
  - Target SDK: 34 (Android 14)
- **iOS:**
  - macOS with Xcode 15+
  - CocoaPods 1.14+
  - Minimum Deployment Target: iOS 14.0

---

## 3. Configuration & Environment Variables

All client-configurable values are passed via compile-time `--dart-define` flags. **Zero secrets, API keys, service roles, or admin access codes are bundled in client binaries.**

| Key | Default (Development) | Production Target | Description |
|---|---|---|---|
| `API_BASE_URL` | `http://localhost:3000/api/mobile/v1` | `https://engivault-ktu-simplified.vercel.app/api/mobile/v1` | Root URL for Mobile API v1 |
| `CONNECT_TIMEOUT_MS` | `10000` | `10000` | Network connect timeout |
| `RECEIVE_TIMEOUT_MS` | `15000` | `15000` | Network receive timeout |

### Example Run Commands

#### Local Development against Local Next.js Backend
```bash
# Android Emulator (using 10.0.2.2 alias for host localhost)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/mobile/v1

# iOS Simulator / macOS desktop
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/mobile/v1
```

#### Production Build against Live Cloud Vercel Backend
```bash
flutter run --release --dart-define=API_BASE_URL=https://engivault-ktu-simplified.vercel.app/api/mobile/v1
```

---

## 4. Testing & Verification

### Running Automated Test Suites

```bash
# Static formatting check
dart format --output=none --set-exit-if-changed .

# Static analyzer (strict linting via analysis_options.yaml)
flutter analyze

# Unit and widget test suite
flutter test

# Backend API and Security test suite (from repo root)
npm test
```

---

## 5. Build Commands

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK (universal)
flutter build apk --release --dart-define=API_BASE_URL=https://engivault-ktu-simplified.vercel.app/api/mobile/v1

# Release App Bundle (for Google Play Store upload)
flutter build appbundle --release --dart-define=API_BASE_URL=https://engivault-ktu-simplified.vercel.app/api/mobile/v1
```

### iOS
```bash
# Release IPA (archive without code signing for CI/CD)
flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://engivault-ktu-simplified.vercel.app/api/mobile/v1

# Full IPA packaging (requires configured Apple Developer certificate & provisioning profile)
flutter build ipa --release --dart-define=API_BASE_URL=https://engivault-ktu-simplified.vercel.app/api/mobile/v1
```

---

## 6. Application Identifiers & Manifest Permissions

### Identifiers (Owner Confirmation Required)
- **Android Application ID:** `app.engivault.mobile` *(Placeholder: confirm before Play Console submission)*
- **iOS Bundle Identifier:** `com.fole.engivault` *(Placeholder: confirm before App Store Connect submission)*

### Android Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Core network connectivity -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Camera for Organizer QR Desk scanner (requested only on scanner screen) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

### iOS Info.plist Declarations (`ios/Runner/Info.plist`)
```xml
<!-- Camera usage description for Organizer Desk -->
<key>NSCameraUsageDescription</key>
<string>ENGIVAULT requires camera access to scan attendee QR passes at the FOLE SPACE check-in desk.</string>

<!-- External file downloads (Materials PDF viewing) -->
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 7. Release Signing & Production Key Management

### Android Release Keystore (Placeholder)
1. Generate release keystore:
   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Reference credentials in `android/key.properties` (strictly **gitignored**):
   ```properties
   storePassword=<KEYSTORE_SECRET>
   keyPassword=<KEY_SECRET>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Never commit `key.properties` or `.jks` files to version control.

### iOS Code Signing (Placeholder)
1. Configure Signing & Capabilities in Xcode (`Runner.xcworkspace`).
2. Select your Apple Developer Team.
3. Automatically or manually provision certificates for Bundle ID `com.fole.engivault`.

---

## 8. Screen Directory & Route Map

| Screen | Route | Role / Auth | Description |
|---|---|---|---|
| **Splash** | `/splash` | Public | Brand initialization, session restoration, network verification |
| **Home** | `/home` | Public | Hero search, KTU department shortcuts, featured subjects, FOLE highlights |
| **Learn / Subjects** | `/subjects` | Public | Filterable catalog by department and semester (S1–S8) |
| **Subject Detail** | `/subjects/:slug` | Public | Complete syllabus, nested module accordion, lecture counts |
| **Lecture Player** | `/lessons/:idOrSlug` | Public | 16:9 YouTube video player, instructor context, linked class notes |
| **Lectures Browser** | `/lectures` | Public | Cascading Dept → Sem → Subject filters with instant query search |
| **Materials Catalog** | `/materials` | Public | Filterable notes, question papers, syllabus, signed download delivery |
| **Global Search** | `/search` | Public | Unified 350ms debounced search across subjects, lessons, and notes |
| **FOLE WORKS** | `/works` | Public | Industrial workshops, hackathons, activity detail with flyer ratio preservation |
| **FOLE SPACE** | `/space` | Public / Student | Real-time seat occupancy gauge, walk-in 45m study pass, countdown timer |
| **Events Catalog** | `/space/events` | Public / Student | Upcoming co-learning sessions, RSVP registration, hybrid virtual check-in |
| **My Space Passes** | `/space/my` | Student | Active study pass, upcoming registrations, digital QR entry passes |
| **Organizer Hub** | `/organizer` | Organizer | Assigned events list, live desk launcher |
| **Live Desk** | `/organizer/events/:id/desk` | Organizer | Real-time checkin metrics, roster search, manual checkin, revocation |
| **QR Scanner** | `/organizer/events/:id/scan` | Organizer | Camera target viewfinder with manual code entry fallback |
| **Admin Login** | `/admin/login` | Administrator | Privileged access code challenge, server-verified HMAC session |
| **Admin Dashboard** | `/admin/dashboard` | Administrator | Academic metrics overview, quick lecture creation, Web Console bridge |
| **Add Lecture** | `/admin/lectures/create` | Administrator | Lecture form with live YouTube URL parser & 16:9 thumbnail preview |
| **Student Login** | `/auth/login` | Public | Username/Password login (never asks for internal email) |
| **Student Register** | `/auth/register` | Public | Alphanumeric username validation, password safety guidance |
| **Student Profile** | `/account` | Public / Student | Account overview, change password trigger, external links, sign out |

---

## 9. Known Limitations & Deferred Features

1. **Large Video File Uploads:** As specified by `AGENTS.md`, raw MP4 uploads are strictly prohibited. All lectures are YouTube-first.
2. **Bulk CSV Academic Import:** Complex bulk curriculum imports remain on the full Web Admin Console (`/admin`) and are linked directly from the mobile Admin Dashboard.
3. **Offline Caching:** Public academic metadata and recent subjects are cached in memory; offline playback of YouTube streams is subject to YouTube terms of service.

