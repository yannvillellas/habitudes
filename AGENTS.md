# Flutter Coding Standards

This file encodes all Flutter architecture recommendations from the official docs.
Sources: [Architecture guide](https://docs.flutter.dev/app-architecture/guide),
[Case study](https://docs.flutter.dev/app-architecture/case-study),
[Concepts](https://docs.flutter.dev/app-architecture/concepts),
[Recommendations](https://docs.flutter.dev/app-architecture/recommendations),
[Design patterns](https://docs.flutter.dev/app-architecture/design-patterns),
[Navigation](https://docs.flutter.dev/ui/navigation).

## Core Principles

- **Separation of concerns**: UI layer and data layer are distinct. UI displays data and receives user input; data layer manages application data and business logic. (Strongly recommend)
- **Layered architecture**: Each layer communicates only with the layer directly below or above it. UI → ViewModel → Repository → Service. The UI layer depends on ViewModels; the data layer depends on services. Layers never skip a level.
- **Single source of truth**: Every data type has one owning repository. Only that repository mutates it.
- **Unidirectional data flow**: Data flows down (repository → view model → view). Events flow up (view → view model → repository).
- **UI is a function of immutable state**: Widgets render from immutable data snapshots. Data drives UI, never the reverse.
- **Extensibility**: Every architectural component has well-defined inputs and outputs. Concrete implementations can be swapped without changing consumers.
- **Testability**: Every component has well-defined inputs/outputs so dependencies can be faked.

## Package Structure

Follow the [Compass app layout](https://github.com/flutter/samples/tree/main/compass_app):

```text
lib/
  data/                   # Organized by TYPE (repos/services shared across features)
    repositories/
    services/
    model/                # API models (raw data from services), if needed
  domain/
    models/               # Domain models (shared by data and UI layers)
  ui/                     # Organized by FEATURE
    core/                 # Shared widgets
      ui/
    <feature>/
      view_models/
      widgets/            # <feature>_screen.dart + sub-widgets
  config/
  utils/
  routing/
  main.dart

test/                     # Mirrors lib/ structure
  data/
  domain/
  ui/

testing/                  # Root-level: fakes, mocks (a "version of your app you don't ship")
  fakes/
```

- Data layer: by type. UI layer: by feature.
- `testing/` is a sibling of `lib/` and `test/`, not nested inside `test/`.
- Shared widgets live in `ui/core/`.
- Themes and app-wide configuration live in `lib/config/`.

## Data Layer

### Repositories

- Repository = single source of truth for one data type.
- One abstract repository interface per data type. Concrete implementations per environment (e.g., `HabitRepository` + `HabitRepositorySqflite`). (Strongly recommend)
- Repositories output **domain models**, not raw rows/API models.
- Repositories handle: caching, error handling, retry logic, polling, data refresh.
- Repositories are independent of each other. Combine data from multiple repos in the view model or domain layer.
- Repository dependencies (services) are **private** members.
- Repositories can manage app-wide session state (in-memory caches, user sessions).

### Services

- Services wrap external data sources (platform APIs, REST endpoints, local databases, files).
- Services are **stateless** — they hold no state, only expose async responses (`Future`, `Stream`).
- One service class per data source.
- Services and repositories: many-to-many relationship.

### Domain Models

- Immutable data classes. Use `@immutable` annotation. (Strongly recommend)
- Consider `freezed` or `built_value` for code generation (copyWith, equality, JSON). (Recommend)
- Live in `lib/domain/models/`. Used by both data and UI layers.
- For small/medium apps, domain models can serve double duty (no separate API models needed). Add separate API models in `lib/data/model/` only when the API/DB shape differs significantly from the domain shape, or when serialization concerns would pollute domain models. (Conditional)
- Avoid `dynamic`; use explicit types.

## UI Layer

### ViewModels

- ViewModel = Dart class handling UI logic. Extends `ChangeNotifier`. (Conditional but recommended)
- One ViewModel per View (1:1 relationship). Note: a "View" is a logical screen or feature, not a single widget. One View may be composed of multiple widgets. The 1:1 relationship is between ViewModel and the logical View, not individual widgets.
- ViewModel inputs: repositories (injected via constructor, stored as **private** members).
- ViewModel outputs: UI state (immutable snapshots of data), commands (callbacks for user events). Use `UnmodifiableListView` for lists.
- Call `notifyListeners()` after state changes to trigger widget rebuilds.
- ViewModel depends on repositories, never knows about views.
- Create ViewModels in go_router route builders using `context.read<Repository>()`.

### Views

- View = a widget class that takes a ViewModel as constructor parameter (`required this.viewModel`). Prefer `StatelessWidget`; use `StatefulWidget` only when the view must manage widget lifecycle (e.g., `TextEditingController`, `AnimationController`).
- Views contain **no business logic**. Only:
  - Simple if-statements to show/hide widgets based on ViewModel state
  - Animation logic
  - Layout logic (screen size, orientation)
  - Simple routing logic
- Use `ListenableBuilder(listenable: viewModel, ...)` to rebuild when ViewModel notifies changes.
- Never access repositories directly from a view. Only through the ViewModel.

### Commands (optional, for complex async UI)

- Command pattern wraps async operations with `running`, `completed`, `error` states.
- Useful for loading indicators, error handling, preventing double-submit.
- Consider `flutter_command` package or write a simple `Command` class that extends `ChangeNotifier`.

### Result objects (optional, for error handling)

- `Result<T>` (Ok/Error) standardizes async error handling across services and repositories.
- See [Result cookbook recipe](https://docs.flutter.dev/app-architecture/design-patterns/result).

### Other design patterns

- [Optimistic state](https://docs.flutter.dev/app-architecture/design-patterns/optimistic-state): Update UI before server confirmation for perceived responsiveness. Useful as apps grow beyond CRUD.
- [Offline-first support](https://docs.flutter.dev/app-architecture/design-patterns/offline-first): Cache data locally and sync when connectivity returns. Builds on the repository pattern.
- [Persistent storage: Key-value](https://docs.flutter.dev/app-architecture/design-patterns/kv-store) and [SQL](https://docs.flutter.dev/app-architecture/design-patterns/sql): Official patterns for on-device storage (see Data & Storage section below).

## Dependency Injection

- Use `package:provider` for DI. (Strongly recommend)
- Expose repositories and services as providers at the top of the widget tree via `MultiProvider`.
- Services are provided solely to be injected into repositories via `context.read`.
- Repositories are exposed so ViewModels can inject them.
- ViewModels are created in go_router route builders, injecting repos via `context.read<Repository>()`.
- Injected dependencies must be **private** members on the consuming class.
- No global singletons; no service locators.

## Navigation

- Use `go_router` for routing. (Recommend)
- Never use named routes (`Navigator.pushNamed`).
- Use the `MaterialApp.router` constructor with `GoRouter`.
- Route builders create ViewModels and pass them to Views.
- Use `ShellRoute` for persistent scaffolds (bottom nav, etc.).
- Use `context.push()` for sub-routes, `context.go()` for top-level navigation.

## Data & Storage (SQL)

- Use `sqflite` + `path` for local SQL databases.
- Wrap sqflite in a `DatabaseService` (stateless service following the service pattern).
- Repository consumes `DatabaseService` and transforms rows → domain models.
- Keep table/column names as constants; use `whereArgs` (never string interpolation in SQL).
- Consider `sqflite_common_ffi` for desktop/test; web support is experimental.

## UI & Theming

- Use Material 3 (`useMaterial3: true`).
- Use `ColorScheme` roles; never hard-code colors.
- Use `ColorScheme.fromSeed` for seed-generated color schemes.
- On Android 12+, use platform dynamic color via `DynamicColorBuilder` or `ColorScheme.fromImageProvider`.
- Keep typography to Material 3 defaults unless explicitly overridden.
- Prefer `const` widgets.

## Testing

- Unit test: services, repositories, ViewModels.
- Widget test: Views.
- Integration test: critical flows.
- Use fakes (not mocks) where possible — implement the same interface with in-memory storage.
- Fakes live in `testing/fakes/` at project root.
- `test/` directory mirrors `lib/` structure as a guideline. A root-level smoke test for `main.dart` is acceptable.
- **Import style** (follows the [Compass app](https://github.com/flutter/samples/tree/main/compass_app) pattern and [Effective Dart](https://dart.dev/effective-dart/style)):
  - `test/` → `lib/`: use `package:` imports (required by `avoid_relative_lib_imports` lint).
  - `test/` → `testing/`: use relative imports (e.g. `../../testing/fakes/fake_habit_repository.dart`).
  - `testing/` → `lib/`: use `package:` imports.
  - Within `lib/`: use relative imports.
- ViewModel tests: inject `Fake*Repository`. Only fakes needed — no Flutter framework.
- View widget tests: create real ViewModel with fake repositories, use `pumpWidget` with providers.
- Data layer tests: inject fake services into repositories, or use in-memory SQLite via `sqflite_common_ffi`.
- Test DI wiring and routing.

## Code Quality

- Use Dart null safety; avoid `dynamic` unless required.
- Keep widgets small and composable; extract reusable pieces.
- Use immutable models. Use `const` constructors where possible.
- Minimize inline comments; only explain non-obvious logic.
- Add or update tests before implementing any feature.
- Ask before introducing a new state management library or architecture change.
- Follow standardized naming: `{Entity}ViewModel`, `{Entity}Screen`, `{Entity}Repository`, `{DataSource}Service`.
  Do not use names that conflict with Flutter SDK classes.
- Use the [`flutter_lints`](https://pub.dev/packages/flutter_lints) package for the Flutter team's recommended lint set. (Recommend)

## Optional: Domain Layer

- Add use-cases for complex logic that merges multiple repositories, or logic reused across ViewModels.
- Use-cases depend on repositories. ViewModels depend on use-cases and/or repositories.
- Not needed for simple CRUD apps. Add reactively, not proactively.

## Recommended Resources

- [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)
- [Flutter architecture case study](https://docs.flutter.dev/app-architecture/case-study)
- [Flutter architecture concepts](https://docs.flutter.dev/app-architecture/concepts)
- [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations)
- [Flutter design patterns](https://docs.flutter.dev/app-architecture/design-patterns)
- [Flutter navigation](https://docs.flutter.dev/ui/navigation)
- [Compass app source code](https://github.com/flutter/samples/tree/main/compass_app)
- [Very Good CLI](https://cli.vgv.dev/) — Alternative Flutter app template by VGV
- [Very Good Engineering docs](https://engineering.verygood.ventures/architecture/architecture/) — Architecture articles and patterns
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools) — Performance and debugging tooling
- [`flutter_lints`](https://pub.dev/packages/flutter_lints) — Official Flutter lint package
