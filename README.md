# ClinixAI — Flutter App Build Guide for GitHub Copilot

> **Purpose:** Step-by-step instructions for GitHub Copilot (or any AI coding assistant) to scaffold, implement, and deliver the ClinixAI Flutter app (multilingual symptom-based diagnosis chatbot) ready to connect to Firebase and a diagnosis backend. Follow the tasks in order — each step builds on the previous. Use the provided file skeletons, mock endpoints, and acceptance criteria to verify correctness.

---

## Table of contents

1. Project overview
2. Prerequisites
3. Project scaffold & folder structure
4. `pubspec.yaml` — dependencies
5. Firebase setup (developer actions)
6. Step-by-step implementation plan (priority order)
7. Screen-by-screen feature checklist
8. APIs & mock backend
9. 3D hologram implementation + fallback
10. Voice (STT) integration
11. Localization & translations
12. Offline / guest mode
13. Security, privacy & consent
14. Testing & acceptance criteria
15. Build & release (Android / iOS)
16. README / docs / deliverables
17. Helpful commands & tips

---

## 1. Project overview

ClinixAI is a Flutter mobile app (Android + iOS) created with the following goals:

* Multilingual (12 Indian languages: English, Hindi, Marathi, Gujarati, Bengali, Tamil, Telugu, Kannada, Malayalam, Punjabi, Assamese, Odia)
* Target: rural-first UX — simple, large tappable targets, minimal jargon, voice-first flow
* Auth: Firebase Phone OTP + Guest (offline)
* Profiles: multiple profiles per account (Myself / Someone else)
* 3D interactive human body (gender-specific) for symptom selection + chat-based input (text & voice)
* Backend: submits symptom reports to `POST /reports` and receives triage result

This guide instructs Copilot how to implement the frontend features, connect to Firebase, create mocks, and produce a working build.

---

## 2. Prerequisites

* Flutter >= 3.0 (stable channel) installed and working
* Android SDK + Xcode (for iOS builds) configured (if building for iOS)
* Firebase project created with Android and iOS apps added
* Node.js installed (optional; used for mock server)
* Basic familiarity with Firestore and Firebase Auth

---

## 3. Project scaffold & folder structure

Create the following folder layout inside a new Flutter project:

```
/lib
  main.dart
  app.dart
  routes.dart
  /screens
    splash_screen.dart
    language_selection.dart
    auth_phone.dart
    guest_mode.dart
    checkup_for.dart
    profile_create_edit.dart
    personal_info.dart
    main_chat_hologram.dart
    symptom_details.dart
    result_screen.dart
    profile_list.dart
    settings.dart
  /widgets
    chat_bubble.dart
    quick_chips.dart
    body_hologram.dart
    unit_input.dart
  /services
    firebase_service.dart
    auth_service.dart
    profile_service.dart
    report_service.dart
    stt_service.dart
    localization_service.dart
  /models
    user_model.dart
    profile_model.dart
    report_model.dart
    symptom_model.dart
  /utils
    unit_conversion.dart
    bmi.dart
    offline_queue.dart
  /i18n
    en.json
    hi.json
    mr.json
    gu.json
    bn.json
    ta.json
    te.json
    kn.json
    ml.json
    pa.json
    as.json
    or.json
/assets
  /models (3D glb/gltf files)
  /images
  /icons
/test
  unit tests for utils

README.md
LICENSE
```

**Note:** Keep code modular and small components. Files above are starting points — Copilot should create implementations incrementally.

---

## 4. `pubspec.yaml` — recommended dependencies

Add the following dependencies (versions flexible):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  firebase_core: ^2.0.0
  firebase_auth: ^4.0.0
  cloud_firestore: ^4.0.0
  shared_preferences: ^2.0.15
  flutter_localizations:
    sdk: flutter
  easy_localization: ^3.0.0
  speech_to_text: ^5.6.0
  flutter_tts: ^3.5.0
  dio: ^5.0.0
  riverpod: ^2.0.0
  flutter_cube: ^0.0.7
  model_viewer_plus: ^2.0.0
  hive: ^2.0.5
  hive_flutter: ^1.1.0
dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^1.1.0
  build_runner: ^2.2.0
```

**Instruction to Copilot:** generate `pubspec.yaml` with these packages and run `flutter pub get` as part of the setup notes.

---

## 5. Firebase setup (developer actions)

> Copilot assumes the developer will provide actual Firebase credentials. Provide instructions to the developer and implement code that reads local config files.

1. Create a Firebase project in the Firebase console.
2. Add an Android app and an iOS app in Firebase. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
3. Enable **Phone Authentication** in Firebase Auth (for OTP). Configure SMS templates if desired.
4. Create Firestore database in **production** or **test** mode. Implement rules stub (see Security section later).
5. (Optional) Enable Firebase Storage if you plan to store images/models.

**Code tasks for Copilot:**

* Add Firebase initialization in `main.dart` using `Firebase.initializeApp()`.
* Implement helper in `firebase_service.dart` to get Firestore and Auth references.
* In README, explain where to place `google-services.json` and `GoogleService-Info.plist`.

**Config file placement:**

* Android: put `google-services.json` in `android/app/` (same folder as `AndroidManifest.xml`).
* iOS: put `GoogleService-Info.plist` in `ios/Runner/` (next to `Info.plist`).
* After placing files, run `flutterfire configure` (recommended) to generate `lib/firebase_options.dart`, or rely on the native configs for Android/iOS; web/desktop require `firebase_options.dart`.

---

## 6. Step-by-step implementation plan (priority order)

Follow the list below — complete each task and run the app in an emulator/device before continuing.

**Sprint 0 — Project basics**

1. Scaffold project & folder structure (create files above with placeholder widgets).
2. Implement Splash screen and Language selection screen (English + Hindi placeholder).* Use `easy_localization` to wire at least `en.json` fully.
3. Wire navigation & theme, add global `AppState` using Riverpod.

**Sprint 1 — Authentication & Profile**
4. Implement Firebase init and phone OTP login (`auth_phone.dart`).
5. Implement Guest mode (`guest_mode.dart`) that stores user as anonymous with local storage.
6. Profile creation screen (`profile_create_edit.dart`) capturing name, age, gender. Save to Firestore under `profiles/` and link to `users/{uid}`.
7. Implement multiple profiles list and selection flow.

**Sprint 2 — Profile details & utilities**
8. Implement Personal Info screen to capture height/weight with unit selectors. Create `unit_conversion.dart` and `bmi.dart`. Show live BMI.
9. Add choices for substance use, existing diseases, family history and persist to the profile document.

**Sprint 3 — Chat UI & symptom JSON**
10. Build the Chat UI (`main_chat_hologram.dart`) with simple message list, input field, quick-chips area.
11. Create `symptoms.json` (or Firestore `symptoms/`) mapping body regions to symptom lists. Cache locally.

**Sprint 4 — 3D hologram + interaction**
12. Implement `body_hologram.dart` using `model_viewer_plus` or `flutter_cube` and load a low-poly GLB/GLTF for male/female. Implement rotate/zoom.
13. Implement touch/pick logic — on selection open symptom modal with relevant chips.
14. Provide 2D silhouette fallback when device can't render 3D.

**Sprint 5 — Voice & STT**
15. Integrate `speech_to_text` for capturing audio locally and sending recorded audio blob to a mocked STT backend endpoint.
16. Display returned transcript in chat and process as user input.

**Sprint 6 — Report submission & results**
17. Implement `report_service.dart` to `POST /reports` (mock) with profileId, symptoms, chat history.
18. Save returned triage to Firestore `reports/` and display `result_screen.dart` with triage, conditions and suggested action.

**Sprint 7 — Offline & guest queue**
19. Implement offline cache of assets + `offline_queue.dart` to store unsent reports locally and auto-send when network is available.
20. Ensure guest mode stores profiles + reports locally.

**Sprint 8 — Polish & tests**
21. Add consent & disclaimer flow (show on first run before profile creation).
22. Add translations skeleton for the 11 other languages (placeholders).
23. Write unit tests for `unit_conversion` and `bmi` utils.

---

## 7. Screen-by-screen acceptance checklist

For every screen, Copilot should implement UI + data wiring and mark completion.

**Splash**

* Displays ClinixAI logo and navigates to Language screen after 1.2s.

**Language selection**

* Shows 12 languages and stores selection locally (`SharedPreferences` or Hive).

**Auth**

* Phone OTP flow functional against Firebase Auth.
* Continue as Guest path stores local guest user.

**Profile creation / edit**

* Add, edit, and list multiple profiles. Profiles are persisted to Firestore (or local in guest mode).

**Personal Info**

* Height & weight units selectable; BMI computed live.
* Substance use & disease fields saved.

**Main chat + hologram**

* 3D model displays, rotates, zooms, supports front/back selection.
* Tapping a region opens symptom modal with quick-chips.
* Chat accepts typed text and voice input (captures audio and displays transcript).

**Symptom detail**

* Follow-ups: onset, severity, duration implemented using chips.

**Result**

* Shows triage level, ranked conditions (from backend mock), and save report button.

---

## 8. APIs & mock backend

Create a simple mock server (Node.js + Express or local Dart server) to emulate backend endpoints during frontend development.

**Endpoints:**

* `POST /stt` — accepts audio upload (multipart/form-data) and returns `{ transcript: string }`.
* `POST /reports` — accept JSON with `profileId`, `userId`, `language`, `symptoms[]`, `chatHistory[]` and return structure:

```json
{
  "triage":{
    "level":"See Doctor",
    "conditions":[{"name":"Condition A","confidence":0.78},{"name":"Condition B","confidence":0.41}]
  }
}
```

**Mock server tips:**

* Return deterministic responses for known symptom sets (helpful for testing). E.g., chest pain + shortness of breath → `Emergency`.
* Provide CORS headers for local testing.

---

## 9. 3D hologram implementation + fallback

**Primary approach:** use `model_viewer_plus` to load GLTF/GLB.

**Steps for Copilot:**

1. Add low-poly GLB assets to `/assets/models/male.glb` and `/assets/models/female.glb`.
2. Use `ModelViewer` widget to render the GLB.
3. Add gestures: `onPan` for rotate, `onScale` for zoom.
4. For body region selection: if the 3D library supports raycasting/picking, use it; if not, overlay invisible touch hotspots (transparent `Positioned` widgets) mapped to the viewport coordinates for each view orientation. When user rotates model, update hotspot positions accordingly (simpler approach: provide front/back toggle and separate hotspots for front & back).

**Fallback:**

* If device lacks WebGL/3D support, show a labeled 2D silhouette PNG with tappable SVG regions.

**Performance tips:**

* Use low-poly models and compressed GLB; avoid textures when possible.
* Lazy-load the model after the main UI is visible.

---

## 10. Voice (STT) integration

**Flow:** user taps mic → app records using `speech_to_text` → sends raw WAV/OGG to `POST /stt` with `languageCode` → backend returns transcript → display in chat and process.

**Implementation notes:**

* Use `speech_to_text` primarily to record and show simple interim transcripts; but since we rely on backend STT for language accuracy, also upload audio to backend. The `speech_to_text` plugin simplifies recording & permissions.
* Manage permissions on both platforms and show a small help tooltip in the UI for first-time mic usage.

---

## 11. Localization & translations

**Approach:**

* Use `easy_localization` or `intl` to provide translation JSON files under `/lib/i18n`.
* Provide a complete `en.json` and placeholders for other languages (Copilot should create all files with English keys and placeholder translations like `"__TODO__"`).
* Map chosen language to STT language codes (examples):

  * English: `en-IN` or `en-US`
  * Hindi: `hi-IN`
  * Marathi: `mr-IN`
  * Gujarati: `gu-IN`
  * Bengali: `bn-IN`
  * Tamil: `ta-IN`
  * Telugu: `te-IN`
  * Kannada: `kn-IN`
  * Malayalam: `ml-IN`
  * Punjabi: `pa-IN`
  * Assamese: `as-IN`
  * Odia: `or-IN`

**UI guidance:** keep text short, avoid medical jargon, use action-oriented labels.

---

## 12. Offline / guest mode

**Caching:**

* Cache `symptoms.json`, translation JSONs chosen, and the 2D model images locally using Hive or SharedPreferences.

**Guest flow:**

* Allow creating profiles stored locally only.
* When a report is generated in guest mode and offline, mark it `pending` and queue it in `offline_queue.dart`.
* On network reconnection, attempt to POST queued reports and update their status.

---

## 13. Security, privacy & consent

* Add a consent modal with a checkbox and brief statement before storing personal data. The user must accept to proceed.
* Use Firebase security rules: only authenticated users can read/write their own `users/{uid}` and `profiles/*` documents. For guest mode, only local storage used.

**Example Firestore rule stub (to include in README):**

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /profiles/{profileId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /reports/{reportId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

---

## 14. Testing & acceptance criteria

**Unit tests:**

* `unit_conversion.dart` tests for ft-in ↔ cm and lb ↔ kg conversions.
* `bmi.dart` tests for a few known values.

**Manual acceptance tests:**

* Language switch changes UI strings and controls STT language code.
* Phone OTP login returns Firebase user.
* Guest mode stores data locally and allows interaction with hologram & symptom flow.
* Submitting symptoms calls `POST /reports` mock and displays triage.
* 3D hologram rotates and region tap opens symptom modal or 2D fallback works.

---

## 15. Build & release (Android / iOS)

**Android:**

1. Place `android/app/google-services.json`.
2. Update `android/app/build.gradle` if required by Firebase packages.
3. Run: `flutter build apk --release` or `flutter run` for dev.

**iOS:**

1. Place `ios/Runner/GoogleService-Info.plist`.
2. Open `ios/Runner.xcworkspace` in Xcode, ensure signing and capabilities are set.
3. Run: `flutter build ios --release` (or use Xcode for archive).

**Note:** For 3D plugins using platform channels, some packages may require running `pod install` and building via Xcode. Document these in README.

---

## 16. README / docs / deliverables

Copilot must generate a `README.md` (this file) and include:

* Setup steps for Firebase and where to place config files.
* How to run the app locally (Android emulator / iOS simulator).
* How to run the mock backend (if provided).
* How to replace mock endpoints with real STT/diagnosis services.
* Testing instructions for unit tests.

---

## 17. Helpful commands & tips

* `flutter pub get`
* `flutter analyze`
* `flutter test`
* `flutter run -d emulator-5554`
* `flutter build apk --release`
* `flutter build ipa` (requires Mac & code signing)

---

## Final notes to Copilot

* Keep commits small and focused (one feature per commit).
* Use clear TODO comments for backend integration points and where production STT/TTS should be wired.
* Favor small, testable functions and components.
* Prioritize the rural-first UX: simple language, big buttons, voice-first options.

---

If you want, I can now generate the initial `main.dart`, `language_selection.dart`, `auth_phone.dart`, and `profile_create_edit.dart` files so you can start coding immediately.
