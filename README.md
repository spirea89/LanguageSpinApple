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

## Web admin (GitHub Pages + auto-commit)

The admin can run on GitHub Pages. Saving there commits the content pack into the repository.

1. In GitHub: **Settings → Pages → Source = GitHub Actions**.
2. After the Pages workflow runs, open:
   `https://spirea89.github.io/LanguageSpinApple/`
3. Create a fine-grained personal access token with **Contents: Read and write** for this repo.
4. Paste the token in the admin **GitHub save settings**, click **Remember settings**.
5. Edit languages/categories and click **Save to GitHub**.
6. On your Mac: `git pull`, then rebuild the iOS app in Xcode.

The token is stored only in your browser (`localStorage`). Do not commit it.

### Local admin (optional)

```bash
python3 admin/dev-server.py
```

Or with Node.js:

```bash
node admin/dev-server.cjs
```

Open [http://localhost:5180](http://localhost:5180).

In the admin you can:

1. Add a language (example: `fr` / French)
2. Fill UI strings for the new language
3. Fill category labels for the new language
4. Edit questions
5. Click **Save to GitHub** (or local Save when using the Python/Node server)

Then rebuild the iOS app in Xcode.

## In-app Configure

The iOS Configure tab still lets you edit categories/questions and labels per language on-device. For adding brand-new languages and full translation packs, use the web admin.

## Project layout

```text
LanguageRoulette.xcodeproj
LanguageRoulette/                 # SwiftUI iOS app
content/content.json              # source-of-truth content pack
admin/                            # web admin UI + local save server
```
