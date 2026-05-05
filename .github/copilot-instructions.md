# Flutter Coding Standards

## General

- Use Dart null safety and avoid `dynamic` unless required.
- Prefer `const` widgets and values where possible.
- Keep widgets small and composable; extract reusable pieces.
- Avoid hard-coded colors; use `Theme.of(context).colorScheme` and `TextTheme`.
- Ask before introducing a new state management library or architecture.
- Follow Flutter’s official architecture recommendations; if an MVVM split is needed, use ViewModels and keep UI logic in the view layer.

## Architecture

- Separate UI and data layers; UI uses View + ViewModel pairs, data uses repositories and services.
- Keep widgets dumb; UI logic lives in ViewModels, with only simple UI/layout logic in widgets.
- Use unidirectional data flow: UI event -> ViewModel -> Repository -> data -> notify UI.
- Use immutable models; consider `freezed` or `built_value` when helpful.
- Use abstract repository interfaces and keep dependencies private.
- Use Result objects and Command pattern when it simplifies async UI state and error handling.

## Dependency Injection & Navigation

- Use `provider` for dependency injection; inject via constructors and avoid global singletons.
- Use `go_router` for navigation; avoid named routes; prefer Router-based `MaterialApp`.
- Create ViewModels in route builders and pass them into Views.

## Data & Storage (SQL)

- Follow Flutter SQLite guidance: `sqflite` + `path` with a DatabaseService behind repositories.
- Keep table/column names as constants; use `whereArgs` (no string interpolation in SQL).
- Consider `sqflite_common_ffi` for desktop if needed; web support is experimental.

## Testing

- Unit test services, repositories, and ViewModels; widget test Views; use integration tests for critical flows.
- Prefer fakes/mocks for dependencies; test DI wiring and routing.
- Mirror `lib/` structure under `test/`; use a `testing/` folder for shared fakes if useful.

## UI & Theming

- Use Material 3 components and `ColorScheme` roles.
- Keep typography default to Material 3 unless explicitly overridden.

## Code Quality

- Generate clean, production-ready code.
- Minimize inline code comments; only explain non-obvious logic.
- Add or update tests before implementing any feature; use tests to validate expected behavior.

## References

- Reference official Flutter/Dart documentation where applicable.
