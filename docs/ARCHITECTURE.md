# Architecture

This document explains how the app is structured, how data flows, and what the upgrade paths look like. Read this before changing anything substantial.

## Layered overview

```
┌─────────────────────────────────────────────────────────┐
│  Screens (lib/screens/) + Widgets (lib/widgets/)        │  ← UI layer
│  - ConsumerWidget / ConsumerStatefulWidget              │
│  - reads providers via ref.watch / ref.read             │
└─────────────────────────────────────────────────────────┘
                          ↑ ref.watch
┌─────────────────────────────────────────────────────────┐
│  Providers (lib/providers/)                             │  ← State layer
│  - FutureProvider, StateProvider, StateNotifierProvider │
│  - cache async data + hold UI state                     │
└─────────────────────────────────────────────────────────┘
                          ↑ calls
┌─────────────────────────────────────────────────────────┐
│  Services (lib/services/)                               │  ← Service layer
│  - MockApiService (today) / RemoteApiService (future)   │
│  - AiAssistantService                                   │
│  - ApiClient (HTTP abstraction)                         │
└─────────────────────────────────────────────────────────┘
                          ↑ returns
┌─────────────────────────────────────────────────────────┐
│  Models (lib/models/)                                   │  ← Data layer
│  - Plain Dart classes with fromJson / toJson            │
└─────────────────────────────────────────────────────────┘
```

The arrows only go one way: **screens depend on providers, providers depend on services, services depend on models.** Models depend on nothing. If you find yourself wanting a screen to call a service directly, stop — that's a sign you need a new provider.

## Folder structure

```
lib/
├── main.dart                # ProviderScope + MaterialApp.router
├── models/                  # Pure data, no logic beyond getters
├── services/                # Business logic + (future) network
├── providers/               # Riverpod state holders
├── router/                  # GoRouter config + auth redirect
├── screens/                 # One file per route
├── widgets/                 # Reusable UI pieces (no providers)
└── utils/                   # Theme, formatters, constants
```

A widget in `lib/widgets/` should never `ref.watch` a provider. If it needs data, the parent screen passes it in. This keeps widgets reusable across screens and easy to preview in isolation.

## Data flow example — dashboard load

When the user lands on `/dashboard`:

1. `DashboardScreen.build()` runs.
2. It calls `ref.watch(loanProvider)` — Riverpod sees nobody has subscribed to `loanProvider` yet, so it executes the provider body: `MockApiService().getLoan()`.
3. `MockApiService.getLoan()` returns a `Future<Loan>` that resolves after an 800 ms simulated delay.
4. While the future is pending, `loanProvider` exposes `AsyncValue.loading()`. The dashboard's `.when()` shows the loading widget.
5. When the future resolves, `loanProvider` flips to `AsyncValue.data(loan)`. Riverpod tells every widget watching it to rebuild.
6. The dashboard's `.when()` now hits the `data:` branch and renders the hero card.

The key idea: **the screen doesn't manage loading flags or error state.** Riverpod's `AsyncValue` is a tagged union of `loading | error | data`, and `.when(...)` forces you to handle all three.

## State management cheatsheet

| Provider type | When to use it | Examples in this app |
|---|---|---|
| `Provider<T>` | Pure derived/computed value | `filteredPaymentsProvider`, `appRouterProvider` |
| `FutureProvider<T>` | One-shot async fetch (cached) | `loanProvider`, `paymentsProvider` |
| `StateProvider<T>` | Mutable UI state, no logic | `paymentFilterProvider` |
| `StateNotifierProvider<N, S>` | Mutable state + methods | `authProvider`, `chatProvider` |

### `ref.watch` vs `ref.read`

- `ref.watch(p)` — **inside `build()`**. Subscribes; the widget rebuilds when `p` changes.
- `ref.read(p)` — **inside callbacks** (`onPressed`, `onSubmit`). One-time read; no subscription.

Mixing them up is the most common Riverpod bug. Rule of thumb: if you're reacting to a button tap, use `read`. If you're displaying a value, use `watch`.

## How auth routing works

Three pieces collaborate:

1. **`authProvider`** (`StateNotifierProvider<AuthNotifier, AuthState>`) holds `user`, `isLoading`, `error`. `login()` and `logout()` mutate this.

2. **`appRouterProvider`** builds a single `GoRouter` instance. It:
   - Creates a `ValueNotifier<int>` and increments it whenever `authProvider` emits (`ref.listen`).
   - Passes that `ValueNotifier` as `refreshListenable` to `GoRouter`.
   - Defines a `redirect` callback that reads `ref.read(authProvider).isAuthenticated`.

3. **`redirect` runs every time** the route changes OR the `refreshListenable` notifies. So as soon as `authProvider` flips from unauthenticated → authenticated, GoRouter re-evaluates the current route and decides where the user should be.

### The full login flow

```
User taps "Sign in"
  ↓
LoginScreen calls ref.read(authProvider.notifier).login(email, password)
  ↓
AuthNotifier sets state.isLoading = true
  ↓ (login screen rebuilds, button shows spinner)
AuthNotifier awaits MockApiService.login()
  ↓
On success, state = AuthState(user: user)  ← authenticated!
  ↓
ref.listen in appRouterProvider fires, bumps the ValueNotifier
  ↓
GoRouter re-runs redirect:
  isAuth = true, isOnLogin = true → return AppRoutes.dashboard
  ↓
User is now on /dashboard. LoginScreen unmounts.
```

Logout is exactly the same in reverse.

## Mock vs. real API

`MockApiService` exists so the rest of the app can be built — and tested — without a backend. Its surface is what the future `RemoteApiService` will look like.

| Method | Future REST endpoint |
|---|---|
| `getCurrentUser()` | `GET /api/v1/users/me` |
| `getLoan()` | `GET /api/v1/loans/active` |
| `getPayments()` | `GET /api/v1/loans/{id}/payments` |
| `login(email, password)` | `POST /api/v1/auth/login` |
| `sendChatMessage(text)` | `POST /api/v1/assistant/messages` |

### Replacing it with a real Django backend

1. Implement `HttpApiClient.get()` and `.post()` in `lib/services/api_client.dart`. Wire timeouts, retries, 401-triggers-logout.
2. Create `lib/services/remote_api_service.dart` that mirrors `MockApiService`'s method signatures but calls `_apiClient.get('/loans/active')` etc.
3. Introduce an `apiServiceProvider` in `lib/providers/`:
   ```dart
   final apiServiceProvider = Provider<ApiService>((ref) {
     const useMock = bool.fromEnvironment('USE_MOCK_API', defaultValue: false);
     return useMock ? MockApiService() : RemoteApiService(...);
   });
   ```
4. Update each `FutureProvider` to read through it:
   ```dart
   final loanProvider = FutureProvider<Loan>((ref) {
     return ref.read(apiServiceProvider).getLoan();
   });
   ```

No screen needs to change. That's the point of the abstraction.

## Replacing the mock AI with a real LLM/agent

`AiAssistantService._respond()` today is a giant `if/else` over keyword matches. It exists so the chat UI can be built end-to-end without paying for API calls.

To swap in a real agent:

1. Build a system prompt that includes the user's loan + payments JSON. Move prompt construction into a `PromptBuilder` class for testability.
2. Replace `_respond()` body with an HTTP call (Anthropic, OpenAI, or an internal agent endpoint).
3. If you want tool-calling (so the model can ask for fresh data instead of getting it all up front), define tools like `getBalance`, `getUpcomingPayments` — route them back through `MockApiService` / `RemoteApiService` so the agent uses the same data the rest of the app sees.
4. Optionally stream the response token-by-token. The provider already exposes `isLoading`; an append-as-it-goes implementation just needs to update the last message's content in place.

The chat UI does not need to change. `MockApiService.sendChatMessage` already returns a `Future<ChatMessage>` — same shape regardless of backend.
