# LifeDrop — Blood Donor Management App (Flutter Frontend)

A modern Flutter frontend for the FastAPI-based Blood Donor Management System backend
found in `blood-donor-management-system-main/backend`.

## Features

- **3-step animated onboarding** (swipeable, with skip/next, dot indicators) shown once on first launch
- **Auth**: register & login (JWT, stored locally, attached automatically to every request)
- **Blood requests**: browse all requests, view "my requests", create a new request, view details,
  update status (pending/accepted/fulfilled/cancelled), delete
- **Donor search**: filter by blood group, area, city
- **Chat**: conversation list + real-time-feeling message thread, start a chat from a donor
  card or from a blood request's detail page
- **Profile**: view & edit personal details, toggle active-donor availability, log out
- Modern Material 3 UI: custom theme, blood-red gradient branding, empty/error/loading states

## Project structure

```
lib/
  app.dart                     # Root widget + routing decision (onboarding/login/home)
  main.dart                    # Entry point, sets up Provider tree
  config/api_config.dart       # <-- SET YOUR BACKEND URL HERE
  models/                      # Plain Dart models matching backend JSON shapes
  services/                    # HTTP layer (ApiClient) + feature services + local storage
  providers/                   # ChangeNotifier state management (Provider package)
  theme/app_theme.dart         # Colors, ThemeData, badge color helpers
  screens/
    splash/                    # Launch splash + 3-step onboarding
    auth/                      # Login, Register
    home/                      # Bottom-nav shell
    blood_requests/            # List, create, detail
    donors/                    # Search & list
    chat/                      # Conversations, chat thread
    profile/                   # View & edit profile
  widgets/common_widgets.dart  # Buttons, badges, empty/error states, blood-drop avatar
```

## 1. Point the app at your backend

Open `lib/config/api_config.dart` and set `baseUrl`:

```dart
static const String baseUrl = "http://10.0.2.2:8000"; // Android emulator default
```

- Android emulator → host machine: `http://10.0.2.2:8000`
- iOS simulator → host machine: `http://127.0.0.1:8000`
- Physical phone: your computer's LAN IP, e.g. `http://192.168.1.10:8000`
- Deployed backend: its public HTTPS URL

Make sure the FastAPI backend (`backend/main.py`) is actually running and reachable at that
address, and that its `.env` (copy from `.env.example`) has valid MySQL + JWT settings.

## 2. Generate native platform folders

This package ships only the Dart/Flutter source (`lib/`, `pubspec.yaml`) — it does not include
the generated `android/`, `ios/`, `web/` etc. folders, since those are normally scaffolded by the
Flutter CLI for your machine/SDK version. From inside this project folder run:

```bash
flutter create .
```

This safely fills in the missing platform folders without touching your existing `lib/` or
`pubspec.yaml`.

## 3. Install dependencies

```bash
flutter pub get
```

## 4. Allow cleartext HTTP while developing locally (Android only)

If your backend runs on plain `http://` (not `https://`), Android 9+ blocks cleartext traffic
by default. After step 2, either:

- Quickest for local dev: in `android/app/src/main/AndroidManifest.xml`, add
  `android:usesCleartextTraffic="true"` to the `<application>` tag, **or**
- Add a network security config allowing your dev host, **or**
- Just deploy the backend behind HTTPS and skip this entirely.

iOS simulators allow local HTTP to `127.0.0.1` by default; for a real device you'll want HTTPS.

## 5. Run

```bash
flutter run
```

## Backend endpoints this app talks to

| Feature | Method & Path |
|---|---|
| Register | `POST /api/users/register` |
| Login | `POST /api/users/login` |
| Get profile | `GET /api/users/profile` (Bearer token) |
| Update profile | `PUT /api/users/profile` (Bearer token) |
| Search donors | `GET /api/users/donors?blood_group=&area=&city=&page=&items_per_page=` |
| Create blood request | `POST /blood-requests/` (Bearer token) |
| List all requests | `GET /blood-requests/` |
| My requests | `GET /blood-requests/my` (Bearer token) |
| Request detail | `GET /blood-requests/{id}` |
| Update request | `PUT /blood-requests/{id}` (Bearer token, owner only) |
| Delete request | `DELETE /blood-requests/{id}` (Bearer token, owner only) |
| List conversations | `GET /conversations/` (Bearer token) |
| Start/get conversation | `POST /conversations/` `{ "user_id": <id> }` (Bearer token) |
| Get conversation | `GET /conversations/{id}` (Bearer token) |
| List messages | `GET /conversations/{id}/messages?page=&items_per_page=` (Bearer token) |
| Send message | `POST /conversations/{id}/messages` `{ "message": "..." }` (Bearer token) |

## Notes

- Auth token is persisted with `shared_preferences` and attached automatically by `ApiClient`.
- All network errors surface as a friendly retry state instead of crashing the UI.
- The onboarding screens only show once; this is tracked locally on-device.
