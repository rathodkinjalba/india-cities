# India Cities — a Monopoly-style board game

An original-branded, **Indian-cities-themed** property trading board game for Android.
Built with **Godot 4.4**. Local **pass-and-play** for 2–6 players. "Little 3D" tilted board
with a clean touch UI.

> Not affiliated with Hasbro. All names, art, and mechanics are original.

## How it's built (no local tooling required)

The Android `.apk` is compiled **entirely in the cloud** by GitHub Actions — you don't install
Godot, the Android SDK, or Java on your PC. Every push runs three jobs:

| Job | What it does |
|-----|--------------|
| `test`    | Runs GUT unit tests headless (game logic correctness) |
| `android` | Exports the debug `.apk` (download from the run's **Artifacts**, or from a tagged **Release**) |
| `web`     | Exports an HTML5 build for quick visual checks in a browser |

## First-time setup (one time, ~3 minutes)

1. Create a **free GitHub account** (if you don't have one) at https://github.com.
2. Create a **new, empty repository** (no README/license) — e.g. `india-cities`.
3. Copy its URL (e.g. `https://github.com/<you>/india-cities.git`) and tell Claude — it will
   add the remote and push. (Git's built-in credential manager opens a browser to log you in;
   nothing is installed.)

## Getting the APK onto your phone

- **Quick:** open the latest green run under the repo's **Actions** tab → download the
  `IndiaCities-debug-apk` artifact → transfer to your phone → tap to install.
- **Easiest on phone:** push a tag like `v0.0.1`; CI attaches the `.apk` to a **GitHub Release**.
  Open the Releases page in your phone's browser and tap the `.apk` to install.

> You may need to enable "Install unknown apps" for your browser/file manager the first time.

## Project layout

See `C:\Users\Dell\.claude\plans\i-want-o-make-jazzy-ocean.md` for the full plan, architecture,
and milestone roadmap.
