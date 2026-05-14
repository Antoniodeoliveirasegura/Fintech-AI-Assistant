# App icon

Drop your icon assets here and run the generator.

## Files expected

| Filename | Size | Purpose |
|---|---|---|
| `app_icon.png` | **1024 × 1024** | Master icon — used by iOS, Android (legacy), web, macOS, Windows |
| `app_icon_foreground.png` | **1024 × 1024** | Android adaptive icon foreground — keep content within the inner ~66% safe area, transparent background |

Both files must be **opaque PNGs** (no transparency on `app_icon.png` because iOS rejects alpha channels).

## Design tips for a fintech-style icon

- Solid background in the brand color `#1A56DB` (the app's primary blue)
- Centered glyph in white — a stylized "F", "$", balance/scale icon, or simple wordmark
- Avoid thin lines (they disappear at small sizes)
- Test at 48 × 48 — if it's still legible, you're done

Free tools that work well:
- [Figma](https://figma.com) — design at 1024 × 1024, export PNG
- [icon.kitchen](https://icon.kitchen/) — generate adaptive icons directly
- [Canva](https://canva.com) — templates with mobile-icon presets

## Generate the icons

After replacing the placeholders:

```bash
flutter pub get
dart run flutter_launcher_icons
```

This rewrites:
- `android/app/src/main/res/mipmap-*/ic_launcher.png` (all densities)
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (adaptive)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `web/icons/Icon-*.png` and `web/favicon.png`
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png`
- `windows/runner/resources/app_icon.ico`

Commit the regenerated files.

## Placeholder note

This folder ships with **no actual PNG files** — drop your own in. The Flutter default icon will be used until then. The README on the main repo and this folder are the only places to look for guidance.
