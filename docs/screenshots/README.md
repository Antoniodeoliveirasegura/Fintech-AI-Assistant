# Screenshots

Drop the captured PNGs into this folder. Filenames must match exactly so the main README renders them.

## Files expected

| Filename | Source screen |
|---|---|
| `login.png` | Login screen — empty state, no errors |
| `dashboard.png` | Dashboard — fully loaded, hero card + recent payments visible |
| `payments.png` | Payments — "All" filter selected, list visible |
| `assistant.png` | AI Assistant — at least one user message + one assistant reply, suggestion chips hidden |

## Recommended capture settings

- **Device size:** Pixel 7 (1080 × 2400) or iPhone 14 (1170 × 2532) — both look clean in the README's 2-column table
- **Mode:** Light theme (the app defaults to light)
- **Status bar:** Optional — clean shots include the device status bar at the top
- **Format:** PNG (lossless, transparent-ready)
- **Target size:** Aim for < 500 KB each — use [TinyPNG](https://tinypng.com/) or `pngquant` to compress without quality loss

## Capture commands

### Android (via `adb`)

```bash
# Take a screenshot on the connected emulator/device
adb exec-out screencap -p > docs/screenshots/dashboard.png
```

### iOS Simulator

```bash
# Captures the active iOS simulator window
xcrun simctl io booted screenshot docs/screenshots/dashboard.png
```

### Flutter DevTools

DevTools → Inspector → "Take screenshot" button — useful for high-DPI captures without device chrome.

## Optional: animated demo GIF

A 10–15 second GIF showing login → dashboard → assistant works well at the top of the README.

```bash
# Record on Android
scrcpy --record demo.mp4

# Convert to GIF (limit to 5 MB)
ffmpeg -i demo.mp4 -vf "fps=15,scale=480:-1:flags=lanczos" -loop 0 demo.gif
```

Save as `docs/screenshots/demo.gif` and add `![demo](docs/screenshots/demo.gif)` near the top of the README.
