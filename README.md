# WriteFlow

WriteFlow is an Android and iOS Flutter application for converting scanned
handwritten documents into editable digital text.

## On-device scanning and AI pipeline

WriteFlow keeps scanning and text processing on the device:

- Android uses ML Kit Document Scanner for capture and ML Kit Text Recognition
  v2 for OCR.
- iOS uses VisionKit Document Camera for capture and Apple Vision text
  recognition for OCR.
- Flutter talks to the native scanner through `writeflow/on_device_ai`.
- Text cleanup is behind a `TextEditingRepository`, so Gemma through
  LiteRT-LM on Android or Apple Foundation Models on iOS can be added without
  changing the UI or MVVM flow.

Current text cleanup uses a local deterministic fallback when a native LLM is
not available. This keeps the app runnable on emulators and simulators while
the production model package/download flow is added.

## Supported platforms

- Android
- iOS


## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Android and iOS builds:

```bash
flutter build apk --debug
flutter build ios --simulator
```
