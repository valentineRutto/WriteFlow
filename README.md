# Write Flow

WriteFlow is an Android and iOS Flutter application for converting scanned
handwritten documents into editable digital text.

WriteFlow turns messy handwritten knowledge into clean, searchable, shareable documents privately on your phone.

WriteFlow AI converts handwritten notebooks, journals, and paper notes into editable digital documents using edge AI.

### App Screenshots

<div align="center">
<img width="280"  alt="Screenshot_20260805_003307" src="https://github.com/user-attachments/assets/d982b9fd-b3e9-4628-a51e-280a8981689b" />
<img width="280"  alt="Screenshot_20260805_003322" src="https://github.com/user-attachments/assets/dbe1665a-c985-4675-9c29-a2d3d4e53227" />
</div>


## On-device scanning and AI pipeline

WriteFlow keeps scanning and text processing on the device:

- Android uses ML Kit Document Scanner for capture and ML Kit Text Recognition
  v2 for OCR.
- iOS uses VisionKit Document Camera for capture and Apple Vision text
  recognition for OCR.
- Flutter talks to the native scanner through `inkdoc/on_device_ai`.
- Text cleanup is behind a `TextEditingRepository`, so Gemma through
  LiteRT-LM on Android or Apple Foundation Models on iOS can be added without
  changing the UI or MVVM flow.

Current text cleanup uses a local deterministic fallback when a native LLM is
not available. This keeps the app runnable on emulators and simulators while
the production model package/download flow is added.

The Preview Clean action (including documents opened from Library) tries the
downloaded Gemma model first and falls back to the Gemini cloud API if Gemma is
unavailable or fails. Enable the cloud fallback at build time without checking
the key into source control:

```sh
flutter run --dart-define=GEMINI_API_KEY=your_key
```

## Features

“Exam season pack” for students.
“Sermon archive pack” for pastors.
“Business ledger pack” for small shops.

- AI Study Mode
Turn scanned class notes into summaries.
Generate flashcards.
Generate quiz questions.
Extract key definitions and formulas.
This gives students a reason to use it weekly, not once.

- Smart Document Templates
Meeting notes → action items.
Sermon notes → sermon outline + shareable devotional.
Recipes → ingredients + steps.
Business ledger → structured table.
Class notes → study guide.
Your existing document type system is a perfect foundation for this.

- Searchable Private Library
Real saved documents, not demo data.
Tags, folders, favorites.
Search inside recognized text.
“Ask my notes” local AI search later.

- Export That Actually Saves Time
PDF, Markdown, DOCX, TXT.
CSV for business/ledger notes.
Direct export to Google Drive, Notion, WhatsApp, email.
The current export button is visible but not wired, so this is a key product gap.

- Before/After Confidence Editing
Highlight low-confidence phrases.
Let users tap only uncertain words.
Show original handwriting image beside recognized text.
This improves trust, which is critical for OCR products.

## Supported platforms

- Android
- iOS


## model architecture

- Ondemand [assets delivery ]  model download after they have finished downloading the app <<-->>  
- Bundle with the app 
-  add baidu unlimited ocr 


