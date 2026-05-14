# Contributing

Thanks for the interest! This is a personal learning project, but suggestions, bug fixes, and small improvements are welcome.

## Before you start

- This is a **demo app**. All data is mocked locally — there is no backend.
- The codebase intentionally uses idiomatic patterns (Riverpod, GoRouter, layered services) that map to production fintech apps. Please match the existing conventions when adding code.
- Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`docs/LEARNING_NOTES.md`](docs/LEARNING_NOTES.md) first — they explain how the pieces fit.

## Setup

```bash
git clone <your-fork-url>
cd fintech-ai-assistant
flutter pub get
flutter test           # should pass
flutter analyze        # should report zero issues
flutter run            # launches on the connected device / emulator
```

## Project conventions

- **Folder layout** — match the existing structure: models / providers / services / screens / widgets / router / utils.
- **State** — use Riverpod. New providers go in `lib/providers/`. Pick the right type (see `docs/ARCHITECTURE.md` cheatsheet).
- **`ref.watch` vs `ref.read`** — `watch` in `build()`, `read` in callbacks.
- **Widgets** — files in `lib/widgets/` must be pure (no `ref.watch`). Screen-specific helpers stay private (`_MyWidget`) in the screen file.
- **No new dependencies** without good reason. Prefer adding to existing files over creating new ones.
- **Comments** — explain *why* something is non-obvious. Don't narrate the *what*.

## Submitting a change

1. **Open an issue first** for anything bigger than a typo fix or a 1-line bug. This avoids duplicate work.
2. **Branch off `master`** with a descriptive name: `fix/payment-filter-bug`, `feat/biometric-login`.
3. **Run the checks locally before pushing**:
   ```bash
   flutter analyze
   flutter test
   ```
   Both must pass.
4. **Open a pull request** describing what changed and why. Include a screenshot for any UI change.

## Good first contributions

If you're looking for somewhere to start, here are bite-sized improvements:

- Add screenshots to `docs/` and link them from the README.
- Add a test for `filteredPaymentsProvider` (currently uncovered).
- Add an `AsyncValue.guard` example somewhere that needs better error handling.
- Add a `restoreSession()` stub in `AuthNotifier` for token persistence.
- Improve the app icon (today's icon is the Flutter default).

## Style

- Default `flutter_lints` rules apply. `flutter analyze` is the source of truth.
- Don't add emojis to code or docs unless asked.
- Keep PRs small. One concern per PR.
