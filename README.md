# Habitudes

A cross-platform habit tracker built with Flutter, demonstrating modern app architecture best practices.

## About

Track daily habits, record completions, and monitor streaks. Supports multiple platforms (Android, iOS, web) with a Material 3 UI that adapts to your device's color scheme.

## Tech Stack

- **Framework**: Flutter (Dart)
- **State management**: MVVM with `ChangeNotifier` + `ListenableBuilder`
- **Dependency injection**: `provider`
- **Navigation**: `go_router`
- **Persistence**: SQLite via `sqflite`
- **Theming**: Material 3 with seed-generated colors and platform dynamic color (Android 12+)

## Architecture

Follows the [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/guide):

```text
UI layer (by feature)     Data layer (by type)
─────────────────────     ────────────────────
View ⇄ ViewModel    →     Repository → Service
```

- **Views**: `StatelessWidget` — display UI state, no business logic
- **ViewModels**: `ChangeNotifier` — manage UI state, expose commands
- **Repositories**: single source of truth per data type
- **Services**: stateless wrappers around external data sources (SQLite)

## Getting Started

```bash
flutter pub get
flutter run
```

Run tests:

```bash
flutter test
```

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
