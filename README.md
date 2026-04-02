# SaneScroll

Separate scroll direction for your mouse and trackpad on macOS — because they shouldn't be tied together.

macOS forces the same "Natural" scroll direction on both your trackpad and mouse. If you prefer natural scrolling on your trackpad but traditional scrolling on your mouse (or vice versa), you're out of luck. SaneScroll fixes this.

> Forked from [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels) by [ther0n](https://github.com/ther0n). Full credit to the original developer for creating this essential utility.

## Why this fork?

The original UnnaturalScrollWheels has been largely unmaintained since August 2022. This fork aims to:

- Keep the app working on the latest macOS releases
- Fix outstanding bugs and review community PRs
- Provide regular, up-to-date releases
- Maintain an active open-source community around the project

## What it does

SaneScroll intercepts scroll events and lets you configure scroll behavior per device type. Keep "Natural" scrolling on your trackpad while using traditional scroll direction on your mouse — or any combination you prefer.

### Features

- Invert scroll direction for physical scroll wheels independently from trackpad
- Disable scroll acceleration for mice
- Adjust scroll distance (line-by-line or custom multiplier)
- Per-device configuration
- Launch at login
- Lives in your menu bar, out of the way

## Installation

### Homebrew

```sh
brew install --cask sanescroll
```

### Manual

1. Download the latest `.dmg` from the [Releases](../../releases) page.
2. Mount it and drag **SaneScroll.app** to your Applications folder.
3. Open SaneScroll. You'll be prompted to grant Accessibility permissions — this is required to intercept and modify scroll events.

#### Unsigned build notice

SaneScroll is currently distributed without an Apple Developer signature. If macOS says the app is "damaged" or can't be verified, run:

```sh
xattr -d com.apple.quarantine /Applications/SaneScroll.app
```

This is safe — it just removes the quarantine flag that macOS applies to unsigned downloads.

## Usage

SaneScroll lives in your menu bar. Click the icon to access preferences.

If you've hidden the menu bar icon, simply open the app again (e.g. from Spotlight or Applications) to bring up the preferences window.

## Building from source

Requires Xcode 15+ and macOS 14+.

```sh
git clone https://github.com/dyarfaradj/SaneScroll.git
cd SaneScroll
open SaneScroll.xcodeproj
```

Build and run from Xcode (⌘R).

## Contributing

Contributions are welcome! Feel free to open issues for bugs or feature requests, or submit a pull request.

## Acknowledgments

This project is a fork of [UnnaturalScrollWheels](https://github.com/ther0n/UnnaturalScrollWheels) by [ther0n](https://github.com/ther0n), originally released under the GPL-3.0 license. Thank you to ther0n and all original contributors for building this essential macOS utility.

## License

[GPL-3.0](LICENSE)
