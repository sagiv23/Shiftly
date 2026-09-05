# Planet - Sagiv23

A minimal, high-performance Flutter app for tracking work shifts and calculating monthly salaries.
Built with Material 3, Provider, and Hive.

## The Core Problem

Most work trackers require too much tapping. **Planet** focuses on speed—allowing you to log shifts
either manually or by pasting raw text from WhatsApp/Notes.

## What it does

- **Smart Parsing:** Paste strings like `24.6 - 17:30 - 23:00 + 50 tip` and let the app handle the
  rest.
- **Overnight Support:** Correctly calculates duration for shifts that cross midnight (e.g., 22:00
  to 06:00).
- **Auto-Breaks:** Configurable rules (default: -45 mins for shifts >= 9 hours).
- **Job Management:** Define custom roles (Sitter, Bar, Logistics) with specific hourly rates.
- **Monthly Summaries:** Grouped history with net hours, base pay, and tips calculated
  automatically.
- **Offline First:** All data is stored locally using Hive for near-instant load times.

## Text Parsing Format

The parser looks for the following pattern:
`[Day].[Month] - [Start Time] - [End Time] + [Optional Tip]`

**Example:**
`24.6 - 17:30 - 23:00 + 50`
*(Result: June 24th, 5.5 hours, 50₪ tip)*

## Tech Stack

- **State:** Provider
- **Storage:** Hive (NoSQL)
- **UI:** Material 3 (Supports System Light/Dark modes)
- **CI/CD:** GitHub Actions for automated multi-platform builds.

## Deployment & Releases

Builds are automated via GitHub Actions. To trigger a new release:

1. Tag your commit: `git tag v1.0.0`
2. Push the tag: `git push origin v1.0.0`
3. Download the APK/IPA/EXE from the **Releases** tab.

## Local Development

1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter run`

### Running Tests

`flutter test test/unit/shift_logic_test.dart`
