# Nani 🎨⚡

> A delightful macOS utility app that plays anime sound effects when connecting or disconnecting cables.

**Nani** brings fun, lively micro-interactions to macOS. Whenever you plug or unplug peripherals — whether it's your charger, display monitor, USB device, or headphones — Nani triggers recognizable anime sound effects and custom audio feedback. Designed with a clean, Notion-inspired aesthetic, Nani blends native macOS feel with warm neutrals, fluid animations, and subtle anime personality.

---

## Quick Start (for users)

1. **Download** the latest release from the [Releases page](https://github.com/user/nani/releases) or build from source (see below).
2. **Move** `Nani.app` to `/Applications`.
3. **Open** Nani — it lives in your menu bar (look for the 👀 icon).
4. **Plug something in** — hear the magic. Each port type plays a different anime sound.
5. **Click the menu bar icon** to quickly see port status, pause sounds, or open Settings.

### Settings

Open Settings from the menu bar popover (`Open Settings`) or press `⌘,`. From there you can:

- **Ports** — see all monitored ports, preview sounds, assign different sounds per port, toggle ports on/off
- **Sound Library** — browse built-in sounds, import custom `.wav`/`.mp3` files (<500 KB)
- **Preferences** — toggle launch at login, play on disconnect, dark mode, volume, Do Not Disturb schedule

### Onboarding

On first launch, Nani walks you through sound assignments and enables launch at login automatically.

---

## ✨ Key Features

- **🔌 Universal Port Monitoring**: Real-time cable connection and disconnection detection for **USB-C**, **USB-A**, **HDMI**, **Headphone Jack**, and **Power / MagSafe Chargers**.
- **🔊 Anime Sound Library & Custom Audio**: Packed with a curated library of built-in anime sound effects. Easily import your own custom `.mp3` or `.wav` files and assign unique sounds to each individual port.
- **🍱 Notion-Inspired Native Design**: A calm, warm, content-first user interface built with native **SwiftUI**. Supports fluid hover animations, status indicators, and automatic Light & Dark modes.
- **⚡ Lightweight Menu Bar Companion**: Keep Nani accessible with a compact system menu bar icon. Quickly check connected port status, pause all sounds, or enable a **Do Not Disturb** schedule on the fly.
- **🚀 Seamless Direct Updates**: Built-in integration with **Sparkle 2** for automatic, secure, direct-distribution updates.

---

## 🛠 System Requirements

- **OS**: macOS 13.0 (Ventura) or newer.
- **Architecture**: Universal Support (Apple Silicon M1/M2/M3/M4 & Intel x86_64).
- **Tools** (to build from source): Swift 5.9+ (included with Xcode 15+ or Xcode Command Line Tools).

---

## 🚀 Building from Source

Nani is configured as a standard Swift Package Manager (SPM) project with a dedicated distribution script for generating deployable application bundles.

### 1. Build & Package for Release (Recommended)

To compile a Universal Binary, generate the application icon, embed framework dependencies, and package a direct-distribution `.app` and `.zip`:

```bash
./build_release.sh
```

**What the script does:**
1. Runs `swift build -c release --arch arm64 --arch x86_64` to compile a Universal Mac binary.
2. Executes `Scripts/make_icon.swift` to generate `AppIcon.icns` directly from `app-icon.png`.
3. Assembles the proper application bundle hierarchy at `Release/Nani.app`.
4. Embeds required SPM module resource bundles and the `Sparkle.framework` with runtime rpath injection.
5. Performs ad-hoc code signing (`-s -`) so the binary executes natively on Apple Silicon.
6. Archives the finished application bundle into `Release/Nani_1.0.0.zip`.

### 2. Quick Development Build (SPM)

If you are developing locally or debugging without generating the full application bundle:

```bash
# Compile the executable via Swift Package Manager
swift build

# Run directly from the command line
swift run Nani
```

---

## 📦 Installation & Gatekeeper Instructions

Because Nani is packaged for direct web distribution (ad-hoc signed without Apple App Store or Developer ID notarization), macOS Gatekeeper requires an initial confirmation upon first launch.

### Standard Install Flow
1. Build the app using `./build_release.sh` (or download the packaged zip).
2. Unzip and move **`Nani.app`** into your `/Applications` directory.
3. On first launch, if macOS says *"Nani can't be opened because Apple cannot check it for malicious software"*:
   - **Right-click** (or Control-click) on **`Nani.app`** in Finder.
   - Select **Open** from the context menu, then click **Open** in the confirmation dialog.
    
Alternatively, you can strip the Apple quarantine attribute via terminal:
```bash
xattr -d com.apple.quarantine /Applications/Nani.app
```

Once opened once, Nani will launch seamlessly thereafter and can be configured in Preferences to automatically **Launch at Login**.

---

## 📂 Repository Structure

```text
Nani/
├── Nani/                 # Core SwiftUI views, application state, models, theme & audio resources
├── Scripts/
│   └── make_icon.swift   # Build utility to compile app-icon.png into AppIcon.icns
├── Info.plist            # macOS application bundle manifest & Sparkle configuration
├── Package.swift         # Swift Package Manager manifest (dependencies & module resources)
├── Package.resolved      # SPM dependency versions lockfile
├── app-icon.png          # High-resolution source icon image used during build
├── build_release.sh      # Complete build, assembly, signing & packaging script
└── README.md             # Project documentation
```
