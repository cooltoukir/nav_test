# Navigation Map App

A Flutter app that shows a map, builds a route, and animates a marker along it using live native
location data. Android only. Two flavors: `dev` and `prod`.

## Requirements

- Flutter `>=3.38.4`
- Android Studio / Android SDK with an emulator or physical device
- Location permission granted on the device

## Build and run

### Android

```bash
flutter pub get

# Run
flutter run --flavor dev
flutter run --flavor prod

# Release builds
flutter build apk --flavor dev
flutter build apk --flavor prod
flutter build appbundle --flavor prod
```

If your entrypoints are split per flavor, add `-t lib/main_dev.dart` / `-t lib/main_prod.dart`.

### iOS

Not implemented.

## Versions

| Item             | Version    |
|------------------|------------|
| Flutter          | `>=3.38.4` |
| flutter_map      | `^8.3.2`   |
| latlong2         | `^0.10.1`  |
| http             | `^1.6.0`   |
| flutter_riverpod | `^3.4.3`   |
| toastification   | `^3.2.0`   |
| dio              | `^5.11.1`  |
| flutter_animate  | `^4.5.2`   |

## Known limitations

- **No pause or resume.** Once navigation starts it cannot be paused or resumed; it can only run to
  completion or be stopped.
- **Android only.** iOS is not implemented.
- **Foreground only.** Location tracking stops when the app is backgrounded.
- **Public routing server.** Routing depends on a public server with no SLA or rate-limit guarantees
  (see `DECISIONS.md`).
- **No offline support.** Map tiles and routes need a network connection.