# ENGIVAULT Mobile (Flutter) — Architecture & Development Rules

This document establishes the binding architectural standards, security rules, and engineering conventions for the ENGIVAULT native mobile application located in `mobile/`.

---

## 1. Core Principles & Boundaries
- **Preserve Next.js Root:** The root Next.js project is the production web application and API provider. Never delete, rename, or destabilize files under `app/`, `components/`, `lib/`, `supabase/`, `public/`, or root configuration files.
- **Root Rules Inviolability:** All rules in root `AGENTS.md`, `GEMINI.md`, and `CLAUDE.md` remain strictly in force.
- **Authoritative Backend:** Supabase PostgreSQL and the versioned Next.js Mobile API (`/api/mobile/v1/*`) are the single source of truth. Never create a secondary client database or treat device caches as authoritative.
- **YouTube-First Delivery:** All video playback must use validated 11-character YouTube video IDs and standard 16:9 responsive aspect ratio players. Arbitrary video URLs, unauthorized domains, and untrusted iframes are strictly prohibited.
- **Zero Secret Exposure:** Never embed `SUPABASE_SECRET_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ADMIN_ACCESS_CODE`, `ADMIN_SESSION_SECRET`, `RESEND_API_KEY`, or any server-only secret into Dart code, assets, configuration, build arguments, or release binaries.

---

## 2. Flutter Architectural Pattern: MVVM Feature-First

Every feature in `lib/features/<feature_name>/` must maintain strict separation of concerns across four layers:

```text
┌─────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER (Widgets & Screens)                      │
│ • UI rendering only, zero direct network or storage calls   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Watches / Dispatches Actions
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ STATE MANAGEMENT (Riverpod Notifiers & ViewModels)          │
│ • Manages UI state (loading, error, data), exposes AsyncValue│
└──────────────────────────────┬──────────────────────────────┘
                               │ Calls domain methods
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ REPOSITORY LAYER (Domain & Data Orchestration)              │
│ • Single source of truth for the feature                    │
│ • Maps API DTOs into immutable domain models                │
│ • Handles offline fallbacks, retries, and caching policies  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Calls raw network / storage
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ SERVICE & PLATFORM LAYER (Data Transfer)                    │
│ • Dio HTTP client, SecureStorageService, Camera/Scanner     │
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure Convention:
```text
mobile/
  lib/
    main.dart
    app/
      app.dart                 # MaterialApp.router initialization
      router/                  # go_router routes and redirect guards
      theme/                   # EngiVault academic color tokens & typography
      config/                  # Non-secret environment configuration (API URL)
    core/
      network/                 # Dio client, auth interceptors, error handling
      errors/                  # Failure types and user-facing messages
      storage/                 # Hardware-backed secure storage service
      widgets/                 # Reusable buttons, badges, glass cards, skeletons
      utils/                   # YouTube parser, date/time helpers (Asia/Kolkata)
    features/
      home/                    # data/ domain/ presentation/
      academics/               # data/ domain/ presentation/
      lectures/                # data/ domain/ presentation/
      materials/               # data/ domain/ presentation/
      search/                  # data/ domain/ presentation/
      auth/                    # data/ domain/ presentation/
      account/                 # data/ domain/ presentation/
      fole_works/              # data/ domain/ presentation/
      fole_space/              # data/ domain/ presentation/
      organizer/               # data/ domain/ presentation/
      admin/                   # data/ domain/ presentation/
```

---

## 3. Authentication & Security Invariants
- **Username-Only Authentication:** Students authenticate with `username` and `password`. The mobile app must never ask for, collect, validate, or display the internal non-routable email (`@students.fole.invalid`).
- **Hardware-Backed Token Storage:** Store Supabase JWT access and refresh tokens exclusively in `flutter_secure_storage` (Android Keystore / iOS Keychain). Never persist auth tokens or passwords in `SharedPreferences`, plain SQLite, logs, or analytics.
- **Admin Isolation:** Administrator credentials (`ADMIN_ACCESS_CODE`) are verified only on the server. If admin features are accessed, the app receives a short-lived HMAC session token stored in isolated secure storage. Never mix student and admin privilege scopes.
- **Ticket Code Integrity:** FOLE SPACE QR tickets use canonical unguessable codes (`FS1.<ticket_code>`). The app displays them at maximum screen brightness without leaking student personal data.
- **Server Authority on Attendance:** The server is the sole authority for seat capacity, active occupancy, ticket validation, and attendance logs. The client must never mark someone checked in locally.

---

## 4. Code Quality & Verification Commands

All mobile contributions must pass these verification checks cleanly with 0 errors and 0 warnings:

```bash
# 1. Format all code according to Dart guidelines
dart format --output=none --set-exit-if-changed .

# 2. Run static analysis (0 warnings, 0 errors allowed)
flutter analyze

# 3. Execute all unit and widget tests
flutter test

# 4. Verify release build compilation
flutter build apk --release
```

