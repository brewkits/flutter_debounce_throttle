# Project: flutter_debounce_throttle

A high-performance, memory-safe, and lifecycle-aware suite of rate-limiting and concurrency control tools for Flutter and Dart.

## Project Overview

This project is a **Flutter/Dart Monorepo** managed by **Melos**. It provides a robust set of utilities for debouncing, throttling, and rate-limiting (Token Bucket), with specialized support for asynchronous operations and Flutter lifecycle management.

### Key Packages
- **`dart_debounce_throttle`**: Pure Dart core (zero Flutter dependencies). Use for CLI, server-side, or pure Dart projects.
- **`flutter_debounce_throttle`**: Flutter-specific widgets, controllers, and `EventLimiterMixin`.
- **`flutter_debounce_throttle_hooks`**: Integration for `flutter_hooks` (e.g., `useDebouncer`).

### Core Architecture Principles
- **Separation of Concerns**: Core logic resides in `dart_debounce_throttle`. UI-specific logic is isolated in the Flutter/Hooks packages.
- **Memory Safety**: Includes auto-cleanup for dynamic limiters (v2.3.0+) and verified with `LeakTracker`.
- **Zero External Dependencies**: Only uses `meta` in production to keep the footprint minimal.
- **Concurrency Control**: Supports 4 modes: `drop`, `enqueue`, `replace`, and `keepLatest`.

---

## Building and Running

The project uses `Melos` for workspace-wide task orchestration.

### Initial Setup
```bash
# Activate Melos globally
dart pub global activate melos

# Bootstrap the workspace (install dependencies and link local packages)
melos bootstrap
```

### Key Commands
| Task | Command | Description |
|------|---------|-------------|
| **Test (All)** | `melos run test` | Runs tests in all packages. |
| **Test (Core)** | `melos run test:core` | Runs pure Dart tests for the core package. |
| **Analyze** | `melos run analyze` | Runs `flutter analyze` across the monorepo. |
| **Format** | `melos run format` | Runs `dart format` on all files. |
| **Clean** | `melos run clean` | Cleans build artifacts in all packages. |
| **Get Deps** | `melos run get` | Runs `pub get` in all packages. |

---

## Development Conventions

### Coding Style & Linting
- Follows `package:flutter_lints/flutter.yaml`.
- Lines should be kept within **80 characters**.
- Use `PascalCase` for classes/enums, `camelCase` for members/functions, and `snake_case` for files.

### Package Dependency Rules
- **`dart_debounce_throttle`**: MUST NOT have any Flutter dependencies or imports.
- **`flutter_debounce_throttle`**: Depends on `dart_debounce_throttle`.
- **`flutter_debounce_throttle_hooks`**: Depends on `flutter_debounce_throttle`.

### Testing Standards
- **High Coverage**: Aim for 95%+ code coverage.
- **Verification**: New features must include unit tests. Flutter widgets must include widget tests.
- **Memory Safety**: Use `LeakTracker` when testing new Flutter widgets or controllers to ensure no leaks occur during disposal.

### Contribution & Release
- **Batching**: Small metadata fixes or dependency bumps should be batched into a single release.
- **Release Cadence**: Minimum gap of 2 weeks between releases to avoid pub.dev volatility.
- **Changelog**: All packages must maintain an accurate `CHANGELOG.md`.

---

## Documentation References
- [FAQ.md](FAQ.md): Common questions and troubleshooting.
- [docs/BEST_PRACTICES.md](docs/BEST_PRACTICES.md): Recommended patterns for buttons, search, and more.
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md): Help for users switching from other libraries.
