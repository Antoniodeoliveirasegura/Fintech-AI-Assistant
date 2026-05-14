# Learning Notes

A personal study guide for this codebase. Read it before pair-programming on a fintech internship — these are the things you should be able to explain off the top of your head.

## What Riverpod does in this app

Riverpod is **a way to hold state outside of widgets** and let any widget subscribe to that state. Without it, you'd be passing data down through constructors and lifting state up manually as the app grows.

In this codebase Riverpod does four jobs:

1. **Cache async data** — `loanProvider` fetches the loan once. If three widgets all `ref.watch(loanProvider)`, the service is called once and all three get the result.
2. **Hold UI state** — `paymentFilterProvider` remembers which filter chip is active across rebuilds.
3. **Drive complex flows** — `authProvider` is a `StateNotifier` with methods (`login`, `logout`). Calling them mutates state, and the rest of the app reacts.
4. **Compute derived values** — `filteredPaymentsProvider` is a `Provider` that watches two other providers. It re-runs only when its inputs change.

### The two methods you'll use 95% of the time

```dart
final loan = ref.watch(loanProvider);   // subscribe — rebuild on change
ref.read(loanProvider.notifier).foo();  // one-shot read — no subscription
```

**Rule:** `watch` in `build()`, `read` in callbacks. Mixing them is the #1 Riverpod bug.

### `AsyncValue` is the thing to memorize

When you `ref.watch(loanProvider)`, you don't get a `Loan` — you get an `AsyncValue<Loan>`. That's a tagged union: it's either `loading`, `error`, or `data`. The `.when(...)` method forces you to handle all three:

```dart
loanAsync.when(
  data: (loan) => Text(loan.balance),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

No more `bool isLoading; String? error;` bookkeeping. The type system makes you handle it.

## What GoRouter does in this app

GoRouter is **declarative routing**. Instead of imperatively pushing screens onto a navigation stack, you declare the routes that exist and the conditions that govern them.

Three concepts you'll see here:

- **`GoRoute`** — one URL → one screen. `/login` → `LoginScreen`.
- **`ShellRoute`** — wraps multiple child routes in a shared parent widget. We use it for the bottom navigation bar: `/dashboard`, `/payments`, and `/assistant` all live inside the same `ShellScreen` so the nav bar persists when switching tabs.
- **`redirect`** — a callback that runs on every navigation. We use it to send unauthenticated users to `/login` and authenticated users away from it.

Navigation calls:

```dart
context.go('/dashboard');      // replace current route
context.push('/payments/123'); // push onto stack (back button works)
```

The big insight: **after a successful login, we never call `context.go()`**. We just update `authProvider`, and the redirect callback handles navigation. UI declares intent; routing handles consequences.

## What `FutureProvider` means

A `FutureProvider<T>` is "an `async` function that's been cached". The body runs once, the result is shared with every subscriber, and the result is exposed as `AsyncValue<T>`.

```dart
final loanProvider = FutureProvider<Loan>((ref) {
  return MockApiService().getLoan();  // returns Future<Loan>
});
```

To re-fetch: `ref.invalidate(loanProvider)`. Riverpod discards the cached value and re-runs the body the next time someone watches it. That's how pull-to-refresh works on the dashboard.

To wait for a fresh value imperatively (inside a refresh handler):
```dart
final loan = await ref.read(loanProvider.future);
```

## How state changes update the UI

This is the mental model:

```
1. User taps a button → callback runs
2. Callback calls ref.read(someProvider.notifier).doSomething()
3. The notifier mutates its state
4. Riverpod tells every widget watching that provider to rebuild
5. build() runs again → reads the new state → UI updates
```

No `setState`. No `notifyListeners` you need to remember to call. Mutating the state IS the notification.

The most subtle part: **mutations must produce a *new* state object**, not mutate the existing one in place. That's why `ChatState` has a `copyWith` method and `chatProvider` does `state = state.copyWith(...)`. If you mutated a list in place and assigned `state = state`, Riverpod wouldn't see a change.

## How Flutter widgets are organized in this app

Three rules:

1. **Screens are in `lib/screens/`** — one file per route. Each screen extends `ConsumerWidget` (stateless + Riverpod) or `ConsumerStatefulWidget` (stateful + Riverpod). Screens are the only place that `ref.watch` providers.

2. **Reusable widgets are in `lib/widgets/`** — they take data in via constructor, never `ref.watch`. This makes them previewable in isolation and reusable anywhere.

3. **Private widgets stay in the same file as their parent** — see `_LoanHeroCard`, `_NextPaymentCard`, `_AssistantBanner` in `dashboard_screen.dart`. They're prefixed with `_` so they're file-private. This avoids creating tiny one-off files in `lib/widgets/` for things only used in one place.

You'll see this pattern across well-organized Flutter codebases.

## What you should understand before pair-programming

Walk through these in order. By the time you finish, you can explain how the whole app works.

### Day 1: data and services
1. `lib/models/loan.dart` — see how `fromJson` / `toJson` work
2. `lib/services/mock_api_service.dart` — see `getLoan()`, the `_loanData` map, and the singleton pattern
3. `lib/services/api_client.dart` — see the abstraction that will replace `MockApiService` later

### Day 2: state
4. `lib/providers/loan_provider.dart` — simplest `FutureProvider`. Watch it on the dashboard.
5. `lib/providers/payments_provider.dart` — see how `filteredPaymentsProvider` derives from `paymentsProvider` + `paymentFilterProvider`.
6. `lib/providers/auth_provider.dart` — see how `AuthNotifier.login` mutates state and the rest of the app reacts.

### Day 3: routing and UI
7. `lib/router/app_router.dart` — see how the auth redirect works.
8. `lib/screens/login_screen.dart` — see how a screen drives a `StateNotifier` and never navigates explicitly.
9. `lib/screens/dashboard_screen.dart` — see `.when()` on three different `AsyncValue`s.

### Day 4: AI and tests
10. `lib/services/mock_api_service.dart` again — read `AiAssistantService._buildReply`. Note the keyword-match order.
11. `test/services/ai_assistant_service_test.dart` — see how the tests exercise the keyword routing.

## Questions to be able to answer

- What's the difference between `ref.watch` and `ref.read`? When would you use each?
- What is `AsyncValue` and why does it exist?
- How does the app know to send the user to `/dashboard` after login if `LoginScreen` never calls `context.go()`?
- Why does `chatProvider` use `StateNotifier` while `loanProvider` uses `FutureProvider`?
- If you wanted to swap `MockApiService` for a real backend, what would you change?
- Where does `filteredPaymentsProvider` get its inputs?
- Why are the AI assistant's `if/else` branches in a specific order?

If you can answer all of these without looking, you're ready.
