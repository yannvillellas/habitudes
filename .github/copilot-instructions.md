# Flutter Coding Standards

## General

- Use Dart null safety and avoid `dynamic` unless required.
- Prefer `const` widgets and values where possible.
- Keep widgets small and composable; extract reusable pieces.
- Avoid hard-coded colors; use `Theme.of(context).colorScheme` and `TextTheme`.
- Ask before introducing a new state management library or architecture.

## UI & Theming

- Use Material 3 components and `ColorScheme` roles.
- Keep typography default to Material 3 unless explicitly overridden.

## Code Quality

- Generate clean, production-ready code.
- Minimize inline code comments; only explain non-obvious logic.
- Add tests for non-trivial logic when requested.

## References

- Reference official Flutter/Dart documentation where applicable.
