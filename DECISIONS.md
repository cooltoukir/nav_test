# DECISIONS

## 1. Architecture and state management

I used a **feature-based architecture** with **Riverpod** (`flutter_riverpod ^3`) for state
management. Code is grouped by feature, and each feature has the same four folders:

```
lib/
  core/              flavor config, theme, shared utils, error types
  features/
    navigation/
      model/         data classes (route point, navigation state, location failure)
      provider/      Riverpod providers and notifiers, routing client, location bridge
      screen/        full-page screens
      widgets/       reusable UI pieces used by the screens
```

Why feature-based:

- Everything for one feature lives together, so it is easy to find, change, or delete without
  touching unrelated code.
- The fixed `model / provider / screen / widgets` split keeps a clear rule for where each piece
  goes: models are plain data, providers hold state and logic, screens and widgets only render
  state.
- It scales well: a new feature is a new folder with the same shape.

Why Riverpod:

- Providers are compile-safe and do not depend on `BuildContext`, so the location stream, the
  routing call and the animation state can be composed and tested without widgets.
- `StreamProvider` / `AsyncNotifier` map directly onto the native event stream and the async route
  request, including loading and error states.
- Dependencies (routing client, location service, flavor config) are overridable in tests and per
  flavor.

A single `NavigationNotifier` owns the navigation state (idle, loading route, navigating, finished,
error). Widgets only watch state and call methods; they hold no business logic.

## 2. Flutter ↔ native location bridge

- **Channel choice:** a `MethodChannel` for one-shot calls (permission check/request, get current
  location, start/stop) and an `EventChannel` for the continuous location stream. Streaming is what
  `EventChannel` is built for, and it avoids polling over a method channel.
- **Native side:** Kotlin, using the platform fused location provider, emitting
  `{lat, lng, accuracy, bearing, speed, timestamp}` maps.
- **Error mapping:** native errors are sent as `PlatformException` codes (e.g. `PERMISSION_DENIED`,
  `PERMISSION_DENIED_FOREVER`, `SERVICE_DISABLED`, `UNAVAILABLE`). The Dart bridge maps these to a
  sealed `LocationFailure` type, so the UI never sees raw platform exceptions. Failures are surfaced
  to the user via `toastification`.
- **Stream lifecycle:** native updates start in `onListen` and are removed in `onCancel`. On the
  Dart side the stream is exposed through a provider that is `autoDispose`, so leaving the screen
  cancels the subscription and stops the GPS. Navigation start/stop also controls the subscription,
  so location is never running while idle.

## 3. Interpolation and bearing

- **Interpolation:** the route is a list of `LatLng` points. Between two consecutive points the
  marker position is a linear interpolation (lerp) of latitude and longitude over a fixed duration.
  This is accurate enough over the short segments a routing engine returns, and is much cheaper than
  great-circle interpolation. `flutter_animate` / an `AnimationController` drives progress `t` from
  0 to 1 per segment, then advances to the next segment.
- **Bearing:** computed with the standard forward-azimuth formula between the current and next
  point:
  `θ = atan2(sin Δλ · cos φ2, cos φ1 · sin φ2 − sin φ1 · cos φ2 · cos Δλ)`, converted to degrees and
  normalised to 0–360.
- **Smoothing:** rotation is interpolated along the shortest angular path (so 359° → 1° turns 2°,
  not 358°), which prevents the marker spinning at corners.

## 4. Flavor configuration

Two flavors, `dev` and `prod`, declared as Android `productFlavors`. Each flavor sets its own
application ID suffix, app name and launcher label in Gradle, so both can be installed side by side.
Dart-side values (routing base URL, logging on/off, any API keys) live in a `FlavorConfig` object
selected at startup and exposed through a Riverpod provider. Nothing flavor-specific is hard-coded
in feature code, and secrets are not committed.

## 5. What I would change before shipping

- **Battery:** adapt update interval and accuracy to speed (lower frequency when slow or
  stationary), use `balanced` accuracy when the user is not actively navigating, and stop updates
  immediately on stop/dispose.
- **Background location:** add a foreground service with a persistent notification on Android (and
  the matching background mode on iOS), handle `ACCESS_BACKGROUND_LOCATION` rationale and Play Store
  review requirements, and handle the process being killed.
- **Routing server:** the public routing server is fine for a demo but has no SLA and strict
  fair-use limits. For production I would use a managed provider (Mapbox, Google Routes, HERE, or
  similar) or self-host OSRM / Valhalla / GraphHopper behind my own API.
- **Cost at scale:** routing requests and map tiles are the main costs. Cache routes, debounce
  re-routing, proxy requests through my own backend (hides keys, adds rate limiting and caching),
  and use a paid tile provider or self-hosted vector tiles instead of public OSM tiles, which forbid
  heavy use.
- **Quality:** off-route detection and automatic re-routing, snapping GPS to the route, crash
  reporting, analytics, and CI for both flavors.

## 6. Deliberately left out (time)

- Pause / resume of navigation
- iOS implementation
- Background and foreground-service tracking
- Off-route detection and re-routing
- Turn-by-turn instructions and voice guidance
- Offline maps and route caching
- Unit, widget and integration test coverage beyond the core math (interpolation / bearing)
- Localisation and accessibility polish