# Language Roulette (iOS)

Native SwiftUI iOS app for the German practice wheel game **Language Roulette**.

This repository also includes a **web admin** for managing languages, UI translations, category labels, and questions.

## Requirements

- macOS with Xcode 15 or newer (iOS 17+)
- Python 3 (for the local web admin save server; Node.js also works)
- Apple Developer account for device installs / App Store submission

## Open and run the iOS app

1. Open `LanguageRoulette.xcodeproj` in Xcode.
2. Select the **LanguageRoulette** target and set your Team under Signing & Capabilities.
3. Choose an iPhone/iPad simulator and press Run.

Display name: **Language Roulette**  
Bundle ID: `com.spirea89.LanguageRoulette`

## Multilingual content pack

All maintainable translations live in one JSON pack:

```text
content/content.json
```

Copied into the app bundle as:

```text
LanguageRoulette/Resources/content/content.json
```

### Format

```json
{
  "version": 1,
  "defaultLanguage": "en",
  "languages": [
    { "code": "en", "name": "English" },
    { "code": "de", "name": "Deutsch" }
  ],
  "ui": {
    "navGame": { "en": "Game", "de": "Spiel" }
  },
  "categories": [
    {
      "id": "morning",
      "labels": { "en": "Morning", "de": "Morgen" },
      "questions": [
        { "prompt": "Wie hast du geschlafen?", "answer": "Ich habe gut geschlafen." }
      ]
    }
  ]
}
```

- **languages**: appears in the app language switcher
- **ui**: app chrome strings
- **categories.labels**: wheel labels (switch with the UI language)
- **questions**: practice prompts (kept in German for this learning game)

## Public support and privacy pages

GitHub Pages publishes only `public-site/`:

- https://spirea89.github.io/LanguageSpinApple/support.html
- https://spirea89.github.io/LanguageSpinApple/privacy.html

The public site contains no editor, tracking scripts, or contact forms. Support email: supportlanguagelearning@gmail.com.

## Local web admin

The content editor stays in `admin/` and is not published by the Pages workflow.

Run `python3 admin/dev-server.py` (or `node admin/dev-server.cjs`) and open http://localhost:5180. Save locally to update all three content copies, then commit the changes and rebuild the app.

## In-app Configure

The in-app Configure editor is available only in **Debug** builds (Xcode Run). **Release** builds, including TestFlight and App Store archives, exclude the editor and load only bundled content, ignoring on-device development overrides. The language switcher and game setup remain available to everyone.

Speech uses only Anna, selecting her best installed quality automatically. Older saved voice selections are ignored. If Anna is unavailable, the game explains how to download her in Accessibility voice settings and remains playable without audio.

The separate web admin remains a development tool; saving to GitHub requires a repository write token.

## Project layout

```text
LanguageRoulette.xcodeproj
LanguageRoulette/                 # SwiftUI iOS app
content/content.json              # source-of-truth content pack
admin/                            # web admin UI + local save server
```
