# WriteFlow

WriteFlow is a native Android app for turning handwritten document scans into
editable digital text. The app is implemented with Kotlin, Jetpack Compose,
MVVM, and Koin.

## Architecture

- `MainActivity` hosts the Compose UI.
- `WriteFlowApplication` starts Koin.
- `di/` wires repositories and view models.
- `domain/` contains app models and repository contracts.
- `data/` contains demo repository implementations.
- `presentation/viewmodel/` owns screen state and user actions.
- `presentation/` contains the Compose screens and reusable UI.

## Current Features

- Select, add, and edit document types.
- Simulated scan flow with batch mode.
- Preview recognized text and edit it.
- Run deterministic text cleanup.
- Browse and search a demo document library.

## Development

From the Android project directory:

```bash
cd android
./gradlew assembleDebug
```

If Gradle cannot write to the default user cache on this machine, use:

```bash
cd android
GRADLE_USER_HOME=/private/tmp/writeflow-gradle ./gradlew assembleDebug
```

Install the debug APK:

```bash
adb install -r ../build/app/outputs/apk/debug/app-debug.apk
```
