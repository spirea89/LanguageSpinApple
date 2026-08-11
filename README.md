# Language Roulette (iOS)

Native SwiftUI iOS app for the German practice wheel game **Language Roulette**.

This repository is the App Store–oriented iOS project. It is separate from the web game at [spirea89/RoataNoroculuiDE](https://github.com/spirea89/RoataNoroculuiDE). Starter question content was copied into `LanguageRoulette/Resources/data/` and is edited only here.

## Requirements

- macOS with Xcode 15 or newer
- iOS 17.0+ simulator or device
- Apple Developer account (for device installs and App Store submission)

## Open and run

1. Open `LanguageRoulette.xcodeproj` in Xcode.
2. Select the **LanguageRoulette** target.
3. Set your **Team** under Signing & Capabilities.
4. Choose an iPhone or iPad simulator and press Run.

Display name: **Language Roulette**  
Bundle ID: `com.spirea89.LanguageRoulette`

## Features

- Spinning category wheel with the same scoring flow as the web game
- 1–10 players, custom names, spins per player (5 / 10 / 20 / 30)
- German text-to-speech for questions (`AVSpeechSynthesizer`)
- Show example answer, replay question, winner celebration
- English / Deutsch UI language
- Configure screen that saves categories and questions on-device (with reset to bundled defaults)

## Project layout

```
LanguageRoulette.xcodeproj
LanguageRoulette/
  LanguageRouletteApp.swift
  ContentView.swift
  Game/
  Configure/
  Models/
  Services/
  Theme/
  Resources/data/
  Assets.xcassets
  Info.plist
```

## App Store notes

- Gameplay works offline from bundled content; user Configure edits stay on device.
- Add a 1024×1024 marketing icon in `Assets.xcassets/AppIcon.appiconset` before submission.
- Set your Development Team, archive with Product → Archive, then upload via Organizer / App Store Connect.
- Privacy: no account system and no network requirement for core gameplay; speech uses on-device synthesis.
