# Building & Testing the Owner App

This Flutter project version-controls only `lib/` (and config). The Android/iOS
platform folders are **generated** at build time, so every build path below runs
`flutter create --platforms=android .` first.

> The app talks to the **live** API at `https://jantrah.io/petrolpump/api`
> (see `lib/config/api_config.dart`), so the built APK shows real data.
> Default login: `admin` / `admin123`.

---

## Option A — Cloud build via GitHub Actions (recommended, no local install)

You get an installable APK and an automatic compile-check (`flutter analyze`)
without installing anything. You only need a free GitHub account.

1. **Create a new repository** on GitHub (Private is fine) — e.g. `petrolpump-app`.
   Do **not** add a README/gitignore (this folder already has them).

2. From this folder (`petrolpump_app/`), push it up:
   ```bash
   git remote add origin https://github.com/<you>/petrolpump-app.git
   git branch -M main
   git push -u origin main
   ```
   (This folder is already a git repo with an initial commit — see below.)

3. GitHub runs **Actions → Build APK** automatically. When it finishes (~5 min),
   open the run → **Artifacts** → download **petrolpump-owner-app-debug**.

4. Unzip → copy `app-debug.apk` to an Android phone → tap to install
   (enable "Install unknown apps" if prompted).

To rebuild later: just `git push`, or use **Actions → Build APK → Run workflow**.

> ⚠ Never push the whole `petrolpump/` folder to a public repo — the PHP side
> (`api/helpers.php`) contains production DB credentials. This app is its **own**
> repo for that reason.

---

## Option B — Build locally (if you want hot-reload / to iterate)

Requires ~10 GB: Flutter SDK + Android Studio (for the Android SDK).

1. Install Flutter: https://docs.flutter.dev/get-started/install/windows
   and Android Studio (gives you the Android SDK + a device emulator).
2. Verify: `flutter doctor` (resolve any ❌ it reports).
3. From this folder:
   ```bash
   flutter create --platforms=android .
   flutter pub get
   flutter analyze          # compile check
   flutter run              # on a connected phone or emulator (debug + hot reload)
   flutter build apk        # produces build/app/outputs/flutter-apk/app-release.apk
   ```

---

## Before a real client release (not needed for testing)

- Set a proper **package id** and app name: `flutter create --org com.yourco --platforms=android .`
  (default is `com.example.petrolpump_app`).
- Add an **app icon** and a **release signing** key.
- Point `api_config.dart` at the production domain (already `jantrah.io`).
