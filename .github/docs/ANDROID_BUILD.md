# Android Build Guide (LifeDrop Flutter App)

How to turn the Flutter app in `frontend/` into an installable Android **APK** (for direct
installs and demos) or **AAB** (for the Google Play Store).

The repo contains only the Dart source (`lib/`, `pubspec.yaml`). The `android/` folder is
generated once on your machine (step 2).

---

## 1. Install the tools (one time)

| Tool | Notes |
|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel) | Add `flutter/bin` to your `PATH`. |
| [Android Studio](https://developer.android.com/studio) | Installs the Android SDK and an emulator. |
| Android SDK Command-line Tools | Android Studio → **Settings** → **Languages & Frameworks** → **Android SDK** → **SDK Tools** → tick it. |
| JDK 17 | Bundled with Android Studio. |

Then check everything:

```bash
flutter doctor
flutter doctor --android-licenses
```

Fix anything `flutter doctor` marks with ✗ under **Android toolchain** before continuing.

---

## 2. Generate the Android project (one time)

From the `frontend/` folder:

```bash
cd frontend
flutter create --platforms=android --org com.lifedrop .
flutter pub get
```

- This creates `android/` without touching your existing `lib/` or `pubspec.yaml`.
- `--org com.lifedrop` sets the app ID to `com.lifedrop.blood_donor_app`. **Choose this
  carefully.** It can't be changed after you publish to the Play Store.
- If it creates `test/widget_test.dart` and that file fails to compile (it references a
  `MyApp` class this project doesn't have), delete it.

Commit the generated `android/` folder so everyone builds the same project.

---

## 3. Configure the Android project

### 3.1 Internet permission (required)

Debug builds get internet access automatically, but **release builds do not**. Without this
line, the release APK can't reach the backend. Every request fails, even though it worked
with `flutter run`.

Open `android/app/src/main/AndroidManifest.xml` and add the permission above `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="LifeDrop"
        ...
```

### 3.2 App name

In the same file, set `android:label="LifeDrop"` (shown under the app icon).

### 3.3 Plain HTTP (local testing only)

The Render backend uses HTTPS, so production builds need nothing here. Only if you point
the app at a local `http://` backend, add `android:usesCleartextTraffic="true"` to the
`<application>` tag. **Remove it again before a release build.**

---

## 4. Point the app at the backend

Edit `lib/config/api_config.dart`:

```dart
// Production (Render). No trailing slash.
static const String baseUrl = "https://blood-donor-api.onrender.com";
```

Other values for development:

| Where the backend runs | `baseUrl` |
|---|---|
| Render (production) | `https://<your-service>.onrender.com` |
| Your PC, app on the Android **emulator** | `http://10.0.2.2:8000` |
| Your PC, app on a **real phone** (same Wi-Fi) | `http://<your-PC-LAN-IP>:8000`, e.g. `http://192.168.1.10:8000` |

On the free Render plan, the first request after the service sleeps can take 30–60 s, and the
app's timeout is 20 s (`connectTimeoutSeconds`). Keep the backend awake (see
[RENDER_DEPLOYMENT.md §5](RENDER_DEPLOYMENT.md#5-keep-the-free-instance-awake)) or raise
`connectTimeoutSeconds` to `60`.

---

## 5. Test on a device first

```bash
flutter devices          # list connected phones / running emulators
flutter run              # debug build on the selected device
flutter run --release    # release build: catches release-only problems such as the missing INTERNET permission
```

Real phone: enable **Developer options** → **USB debugging**, connect via USB, and accept the
prompt on the phone.

---

## 6. Create a signing key (one time)

Release builds must be signed. Create an upload key **once** and keep it safe.
If you lose it, you can't publish updates to the same app.

**Linux / macOS:**

```bash
keytool -genkey -v -keystore ~/lifedrop-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Windows (PowerShell):**

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\lifedrop-upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

(If `keytool` isn't found, it's in Android Studio's `jbr/bin` folder.)

Create `frontend/android/key.properties`:

```properties
storePassword=<the password you chose>
keyPassword=<the password you chose>
keyAlias=upload
storeFile=/home/<you>/lifedrop-upload-keystore.jks
```

On Windows, use forward slashes in `storeFile`, e.g. `C:/Users/<you>/lifedrop-upload-keystore.jks`.

> ⚠️ **Never commit `key.properties` or the `.jks` file.** Both are listed in the repo's
> `.gitignore`. Back them up somewhere private (password manager, private drive).

---

## 7. Use the key in the Gradle build

New Flutter projects use `android/app/build.gradle.kts` (Kotlin). Edit it:

**a)** At the very top of the file, add:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

**b)** Inside the `android { ... }` block, add `signingConfigs` **above** `buildTypes`,
and change the release `signingConfig`:

```kotlin
android {
    // ...existing namespace, compileSdk, defaultConfig...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // was: signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

<details>
<summary>Older project with <code>build.gradle</code> (Groovy) instead?</summary>

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```
</details>

---

## 8. Set the version

In `pubspec.yaml`:

```yaml
version: 1.0.0+1   # <versionName>+<versionCode>
```

Increase the number after `+` for **every** build you give to users or upload to Play
(`1.0.1+2`, `1.0.2+3`, ...). Android refuses to install an update with the same or a lower
code over an existing install.

---

## 9. Build

Always start from a clean state when switching backend URLs or signing settings:

```bash
flutter clean
flutter pub get
```

### APK: share directly / install on phones

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk` (one file, works on all phones).

Smaller APKs, one per CPU type (most modern phones need `arm64-v8a`):

```bash
flutter build apk --release --split-per-abi
```

Output: `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`.

### AAB: Google Play Store

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`. Upload this in
Play Console → your app → **Release** → **Production** (or a testing track) → **Create new release**.

---

## 10. Install the APK

Phone connected via USB:

```bash
flutter install --release
# or
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Without a cable: send the APK to the phone (Drive, Telegram, etc.), open it, and allow
**Install unknown apps** for that app when prompted.

---

## 11. Release checklist

- [ ] `baseUrl` points to the Render **HTTPS** URL
- [ ] Backend `/health` responds and the keep-alive is set up
- [ ] `INTERNET` permission is in `AndroidManifest.xml`
- [ ] `usesCleartextTraffic` is **not** set
- [ ] `pubspec.yaml` version code increased
- [ ] Tested with `flutter run --release` on a real phone: register, login, donor search,
      blood request, chat
- [ ] Keystore and `key.properties` backed up and **not** committed

---

## 12. Troubleshooting

| Problem | Fix |
|---|---|
| Works with `flutter run`, but the release APK shows network errors everywhere | Missing `INTERNET` permission (step 3.1). |
| `Cleartext HTTP traffic not permitted` | You're using an `http://` URL. Use the HTTPS Render URL, or see step 3.3 for local testing. |
| First request times out, retry works | Render free instance was asleep. See step 4's note. |
| Phone can't reach `http://192.168.x.x:8000` | Run the backend with `--host 0.0.0.0`, keep the phone on the same Wi-Fi, and allow port 8000 through the PC firewall. |
| `App not installed` / `package conflicts` | An older build is signed with a different key (e.g. a debug build). Uninstall it first. |
| `Keystore file not found for signing config 'release'` | Wrong `storeFile` path in `key.properties`. |
| `Unsupported class file major version` / Gradle Java errors | Use JDK 17: `flutter config --jdk-dir <path-to-jdk-17>`. |
| `Android license status unknown` | `flutter doctor --android-licenses` and accept all. |
