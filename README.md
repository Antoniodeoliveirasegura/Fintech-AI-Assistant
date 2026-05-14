# Fintech AI Assistant

> Mobile-first Flutter portfolio app that simulates a fintech loan dashboard, payment history, protected routing, and a local AI assistant.

[![Flutter](https://img.shields.io/badge/Flutter-3-blue?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3-blue?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-7C4DFF)](https://riverpod.dev)
[![GoRouter](https://img.shields.io/badge/Routing-GoRouter-02569B)](https://pub.dev/packages/go_router)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

Fintech AI Assistant is a learning project designed to feel like a small, internship-ready mobile codebase. It practices the pieces common to production Flutter work: authentication state, protected navigation, async data loading, reusable widgets, service-layer boundaries, testing, and a mock AI workflow.

All data is local demo data. There is no real backend, no real customer data, no real loan product, and no external AI API call.

## Screenshots

Place captured screenshots in `docs/screenshots/` using these exact filenames.

| Login | Dashboard |
|---|---|
| ![Login screen](docs/screenshots/login.png) | ![Dashboard screen](docs/screenshots/dashboard.png) |

| Payments | AI Assistant |
|---|---|
| ![Payments screen](docs/screenshots/payments.png) | ![Assistant screen](docs/screenshots/assistant.png) |

Capture instructions live in [docs/screenshots/README.md](docs/screenshots/README.md).

## Tech Stack

| Layer | Choice |
|---|---|
| App framework | Flutter, Material 3 |
| Language | Dart 3 |
| State management | Riverpod |
| Routing | GoRouter |
| Secure persistence | flutter_secure_storage |
| Mock services | Local async service layer |
| Formatting | intl |
| CI | GitHub Actions |
| Tests | flutter_test, provider tests, widget tests |

## Features

- Mock login with secure token persistence.
- App startup session restore using `flutter_secure_storage`.
- Protected routes with GoRouter auth redirects.
- Mobile-first dashboard with loan summary, progress, next payment, live activity, and recent payments.
- Payments screen with status filters and a detail bottom sheet.
- Local AI assistant that answers account and loan questions from mock data.
- StreamProvider practice through live account activity updates.
- Reusable fintech UI widgets for cards, badges, payments, chat bubbles, loading, and error states.
- GitHub Actions CI for `flutter pub get`, `flutter analyze`, and `flutter test`.

## Architecture

The app follows a simple layered structure:

```text
Screens + widgets
    watch
Riverpod providers
    call
Services
    parse
Models
```

### Data flow example

1. `DashboardScreen` calls `ref.watch(loanProvider)`.
2. `loanProvider` calls `MockApiService().getLoan()`.
3. `MockApiService` returns JSON-like seed data after a delay.
4. `Loan.fromJson()` converts the response into a typed Dart model.
5. The screen receives an `AsyncValue<Loan>` and renders loading, error, or data UI.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full walkthrough.

## State Management

Riverpod is used as the source of truth for app state:

| Provider | Purpose |
|---|---|
| `authProvider` | Login, logout, startup session restore, auth error/loading state |
| `loanProvider` | Async active loan fetch |
| `paymentsProvider` | Async payment history fetch |
| `paymentFilterProvider` | Current payment filter chip |
| `filteredPaymentsProvider` | Derived filtered payment list |
| `accountNotificationsProvider` | StreamProvider for live account activity |
| `chatProvider` | AI assistant messages and loading state |

Provider tests use `ProviderContainer`; widget tests override platform storage with an in-memory token store.

## Routing

GoRouter owns navigation:

- `/login` is public.
- `/dashboard`, `/payments`, and `/assistant` are protected by the auth redirect.
- Authenticated users are redirected away from `/login`.
- The authenticated routes are wrapped in a `ShellRoute` with bottom navigation.
- Named routes (`goNamed`) are used for safer navigation.

The login screen does not manually navigate. It updates `authProvider`, then the router reacts to the new auth state.

## AI Assistant

The assistant is intentionally local and mock-only. `AiAssistantService` uses keyword matching over mock loan and payment data to answer questions such as:

- What is my balance?
- When is my next payment?
- Do I have late payments?
- How much have I paid so far?
- What percentage of my loan is paid?
- What should I do next?

The public surface stays small: `MockApiService.sendChatMessage(String)`. That makes it straightforward to replace the local logic with a real LLM or agent endpoint later.

## Folder Structure

```text
lib/
  main.dart
  models/
    account_notification.dart
    chat_message.dart
    loan.dart
    payment.dart
    user.dart
  providers/
    auth_provider.dart
    chat_provider.dart
    loan_provider.dart
    notifications_provider.dart
    payments_provider.dart
  router/
    app_router.dart
  screens/
    assistant_screen.dart
    dashboard_screen.dart
    login_screen.dart
    payments_screen.dart
    shell_screen.dart
  services/
    api_client.dart
    mock_api_service.dart
    secure_token_store.dart
  utils/
    app_theme.dart
  widgets/
    app_error_widget.dart
    app_loading_widget.dart
    chat_bubble.dart
    fintech_card.dart
    payment_list_item.dart
    status_badge.dart

docs/
  ARCHITECTURE.md
  LEARNING_NOTES.md
  screenshots/

test/
  providers/
  screens/
  services/
  widget_test.dart
```

## Getting Started

```bash
git clone <your-repo-url>
cd fintech-ai-assistant
flutter pub get
flutter run
```

Demo login:

- Email: any valid email address
- Password: any value with at least 6 characters

## Tests and CI

Run checks locally:

```bash
flutter pub get
flutter analyze
flutter test
```

GitHub Actions runs the same checks on pushes and pull requests to `main` and `master`.

If Windows local tests hit a Flutter shader compiler issue, run:

```bash
flutter test --no-test-assets
```

The CI workflow still runs the normal `flutter test` command on Ubuntu.

## Learning Goals

This project is meant to help practice:

- Riverpod provider types and provider testing.
- GoRouter redirects and protected navigation.
- Secure token persistence with a testable storage abstraction.
- `FutureProvider` for API-style reads.
- `StreamProvider` for live updates.
- Mock-first service design that can later swap to a backend.
- Widget tests for real app flows.
- CI setup for Flutter repositories.

See [docs/LEARNING_NOTES.md](docs/LEARNING_NOTES.md) for a guided study path.

## Future Improvements

- Replace `MockApiService` with a Django REST-backed `RemoteApiService`.
- Implement real token refresh and centralized 401 handling in `ApiClient`.
- Replace local assistant logic with a real LLM or agent endpoint.
- Add typed route generation if route complexity grows.
- Add screenshot PNGs and a short demo GIF.
- Add a custom app icon using `flutter_launcher_icons`.
- Add dark-mode screenshots.

## Disclaimer

This repository is for learning and portfolio demonstration only. It does not provide financial advice, does not process real transactions, and does not connect to real banking or lending systems.

## License

[MIT](LICENSE)
